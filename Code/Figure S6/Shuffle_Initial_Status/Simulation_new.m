%% --- Section 1: Initialize Simulation Parameters ---

% Simulation constants
dt       = 0.2;          % Time step size
dt_ini   = 0.01;         % Time step set at Initilization code
Tmax     = 50;           % Total simulation steps (t=0 to 5*Tmax)
r        = 1;            % Radius of each cell
f0       = 1;            % Mechanical repulsion strength
friction = 1;            % Potential friction
kappaF   = 0.1;          % Noise strength for physical movement
D1       = 2;            % Power-law decay exponent of signal

% User-defined parameter set
Aii      = 0.775;
Aoo      = 0.950;
Aio      = 0.875;
BLii     = 0;
BLoo     = 0.135;
BLio     = 0;
BLoi     = 0;
row      = [Aii, Aoo, Aio, BLii, BLoo, BLio, BLoi];

%% --- Section 2: Define File Paths and Load Data ---

% Define paths
library_path              = '/n/data1/hms/sysbio/hormoz/users/suxuan/gastruloids_1500_25%_check';
parent_path               = '/n/data1/hms/sysbio/hormoz/users/suxuan/Materials/Codes/Virtual_Experiment/Experiment 4/Shuffle_Initial_Status';

% Load Noise  
noise_path      = '/n/data1/hms/sysbio/hormoz/users/suxuan/Materials/Codes/Virtual_Experiment';                                         
noise_filename  = fullfile(noise_path, 'Noise_s10_p3000_t3000'); 
load(noise_filename, 'Noise');

% Load all alpha and betaL combinations from scanning library to find matching row index
scanning_library_filename = fullfile(library_path, 'scanning_library.mat'); % Path to scanning library file
load(scanning_library_filename, 'scanning_library');                        % 7 terms: alpha_ii, alpha_oo, alpha_io, betaL_ii, betaL_oo, betaL_io, betaL_oi (order matter!)
rounded_library       = round(scanning_library, 4);
rounded_row           = round(row, 4);
[is_match, combo_idx] = ismember(rounded_row, rounded_library, 'rows');
if is_match
    fprintf('Match found at row index: %d\n', combo_idx);
else
    error('No exact match found for the specified Aii/Aoo/Aio/Beta values.');
end

% 1) Create "video" subfolder
video_root = fullfile(parent_path, 'Simulation', ...
             sprintf('Aii_%.3f_Aoo_%.3f_Aio_%.3f_BLii_%.3f_BLoo_%.3f_BLio_%.3f_BLoi_%.3f_D1_%d_tmax_3000', ...
             Aii, Aoo, Aio, 0.135, BLoo, BLio, BLoi, D1));
if ~exist(video_root, 'dir'), mkdir(video_root); end
% 2) Create OUTPUT6..OUTPUT10 inside "video"
for s = 6:10
    out_dir_s = fullfile(video_root, sprintf('OUTPUT%d', s));
    if ~exist(out_dir_s, 'dir'), mkdir(out_dir_s); end
end

%% --- Section 3: Run Simulation for 5 Samples ---

% Start parallel pool with 6 workers
if isempty(gcp('nocreate'))
    parpool('local', 6); % Starts a pool with 6 workers
end

parfor Sample = 6:10

    sample_folder             = fullfile(parent_path, 'Initial_Status', ['OUTPUT', num2str(Sample)]);
    sample_dir                = fullfile(video_root, sprintf('OUTPUT%d', Sample));
    
    % Input files for initial position and gene expression
    input_file_path_P         = fullfile(sample_folder, 'WorkSpace_MatrixP_Initial.csv');
    input_file_path_G         = fullfile(sample_folder, 'WorkSpace_MatrixG_Shuffled.csv');
    
    % Total number of cells
    MatrixP                   = cell2mat(table2cell(readtable(input_file_path_P)));
    num_cells                 = size(MatrixP, 1);
    
    % Reload initial position and gene expression (independent copy for each loop)
    MatrixP = cell2mat(table2cell(readtable(input_file_path_P)));
    MatrixG = cell2mat(table2cell(readtable(input_file_path_G)));
    
    % Assign current alpha and betaL values
    % oo, ii, io, oi indicate the cell type of two cells, where o stand for outer cell type and i stand for inner cell type
    % alpha is the short-range force strength scaling factor
    alpha_ii = scanning_library(combo_idx, 1); % ii: Short-range force between inner cell and inner cell
    alpha_oo = scanning_library(combo_idx, 2); % oo: Short-range force between outer cell and outer cell
    alpha_io = scanning_library(combo_idx, 3); % io: Short-range force between inner cell and outer cell (io, oi order does not matter right now)
    
    % betaL is the long-range force strength scaling factor
    % Long-range force has specific direction: the first cell apply the long-range force to the second cell. (for example 'io' means the inner cell apply force to the outer cell)
    % + Positive betaL value indicate ATTRACTION from the first cell to the second cell.
    % - Negative betaL value indicate REPULSION from the first cell to the second cell. 
    betaL_ii = scanning_library(combo_idx, 4); % ii: Long-range force from inner cell to inner cell
    betaL_oo = scanning_library(combo_idx, 5); % oo: Long-range force from outer cell to outer cell
    betaL_io = scanning_library(combo_idx, 6); % io: Long-range force from inner cell to outer cell (order matter !)
    betaL_oi = scanning_library(combo_idx, 7); % oi: Long-range force from outer cell to inner cell (order matter !)
    
    betaL_ii = betaL_oo;

    % Calculating Short-Range Force Strength (Scaling) 
    ShortRangeScale = ones(num_cells, num_cells);
    for cellA = 1:num_cells
        G2_cellA = MatrixG(cellA, 2);                         % Gene 2 in cell A
        for cellB = 1:num_cells
            if cellA == cellB
                ShortRangeScale(cellA, cellB) = NaN;          % No self-interaction
            else 
                G2_cellB = MatrixG(cellB, 2);                 % Gene 2 in cell B
                if     G2_cellA == 1 && G2_cellB == 1
                    ShortRangeScale(cellA, cellB) = alpha_oo;
                elseif G2_cellA == 0 && G2_cellB == 0
                    ShortRangeScale(cellA, cellB) = alpha_ii;
                else
                    ShortRangeScale(cellA, cellB) = alpha_io;
                end
            end
        end
    end
    
    num_issue = sum(ShortRangeScale(:) == 1, 'omitnan');      % Count exactly equal to 1 
    if num_issue > 0
        fprintf('⚠️ Found %d ShortRangeScale entries exactly equal to 1.\n', num_issue);
    else
        fprintf('✅ No ShortRangeScale entries exactly equal to 1.\n');
    end
    
    % Calculating Long-Range Force Strength (Scaling) 
    LongRangeScale = ones(num_cells, num_cells);
    % Cell A apply the Long-Range Force to Cell B
    % - ith row represent the long-range force (scale) of ith cell applied TO other cells, e.g. LongRangeScale(N, :)
    % - ith column represent the long-range force (scale) of ith cell received FROM other cells, e.g. LongRangeScale(:, N)
    for cellA = 1:num_cells
        G2_cellA = MatrixG(cellA, 2);                         % Gene 2 in cell A
        for cellB = 1:num_cells
            if cellA == cellB
                LongRangeScale(cellA, cellB) = NaN;           % No self-interaction
            else
                G2_cellB = MatrixG(cellB, 2);                 % Gene 2 in cell B
                if     G2_cellA == 1 && G2_cellB == 1         % outer A apply force to outer B
                    LongRangeScale(cellA, cellB) = betaL_oo;
                elseif G2_cellA == 0 && G2_cellB == 0         % inner A apply force to inner B
                    LongRangeScale(cellA, cellB) = betaL_ii;
                elseif G2_cellA == 1 && G2_cellB == 0         % outer A apply force to inner B
                    LongRangeScale(cellA, cellB) = betaL_oi;
                elseif G2_cellA == 0 && G2_cellB == 1         % inner A apply force to outer B 
                    LongRangeScale(cellA, cellB) = betaL_io;
                end
            end
        end
    end
    
    num_issue = sum(LongRangeScale(:) == 1, 'omitnan');       % Count exactly equal to 1 
    if num_issue > 0
        fprintf('⚠️ Found %d LongRangeScale entries exactly equal to 1.\n', num_issue);
    else
        fprintf('✅ No LongRangeScale entries exactly equal to 1.\n');
    end
    
    
    % Time Integration Loop 
    for t = Tmax*2 + dt : dt : Tmax*12
    
        frame_idx = round(t / dt) - 1;                        % integer index per your code
        % Optional: zero-pad indices, e.g., idx_str = sprintf('%04d', frame_idx);
        idx_str   = sprintf('%d', frame_idx);
    
        % Step 0: Write to the correct OUTPUT# folder under beta_zero_top_asymmetry_video/
        writematrix(MatrixP, fullfile(sample_dir, sprintf('WorkSpace_MatrixP_%s.csv', idx_str)));
        writematrix(MatrixG, fullfile(sample_dir, sprintf('WorkSpace_MatrixG_%s.csv', idx_str)));
    
        % Step 1: Compute Cell-Cell Distances
        % For DistanceX, Y, Z (which is actually displacement as it has sign/direction): 
        % At ith row, the values indicate the displacement FROM ith cell TO other cell    [ith cell - other cell]
        % At ith column, the values indicate the displacement FROM other cell TO ith cell [other cell - ith cell]
        % - Row i, Column j: displacement from cell i to cell j  →  (cell_i - cell_j)
        % - Row j, Column i: displacement from cell j to cell i  →  (cell_j - cell_i)
        % Diagonal entries are always 0 (distance from a cell to itself)
        % Eventually the dimension of DistanceX, Y, Z are all [num_cells x num_cells] 
        
        % MatrixP(:,1) [num_cell, 1], ones(1,size(MatrixP,1) [1, num_cell]
        % MatrixP(:,1) * ones(1,size(MatrixP,1)) [num_cell, num_cell], each column represent all cells in x-direction, and each row is the replicate of one cell in x-direction
        % ones(size(MatrixP,1),1) [num_cell, 1], MatrixP(:,1)' [1, num_cell]
        % ones(size(MatrixP,1),1) * MatrixP(:,1)' [num_cell, num_cell], each row represent all cells in x-direction, and each column is the replicate of one cell in x-direction 
        % [cell 1, cell 1, cell 1, ...] - [cell 1, cell 2, cell 3, ...] = [cell 1-1, cell 1-2, cell 1-3, ...]
        % [cell 2, cell 2, cell 2, ...]   [cell 1, cell 2, cell 3, ...]   [cell 2-1, cell 2-2, cell 2-3, ...]
        % [cell 3, cell 3, cell 3, ...]   [cell 1, cell 2, cell 3, ...]   [cell 3-1, cell 3-2, cell 3-3, ...]
        % [...   , ...   , ...   , ...]   [...   , ...   , ...   , ...]   [...     , ...     , ...     , ...]
        DistanceX = MatrixP(:,1) * ones(1,size(MatrixP,1)) - ones(size(MatrixP,1),1) * MatrixP(:,1)';  
        DistanceY = MatrixP(:,2) * ones(1,size(MatrixP,1)) - ones(size(MatrixP,1),1) * MatrixP(:,2)';  
        DistanceZ = MatrixP(:,3) * ones(1,size(MatrixP,1)) - ones(size(MatrixP,1),1) * MatrixP(:,3)';  
        Distance  = sqrt(DistanceX.^2 + DistanceY.^2 + DistanceZ.^2);                                             % Euclidean distance [N × N], at ith row/column, the values indicate the distance between all cells and ith cell
    
        MatrixF = zeros(size(MatrixP));                                                                           % Reset mechanical force accumulator
    
        % Step 2: Compute Mechanical Forces
        for N = 1:num_cells
    
            % Step 2.1: Compute Short-Range Force 
            valid_S              = intersect(find(~isnan(ShortRangeScale(:, N))), find(Distance(:, N) < 2 * r));  % Identify valid neighboring cells (distance < 2*r, not itself)
            direction_S          = [DistanceX(valid_S, N), DistanceY(valid_S, N), DistanceZ(valid_S, N)];         % Compute unit direction vectors, (valid, N) indicate distance cells_valid - cell_N
            unit_vector_S        = direction_S ./ (Distance(valid_S, N) * ones(1,3));                             % Normalize to unit vectors
    
            alpha0               = ShortRangeScale(valid_S, N) * ones(1, 3);                                      % Expand interaction scale to 3D (x, y, z) for each neighbor, [#neighbors × 3]
            force_magnitude      = - f0 ./ (2 * r * alpha0) .* (Distance(valid_S, N) * ones(1, 3)) + f0;          % Compute pairwise force magnitudes using linear soft-core repulsion
            force_short          = - force_magnitude .* unit_vector_S;                                            % Apply direction to convert magnitudes into 3D force vectors, [#neighbors × 3]
    
            if     size(force_short, 1) == 1                                                                      % Accumulate total short-range repulsive force on cell N  
                MatrixF(N, :)    = MatrixF(N, :) + force_short;                                                   % If one neighbor: add vector directly
            elseif size(force_short, 1) > 1 
                MatrixF(N, :)    = MatrixF(N, :) + sum(force_short, 1);                                           % If multiple neighbors: sum forces component-wise (x, y, z)
            end
    
            % Step 2.2: Compute Long-Range Force
            valid_L              = find(Distance(:, N) > 2 * r);                                                  % Identify valid long-range cells (distance > 2*r)
            direction_L          = [DistanceX(valid_L, N), DistanceY(valid_L, N), DistanceZ(valid_L, N)];         % Compute unit direction vectors, (valid, N) indicate distance cells_valid - cell_N
            unit_vector_L        = direction_L ./ (Distance(valid_L, N) * ones(1,3));                             % Normalize to unit vectors
    
            chemotactic_strength = LongRangeScale(valid_L, N);                                                    % Make sure the order is valid_L, N because the second cell N receive the force
            decay_factor         = (Distance(valid_L, N).^D1) * ones(1, 3); 
            force_long           = chemotactic_strength .* unit_vector_L ./ decay_factor;                         % Each vector is scaled by: LongRangeStrength × Unit_Vectors / (Distance^D1)
    
            MatrixF(N, :)        = MatrixF(N, :) + sum(force_long, 1);                                            % Accumulate net chemotactic force by adding all rows together
            
            % Step 2.3: Compute Potential Friction
            if isempty(valid_S)                                                                                   % Apply frictional damping if cell N has no short-range interactions
                net_force_magnitude = norm(MatrixF(N,:));                                                         % Compute total force magnitude
                if net_force_magnitude <= friction
                    MatrixF(N,:) = 0;                                                                             % If force is small, stop the cell completely
                else
                    MatrixF(N,:) = MatrixF(N,:) - friction * MatrixF(N,:) / net_force_magnitude;                  % Apply frictional drag opposite to current force direction
                end
            end
    
        end
    
        % Step 3: Update Positions with Deterministic and Stochastic Movement 
        noise_term               = kappaF * sqrt(dt) * Noise{1, Sample}(1:num_cells, :, round(t / dt_ini));
        MatrixP                  = MatrixP + MatrixF * dt + noise_term;
    
    end
    
    % % Step 4: Save final cell positions and gene expression states
    frame_idx = round(t / dt);
    idx_str   = sprintf('%d', frame_idx);
    writematrix(MatrixP, fullfile(sample_dir, sprintf('WorkSpace_MatrixP_%s.csv', idx_str)));
    writematrix(MatrixG, fullfile(sample_dir, sprintf('WorkSpace_MatrixG_%s.csv', idx_str)));

end