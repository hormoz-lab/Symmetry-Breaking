%% ========================================================================
% Render_InitialCells_Batch_Clusters.m  (Transparent look matched to manual)
% Manually chosen (Aii, Aoo, Aio) triplets -> render ONLY the largest
% cluster for each case, with a CONSISTENT spread across all plots.
% Exports transparent-background PNGs.
% ========================================================================

%% -------------------- User Controls --------------------
Sample        = 6;        % replicate index
r             = 1;        % cell radius
threshold_G2  = 0.95;     % (kept for compatibility; cluster color uses gene_2=0/1)
TOL           = 0;        % exact-match against summary CSV

% Long-range (betaL) — fixed for this batch
BLii = 0.000;
BLoo = 0.135;
BLio = 0.000;
BLoi = 0.000;

% ====== MANUAL alpha triplets (rows = cases) ======
% Each row: [Aii, Aoo, Aio]
alpha_triplets = [
    0.65  0.85  0.65
    0.65  0.85  0.95
    0.75  0.85  0.95
    0.75  0.95  0.75
    0.85  0.95  0.65
    0.95  0.75  0.85
    0.775 0.950 0.875
];

% Paths
in_csv      = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/OUTPUT6_10_asymmetry_cluster_weighted_summary_avg.csv';
parent_path = '/n/scratch/users/s/suw469/gastruloids_1500_25%_check';
output_path = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Figure_2';

% Figure / camera / lighting
fig_pos        = [50, 50, 500, 500];   % [x y w h]
view_azel      = [-165, -70];
lighting_side  = 'left';
mesh_res       = 100;                  % ellipsoid mesh resolution
dpi            = 300;                  % PNG resolution

% Spread settings
use_cluster_for_spread = true;   % compute spread from largest clusters
use_all_for_spread     = false;  % don't mix with all-cells spread
extra_margin           = 0.5;    % margin (units of positions) on half-extent

% Create output folder if needed
if ~exist(output_path, 'dir'); mkdir(output_path); end

%% -------------------- Load summary once --------------------
S = readtable(in_csv, 'TextType','string');

% Robust column-name resolution (case/underscore tolerant)
vn = lower(strrep(S.Properties.VariableNames, '__', '_'));
vn = strrep(vn, '-', '_');
find_var = @(key) S.Properties.VariableNames{strcmpi(vn, key)};

col_aii = find_var('alpha_ii');
col_aoo = find_var('alpha_oo');
col_aio = find_var('alpha_io');
col_bii = find_var('betal_ii');   if isempty(col_bii), col_bii='betaL_ii'; end
col_boo = find_var('betal_oo');   if isempty(col_boo), col_boo='betaL_oo'; end
col_bio = find_var('betal_io');   if isempty(col_bio), col_bio='betaL_io'; end
col_boi = find_var('betal_oi');   if isempty(col_boi), col_boi='betaL_oi'; end
col_as6 = find_var('asymmetry_6');  % must exist

Aii_col = double(S.(col_aii));
Aoo_col = double(S.(col_aoo));
Aio_col = double(S.(col_aio));
Bii_col = double(S.(col_bii));
Boo_col = double(S.(col_boo));
Bio_col = double(S.(col_bio));
Boi_col = double(S.(col_boi));

%% -------------------- Helper lambdas --------------------
lib = @(v) sprintf('%.3f', v);  % 3-decimal fixed string

make_basename = @(aii,aoo,aio) sprintf( ...
    ['Aii_%s_Aoo_%s_Aio_%s_', ...
     'BLii_%s_BLoo_%s_BLio_%s_BLoi_%s_', ...
     'D1_2_dt_0.20'], ...
     lib(aii), lib(aoo), lib(aio), ...
     lib(BLii), lib(BLoo), lib(BLio), lib(BLoi));

%% -------------------- First pass: gather frames for SPREAD --------------------
MatrixP_list = {};
MatrixG_list = {};

fprintf('== Computing global spread from selected cases ==\n');
for k = 1:size(alpha_triplets,1)
    aii = alpha_triplets(k,1); aoo = alpha_triplets(k,2); aio = alpha_triplets(k,3);

    basename    = make_basename(aii, aoo, aio);
    out_dir     = fullfile(parent_path, ['OUTPUT' num2str(Sample)]);
    file_path_P = fullfile(out_dir, [basename '_MatrixP_Final.csv']);
    file_path_G = fullfile(out_dir, [basename '_MatrixG_Final.csv']);

    if ~exist(file_path_P, 'file') || ~exist(file_path_G, 'file')
        fprintf('  [skip spread] Missing files for %s (Sample %d)\n', basename, Sample);
        continue;
    end

    P = cell2mat(table2cell(readtable(file_path_P)));
    G = cell2mat(table2cell(readtable(file_path_G)));

    % For compute_spread with use_cluster=true, pass FULL frames here;
    % the function will internally find the largest cluster.
    MatrixP_list{end+1} = P; %#ok<SAGROW>
    MatrixG_list{end+1} = G; %#ok<SAGROW>
end

if isempty(MatrixP_list)
    error('No frames available to compute spread. Check paths or alpha_triplets.');
end

spread = compute_spread(MatrixP_list, MatrixG_list, r, extra_margin, ...
                        use_cluster_for_spread, use_all_for_spread);
fprintf('== Done. Using CONSISTENT spread: [%.3f %.3f %.3f]\n', spread);

%% -------------------- Second pass: render each case (largest cluster only) ---
count_done = 0; count_skip = 0;

for k = 1:size(alpha_triplets,1)
    aii = alpha_triplets(k,1); aoo = alpha_triplets(k,2); aio = alpha_triplets(k,3);

    basename    = make_basename(aii, aoo, aio);
    out_dir     = fullfile(parent_path, ['OUTPUT' num2str(Sample)]);
    file_path_P = fullfile(out_dir, [basename '_MatrixP_Final.csv']);
    file_path_G = fullfile(out_dir, [basename '_MatrixG_Final.csv']);

    if ~exist(file_path_P, 'file') || ~exist(file_path_G, 'file')
        fprintf('⚠️ Missing files for %s (Sample %d). Skipping.\n', basename, Sample);
        count_skip = count_skip + 1;
        continue;
    end

    % Load data
    MatrixP = cell2mat(table2cell(readtable(file_path_P)));
    MatrixG = cell2mat(table2cell(readtable(file_path_G)));

    % Lookup asymmetry_6 from summary for filename
    idx = find( abs(Aii_col - aii) <= TOL & ...
                abs(Aoo_col - aoo) <= TOL & ...
                abs(Aio_col - aio) <= TOL & ...
                abs(Bii_col - BLii) <= TOL & ...
                abs(Boo_col - BLoo) <= TOL & ...
                abs(Bio_col - BLio) <= TOL & ...
                abs(Boi_col - BLoi) <= TOL );
    assert(~isempty(idx), 'No row matched A/B values in:\n%s', in_csv);
    if numel(idx) > 1
        warning('Multiple rows matched (%d). Using the first.', numel(idx));
        idx = idx(1);
    end
    asym6 = double(S.(col_as6)(idx));

    % ---- Find LARGEST CLUSTER indices ----
    contact_thresh = 2*r;
    idx_cluster    = find_largest_cluster(MatrixP(:,1:3), MatrixG, contact_thresh);
    if isempty(idx_cluster)
        fprintf('⚠️ No cluster found for %s. Skipping.\n', basename);
        count_skip = count_skip + 1;
        continue;
    end

    position_cluster = MatrixP(idx_cluster, 1:3);
    gene2_cluster    = MatrixG(idx_cluster, 2);

    % ---- Draw only the chosen cluster, with the CONSISTENT spread ----
    [f, ax] = draw_cluster_figure(position_cluster, gene2_cluster, spread, ...
                                  r, mesh_res, 'off'); %#ok<ASGLU>
    % Match manual look: transparent figure + axes, same view & lighting
    set(f, 'Position', fig_pos, 'Color', 'none');       % transparent fig
    set(gca, 'Color', 'none');                          % transparent axes
    view(gca, view_azel); 
    camlight(gca, lighting_side); 
    material(gca, 'dull');

    % Output filename (transparent PNG)
    png_name = sprintf('%s_asym6_%0.3f_Sample%d.png', ...
        strip_suffix(basename, '_D1_2_dt_0.20'), asym6, Sample);
    output_file = fullfile(output_path, png_name);

    % Transparent background export
    try
        exportgraphics(f, output_file, ...
            'BackgroundColor', 'none', 'Resolution', dpi, 'ContentType', 'image');
        fprintf('✅ Saved: %s\n', output_file);
        count_done = count_done + 1;
    catch ME
        fprintf('❌ Failed to save PNG: %s\n   %s\n', output_file, ME.message);
    end

    close(f);
end

fprintf('\nDone. Rendered %d images; skipped %d.\n', count_done, count_skip);

%% ======================= Local functions =======================

%% COMPUTE_SPREAD
% Compute ONE cube half-extent vector [Hx Hy Hz] across many frames.
%   - largest cluster only (use_cluster = true)  -> needs MatrixG_list
%   - all cells in the frame (use_all = true)
% If both are true, a single scalar extreme is accumulated globally;
% final spread is [m m m] (a cube).
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
                    position_cluster   = P(idx_cluster, 1:3);           % <-- fixed name
                    center_cluster     = mean(position_cluster, 1);
                    deviation_cluster  = position_cluster - center_cluster;
                    half_extent_cluster = [ ...
                        max(abs(deviation_cluster(:,1))), ...
                        max(abs(deviation_cluster(:,2))), ...
                        max(abs(deviation_cluster(:,3))) ...
                    ];
                    global_max = max(global_max, max(half_extent_cluster));
                end
            end
        end

        % ===== all-cells candidate (optional) =====
        if use_all
            center_all     = mean(P(:,1:3), 1);
            deviation_all  = P(:,1:3) - center_all;
            half_extent_all = [ ...
                max(abs(deviation_all(:,1))), ...
                max(abs(deviation_all(:,2))), ...
                max(abs(deviation_all(:,3))) ...
            ];
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
% Returns indices of the cells that belong to the chosen cluster:
%   1) pick cluster with the most cells (distance <= contact_thresh)
%   2) ties: pick the one with higher asymmetry (outer-vs-inner center shift)
function idx_cluster = find_largest_cluster(MatrixP, MatrixG, contact_thresh)

    % Step 1: build adjacency by distance <= contact_thresh
    N = size(MatrixP,1);
    D = pdist2(MatrixP(:,1:3), MatrixP(:,1:3));
    A = (D <= contact_thresh) & ~eye(N);

    % Step 2: connected components
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

    % (If more than 1 largest cluster) — tie-break by asymmetry
    gene_2_all       = MatrixG(:,2);         
    N_inner_global   = nnz(gene_2_all == 0);
    N_outer_global   = nnz(gene_2_all == 1);

    asym_list  = nan(numel(labels_max), 1);

    for i = 1:numel(labels_max)
        idx_c            = find(comp == labels_max(i));
        position_cluster = MatrixP(idx_c, 1:3);
        gene_2_cluster   = MatrixG(idx_c, 2);
        asymmetry        = compute_asymmetry(position_cluster, gene_2_cluster, ...
                                             N_inner_global, N_outer_global);
        asym_list(i)     = asymmetry;
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
% Matches the manual visualization look: transparent figure & axes,
% FaceLighting gouraud, material dull, same view & camlight.
function [f, ax] = draw_cluster_figure(position, gene_2, spread, ...
                                       r, resolution, fig_visibility)
    
    % Step 1: figure & axes (transparent, no explicit renderer)
    f = figure('Visible', fig_visibility, 'Position', [50, 50, 500, 500], ...
               'Color', 'none');              % transparent like manual
    ax = axes('Parent', f); 
    hold(ax, 'on'); axis(ax, 'equal'); axis(ax, 'off');
    set(ax, 'Color', 'none');                 % transparent axes

    % Step 2: fixed scale from spreads, centered on cluster center
    center = mean(position, 1);
    max_x  = spread(1); max_y = spread(2); max_z = spread(3);
    xlim(ax, [center(1)-max_x, center(1)+max_x]);
    ylim(ax, [center(2)-max_y, center(2)+max_y]);
    zlim(ax, [center(3)-max_z, center(3)+max_z]);

    % Step 3: draw the ellipsoids (match manual colors & lighting)
    for n = 1:size(position,1)
        x = position(n,1); y = position(n,2); z = position(n,3);
        [rx, ry, rz] = ellipsoid(x, y, z, r, r, r, resolution);

        if gene_2(n) > 0.5
            faceColor = 'r';   % red (outer)
        else
            faceColor = 'b';   % blue (inner)
        end

        surf(ax, rx, ry, rz, ...
             'FaceColor', faceColor, ...
             'FaceAlpha', 1, ...
             'EdgeColor', 'none', ...
             'FaceLighting', 'gouraud');     % same as manual
    end

    % Step 4: camera & lighting (caller sets final view/lighting again)
    % (Kept minimal here to mirror manual order in caller)
end

function s = strip_suffix(s, suffix)
    if endsWith(s, suffix)
        s = extractBefore(s, strlength(s) - strlength(suffix) + 1);
    end
end
