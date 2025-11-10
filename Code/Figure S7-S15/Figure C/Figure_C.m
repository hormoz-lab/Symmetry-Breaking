%% =============================== Figure B (CSV-driven) ===============================
% Render GLOBAL & CLUSTER PNGs for alpha triplets listed in a CSV:
% columns:  alpha_ii, alpha_oo, alpha_io, sample, asymmetry, loss
% - Uses one fixed cubic world box computed across ALL selected rows (32 total)
% - β_ii = 0.150 (others 0) for file path building
% - Exports to: Supplement_All/beta_ii_0.150/Figure_B/{0.65_0.95,0.75_0.85}/{global,cluster}
%
% Linda — 2025-09-14

%% ---------- User Inputs ----------
csv_path       = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Supplement_All/beta_ii_0.150/Figure_C_beta_ii_0.150.csv';
parent_output  = '/n/scratch/users/s/suw469/gastruloids_1500_25%_check';  % where OUTPUT{sample} live
save_root      = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Supplement_All/beta_ii_0.150/Figure_C';

% Two alpha sets → two subfolders
SET_A = [0.65, 0.95];  SUB_A = '0.65_0.95';
SET_B = [0.75, 0.85];  SUB_B = '0.75_0.85';

% Betas (used for file names on disk)
BETA_II =  0.150;
BETA_OO =  0.000;
BETA_IO =  0.000;
BETA_OI =  0.000;

% Appearance / export
SHOW_GUI          = false;
PNG_DPI           = 600;
SHOW_TEXT_OVERLAY = false;     % keep off per your spec
cell_radius       = 1;
ellip_res         = 100;
contact_thresh    = 2 * cell_radius;
threshold_G2      = 0.95;
VIEW_AZEL         = [-165, -70];
EXTRA_MARGIN      = 0.0;       % world-units beyond (spread + cell_radius)
USE_CUBIC_BOUNDS  = true;

% Fixed D1/dt used in filenames (adjust if your files differ)
D1_VAL = 2;
DT_VAL = 0.20;

%% ---------- Prep output folders ----------
sub_dirs = {SUB_A, SUB_B};
for si = 1:numel(sub_dirs)
    ensure_dir(fullfile(save_root, sub_dirs{si}, 'global'));
    ensure_dir(fullfile(save_root, sub_dirs{si}, 'cluster'));
end

%% ---------- Read CSV ----------
if ~isfile(csv_path), error('CSV not found: %s', csv_path); end
T = readtable(csv_path, 'TextType','string');

col.alpha_ii  = colidx(T,'alpha_ii');
col.alpha_oo  = colidx(T,'alpha_oo');
col.alpha_io  = colidx(T,'alpha_io');
col.sample    = colidx(T,'sample');
col.asymmetry = colidx(T,'asymmetry');
col.loss      = colidx(T,'loss');

need = {'alpha_ii','alpha_oo','alpha_io','sample','asymmetry','loss'};
for k = 1:numel(need)
    if col.(need{k}) == 0
        error('CSV missing required column: %s', need{k});
    end
end

Aii = T{:,col.alpha_ii};
Aoo = T{:,col.alpha_oo};
Aio = T{:,col.alpha_io};
Smp = T{:,col.sample};
Asy = T{:,col.asymmetry};
Los = T{:,col.loss};

% Select the two 2×2×2 sets (8 rows each)
in_set = @(vals, set2) ismember(round(vals,3), round(set2,3));
maskA =  in_set(Aii,SET_A) & in_set(Aoo,SET_A) & in_set(Aio,SET_A);
maskB =  in_set(Aii,SET_B) & in_set(Aoo,SET_B) & in_set(Aio,SET_B);

rowsA = find(maskA);
rowsB = find(maskB);
if numel(rowsA) ~= 8
    fprintf(2,'[Warn] Expected 8 rows for set %s, found %d.\n', SUB_A, numel(rowsA));
end
if numel(rowsB) ~= 8
    fprintf(2,'[Warn] Expected 8 rows for set %s, found %d.\n', SUB_B, numel(rowsB));
end

rows_all = [rowsA; rowsB];
rows_all = rows_all(:).';
if isempty(rows_all)
    error('No matching rows across both sets.');
end

%% ---------- PASS 1: Determine fixed cubic bounds (MAX over ALL selected rows = 32) ----------
Hx=0; Hy=0; Hz=0;
half_margin = cell_radius + EXTRA_MARGIN;

fprintf('Computing fixed bounds from MAX(global, cluster) across %d rows...\n', numel(rows_all));
for r = rows_all
    sample = Smp(r);
    aii = Aii(r); aoo = Aoo(r); aio = Aio(r);

    [fileP, fileG] = build_paths_from_values(parent_output, aii, aoo, aio, ...
        BETA_II, BETA_OO, BETA_IO, BETA_OI, D1_VAL, DT_VAL, sample);

    if ~isfile(fileP) || ~isfile(fileG)
        fprintf(2,'  ↳ Missing files for row %d (OUTPUT%d)\n', r, sample);
        continue;
    end
    P = readmatrix(fileP);
    G = readmatrix(fileG);
    if isempty(P) || size(P,2)<3 || isempty(G) || size(G,2)<2
        fprintf(2,'  ↳ Bad data shapes row %d: P(%dx%d) G(%dx%d)\n', r, size(P,1), size(P,2), size(G,1), size(G,2));
        continue;
    end
    if size(P,1) ~= size(G,1)
        n = min(size(P,1), size(G,1)); P = P(1:n,:); G = G(1:n,:);
        fprintf('  ↳ Row %d: trimmed to %d rows.\n', r, n);
    end

    % GLOBAL spreads
    c_g = mean(P(:,1:3),1);
    dev = P(:,1:3) - c_g;
    hx_g = max(abs(dev(:,1)));
    hy_g = max(abs(dev(:,2)));
    hz_g = max(abs(dev(:,3)));

    % CLUSTER spreads
    idxC = largest_cluster_fast(P(:,1:3), contact_thresh);
    if ~isempty(idxC)
        c_c  = mean(P(idxC,1:3),1);
        devc = P(idxC,1:3) - c_c;
        hx_c = max(abs(devc(:,1)));
        hy_c = max(abs(devc(:,2)));
        hz_c = max(abs(devc(:,3)));

        % Accumulate MAX(global, cluster)
        Hx = max([Hx, hx_g, hx_c]);
        Hy = max([Hy, hy_g, hy_c]);
        Hz = max([Hz, hz_g, hz_c]);
    else
        % No cluster → fall back to global only
        Hx = max(Hx, hx_g);
        Hy = max(Hy, hy_g);
        Hz = max(Hz, hz_g);
    end
end

Hx = Hx + half_margin; Hy = Hy + half_margin; Hz = Hz + half_margin;
if USE_CUBIC_BOUNDS
    Hmax = max([Hx,Hy,Hz]); Hx = Hmax; Hy = Hmax; Hz = Hmax;
end
half_extents = [Hx Hy Hz];
fprintf('Fixed half-extents (ALL rows): Hx=%.3f Hy=%.3f Hz=%.3f  (full spans: %.3f, %.3f, %.3f)\n', ...
        Hx,Hy,Hz, 2*Hx,2*Hy,2*Hz);

%% ---------- PASS 2: Render + Save ----------
fig_vis = ternary(SHOW_GUI,'on','off');

do_one_set(rowsA, SUB_A, ...
    Aii, Aoo, Aio, Smp, Asy, Los, ...
    parent_output, half_extents, SHOW_TEXT_OVERLAY, VIEW_AZEL, ...
    threshold_G2, cell_radius, ellip_res, PNG_DPI, save_root, fig_vis, ...
    BETA_II, BETA_OO, BETA_IO, BETA_OI, D1_VAL, DT_VAL);

do_one_set(rowsB, SUB_B, ...
    Aii, Aoo, Aio, Smp, Asy, Los, ...
    parent_output, half_extents, SHOW_TEXT_OVERLAY, VIEW_AZEL, ...
    threshold_G2, cell_radius, ellip_res, PNG_DPI, save_root, fig_vis, ...
    BETA_II, BETA_OO, BETA_IO, BETA_OI, D1_VAL, DT_VAL);

fprintf('Done.\n');

%% ======================= Local functions =======================

function do_one_set(rows_idx, subname, ...
    Aii, Aoo, Aio, Smp, Asy, Los, ...
    parent_output, half_extents, SHOW_TEXT_OVERLAY, VIEW_AZEL, ...
    threshold_G2, cell_radius, ellip_res, PNG_DPI, save_root, fig_vis, ...
    BETA_II, BETA_OO, BETA_IO, BETA_OI, D1_VAL, DT_VAL)

    if isempty(rows_idx), return; end
    for r = rows_idx(:).'
        do_one_row(r, subname, ...
            Aii, Aoo, Aio, Smp, Asy, Los, ...
            parent_output, half_extents, SHOW_TEXT_OVERLAY, VIEW_AZEL, ...
            threshold_G2, cell_radius, ellip_res, PNG_DPI, save_root, fig_vis, ...
            BETA_II, BETA_OO, BETA_IO, BETA_OI, D1_VAL, DT_VAL);
    end
end

function do_one_row(r, subname, ...
    Aii, Aoo, Aio, Smp, Asy, Los, ...
    parent_output, half_extents, SHOW_TEXT_OVERLAY, VIEW_AZEL, ...
    threshold_G2, cell_radius, ellip_res, PNG_DPI, save_root, fig_vis, ...
    BETA_II, BETA_OO, BETA_IO, BETA_OI, D1_VAL, DT_VAL)

    sample = Smp(r);
    aii = Aii(r); aoo = Aoo(r); aio = Aio(r);
    asym = Asy(r); loss = Los(r);

    [fileP, fileG, prefix] = build_paths_from_values( ...
        parent_output, aii, aoo, aio, BETA_II, BETA_OO, BETA_IO, BETA_OI, D1_VAL, DT_VAL, sample);
    if ~isfile(fileP) || ~isfile(fileG)
        fprintf(2,'  ↳ Missing files for row %d (OUTPUT%d)\n', r, sample);
        return;
    end
    P = readmatrix(fileP);
    G = readmatrix(fileG);
    if size(P,1) ~= size(G,1)
        n = min(size(P,1), size(G,1)); P = P(1:n,:); G = G(1:n,:);
    end
    gene2 = G(:,2);

    % ----- GLOBAL -----
    try
        [f1, ax1] = start_fig(fig_vis);
        draw_points(ax1, P(:,1:3), gene2, threshold_G2, cell_radius, ellip_res);
        c_g = mean(P(:,1:3),1);
        apply_world(ax1, c_g, half_extents, VIEW_AZEL);
        if SHOW_TEXT_OVERLAY
            title(ax1, sprintf('OUTPUT%d  %s (global)', sample, prefix), 'Interpreter','none');
        end
        out_base = mk_basename(aii, aoo, aio, sample, asym, loss);
        out_dir  = fullfile(save_root, subname, 'global'); ensure_dir(out_dir);
        save_figure_png(f1, fullfile(out_dir, [out_base '.png']), PNG_DPI);
        if strcmpi(fig_vis,'off'), close(f1); end
    catch ME
        fprintf('  ❌ Row %d GLOBAL error: %s\n', r, ME.message);
    end

    % ----- CLUSTER -----
    try
        idxC = largest_cluster_fast(P(:,1:3), 2 * cell_radius);
        if isempty(idxC)
            fprintf('  [skip] Row %d: no cluster found\n', r);
            return;
        end
        [f2, ax2] = start_fig(fig_vis);
        draw_points(ax2, P(idxC,1:3), gene2(idxC), threshold_G2, cell_radius, ellip_res);
        c_c = mean(P(idxC,1:3),1);
        apply_world(ax2, c_c, half_extents, VIEW_AZEL);
        if SHOW_TEXT_OVERLAY
            title(ax2, sprintf('OUTPUT%d  %s (cluster)', sample, prefix), 'Interpreter','none');
        end
        out_base = mk_basename(aii, aoo, aio, sample, asym, loss);
        out_dir  = fullfile(save_root, subname, 'cluster'); ensure_dir(out_dir);
        save_figure_png(f2, fullfile(out_dir, [out_base '.png']), PNG_DPI);
        if strcmpi(fig_vis,'off'), close(f2); end
    catch ME
        fprintf('  ❌ Row %d CLUSTER error: %s\n', r, ME.message);
    end
end

function name = mk_basename(aii, aoo, aio, sample, asym, loss)
    % Asymmetry: 2 decimals; Loss: integer percentage
    asym_str = sprintf('%.2f', asym);
    loss_pct = round(double(loss) * 100);  % integer percent
    name = sprintf('Aii_%.3f_Aoo_%.3f_Aio_%.3f_OUTPUT%d_Asymmetry_%s_Loss_%d%%', ...
                   aii, aoo, aio, sample, asym_str, loss_pct);
end

function ensure_dir(d)
    if ~exist(d, 'dir'), mkdir(d); end
end

function idx = colidx(T, name)
    idx = find(strcmpi(T.Properties.VariableNames, name), 1, 'first');
    if isempty(idx), idx = 0; end
end

function [fileP, fileG, prefix] = build_paths_from_values(parent_path, aii, aoo, aio, blii, bloo, blio, bloi, D1, dt, sample)
    % Build filename stem exactly as on disk
    sAii  = sprintf('%.3f', aii);
    sAoo  = sprintf('%.3f', aoo);
    sAio  = sprintf('%.3f', aio);
    sBLii = sprintf('%.3f', blii);
    sBLoo = sprintf('%.3f', bloo);
    sBLio = sprintf('%.3f', blio);
    sBLoi = sprintf('%.3f', bloi);
    sD1   = sprintf('%d',  D1);
    sdt   = sprintf('%.2f', dt);

    prefix = sprintf(['Aii_%s_Aoo_%s_Aio_%s_', ...
                      'BLii_%s_BLoo_%s_BLio_%s_BLoi_%s_', ...
                      'D1_%s_dt_%s'], ...
                      sAii, sAoo, sAio, sBLii, sBLoo, sBLio, sBLoi, sD1, sdt);

    out_dir = fullfile(parent_path, sprintf('OUTPUT%d', sample));
    fileP   = fullfile(out_dir, [prefix '_MatrixP_Final.csv']);
    fileG   = fullfile(out_dir, [prefix '_MatrixG_Final.csv']);
end

function idx_cluster = largest_cluster_fast(X, thresh)
    N = size(X,1);
    if N==0, idx_cluster = []; return; end
    D = pdist2(X, X);
    A = (D <= thresh) & ~eye(N);
    Gc = graph(sparse(triu(A,1)),'upper');
    comp = conncomp(Gc);
    sizes = accumarray(comp(:), 1);
    [m] = max(sizes);
    labels = find(sizes==m);
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

function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end

function save_figure_png(f, out_path, dpi)
    out_dir = fileparts(out_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir'), mkdir(out_dir); end
    try
        exportgraphics(f, out_path, 'Resolution', dpi, 'BackgroundColor','white');
        fprintf('✅ PNG: %s\n', out_path);
    catch ME
        fprintf('❌ PNG save failed: %s\n   %s\n', out_path, ME.message);
    end
end


