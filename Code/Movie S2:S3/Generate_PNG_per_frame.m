%% Step 1: USER SETTINGS
% Input and output files
input_path      = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Figure_4/Figure_4B/Aii_0.775_Aoo_0.950_Aio_0.875_BLii_0.000_BLoo_0.135_BLio_0.000_BLoi_0.000';
output_path     = '/Users/linda0122/Desktop/Materials/Movies/Movie S2';
base_name       = 'Movie_S2';
OUTPUTS         = 6:10;   
n_samples       = numel(OUTPUTS);

% Geometry configuration
cell_radius     = 1;                   
contact_thresh  = 2*cell_radius;      
num_face        = 100;   % mesh resolution for cell surfaces

% Frame configuration
T_MIN           = 501;
T_MAX           = 1251;
T_full          = T_MIN:T_MAX;           % full continuous list of frames

T_START         = 501;                   % first frame to render
T_END           = 1251;                   % last frame to render
T_STEP          = 100;                   % render every T_STEP frames (sampling interval)
T_render        = T_START:T_STEP:T_END;  % list of frames to render

% Figure layout configuration 
PNG_RESOLUTION  = 300;
SKIP_IF_EXISTS  = true;                  % set false to overwrite
FIG_POS         = [100, 100, 1600, 400]; % Figure window (identical across frames)
TITLE_FS        = 20;      
OUTPUT_FS       = 15;      


%% Step 2: Define the figure layout
% Step 2.1: Hard-coded normalized subplot positions 
sample_positions = {
    [0.02  0.00  0.18  0.70]    % replicate 1
    [0.22  0.00  0.18  0.70]    % replicate 2
    [0.42  0.00  0.18  0.70]    % replicate 3
    [0.62  0.00  0.18  0.70]    % replicate 4
    [0.82  0.00  0.18  0.70]    % replicate 5
};

% Step 2.2: Position for the time annotation centered above all plots
time_x = 0.39;                  % x position for the time annotation
time_y = 0.85;                  % y position for the time annotation
time_position = [time_x time_y 0.22 0.06];

% Step 2.3: Positions for replicate labels 
replicate_y = 0.65;             % y position for all replicate labels
replicate_w = 0.16;             % width of each label box
replicate_h = 0.045;            % height of each label box
replicate_positions = zeros(n_samples,4);
for s = 1:n_samples
    sample_position = sample_positions{s};
    center_x        = sample_position(1) + sample_position(3)/2;   % horizontal center of the specific sample subplot 
    replicate_positions(s,:) = [center_x - replicate_w/2, ...
                                replicate_y, replicate_w, replicate_h];
end
fprintf('Static subplot layout initialized\n');


%% Step 3: Compute global boundary
global_half_span = 0;   % Global bounding-box half-span (cubic bounds)

% Loop through each OUTPUT sample and each timestep
for n = OUTPUTS

    input_path_n = fullfile(input_path, sprintf('OUTPUT%d', n));

    for t = T_full

        % Step 3.1: Load positions and genes
        fileP = fullfile(input_path_n, sprintf('WorkSpace_MatrixP_%d.csv', t));
        fileG = fullfile(input_path_n, sprintf('WorkSpace_MatrixG_%d.csv', t));
        MatrixP = readmatrix(fileP);   
        MatrixG = readmatrix(fileG); 

        % Step 3.2: Identify the largest-cluster candidates
        idx_clusters = find_largest_cluster(MatrixP, contact_thresh);   
        if numel(idx_clusters) == 1
            % Single candidate → select directly
            idx_cluster_best = idx_clusters{1};
        else
            % Multiple candidates → select the one with the highest asymmetry
            N_inner_global = nnz(MatrixG(:, 2) == 0);
            N_outer_global = nnz(MatrixG(:, 2) == 1);
            asymmetry_max  = 0;
            for i = 1:numel(idx_clusters)
                asymmetry = compute_asymmetry( ...
                    MatrixP(idx_clusters{i}, 1:3), ... % Positions x, y, z
                    MatrixG(idx_clusters{i}, 2),   ... % Gene 2
                    N_inner_global, ...
                    N_outer_global);
                if asymmetry > asymmetry_max
                    asymmetry_max = asymmetry;
                    idx_cluster_best = idx_clusters{i};
                end
            end
        end
    
        % Step 3.3: Compute the center and half-span of the largest cluster
        [~, half_span] = compute_center_and_half_span(MatrixP(idx_cluster_best, :));

        % Step 3.4: Update the global half-span (used for a fixed visualization scale)
        if half_span > global_half_span
            global_half_span = half_span;
        end
    end
end

global_half_span = global_half_span + cell_radius;  % Add a safety margin equal to one cell radius (prevents clipping)
fprintf('Global cubic bounds: half-range = %.3f, full span = %.3f\n', global_half_span, 2*global_half_span);


%% Step 4: Render movie frames
fprintf('Rendering PNG frames for T in [%d : %d : %d]\n', T_START, T_STEP, T_END);
for T = T_render
    
    % Step 4.1: Define the output png filename and check whether it is already generated 
    frame_name = sprintf('%s_T_%05d', base_name, T);
    out_png    = fullfile(output_path, [frame_name '.png']);
    if SKIP_IF_EXISTS && exist(out_png,'file')
        fprintf('⏩ Skip existing: %s\n', out_png);
        continue;
    end

    % Step 4.2: Create the overall figure 
    f = figure('Position', FIG_POS, ...
               'Visible', 'off', ...
               'Color','w');

    % Step 4.3: Pre-create axes for all replicates
    axes_all = gobjects(1, n_samples);
    for s = 1:n_samples
        axes_all(s) = axes('Parent', f, ...
                           'Position', sample_positions{s}, ...
                           'Box','off', ...
                           'Visible','off');
        hold(axes_all(s),'on');
    end

    % Step 4.4: Loop through each replicate subplots
    for s = 1:n_samples

        % Step 4.4.1: Load sample index and axes 
        sample = OUTPUTS(s);
        ax     = axes_all(s);

        % Step 4.4.2: Load positions and genes
        fileP = fullfile(input_path, sprintf('OUTPUT%d', sample), sprintf('WorkSpace_MatrixP_%d.csv', T));
        fileG = fullfile(input_path, sprintf('OUTPUT%d', sample), sprintf('WorkSpace_MatrixG_%d.csv', T));
        MatrixP = readmatrix(fileP); 
        MatrixG = readmatrix(fileG); 

        % Step 4.4.3: Identify the largest-cluster candidates
        idx_clusters = find_largest_cluster(MatrixP, contact_thresh);   
        if numel(idx_clusters) == 1
            % Single candidate → select directly
            idx_cluster_best = idx_clusters{1};
        else
            % Multiple candidates → select the one with the highest asymmetry
            N_inner_global = nnz(MatrixG(:, 2) == 0);
            N_outer_global = nnz(MatrixG(:, 2) == 1);
            asymmetry_max  = 0;
            for i = 1:numel(idx_clusters)
                asymmetry = compute_asymmetry( ...
                    MatrixP(idx_clusters{i}, 1:3), ... % Positions x, y, z
                    MatrixG(idx_clusters{i}, 2),   ... % Gene 2
                    N_inner_global, ...
                    N_outer_global);
                if asymmetry > asymmetry_max
                    asymmetry_max = asymmetry;
                    idx_cluster_best = idx_clusters{i};
                end
            end
        end

        % Step 4.4.4: Create the 3D visualization of the largest cluster
        position = MatrixP(idx_cluster_best, :);
        gene_2   = MatrixG(idx_cluster_best, 2);
        draw_cell_structure_on_ax(ax, position, gene_2, global_half_span, cell_radius, num_face)
    end

    % Step 4.5: Time annotation
    t_value = T - T_MIN;  
    annotation('textbox', time_position, ...
               'String', sprintf('{\\it t} = %d', t_value), ...
               'HorizontalAlignment','center', ...
               'VerticalAlignment','middle', ...
               'EdgeColor','none', ...
               'FontSize', TITLE_FS, ...
               'Color','k');

    % Step 4.6: Replicate label annotations
    for s = 1:n_samples
        annotation('textbox', replicate_positions(s,:), ...
                   'String', sprintf('Replicate %d', s), ...
                   'HorizontalAlignment','center', ...
                   'VerticalAlignment','middle', ...
                   'EdgeColor','none', ...
                   'FontSize', OUTPUT_FS, ...
                   'Color','k');
    end

    % Step 4.7: Set all the text within the figure be Arial
    fontname(f,"Arial");

    % Step 4.8: Save PNG
    save_png_print(output_path, frame_name, f, PNG_RESOLUTION);  
    close(f);
end

fprintf('\n✅ Done. PNGs are in: %s\n', output_path);



%% Helper Functions
function idx_clusters = find_largest_cluster(MatrixP, contact_thresh)
% FIND_LARGEST_CLUSTER
% Returns indices for ALL clusters that tie for the largest size (i.e. maximum number of cells).
% Output is a cell array: each cell contains the row indices (into MatrixP/MatrixG) for one largest cluster.
%
% Inputs
%   MatrixP : N×3 positions [x y z]
%   contact_thresh : scalar; adjacency if cell-cell distance <= contact_thresh
%
% Output
%   idx_clusters : 1×M cell; each element is a vector of row indices for a largest cluster

    % Step 1: build adjacency by distance <= contact_thresh 
    N                = size(MatrixP,1);
    distance         = pdist2(MatrixP, MatrixP);
    distance_contact = (distance <= contact_thresh) & ~eye(N);

    % Step 2: connected components 
    graph_contact    = graph(sparse(triu(distance_contact,1)),'upper');
    cluster_labels   = conncomp(graph_contact);
    cluster_sizes    = accumarray(cluster_labels(:), 1);

    % Step 3: largest size & all labels that achieve it
    max_size   = max(cluster_sizes);
    labels_max = find(cluster_sizes == max_size);

    % Step 4: return ALL largest clusters 
    idx_clusters = cell(1, numel(labels_max));
    for i = 1:numel(labels_max)
        idx_clusters{i} = find(cluster_labels == labels_max(i));
    end

    % % (Optional)
    % if numel(labels_max) == 1
    %     fprintf('✅ Found one largest cluster (label=%d) with %d cells.\n', labels_max, numel(idx_clusters{1}));
    % else
    %     fprintf('✅ Found %d tied largest clusters (size=%d each). Returning all.\n', numel(labels_max), max_size);
    % end
end


function asymmetry = compute_asymmetry(position_cluster, gene_2_cluster, N_inner_global, N_outer_global)
% COMPUTE_ASYMMETRY
%
% Inputs
%   position_cluster : N×3 positions (x,y,z)
%   gene_2_cluster   : N×1 (0=inner, 1=outer)
%   N_inner_global   : scalar, total number of inner cells 
%   N_outer_global   : scalar, total number of outer cells
%
% Output
%   Returns a scalar asymmetry score >= 0
%   asymmetry = (||center_outer - center_inner|| / distance_center_avg) * (N_inner_local/N_inner_global) * (N_outer_local/N_outer_global)

    % Step 1: counts within the cluster
    N_inner_local = nnz(gene_2_cluster == 0);
    N_outer_local = nnz(gene_2_cluster == 1);

    % No separation if only one cell type present
    if N_inner_local == 0 || N_outer_local == 0
        asymmetry = 0;        
        return;
    end

    % Step 2: compute geometric center and mean distance to center
    center_cluster      = mean(position_cluster, 1);
    distance_center_avg = mean(vecnorm(position_cluster - center_cluster, 2, 2));  

    % Step 3: centers of outer/inner subsets
    center_outer = mean(position_cluster(gene_2_cluster == 1, :), 1);
    center_inner = mean(position_cluster(gene_2_cluster == 0, :), 1);

    % Step 4: compute weight based on cell number in the largest cluster versus the entire cell population
    inner_ratio = N_inner_local / N_inner_global;
    outer_ratio = N_outer_local / N_outer_global;
    weight  = inner_ratio * outer_ratio;

    % Step 5: compute asymmetry
    asymmetry = (norm(center_outer - center_inner) / distance_center_avg) * weight;
end


function [center, half_span] = compute_center_and_half_span(position)
% COMPUTE_CENTER_AND_HALF_SPAN  
% Compute the center and half-range 
%
% Inputs
%   position  : N×3 positions (x,y,z)
%
% Outputs:
%   center    : 1×3 geometric centroid of the position [x, y, z] 
%   half_span : scalar half-size of the bounding box (largest deviation from the centroid across all axes).

    % Compute center
    center    = mean(position, 1);   
    
    % Compute max_half_bbox
    deviation = position - center;         
    half_span = max(abs(deviation), [], 'all');
end


function draw_cell_structure_on_ax(ax, position, gene_2, ...
                             global_half_span, cell_radius, num_face)
% DRAW_CELL_STRUCTURE_ON_AX  
% Draw a 3D visualization of a multicellular structure on a given ax.
%
% Inputs
%   ax               : existing axes to render the 3D cell structure into 
%   position         : N×3 positions (x,y,z)
%   gene_2           : N×1 (0=inner, 1=outer)
%   global_half_span : half-size of the bounding box for fixed scale (scalar)
%   cell_radius      : radius of each cell sphere (scalar)
%   num_face         : number of grid divisions for sphere smoothness (scalar)

    % Step 1: Axes configuration
    hold(ax, 'on'); 
    axis(ax, 'equal');       % Keep equal aspect ratio in all dimensions
    axis(ax, 'off');         % Hide axis ticks and frame for clean look
 
    % Step 2: Define fixed 3D view limits
    center    = mean(position, 1); 
    xlim(ax, [center(1) - global_half_span, center(1) + global_half_span]);
    ylim(ax, [center(2) - global_half_span, center(2) + global_half_span]);
    zlim(ax, [center(3) - global_half_span, center(3) + global_half_span]);

    % Step 3: Draw each cell as a colored sphere
    % Loop over all positions and render cells with colors based on cell type (gene_2 = 0 or 1)
    for n = 1:size(position, 1)
        [x, y, z] = ellipsoid(position(n,1), position(n,2), position(n,3), ...
                              cell_radius,   cell_radius,   cell_radius, ...
                              num_face);
        % Assign color
        if gene_2(n) == 1
            color = [1 0 0]; % Red  → outer cell
        else
            color = [0 0 1]; % Blue → inner cell
        end
        % Draw cell surface with smooth shading and no mesh edges
        surf(ax, x, y, z, ...
             'FaceColor', color, ...
             'EdgeColor', 'none', ...
             'FaceLighting', 'gouraud');
    end

    % Step 4: Configure lighting and camera view
    view(ax, [-165, -70]);   % Set azimuth and elevation angles
    camlight(ax, 'left');    % Add light from the left of camera
    material(ax, 'dull');    % Use soft, diffuse reflection (no bright glare)
end


function save_png_print(out_dir, filename, fig, resolution)
% SAVE_PNG_PRINT  Save a figure as a PNG file. 
% Uses `print`, which preserves the full white background and boundary
% Inputs
%   out_dir   : folder to save the .png file into
%   filename  : base name WITHOUT extension
%   fig       : figure handle
%   resolution: image quality

    out_png = fullfile(out_dir, [filename '.png']);
    try                       
        print(fig, out_png, '-dpng', sprintf('-r%d', resolution)); 
        fprintf('Saved PNG: %s\n', out_png);
    catch ME
        warning('Failed to save PNG: %s\n%s', out_png, ME.message);
    end
end