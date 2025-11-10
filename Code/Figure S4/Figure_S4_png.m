%% ================== USER SETTINGS ==================
% Input root
SAMPLES            = 6:10;
input_parent_path  = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Noise_Test';

% Output root for saved figures
output_parent_path = ['/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Noise_Test/Supplement_Noise'];
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
use_cluster    = false;    % include largest-cluster candidate in spread
use_all        = true;     % include all-cells candidate in spread

% Two scenarios
test_1    = 'Test_1';
test_2    = 'Test_2';
scenarios = {test_1, test_2};


%% =============== MAIN WORKFLOW =====================
% Step 1: Load all the csv files
MatrixP_list   = {};   % holds MatrixP for each file
MatrixG_list   = {};   % holds MatrixG for each file
prefixes       = {};   % holds the filename prefix for each file
sample_list    = {};   % holds the OUTPUT# for each file

for sc = 1:numel(scenarios)
    scenario = scenarios{sc};
    for k = 1:numel(SAMPLES)
        sample   = SAMPLES(k);
        base_dir = fullfile(input_parent_path, scenario, sprintf('OUTPUT%d', sample));
        P_files  = dir(fullfile(base_dir, '**', '*_MatrixP_Final.csv'));
        
        for i = 1:numel(P_files)
            p_path = fullfile(P_files(i).folder, P_files(i).name);
            pref   = erase(P_files(i).name, '_MatrixP_Final.csv');

            g_path = fullfile(P_files(i).folder, [pref '_MatrixG_Final.csv']);
            if ~isfile(g_path)
                fprintf('⚠️  No matching G for %s\n', pref);
                continue;
            end

            P = readmatrix(p_path);
            G = readmatrix(g_path);

            MatrixP_list{end+1}  = P;             %#ok<AGROW>
            MatrixG_list{end+1}  = G;             %#ok<AGROW>
            prefixes{end+1}      = string(pref);  %#ok<AGROW>
            sample_list{end+1}   = sample;        %#ok<AGROW>

            fprintf('✅ %s | OUTPUT%d | %s\n', scenario, sample, pref);
        end
    end
end

% ---- Extract kappaF per item ----
K = numel(prefixes);
kappaF_vals = nan(1, K);
for i = 1:K
    kappaF_vals(i) = parse_kappaF_from_prefix(prefixes{i});
end

% ---- Pool spreads PER UNIQUE kappaF value (no cross-kappa sharing) ----
tol = 1e-9;
unique_k = unique(kappaF_vals(~isnan(kappaF_vals)));
spread_map = containers.Map('KeyType','char','ValueType','any');

fprintf('\n====== POOLED SPREADS BY kappaF (exact match) ======\n');
for kk = 1:numel(unique_k)
    kappa = unique_k(kk);
    idx_k = find(abs(kappaF_vals - kappa) < tol);

    spread_k = compute_spread( ...
        MatrixP_list(idx_k), ...
        MatrixG_list(idx_k), ...
        r, extra_margin, use_cluster, use_all);

    key = sprintf('%.12g', kappa);
    spread_map(key) = spread_k;

    fprintf('kappaF = %s | [Hx Hy Hz] = [%.3f  %.3f  %.3f] | spans [%.3f  %.3f  %.3f] | %d items\n', ...
        key, spread_k(1), spread_k(2), spread_k(3), 2*spread_k(1), 2*spread_k(2), 2*spread_k(3), numel(idx_k));
end

% Report files with NaN kappaF (no pooling; will use per-file spread)
nan_idx = find(isnan(kappaF_vals));
if ~isempty(nan_idx)
    fprintf('\n⚠️  %d item(s) with unparseable kappaF. These will use per-file spreads:\n', numel(nan_idx));
    for ii = nan_idx
        fprintf('   OUTPUT%d | %s\n', sample_list{ii}, prefixes{ii});
    end
end
fprintf('\n');

% Step 3: Draw & save using the pooled spread for that item's kappaF
for i = 1:numel(MatrixP_list)
    MatrixP = MatrixP_list{i};
    MatrixG = MatrixG_list{i};
    prefix  = prefixes{i};
    sample  = sample_list{i};

    try
        % Choose pooled spread by exact kappaF; if NaN, compute per-file spread
        kappa = kappaF_vals(i);
        if ~isnan(kappa)
            key = sprintf('%.12g', kappa);
            if isKey(spread_map, key)
                spread_use = spread_map(key);
            else
                % Should not happen, but fallback to per-file
                spread_use = compute_spread({MatrixP}, {MatrixG}, r, extra_margin, use_cluster, use_all);
            end
        else
            spread_use = compute_spread({MatrixP}, {MatrixG}, r, extra_margin, use_cluster, use_all);
        end

        % Prepare inputs for drawing the entire cell population
        position_all = MatrixP(:, 1:3);
        gene2_all    = MatrixG(:, 2);

        % Draw
        [f, ax] = draw_cluster_figure(position_all, gene2_all, spread_use, ...
                                      r, ellip_res, fig_visibility); %#ok<ASGLU>

        % Save (SVG + PNG) using prefix
        base = sprintf('OUTPUT%d_%s', sample, prefix);
        svg_path = fullfile(save_dir_svg, [base '.svg']);
        png_path = fullfile(save_dir_png, [base '.png']);
        % save_figure_svg(f, svg_path);
        save_figure_png(f, png_path, 600);

        if strcmpi(fig_visibility,'off')
            close(f);
        end

    catch ME
        fprintf('  ❌ OUTPUT%d draw/save error: %s\n', sample, ME.message);
    end
end



%% ======================= HELPERS =======================

function ensure_dir(d)
    if ~exist(d, 'dir'), mkdir(d); end
end

% --- Extract numeric kappaF from the filename prefix
function kappaF = parse_kappaF_from_prefix(pref)
    % Accepts integers/decimals/scientific notation after 'kappaF_'
    s   = char(pref);
    expr = 'kappaF_([0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?)';
    tok  = regexp(s, expr, 'tokens', 'once');
    if isempty(tok)
        kappaF = NaN;  return;
    end
    kappaF = str2double(tok{1});
    if ~isnan(kappaF) && abs(kappaF - round(kappaF)) < 1e-9
        kappaF = round(kappaF);  % snap 10.000 -> 10, 1.000 -> 1
    end
end

% --- Compute one cube half-extent [Hx Hy Hz] from many frames
function spread = compute_spread(MatrixP_list, MatrixG_list, r, extra_margin, use_cluster, use_all)
    K              = numel(MatrixP_list);
    global_max     = 0;              % accumulate the largest half-extent scalar
    contact_thresh = 2 * r;

    for i = 1:K
        P = MatrixP_list{i};

        % cluster-based candidate
        if use_cluster
            G = MatrixG_list{i};
            if isempty(G) || size(G,2) < 2 || size(G,1) ~= size(P,1)
                fprintf('  [skip] Frame %d: invalid MatrixG for cluster mode\n', i);
            else
                idx_cluster = find_largest_cluster(P, G, contact_thresh);
                if isempty(idx_cluster)
                    fprintf('  [skip] Frame %d: no cluster found\n', i);
                else
                    position_cluster   = P(idx_cluster, 1:3);
                    center_cluster     = mean(position_cluster, 1);
                    deviation_cluster  = position_cluster - center_cluster;
                    he_cluster = [max(abs(deviation_cluster(:,1))), ...
                                  max(abs(deviation_cluster(:,2))), ...
                                  max(abs(deviation_cluster(:,3)))];
                    global_max = max(global_max, max(he_cluster));
                end
            end
        end

        % all-cells candidate
        if use_all
            center_all    = mean(P(:,1:3), 1);
            deviation_all = P(:,1:3) - center_all;
            he_all = [max(abs(deviation_all(:,1))), ...
                      max(abs(deviation_all(:,2))), ...
                      max(abs(deviation_all(:,3)))];
            global_max = max(global_max, max(he_all));
        end
    end

    max_spread = global_max + (r + extra_margin);
    spread     = [max_spread, max_spread, max_spread];
end

% --- Cluster finder with tie-break by asymmetry
function idx_cluster = find_largest_cluster(MatrixP, MatrixG, contact_thresh)
    N = size(MatrixP,1);
    D = pdist2(MatrixP(:,1:3), MatrixP(:,1:3));
    A = (D <= contact_thresh) & ~eye(N);

    Gc    = graph(sparse(triu(A,1)),'upper');
    comp  = conncomp(Gc);
    sizes = accumarray(comp(:), 1);

    max_size   = max(sizes);
    labels_max = find(sizes == max_size);

    if numel(labels_max) == 1
        idx_cluster = find(comp == labels_max);
        fprintf('✅ Largest cluster (label=%d) with %d cells\n', labels_max, numel(idx_cluster));
        return;
    end

    % tie-break by asymmetry
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

    [~, rel_best] = max(asym_list);
    if isnan(asym_list(rel_best)), rel_best = 1; end
    label_best  = labels_max(rel_best);
    idx_cluster = find(comp == label_best);
end

% --- Asymmetry score used for tie-breaking
function asymmetry = compute_asymmetry(position_cluster, gene_2_cluster, N_inner_global, N_outer_global)
    N_inner_local = nnz(gene_2_cluster == 0);
    N_outer_local = nnz(gene_2_cluster == 1);

    if N_inner_local == 0 || N_outer_local == 0
        asymmetry = 0;  return;
    end

    center_cluster      = mean(position_cluster, 1);
    distance_center_avg = mean(vecnorm(position_cluster - center_cluster, 2, 2));

    center_outer = mean(position_cluster(gene_2_cluster == 1, :), 1);
    center_inner = mean(position_cluster(gene_2_cluster == 0, :), 1);

    inner_ratio = N_inner_local / max(N_inner_global, 1);
    outer_ratio = N_outer_local / max(N_outer_global, 1);
    weight      = inner_ratio * outer_ratio;

    asymmetry = (norm(center_outer - center_inner) / distance_center_avg) * weight;
end

% --- Renderer
function [f, ax] = draw_cluster_figure(position, gene_2, spread, r, resolution, fig_visibility)
    f = figure('Visible', fig_visibility, 'Position', [50, 50, 500, 500], ...
               'Color', 'w', 'Renderer', 'opengl');
    ax = axes('Parent', f); hold(ax, 'on'); axis(ax, 'equal'); axis(ax, 'off');

    center = mean(position, 1);
    max_x  = spread(1); max_y = spread(2); max_z = spread(3);
    xlim(ax, [center(1)-max_x, center(1)+max_x]);
    ylim(ax, [center(2)-max_y, center(2)+max_y]);
    zlim(ax, [center(3)-max_z, center(3)+max_z]);

    for n = 1:size(position,1)
        x = position(n,1);  y = position(n,2);  z = position(n,3);
        [rx, ry, rz] = ellipsoid(x, y, z, r, r, r, resolution);
        if gene_2(n) == 1
            c = [1 0 0];   % outer: red
        else
            c = [0 0 1];   % inner: blue
        end
        surf(ax, rx, ry, rz, 'FaceColor', c, 'FaceAlpha', 1, ...
             'EdgeColor', 'none', 'FaceLighting', 'gouraud');
    end

    view(ax, [-165, -70]);
    camlight(ax, 'left');
    material(ax, 'dull');
end

% --- Save helpers
function save_figure_svg(f, out_path)
    out_dir = fileparts(out_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    try
        exportgraphics(f, out_path, 'ContentType','vector', 'BackgroundColor','white');
        fprintf('✅ SVG saved: %s\n', out_path);
    catch ME
        fprintf('❌ Failed to save SVG: %s\n   %s\n', out_path, ME.message);
    end
end

function save_figure_png(f, out_path, dpi)
    if nargin < 3, dpi = 300; end
    out_dir = fileparts(out_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    try
        exportgraphics(f, out_path, 'Resolution', dpi, 'BackgroundColor', 'white');
        fprintf('✅ PNG saved: %s\n', out_path);
    catch ME
        fprintf('❌ Failed to save PNG: %s\n   %s\n', out_path, ME.message);
    end
end
