%% ================== USER SETTINGS ==================
% Input root
SAMPLES            = 6:10;
input_parent_path  = '/n/scratch/users/s/suw469/gastruloids_1500_25%_check';

% Output root for saved figures
output_parent_path = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Figure_4/Figure_4D/1';
save_dir_svg = fullfile(output_parent_path, 'svg');
save_dir_png = fullfile(output_parent_path, 'png');
ensure_dir(save_dir_svg);
ensure_dir(save_dir_png);

% Rendering / geometry params
r              = 1;        % cell radius
extra_margin   = 0;        % extra margin added to half-extent
ellip_res      = 100;      % ellipsoid mesh resolution
fig_visibility = 'off';    % 'on' to view, 'off' for headless
contact_thresh = 2*r;      % linking threshold for clusters
use_cluster    = true;     % draw cluster cells
use_all        = false;    % draw overall cells

% Two scenarios
paramsA   = struct('Aii',0.775,'Aoo',0.950,'Aio',0.875, ...
                     'BLii',0.000,'BLoo',0.135,'BLio',0.000,'BLoi',0.000, ...
                     'D1',2,'dt',0.20);

paramsB   = struct('Aii',0.775,'Aoo',0.950,'Aio',0.875, ...
                    'BLii',0.000,'BLoo',0.000,'BLio',0.000,'BLoi',0.000, ...
                    'D1',2,'dt',0.20);

scenarios = {paramsA, paramsB};


%% =============== MAIN WORKFLOW =====================
% Step 1: Load all the csv files
MatrixP_list   = {};   % holds MatrixP for each sample
MatrixG_list   = {};   % holds MatrixG for each sample
prefixes       = {};   % holds the filename prefix for each sample
sample_list    = {};   % holds the sample list index

for sc = 1:numel(scenarios)
    params = scenarios{sc};
    for k = 1:numel(SAMPLES)
        sample = SAMPLES(k);
        try
            % use your fast direct-path loader
            [P, G, prefix] = load_files(input_parent_path, sample, params);
            % append (grow) the lists
            MatrixP_list{end+1} = P;           %#ok<AGROW>
            MatrixG_list{end+1} = G;           %#ok<AGROW>
            prefixes{end+1}     = prefix;      %#ok<AGROW>
            sample_list{end+1}  = sample;      %#ok<AGROW>
        catch ME
            fprintf('❌ OUTPUT%d: %s\n', sample, ME.message);
        end
    end
end

% Step 2: Compute unified cube spread 
spread = compute_spread(MatrixP_list, MatrixG_list, r, extra_margin, use_cluster, use_all);
fprintf('General spread (cube) = [%.3f %.3f %.3f]\n', spread(1), spread(2), spread(3));

% Step 3: Draw & save each structure using the global spread 
for i = 1:numel(MatrixP_list)

    MatrixP = MatrixP_list{i};
    MatrixG = MatrixG_list{i};
    prefix  = prefixes{i};
    sample  = sample_list{i};

    try
        % Step 3.1: Find largest cluster
        idx_cluster = find_largest_cluster(MatrixP, MatrixG, contact_thresh);
        if isempty(idx_cluster)
            fprintf('  [skip] OUTPUT%d: no cluster found\n', s);
            continue
        end

        % Step 3.2: Prepare inputs for drawing ONLY the cluster
        position_cluster = MatrixP(idx_cluster, 1:3);
        gene2_cluster    = MatrixG(idx_cluster, 2);

        % Step 3.3: Draw
        [f, ax] = draw_cluster_figure(position_cluster, gene2_cluster, spread, ...
                                      r, ellip_res, fig_visibility);

        % 4) Save (SVG + PNG) using prefix
        base = sprintf('OUTPUT%d_%s', sample, prefix);
        svg_path = fullfile(save_dir_svg, [base '.svg']);
        png_path = fullfile(save_dir_png, [base '.png']);

        %save_figure_svg(f, svg_path);
        save_figure_png(f, png_path, 600);

        if strcmpi(fig_visibility,'off')
            close(f);
        end

    catch ME
        fprintf('  ❌ OUTPUT%d draw/save error: %s\n', sample, ME.message);
    end
end



%% helper: ensure_dir
function ensure_dir(d)
    if ~exist(d, 'dir'), mkdir(d); end
end



%% LOAD_FILES
% Build paths directly from params and read the CSVs (no folder scanning).
%
% Inputs
%   parent_path : e.g. '/n/scratch/users/s/suw469/gastruloids_1500_25%_check'
%   output_idx  : integer OUTPUT number (e.g. 6)
%   params      : struct with fields:
%                 Aii, Aoo, Aio, BLii, BLoo, BLio, BLoi, D1, dt
%
% Outputs
%   MatrixP, MatrixG : data from the CSVs
%   prefix           : filename stem (for reuse in figure names)
%   p_path, g_path   : full paths used
function [MatrixP, MatrixG, prefix, p_path, g_path] = load_files(parent_path, output_idx, params)

    
    out_dir = fullfile(parent_path, sprintf('OUTPUT%d', output_idx));  % Build OUTPUT dir
    prefix = build_filename(params, '%.3f', '%.3f', '%.2f');           % Build the filename stem with fixed formatting (3dp for A/BL, 2dp for dt)
    p_path = fullfile(out_dir, [prefix '_MatrixP_Final.csv']);         % Compose full paths for positions
    g_path = fullfile(out_dir, [prefix '_MatrixG_Final.csv']);         % Compose full paths for genes

    if ~isfile(p_path)
        error('MatrixP file not found:\n  %s', p_path);
    end
    if ~isfile(g_path)
        error('MatrixG file not found:\n  %s', g_path);
    end

    MatrixP = readmatrix(p_path);
    MatrixG = readmatrix(g_path);

    fprintf('✅ Loaded OUTPUT%d\n  P: %s\n  G: %s\n', output_idx, p_path, g_path);
end

% BUILD_FILENAME  
% Create the exact filename stem from params.
% prefix looks like:
% Aii_0.775_Aoo_0.950_Aio_0.875_BLii_0.000_BLoo_-0.135_BLio_0.000_BLoi_0.000_D1_2_dt_0.20
%
% Inputs
%   params : struct with fields Aii, Aoo, Aio, BLii, BLoo, BLio, BLoi, D1, dt
%   fmtA   : (optional) sprintf format for A* values, default '%.3f'
%   fmtBL  : (optional) sprintf format for BL* values, default '%.3f'
%   fmtDt  : (optional) sprintf format for dt,     default '%.2f'
function prefix = build_filename(params, fmtA, fmtBL, fmtDt)

    if nargin < 2 || isempty(fmtA),  fmtA  = '%.3f'; end
    if nargin < 3 || isempty(fmtBL), fmtBL = '%.3f'; end
    if nargin < 4 || isempty(fmtDt), fmtDt = '%.2f'; end

    sAii  = sprintf(fmtA,  params.Aii);
    sAoo  = sprintf(fmtA,  params.Aoo);
    sAio  = sprintf(fmtA,  params.Aio);
    sBLii = sprintf(fmtBL, params.BLii);
    sBLoo = sprintf(fmtBL, params.BLoo);
    sBLio = sprintf(fmtBL, params.BLio);
    sBLoi = sprintf(fmtBL, params.BLoi);
    sD1   = sprintf('%d',  params.D1);
    sdt   = sprintf(fmtDt, params.dt);

    prefix = sprintf( ...
        ['Aii_%s_Aoo_%s_Aio_%s_', ...
         'BLii_%s_BLoo_%s_BLio_%s_BLoi_%s_', ...
         'D1_%s_dt_%s'], ...
         sAii, sAoo, sAio, sBLii, sBLoo, sBLio, sBLoi, sD1, sdt);
end



%% COMPUTE_SPREAD
% Compute ONE cube half-extent vector [Hx Hy Hz] across many frames.
% For each frame you can include:
%   - largest cluster only      (use_cluster = true)  -> needs MatrixG_list
%   - all cells in the frame    (use_all     = true)
% If both are true, the single scalar extreme (max over {x,y,z} for each
% candidate and frame) is accumulated globally; final spread is [m m m].
%
% Inputs
%   MatrixP_list : 1xK cell, each cell is MatrixP_i (Ni x 3)
%   MatrixG_list : 1xK cell (only needed if use_cluster=true), MatrixG_i (Ni x >= 2, col 2 = gene_2)
%   r            : scalar; cell radius (also used for contact threshold = 2*r)
%   extra_margin : scalar; extra margin added to the final half-extent
%   use_cluster  : logical; include largest-cluster spread
%   use_all      : logical; include all-cells (frame) spread
%
% Output
%   spread       : 1x3 [Hx Hy Hz] (cube half-extents), i.e., [max, max, max]

function spread = compute_spread( ...
    MatrixP_list, MatrixG_list, r, extra_margin, use_cluster, use_all)

    K              = numel(MatrixP_list);
    global_max     = 0;  % single-scalar accumulator for the extreme half-extent
    contact_thresh = 2 * r;

    for i = 1:K
        P = MatrixP_list{i};

        % ===== cluster-based candidate =====
        if use_cluster
            G = MatrixG_list{i};
            if isempty(G) || size(G,2) < 2 || size(G,1) ~= size(P,1)
                fprintf('  [skip] Frame %d: invalid MatrixG for cluster mode\n', i);
            else
                idx_cluster = find_largest_cluster(P, G, contact_thresh);
                if isempty(idx_cluster)
                    fprintf('  [skip] Frame %d: no cluster found\n', i);
                else
                    position_cluter   = P(idx_cluster, 1:3);
                    center_cluster    = mean(position_cluter, 1);
                    deviation_cluster = position_cluter - center_cluster;
                    % half-extents for cluster
                    half_extent_cluster = ...
                        [max(abs(deviation_cluster(:,1))), ...
                         max(abs(deviation_cluster(:,2))), ...
                         max(abs(deviation_cluster(:,3)))];
                    % update scalar with the largest of {Hx,Hy,Hz}
                    global_max = max(global_max, max(half_extent_cluster));
                end
            end
        end

        % ===== all-cells candidate (optional) =====
        if use_all
            center_all    = mean(P(:,1:3), 1);
            deviation_all = P(:,1:3) - center_all;
            % half-extents for all cells
            half_extent_all = ...
                [max(abs(deviation_all(:,1))), ...
                 max(abs(deviation_all(:,2))), ...
                 max(abs(deviation_all(:,3)))];
            % update scalar with the largest of {Hx,Hy,Hz}
            global_max = max(global_max, max(half_extent_all));
        end
    end

    % Finalize cube spread 
    max_spread = global_max + (r + extra_margin);      % add margin once to the scalar
    spread     = [max_spread, max_spread, max_spread];

    % Summary print 
    fprintf('Global cube spread = [%.3f  %.3f  %.3f]\n', spread(1), spread(2), spread(3));
    fprintf('Full spans -> X: %.3f, Y: %.3f, Z: %.3f\n', 2*max_spread, 2*max_spread, 2*max_spread);
end



%% FIND_LARGEST_CLUSTER
% Returns the indices of the cells (row numbers in MatrixP/MatrixG) that
% belong to the chosen cluster:
%   1) pick cluster with the most cells (connected by distance <= contact_thresh)
%   2) if there is a tie, pick the one with higher asymmetry (outer-vs-inner center shift)
%
% Inputs
%   MatrixP : N×3 positions [x y z]
%   MatrixG : N×K expression (expects gene_2 in column 2 with values 0/1)
%   contact_thresh : scalar; adjacency if distance <= contact_thresh
%
% Output
%   idx_cluster : vector of row indices forming the selected cluster
function idx_cluster = find_largest_cluster(MatrixP, MatrixG, contact_thresh)

    % Step 1: build adjacency by distance <= contact_thresh ---
    N = size(MatrixP,1);
    D = pdist2(MatrixP(:,1:3), MatrixP(:,1:3));
    A = (D <= contact_thresh) & ~eye(N);

    % Step 2: connected components ---
    Gc    = graph(sparse(triu(A,1)),'upper');
    comp  = conncomp(Gc);
    sizes = accumarray(comp(:), 1);

    % Step 3: largest size & all labels that achieve it
    max_size   = max(sizes);
    labels_max = find(sizes == max_size);

    % Step 4: simple case: only one largest cluster
    if numel(labels_max) == 1
        idx_cluster = find(comp == labels_max);
        fprintf('✅ Found one largest cluster (label=%d) with %d cells\n', ...
            labels_max, numel(idx_cluster));
        return;
    end

    % (If more than 1 largest cluster)
    % Step 5: tie-break by asymmetry
    % Global counts of inner/outer for weighting
    gene_2_all       = MatrixG(:,2);         
    N_inner_global   = nnz(gene_2_all == 0);
    N_outer_global   = nnz(gene_2_all == 1);

    asym_list  = nan(numel(labels_max), 1);

    for i = 1:numel(labels_max)
        idx_c             = find(comp == labels_max(i));
        position_cluster  = MatrixP(idx_c, 1:3);
        gene_2_cluster    = MatrixG(idx_c, 2);
        asymmetry         = compute_asymmetry(position_cluster, gene_2_cluster, N_inner_global, N_outer_global);
        asym_list(i)      = asymmetry;
    end

    % Pick the tied cluster with the highest asymmetry
    [~, rel_best] = max(asym_list);
    if isnan(asym_list(rel_best)), rel_best = 1; end
    label_best  = labels_max(rel_best);
    idx_cluster = find(comp == label_best);
end



%% COMPUTE_ASYMMETRY
% position_cluster : M×3 positions (x,y,z)
% gene_2_cluster   : M×1 (0=inner, 1=outer)
% N_inner_global   : scalar, count of inner cells in the whole frame
% N_outer_global   : scalar, count of outer cells in the whole frame

% Returns a scalar asymmetry score >= 0.
% asymmetry = ||center_outer - center_inner|| / r_geom  *  (N_inner_local/N_inner_global) * (N_outer_local/N_outer_global)
function asymmetry = compute_asymmetry(position_cluster, gene_2_cluster, N_inner_global, N_outer_global)
    
    % Step 1: counts within the cluster
    N_inner_local = nnz(gene_2_cluster == 0);
    N_outer_local = nnz(gene_2_cluster == 1);

    if N_inner_local == 0 || N_outer_local == 0
        asymmetry = 0;        % no separation if only one class present
        return;
    end

    % Step 2: geometric center & typical radius
    center_cluster      = mean(position_cluster, 1);
    distance_center_avg = mean(vecnorm(position_cluster - center_cluster, 2, 2));  % avg distance to center

    % Step 3: centers of outer/inner subsets
    center_outer = mean(position_cluster(gene_2_cluster == 1, :), 1);
    center_inner = mean(position_cluster(gene_2_cluster == 0, :), 1);

    % Step 4: weights based on global composition in the frame
    inner_ratio = N_inner_local / max(N_inner_global, 1);
    outer_ratio = N_outer_local / max(N_outer_global, 1);
    weight  = inner_ratio * outer_ratio;

    % Step 5: final asymmetry
    asymmetry = (norm(center_outer - center_inner) / distance_center_avg) * weight;
end



%% DRAW_CLUSTER_FIGURE  Render a 3D cluster of cells as colored ellipsoids.
%
% Inputs
%   position        : N×3 positions [x y z]
%   gene_2          : N×1 scalar per cell (used for coloring via threshold)
%   spread          : 1×3 half-widths [Hx Hy Hz] for x/y/z limits
%   r               : radius of each cell ellipsoid
%   resolution      : resolution of ellipsoid mesh (higher = smoother)
%   fig_visibility  : 'on' or 'off' (string)
%
% Outputs
%   f, ax : handles to figure and axes
function [f, ax] = draw_cluster_figure(position, gene_2, spread, ...
                                       r, resolution, fig_visibility)
    
    % Step 1: figure & axes
    f = figure('Visible', fig_visibility, 'Position', [50, 50, 500, 500], ...
               'Color', 'w', 'Renderer', 'opengl');
    ax = axes('Parent', f); hold(ax, 'on'); axis(ax, 'equal'); axis(ax, 'off');
    
    % Step 2: fixed scale from spreads, centered on ccent
    center = mean(position, 1);
    max_x  = spread(1); max_y = spread(2); max_z = spread(3);
    xlim(ax, [center(1)-max_x, center(1)+max_x]);
    ylim(ax, [center(2)-max_y, center(2)+max_y]);
    zlim(ax, [center(3)-max_z, center(3)+max_z]);
    
    % Step 3: draw the ellipsoids
    for n = 1:size(position,1)
        x            = position(n,1); 
        y            = position(n,2); 
        z            = position(n,3);
        [rx, ry, rz] = ellipsoid(x, y, z, r, r, r, resolution);
        if     gene_2(n) == 1
            color    = [1 0 0];   % outer cell are red
        elseif gene_2(n) == 0
            color    = [0 0 1];   % inner cell are blue
        end
        surf(ax, rx, ry, rz, 'FaceColor', color, 'FaceAlpha', 1, ...
             'EdgeColor', 'none', 'FaceLighting', 'gouraud');
    end
    
    % Step 4: camera & lighting
    view(ax, [-165, -70]);
    camlight(ax, 'left');
    material(ax, 'dull');
end



%% SAVE_FIGURE_SVG  Save a figure to an SVG file (vector).
%
% Inputs
%   f        : figure handle
%   out_path : full path for the PNG file
function save_figure_svg(f, out_path)

    % Ensure target folder exists
    out_dir = fileparts(out_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    
    try
        exportgraphics(f, out_path, 'ContentType','vector', 'BackgroundColor','white');
        fprintf('✅ Successfully saved SVG: %s\n', out_path);
    catch ME
        fprintf('❌ Failed to save SVG: %s\n', out_path);
        fprintf('   Error message: %s\n', ME.message);
    end
end



%% SAVE_FIGURE_PNG Save a figure to a PNG file.
%
% Inputs
%   f        : figure handle
%   out_path : full path for the PNG file
%   dpi      : resolution in dots per inch (default = 300)
function save_figure_png(f, out_path, dpi)

    % Ensure target folder exists
    out_dir = fileparts(out_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    
    try
        exportgraphics(f, out_path, 'Resolution', dpi, 'BackgroundColor', 'white');
        fprintf('✅ Successfully saved PNG: %s\n', out_path);
    catch ME
        fprintf('❌ Failed to save PNG: %s\n', out_path);
        fprintf('   Error message: %s\n', ME.message);
    end
end