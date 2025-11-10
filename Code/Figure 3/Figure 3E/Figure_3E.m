%% Step 1: USER SETTINGS
% Input and output files
parent_path     = '/Users/linda0122/Desktop/Materials';
input_path      = fullfile(parent_path, 'Figures/Figure 3/Figure 3D/Aii_0.750_Aoo_0.725_Aio_0.800_BLii_0.000_BLoo_0.000_BLio_0.000_BLoi_0.000');
output_path     = fullfile(parent_path, 'Figures/Figure 3/Figure 3E');
if ~exist(output_path,'dir'), mkdir(output_path); end
output_filename = 'Figure_3E';
OUTPUT          = 6:10;               

% Define physical parameters
r               = 1.0;              % cell radius used for "contact"
contact_thresh  = 2*r;              % two cells are connected if cell-cell distance <= contact_thresh

% Extract frame numbers
sample_folder   = fullfile(input_path, sprintf('OUTPUT%d', OUTPUT(1)));
all_MatrixG     = dir(fullfile(sample_folder, 'WorkSpace_MatrixG_*.csv'));
frames          = nan(numel(all_MatrixG), 1); 
for i = 1:numel(all_MatrixG)
    tok = regexp(all_MatrixG(i).name, 'WorkSpace_MatrixG_(\d+)\.csv$', 'tokens','once');
    if ~isempty(tok)
        frames(i) = str2double(tok{1}); 
    end
end
frames          = sort(frames(~isnan(frames))); 

% Figure layout configuration    
FIG_WIDTH       = 2000;     % width in pixels
FIG_HEIGHT      = 500;      % height in pixels
FONT_SIZE       = 40;       % tick number font size



%% Step 2: Compute asymmetry per frame for OUTPUTs and get average and standard deviation
% Step 2.1: Preallocate storage for mean and standard deviation
asymmetry_mean = nan(numel(frames), 1);
asymmetry_std  = nan(numel(frames), 1);

% Step 2.2: Loop through each frame to compute asymmetry
for i = 1:numel(frames)

    frame           = frames(i);
    asymmetry_value = nan(numel(OUTPUT),1); % Preallocate storage for all OUTPUTs

    % Step 2.2.1: Loop through each sample 
    for j = 1:numel(OUTPUT)

        % Step 2.2.1.1: Load MatrixP and MatrixG
        sample        = OUTPUT(j);
        sample_folder = fullfile(input_path, sprintf('OUTPUT%d', sample));
        fileP         = fullfile(sample_folder, sprintf('WorkSpace_MatrixP_%d.csv', frame));
        fileG         = fullfile(sample_folder, sprintf('WorkSpace_MatrixG_%d.csv', frame));
        MatrixP       = readmatrix(fileP);
        MatrixG       = readmatrix(fileG);
        
        % Step 2.2.1.2: Identify the largest cell cluster 
        idx_clusters = find_largest_cluster(MatrixP, contact_thresh);

        % Step 2.2.1.3: Compute asymmetry for the largest cluster(s) 
        N_inner_global = nnz(MatrixG(:, 2) == 0);
        N_outer_global = nnz(MatrixG(:, 2) == 1);
        asymmetry_list = nan(1, numel(idx_clusters));
        for k = 1:numel(idx_clusters)
            idx_i = idx_clusters{k};
            asymmetry_list(k) = compute_asymmetry( ...
                MatrixP(idx_i, 1:3), ...   % Positions x, y, z
                MatrixG(idx_i, 2),   ...   % Gene 2
                N_inner_global, ...
                N_outer_global);
        end

        % Step 2.2.1.4: Average asymmetry across tied largest clusters (omit NaNs)
        if any(~isnan(asymmetry_list))
            asymmetry_value(j) = mean(asymmetry_list, 'omitnan');
        else
            error('Degenerate largest clusters for %s. Asymmetry is NaN. Aborting.', fileP);
        end
    end

    % Step 2.2.2: Store average and standard deviation of asymmetry cross OUTPUTs for this frame
    asymmetry_mean(i) = mean(asymmetry_value);
    asymmetry_std(i)  = std(asymmetry_value);

end



%% Step 3: Plot asymmetry versus time
% Step 3.1: Create figure and axes
fig = figure('Color','w', ...
             'Position',[100 100 FIG_WIDTH FIG_HEIGHT]);
ax  = axes(fig); 
hold(ax,'on');
ax.Color     = 'w';
ax.XColor    = 'k';
ax.YColor    = 'k';
ax.LineWidth = 1.2;
ax.FontSize  = FONT_SIZE;
grid(ax,'off');

% Step 3.2: Draw the shaded ±1 standard deviation band
frame_min = min(frames);      
time_rel  = frames - frame_min;              % Convert frame numbers to relative time (e.g., 501→0)
y_top     = asymmetry_mean + asymmetry_std;  % Upper boundary of the band
y_bottom  = asymmetry_mean - asymmetry_std;  % Lower boundary of the band
px = [time_rel; flipud(time_rel)];           % Build a closed polygon for the filled region
py = [y_bottom; flipud(y_top)];
patch('XData', px, ...                      
      'YData', py, ...
      'FaceColor', [0.75 0.75 0.75], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.35);                    % Transparency for shaded band 

% Step 3.3: Plot the mean asymmetry curve 
plot(time_rel, asymmetry_mean, ...
     '-', 'LineWidth', 2.0, ...              % Solid black line
     'Marker', '.', 'MarkerSize', 12, ...    % Dot markers at sample points
     'Color', 'k');

% Step 3.5: Configure axis limits and tick marks
x_max = max(time_rel);
xlim([0 x_max]);      
xticks(0:75:x_max);  
yticks(0:0.5:1);
yticklabels({'0.0','0.5','1.0'});

% Step 3.6: Axis labels 
xlabel(ax, '{\it in silico} time for pattern formation', ...
       'FontSize', FONT_SIZE, ...
       'Color','k', ...
       'FontName','Arial');
ylabel(ax, {'Morphological', 'Asymmetry ({\itA})'}, ...
       'FontSize', FONT_SIZE, ...
       'Color','k', ...
       'FontName','Arial');

% Step 3.7: Save as SVG file
save_svg(output_path, output_filename, fig)



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


function save_svg(out_dir, filename, fig)
% SAVE_SVG  Save a figure as an SVG (vector) file.
% Inputs
%   out_dir   : folder to save the .svg file into
%   filename  : base name WITHOUT extension
%   fig       : figure handle

    out_svg = fullfile(out_dir, filename);                         
    try
        print(fig, out_svg, '-dsvg', '-vector');  
        fprintf('Saved SVG: %s\n', out_svg);
    catch ME
        warning('Failed to save SVG: %s\n%s', out_svg, ME.message);
    end
end