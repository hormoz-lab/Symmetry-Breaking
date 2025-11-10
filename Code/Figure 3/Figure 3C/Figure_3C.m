%% Figure_3B: winners at all betas=0, fixed cubic scale = MAX(global,cluster), render PNGs
% Linda 2025-09-04

% =======================
% === User parameters ===
% =======================
agg_csv     = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/OUTPUT6_10_asymmetry_cluster_weighted_summary_avg.csv';
parent_path = '/n/scratch/users/s/suw469/gastruloids_1500_25%_check';
save_root   = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Figure_3/Figure_3C';

% All betas = 0
b_ii = 0.000; b_oo = 0.000; b_io = 0.000; b_oi = 0.000;

% Optional additional keys (used only if present in CSV)
D1_val = 2;          % constrain if present; ignored if not in CSV
dt_val = 0.20;       % constrain if present; ignored if not in CSV

% Visualization & export
SHOW_GUI          = false;
SAVE_PNG          = true;             % we render PNGs
PNG_DPI           = 600;
SHOW_TEXT_OVERLAY = false;            % no overlays for Fig 3B

% Geometry & clustering
cell_radius    = 1;
contact_thresh = 2 * cell_radius;     % connectivity threshold
threshold_G2   = 0.95;                % red vs blue (MatrixG(:,2) > 0.95 -> red)
ellip_res      = 100;                 % lower (e.g., 24) = faster

% Fixed-scale options
USE_CUBIC_BOUNDS = true;              % Hx=Hy=Hz = max(Hx,Hy,Hz)
EXTRA_MARGIN     = 0.0;               % extra world-units beyond (spread + cell_radius)

% View
VIEW_AZEL = [-165, -70];

% Limit (0 = all 16)
ROW_LIMIT = 0;

% Output subfolders
save_dir_global  = fullfile(save_root, 'global');
save_dir_cluster = fullfile(save_root, 'cluster');
ensure_dir(save_dir_global);
ensure_dir(save_dir_cluster);

% =========================
% === Alpha combinations ==
% =========================
Aset1 = [0.75, 0.85];
[AIIs1, AOOs1, AIOs1] = ndgrid(Aset1, Aset1, Aset1);
C1 = [AIIs1(:), AOOs1(:), AIOs1(:)];
Aset2 = [0.65, 0.95];
[AIIs2, AOOs2, AIOs2] = ndgrid(Aset2, Aset2, Aset2);
C2 = [AIIs2(:), AOOs2(:), AIOs2(:)];
combos = [C1; C2];   % 16x3

% =======================
% === Load the table  ===
% =======================
if ~isfile(agg_csv), error('File not found: %s', agg_csv); end
T = readtable(agg_csv);

% Per-replicate asymmetry and loss columns actually present
asym_names = {};  sample_ids = [];
loss_names = {};
for s = 6:10
    a_nm = sprintf('asymmetry_%d', s);
    l_nm = sprintf('loss_%d', s);
    a_idx = colidx(T, a_nm);
    if a_idx > 0
        asym_names{end+1} = T.Properties.VariableNames{a_idx}; %#ok<SAGROW>
        sample_ids(end+1)  = s;                                %#ok<SAGROW>
        l_idx = colidx(T, l_nm);
        if l_idx > 0
            loss_names{end+1} = T.Properties.VariableNames{l_idx}; %#ok<SAGROW>
        else
            loss_names{end+1} = ''; %#ok<SAGROW>
        end
    end
end
if isempty(asym_names)
    error('No columns like "asymmetry_6..10" found in %s', agg_csv);
end

fig_visibility = ternary(SHOW_GUI, 'on', 'off');

% =========================================
% === PASS 1: selection + spread scanning ===
% =========================================
n_do = size(combos,1);
if ROW_LIMIT > 0, n_do = min(n_do, ROW_LIMIT); end
fprintf('Selecting winners (all betas=0) and computing fixed scale from MAX(global, cluster) spread...\n');

% Minimal info to carry to PASS 2
Jobs = struct( ...
    'rowIdx', [], 'best_sample', [], 'best_asym', [], 'best_loss', [], ...
    'alpha_ii', [], 'alpha_oo', [], 'alpha_io', [], 'prefix', [] );

J = 0;
Hx = 0; Hy = 0; Hz = 0;                     % global fixed half-extents accumulator
half_margin = cell_radius + EXTRA_MARGIN;

for k = 1:n_do
    alpha_ii = combos(k,1);
    alpha_oo = combos(k,2);
    alpha_io = combos(k,3);

    % --- mask row under beta=0 (+ optional D1/dt) ---
    mask = true(height(T),1);
    mask = mask & eq_rounded(T, 'alpha_ii', alpha_ii, 3);
    mask = mask & eq_rounded(T, 'alpha_oo', alpha_oo, 3);
    mask = mask & eq_rounded(T, 'alpha_io', alpha_io, 3);
    mask = mask & eq_rounded(T, 'betaL_ii', b_ii, 3) ...
               & eq_rounded(T, 'betaL_oo', b_oo, 3) ...
               & eq_rounded(T, 'betaL_io', b_io, 3) ...
               & eq_rounded(T, 'betaL_oi', b_oi, 3);
    if colidx(T,'D1') > 0, mask = mask & (T{:, colidx(T,'D1')} == D1_val); end
    if colidx(T,'dt') > 0, mask = mask & eq_rounded(T, 'dt', dt_val, 2); end

    rowIdx = find(mask, 1, 'first');
    if isempty(rowIdx)
        fprintf(2,'❌ No row for Aii=%.3f Aoo=%.3f Aio=%.3f | betas=0\n', alpha_ii, alpha_oo, alpha_io);
        continue;
    end

    % --- choose winning replicate by max asymmetry ---
    asym_vals = nan(1, numel(asym_names));
    for j = 1:numel(asym_names)
        asym_vals(j) = T{rowIdx, colidx(T, asym_names{j})};
    end
    finiteMask = isfinite(asym_vals);
    if ~any(finiteMask)
        fprintf(2,'[Row %d] All asymmetry_* are NaN; skip.\n', rowIdx);
        continue;
    end
    [best_asym, relPos] = max(asym_vals(finiteMask));
    finiteIdxs  = find(finiteMask);
    absPos      = finiteIdxs(relPos);
    best_sample = sample_ids(absPos);

    % match loss (if present)
    best_loss = NaN;
    if absPos <= numel(loss_names) && ~isempty(loss_names{absPos})
        best_loss = T{rowIdx, colidx(T, loss_names{absPos})};
    end

    % --- locate files & read once JUST to measure spreads ---
    [fileP, fileG, prefix] = build_paths_from_row(parent_path, T, rowIdx, best_sample);
    if ~isfile(fileP) || ~isfile(fileG)
        fprintf(2,'  ↳ Files not found in OUTPUT%d (row %d)\n', best_sample, rowIdx);
        continue;
    end
    P = readmatrix(fileP);   % Nx3
    G = readmatrix(fileG);   % Nx>=2
    if isempty(P) || size(P,2) < 3 || isempty(G) || size(G,2) < 2
        fprintf(2,'  ↳ Bad data shapes (skip): P(%dx%d) G(%dx%d)\n', size(P,1), size(P,2), size(G,1), size(G,2));
        continue;
    end
    if size(P,1) ~= size(G,1)
        n = min(size(P,1), size(G,1)); P = P(1:n,:); G = G(1:n,:);
        fprintf('  ↳ Row mismatch trimmed to %d rows.\n', n);
    end

    % --- GLOBAL centroid & spreads ---
    center_global = mean(P(:,1:3), 1);
    dev_g = P(:,1:3) - center_global;
    hx_g  = max(abs(dev_g(:,1)));
    hy_g  = max(abs(dev_g(:,2)));
    hz_g  = max(abs(dev_g(:,3)));

    % --- Largest CLUSTER & spreads ---
    idx_cluster   = largest_cluster_fast(P(:,1:3), contact_thresh);
    center_cluster= mean(P(idx_cluster,1:3), 1);
    dev_c = P(idx_cluster,1:3) - center_cluster;
    hx_c  = max(abs(dev_c(:,1)));
    hy_c  = max(abs(dev_c(:,2)));
    hz_c  = max(abs(dev_c(:,3)));

    % --- Update fixed half-extents with MAX(global, cluster) ---
    Hx = max([Hx, hx_g, hx_c]);
    Hy = max([Hy, hy_g, hy_c]);
    Hz = max([Hz, hz_g, hz_c]);

    % Save ONLY minimal info for pass 2
    J = J + 1;
    Jobs(J).rowIdx      = rowIdx;
    Jobs(J).best_sample = best_sample;
    Jobs(J).best_asym   = best_asym;
    Jobs(J).best_loss   = best_loss;
    Jobs(J).alpha_ii    = alpha_ii;
    Jobs(J).alpha_oo    = alpha_oo;
    Jobs(J).alpha_io    = alpha_io;
    Jobs(J).prefix      = prefix;

    fprintf('k=%2d | row %6d | Aii=%.3f Aoo=%.3f Aio=%.3f | betas=0 | winner OUTPUT%d (asym=%.3f, loss=%s)\n', ...
        k, rowIdx, alpha_ii, alpha_oo, alpha_io, best_sample, best_asym, ...
        ternary(isfinite(best_loss), sprintf('%.3f', best_loss), 'NaN'));
end

if J==0, error('No valid winners found.'); end

% Finalize fixed half-extents (add margin; optional cubic)
Hx = Hx + half_margin; Hy = Hy + half_margin; Hz = Hz + half_margin;
if USE_CUBIC_BOUNDS
    Hmax = max([Hx,Hy,Hz]); Hx = Hmax; Hy = Hmax; Hz = Hmax;
end
fprintf('FIXED half-extents from MAX(global, cluster) spread: Hx=%.3f Hy=%.3f Hz=%.3f (full spans %.3f, %.3f, %.3f)\n', ...
    Hx,Hy,Hz, 2*Hx,2*Hy,2*Hz);

% =========================================
% === PASS 2: draw global & cluster PNGs ===
% =========================================
for j = 1:J
    rowIdx      = Jobs(j).rowIdx;
    best_sample = Jobs(j).best_sample;
    prefix      = Jobs(j).prefix;

    [fileP, fileG] = build_paths_from_row(parent_path, T, rowIdx, best_sample);
    if ~isfile(fileP) || ~isfile(fileG)
        fprintf(2,'  ↳ PASS2 files not found in OUTPUT%d (row %d)\n', best_sample, rowIdx);
        continue;
    end
    P = readmatrix(fileP);
    G = readmatrix(fileG);
    if size(P,1) ~= size(G,1)
        n = min(size(P,1), size(G,1)); P = P(1:n,:); G = G(1:n,:);
    end

    % --- color vector from MatrixG(:,2) vs threshold_G2 ---
    gene2 = G(:,2);
    % Prepare common scale & center on global or cluster center per view
    half_extents = [Hx, Hy, Hz];

    % ===== GLOBAL =====
    try
        [f_glob, ax_glob] = start_fig(fig_visibility);
        draw_points(ax_glob, P(:,1:3), gene2, threshold_G2, cell_radius, ellip_res);
        center_g = mean(P(:,1:3), 1);
        apply_world(ax_glob, center_g, half_extents, VIEW_AZEL);
        if SHOW_TEXT_OVERLAY
            title(ax_glob, sprintf('OUTPUT%d  %s (global)', best_sample, prefix), 'Interpreter','none');
        end
        base = sprintf('OUTPUT%d_%s', best_sample, prefix);
        png_path = fullfile(save_dir_global, [base '.png']);
        save_figure_png(f_glob, png_path, PNG_DPI);
        if strcmpi(fig_visibility,'off'), close(f_glob); end
    catch ME
        fprintf('  ❌ OUTPUT%d global draw/save error: %s\n', best_sample, ME.message);
    end

    % ===== CLUSTER =====
    try
        idx_cluster = largest_cluster_fast(P(:,1:3), contact_thresh);
        if isempty(idx_cluster)
            fprintf('  [skip] OUTPUT%d: no cluster found\n', best_sample);
        else
            [f_clu, ax_clu] = start_fig(fig_visibility);
            draw_points(ax_clu, P(idx_cluster,1:3), gene2(idx_cluster), threshold_G2, cell_radius, ellip_res);
            center_c = mean(P(idx_cluster,1:3), 1);
            apply_world(ax_clu, center_c, half_extents, VIEW_AZEL);
            if SHOW_TEXT_OVERLAY
                title(ax_clu, sprintf('OUTPUT%d  %s (cluster)', best_sample, prefix), 'Interpreter','none');
            end
            base = sprintf('OUTPUT%d_%s', best_sample, prefix);
            png_path = fullfile(save_dir_cluster, [base '.png']);
            save_figure_png(f_clu, png_path, PNG_DPI);
            if strcmpi(fig_visibility,'off'), close(f_clu); end
        end
    catch ME
        fprintf('  ❌ OUTPUT%d cluster draw/save error: %s\n', best_sample, ME.message);
    end
end

fprintf('Done.\n');

%% =======================
%% ====== Functions ======
%% =======================

function ensure_dir(d)
    if ~exist(d, 'dir'), mkdir(d); end
end

function idx = colidx(T, name)
    idx = find(strcmpi(T.Properties.VariableNames, name), 1, 'first');
    if isempty(idx), idx = 0; end
end

function tf = eq_rounded(T, col, val, digits)
    c = colidx(T, col);
    if c==0
        tf = true(size(T,1),1);  % tolerate missing col
        return
    end
    tf = round(T{:,c}, digits) == round(val, digits);
end

function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end

function [fileP, fileG, prefix] = build_paths_from_row(parent_path, T, rowIdx, sample)
    % Build filename stem from row values (use fixed formatting to match disk)
    fmtA  = '%.3f'; fmtBL = '%.3f'; fmtDt = '%.2f';
    getv = @(nm) T{rowIdx, colidx(T,nm)};
    sAii  = sprintf(fmtA,  getv('alpha_ii'));
    sAoo  = sprintf(fmtA,  getv('alpha_oo'));
    sAio  = sprintf(fmtA,  getv('alpha_io'));
    sBLii = sprintf(fmtBL, getv('betaL_ii'));
    sBLoo = sprintf(fmtBL, getv('betaL_oo'));
    sBLio = sprintf(fmtBL, getv('betaL_io'));
    sBLoi = sprintf(fmtBL, getv('betaL_oi'));
    if colidx(T,'D1')>0,   sD1 = sprintf('%d', getv('D1')); else, sD1 = '2'; end
    if colidx(T,'dt')>0,   sdt = sprintf(fmtDt, getv('dt')); else, sdt = '0.20'; end
    prefix = sprintf( ...
        ['Aii_%s_Aoo_%s_Aio_%s_', ...
         'BLii_%s_BLoo_%s_BLio_%s_BLoi_%s_', ...
         'D1_%s_dt_%s'], ...
         sAii, sAoo, sAio, sBLii, sBLoo, sBLio, sBLoi, sD1, sdt);
    out_dir = fullfile(parent_path, sprintf('OUTPUT%d', sample));
    fileP   = fullfile(out_dir, [prefix '_MatrixP_Final.csv']);
    fileG   = fullfile(out_dir, [prefix '_MatrixG_Final.csv']);
end

function idx_cluster = largest_cluster_fast(X, thresh)
    % X: N x 3
    N = size(X,1);
    if N==0, idx_cluster = []; return; end
    D = pdist2(X, X);
    A = (D <= thresh) & ~eye(N);
    Gc = graph(sparse(triu(A,1)),'upper');
    comp = conncomp(Gc);
    sizes = accumarray(comp(:), 1);
    [m] = max(sizes);
    labels = find(sizes==m);
    % tie-break: just pick the first (fast); we’ll refine during render if needed
    idx_cluster = find(comp==labels(1));
end

function [f, ax] = start_fig(vis)
    f = figure('Visible', vis, 'Position', [50, 50, 500, 500], ...
               'Color', 'w', 'Renderer', 'opengl');
    ax = axes('Parent', f); hold(ax, 'on'); axis(ax, 'equal'); axis(ax, 'off');
end

function draw_points(ax, pos, gene2, thr, r, res)
    for n = 1:size(pos,1)
        [rx, ry, rz] = ellipsoid(pos(n,1), pos(n,2), pos(n,3), r, r, r, res);
        if gene2(n) > thr, c = [1 0 0]; else, c = [0 0 1]; end
        surf(ax, rx, ry, rz, 'FaceColor', c, 'FaceAlpha', 1, ...
            'EdgeColor', 'none', 'FaceLighting', 'gouraud');
    end
    view(ax, [-165, -70]); camlight(ax, 'left'); material(ax, 'dull');
end

function apply_world(ax, center, half_extents, view_azel)
    xlim(ax, [center(1)-half_extents(1), center(1)+half_extents(1)]);
    ylim(ax, [center(2)-half_extents(2), center(2)+half_extents(2)]);
    zlim(ax, [center(3)-half_extents(3), center(3)+half_extents(3)]);
    view(ax, view_azel);
end

function save_figure_png(f, out_path, dpi)
    out_dir = fileparts(out_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir'), mkdir(out_dir); end
    try
        exportgraphics(f, out_path, 'Resolution', dpi, 'BackgroundColor', 'white');
        fprintf('✅ PNG: %s\n', out_path);
    catch ME
        fprintf('❌ PNG save failed: %s\n   %s\n', out_path, ME.message);
    end
end


