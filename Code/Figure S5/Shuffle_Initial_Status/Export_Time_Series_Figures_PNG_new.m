%% Step 1: User setting
% Input and output paths
parent_path    = '/n/data1/hms/sysbio/hormoz/users/suxuan/Materials/Codes/Virtual_Experiment/Experiment 4/Shuffle_Initial_Status/Simulation';
input_path     = fullfile(parent_path, 'Aii_0.775_Aoo_0.950_Aio_0.875_BLii_0.000_BLoo_0.135_BLio_0.000_BLoi_0.000_D1_2_tmax_3000');
OUTPUTS        = 6:10;  % Output groups to iterate over (OUTPUT6..OUTPUT10)
output_path    = fullfile(parent_path, 'PNG');
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

% Time steps to process
T_min          = 500;
T_step         = 250;
T_max          = 3000;
T_list         = T_min:T_step:T_max;

% Plotting and geometry settings
cell_radius    = 1;                   
contact_thresh = 2*cell_radius;      
num_face       = 100;   % mesh resolution for cell surfaces
FIG_HEIGHT     = 500;
FIG_WIDTH      = 500;
resolution     = 300;   % DPI for PNG export
fig_visibility = 'off'; % 'on' to preview, 'off' for batch rendering



%% Step 2: Find largest cluster per timestep and compute global bounds
fprintf('Compute global half range from cluster SPREAD across OUTPUT%d..OUTPUT%d; t=%d:%d:%d (|T|=%d)\n', ...
    OUTPUTS(1), OUTPUTS(end), T_min, T_step, T_max, numel(T_list));

% Step 2.1 Preallocate collectors (one row per OUTPUT×time)
n_row = numel(OUTPUTS) * numel(T_list);
collection_table = table( ...
    cell(n_row, 1), ... % filenames    : 'OUTPUT%d_t%d' labels
    cell(n_row, 1), ... % positions    : Nx3 positions of the largest cluster
    cell(n_row, 1), ... % gene2 values : Nx1 gene 2 value of the largest cluster
    cell(n_row, 1), ... % centers      : 1x3 center of the largest cluster [x, y, z]
    'VariableNames', {'Filename', 'Position', 'Gene2', 'Center'} ...
);

global_half_span = 0;   % Global bounding-box half-span (cubic bounds)
k = 1;                  % Row cursor for collectors

% Step 2.2: Loop through each OUTPUT sample and each timestep
for n = OUTPUTS

    % Step 2.2.1: Create input path and output subfolders under PNG for each OUTPUT group
    input_path_n = fullfile(input_path, sprintf('OUTPUT%d', n));
    subfolder_name = sprintf('OUTPUT%d_time_series', n);
    subfolder_path = fullfile(output_path, subfolder_name);
    if ~exist(subfolder_path, 'dir') 
        mkdir(subfolder_path); 
    end

    for t = T_list

        % Step 2.2.2: Load positions and genes
        fileP = fullfile(input_path_n, sprintf('WorkSpace_MatrixP_%d.csv', t));
        fileG = fullfile(input_path_n, sprintf('WorkSpace_MatrixG_%d.csv', t));
        MatrixP = readmatrix(fileP);   
        MatrixG = readmatrix(fileG); 

        filename = sprintf('OUTPUT%d_t%d', n, t);

        % Step 2.2.3: Identify the largest-cluster candidates
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
    
        % Step 2.2.4: Compute the center and half-span of the largest cluster
        [center, half_span] = compute_center_and_half_span(MatrixP(idx_cluster_best, :));

        % Step 2.2.5: Record per-frame selection into the collection table    
        collection_table.Filename{k} = filename;
        collection_table.Position{k} = MatrixP(idx_cluster_best, 1:3);
        collection_table.Gene2{k}    = MatrixG(idx_cluster_best, 2);
        collection_table.Center{k}   = center;

        % Step 2.2.6: Update the global half-span (used for a fixed visualization scale)
        if half_span > global_half_span
            global_half_span = half_span;
        end

        k = k + 1;
    end
end

global_half_span = global_half_span + cell_radius;  % Add a safety margin equal to one cell radius (prevents clipping)
fprintf('Global cubic bounds: half-range = %.3f, full span = %.3f (same for X/Y/Z)\n', global_half_span, 2*global_half_span);



%% Step 3: Generate and save cell structure images
for k = 1:n_row

    % Step 3.1: Retrieve data for each largest cluster
    filename = collection_table.Filename{k};
    position = collection_table.Position{k};
    gene_2   = collection_table.Gene2{k};
    center   = collection_table.Center{k};

    fprintf('Processing %s: drawing cell structure with fixed global scale\n', filename);

    % Step 3.2: Create the 3D visualization of the largest cluster
    cell_figure = draw_cell_structure(position, gene_2, center, ...
                                      global_half_span, cell_radius, num_face, ...
                                      fig_visibility, FIG_HEIGHT, FIG_WIDTH);

    % Step 3.3: Export the visualization to a PNG image
    tokens      = regexp(filename, '(OUTPUT\d+)', 'tokens');
    output_name = tokens{1}{1};  % e.g. 'OUTPUT6'
    png_path    = fullfile(output_path, sprintf('%s_time_series', output_name));
    save_png(png_path, filename, cell_figure, resolution)
    close(cell_figure); 
end
    
fprintf('Done. Generated PNG images for OUTPUT%d–OUTPUT%d using a fixed global scale from cluster spread.\n', OUTPUTS(1), OUTPUTS(end));



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


function cell_figure = draw_cell_structure(position, gene_2, center, ...
                                           global_half_span, cell_radius, num_face, ...
                                           fig_visibility, FIG_HEIGHT, FIG_WIDTH)
% DRAW_CELL_STRUCTURE  
% Draw a 3D visualization of a multicellular structure.
%
% Inputs
%   position         : N×3 positions (x,y,z)
%   gene_2           : N×1 (0=inner, 1=outer)
%   center           : 1×3 geometric centroid of the position [x, y, z]
%   global_half_span : half-size of the bounding box for fixed scale (scalar)
%   cell_radius      : radius of each cell sphere (scalar)
%   num_face         : number of grid divisions for sphere smoothness (scalar)
%   fig_visibility   : 'on' or 'off', whether to show the figure window
%   FIG_HEIGHT       : figure height in pixels (scalar)
%   FIG_WIDTH        : figure width in pixels (scalar)
%
% Output
%   cell_figure      : figure handle to the created cell structure object

    % Step 1: Create figure and axes
    cell_figure = figure('Visible', fig_visibility, ...
                         'Position', [50, 50, FIG_HEIGHT, FIG_WIDTH], ...
                         'Color', 'w');                                       
    ax = axes('Parent', cell_figure);
    hold(ax, 'on'); 
    axis(ax, 'equal');       % Keep equal aspect ratio in all dimensions
    axis(ax, 'off');         % Hide axis ticks and frame for clean look
 
    % Step 2: Define fixed 3D view limits
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


function save_png(out_dir, filename, fig, resolution)
% % SAVE_PNG  Save the figure as an PNG file.
% % Inputs
% %   out_dir   : folder to save the .png file into
% %   filename  : base name WITHOUT extension
% %   fig       : figure handle
% %   resolution: image quality
    out_file = fullfile(out_dir, [filename '.png']);
    try
        exportgraphics(fig, out_file, 'Resolution', resolution, 'BackgroundColor','white');
        fprintf('Saved PNG: %s\n', out_file);
    catch ME
        warning('Failed to save PNG: %s.png\n%s', out_file, ME.message);
    end
end
