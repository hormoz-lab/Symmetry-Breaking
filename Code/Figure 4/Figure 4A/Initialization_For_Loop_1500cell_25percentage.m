% ===================================================================================================
% Symmetry Breaking Simulation - Initialization, Cell Position Randomization
% This section generates a 3D lattice of initial cell positions,
% centered at the origin, and spaced according to diameter × packing factor.
% (can be replaced by loading saved positions, WorkSpace_MatrixP_Initial)
% ===================================================================================================

% Step 1: Define Initial Parameters
% Step 1.1:Define Population and Time Step 
Population       = 15:15:1500;                 % List of candidate population sizes to sweep
SAMPLE           = 10;                         % Number of stochastic replicates to potentially run
r                = 1;                          % Radius of each cell
dt               = 0.01;                       % Time step size for the simulation
Tmax             = 50;                         % Simulation runs from t=0 to t=5*Tmax
GeneNum          = 3;                          % Number of genes (gene1, gene2, gene3)
outer_fraction   = 0.25;                       % Percentage of total cells classified as outer cells

% Step 1.2: Define Lattice Grid 
NNN              = 15;                         % Number of grid points in each spatial dimension (X, Y, Z)
                                               % Total candidate points = NNN^3 = 3375

InitialPosition  = [];                         % Container to store unshuffled lattice positions (Nx3)
InitialPosition0 = [];                         % Temporary container for shuffled positions
MatrixP          = [];                         % Final cell positions (used after relaxation)

kappaF           = 0.1;                        % Strength of random noise during initial force relaxation
f0               = 1;                          % Force constant for mechanical repulsion between cells

% Step 1.3: Define spacing factor between cells 
alphaMAX         = 0.95;                       % Maximum alpha (looser packing)
alphaMIN         = 0.65;                       % Minimum alpha (tighter packing)
alpha            = (alphaMAX + alphaMIN) / 2;  % Use the midpoint value: 0.80 (moderate overlap)
delta_alpha      = alphaMAX - alphaMIN;        % Span of alpha values (not used here)

% Step 1.4: Define parent path
parent_path      = '/n/scratch/users/s/suw469/gastruloids_1500_25%_check';

% Step 2: Construct 3D lattice of candidate positions
% Centered around (0, 0, 0), scaled by cell diameter and packing (2 * r * alpha)
for x = 1:NNN
    for y = 1:NNN
        for z = 1:NNN
            % Compute centered grid coordinate
            % (x, y, z) ranges from 1 to NNN, so subtract (NNN+1)/2 to center at 0
            coord           = [x - (NNN+1)/2, y - (NNN+1)/2, z - (NNN+1)/2];

            % Scale by 2 * r * alpha
            % - 2r = cell diameter
            % - alpha = packing factor (e.g. 0.8 means slight overlap)
            scaled_coord    = coord * 2 * r * alpha;

            % Append to the list of initial candidate positions
            InitialPosition = [InitialPosition; scaled_coord];
        end
    end
end


% Step 3: Select Specific Population Size (1500 cells when I = 100) 
for I = 100 % population = 1500

    population = Population(I);  % Set number of cells for this simulation
    % Preallocate noise arrays:
    % Noise{1, sample} → cell movement noise (x/y/z)
    % Noise{2, sample} → gene expression noise (gene1/gene2/gene3)
    %Noise = cell(2, SAMPLE);  % 2 types of noise × number of samples
    Noise = cell(1, SAMPLE);  % (changed) consider only cell movement noise (x/y/z) but not gene 

    % Step 4: Loop over replicates (Sample = 1 to 10)
    for Sample = 1:SAMPLE  % (changed) 

        % Step 4.1: Create an output folder for this replicate
        output_folder = fullfile(parent_path, ['OUTPUT', num2str(Sample)]);
        mkdir(output_folder);

        % Step 4.2: Shuffle all candidate positions to remove bias 
        InitialPosition_shuffled = InitialPosition(randperm(size(InitialPosition, 1)), :);

        % Step 4.3: Select N nearest points to the origin
        Distance                 = sqrt(sum((InitialPosition_shuffled.^2)'))';          % Distance from origin
        Distance0                = sort(Distance);                                      % Sorted distances
        Indices                  = find(Distance <= Distance0(population));             % Indices of N nearest points
        indices                  = Indices(1:population);             
        InitialPosition_shuffled = InitialPosition_shuffled(indices, :);   % Final selected initial positions
        clear Indices; clear indices;

        % Step 4.4: Initialize interaction matrix and cell list
        MatrixP                  = InitialPosition_shuffled;                            % Final cell position matrix
        num_cells                = size(MatrixP, 1);                                    % total number of cells, should be 1500 here 
        fprintf('Number of cells: %d\n', num_cells);
        Alpha                    = NaN * zeros(num_cells, num_cells);                   % N x N interaction matrix initialized with NaN

        % Step 4.5: Fill interaction matrix with constant alpha value for all distinct cell pairs 
        for cellA = 1:num_cells
            for cellB = 1:num_cells
                if cellA ~= cellB
                    Alpha(cellA, cellB) = alpha;                                        % Uniform interaction strength
                end
            end
        end

        % Step 4.6: Generate and store noise for each sample 
        % Create 3D Gaussian noise arrays:
        % Shape: [cells, 3, time]
        % - 3 = x/y/z for movement OR gene1/gene2/gene3 for gene regulation
        % - Total time points = Tmax * 5 / dt

        % Movement noise (for physical position updates in 3D space)
        Noise{1, Sample} = randn([population, 3, Tmax * 5 / dt]);  

        % Gene noise (for stochastic gene regulation, 3 genes)
        % Noise{2, Sample} = randn([population, 3, Tmax * 5 / dt]);  

        % Step 4.7: Force relaxation over time to resolve overlaps 
        for t = dt : dt : Tmax * 2                                                      % Simulate for 2*Tmax units of time
        
            MatrixF = zeros(size(MatrixP));                                             % Reset net force for each time step
        
            % Step 4.7.1: Compute Cell-Cell Distances
            % For DistanceX, Y, Z (which is actually displacement as it has sign/direction): 
            % At ith row, the values indicate the displacement FROM ith cell TO other cell    [ith cell - other cell]
            % At ith column, the values indicate the displacement FROM other cell TO ith cell [other cell - ith cell]
            % - Row i, Column j: displacement from cell i to cell j  →  (cell_i - cell_j)
            % - Row j, Column i: displacement from cell j to cell i  →  (cell_j - cell_i)
            % Diagonal entries are always 0 (distance from a cell to itself)
            % Eventually the dimension of DistanceX, Y, Z are all [num_cells x num_cells] 
            
            % MatrixP(:,1) [num_cell, 1], ones(1,size(MatrixP,1) [1, num_cell]
            % MatrixP(:,1) * ones(1,size(MatrixP,1)) [num_cell, num_cell], each column represent all cells in x-direction, and each row is the replicate of this 
            % ones(size(MatrixP,1),1) [num_cell, 1], MatrixP(:,1)' [1, num_cell]
            % ones(size(MatrixP,1),1) * MatrixP(:,1)' [num_cell, num_cell], each row represent all cells in x-direction, and each column is the replicate of this 
            
            DistanceX = MatrixP(:,1) * ones(1,size(MatrixP,1)) - ones(size(MatrixP,1),1) * MatrixP(:,1)';  
            DistanceY = MatrixP(:,2) * ones(1,size(MatrixP,1)) - ones(size(MatrixP,1),1) * MatrixP(:,2)';  
            DistanceZ = MatrixP(:,3) * ones(1,size(MatrixP,1)) - ones(size(MatrixP,1),1) * MatrixP(:,3)';  
            Distance  = sqrt(DistanceX.^2 + DistanceY.^2 + DistanceZ.^2);   
        
            % Step 4.7.2 Loop over each cell to compute short-range force 
            for N = 1:num_cells

                % Find valid neighbor cells within short-range (< 2*r) and exclude self-interaction
                valid             = intersect(find(~isnan(Alpha(:, N))), find(Distance(:, N) < 2 * r));              
                if isempty(valid) 
                    continue;                                                                            % No interaction partners → skip
                end
                
                % Compute unit vectors for direction information
                direction         = [DistanceX(valid, N), DistanceY(valid, N), DistanceZ(valid, N)];     % Compute unit direction vectors, (valid, N) indicate distance cells_valid - cell_N
                unit_vector       = direction./ (Distance(valid, N) * ones(1,3));     

                % Compute short-range force based on distance
                alpha0            = Alpha(valid, N) * ones(1, 3);                                        % Expand interaction scale to 3D (x, y, z) for each neighbor, [#neighbors × 3]
                force_magnitude   = - f0 ./ (2 * r * alpha0) .* (Distance(valid, N) * ones(1, 3)) + f0;  % Compute pairwise force magnitudes using linear soft-core repulsion
                force             = - force_magnitude .* unit_vector;     

                % Accumulate total force on cell N 
                if     size(force, 1) == 1      
                    MatrixF(N, :) = MatrixF(N, :) + force;                                               % If one neighbor: add vector directly
                elseif size(force, 1) > 1       
                    MatrixF(N, :) = MatrixF(N, :) + sum(force, 1);                                       % If multiple neighbors: sum forces component-wise (x, y, z)
                end
            end

            % Step 4.7.3 Update positions with deterministic and stochastic movement 
            noise_term            = kappaF * sqrt(dt) * Noise{1, Sample}(:, :, round(t / dt));
            MatrixP               = MatrixP + MatrixF * dt + noise_term;

        end

        % Step 4.8: Recenter the entire system and Save Position Matrix
        MatrixP                   = MatrixP - ones(size(MatrixP, 1),1) * mean(MatrixP);                  % Subtract center of mass
        output_file_path_P        = fullfile(parent_path, ['OUTPUT', num2str(Sample)], 'WorkSpace_MatrixP_Initial.csv');   
        writematrix(MatrixP, output_file_path_P);  

        % Step 4.9: Initialize Gene Expression Matrix and Save it
        MatrixG                   = zeros(size(MatrixP, 1), GeneNum);                                    % Initialize MatrixG with all gene values be zero
        distance_to_origin        = sqrt(sum((MatrixP.^2)'))';                                           % Compute distance of each cell from origin
        [~, sorted_indices]       = sort(distance_to_origin, 'descend');                                 % Sort distances in descending order
        top_n                     = round(outer_fraction * num_cells);
        top_indices               = sorted_indices(1:top_n);
        MatrixG(top_indices, 2)   = 1;                                                                   % Set Gene 2 = 1 for those farthest cells

        num_gene2_cells           = sum(MatrixG(:, 2) == 1);                                             % Double check
        fraction_gene2            = num_gene2_cells / num_cells;
        fprintf('%d cells over total %d cells set gene 2 = 1, which is %.3f fraction.\n', ...
        num_gene2_cells, num_cells, fraction_gene2);

        output_file_path_G        = fullfile(parent_path, ['OUTPUT', num2str(Sample)], 'WorkSpace_MatrixG_Initial.csv');
        writematrix(MatrixG, output_file_path_G);

    end

    % Save the complete Noise variable (all samples) to the general folder
    noise_filename = fullfile(parent_path, 'Noise.mat');
    save(noise_filename, 'Noise', '-v7.3');

end
