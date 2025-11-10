%% Time-series: fixed SCALE from cluster SPREAD (not absolute position), SVG for OUTPUT6..10
% - For each (OUTPUT, t): find largest cluster (contact <= 2*cell_radius), tie-break by asymmetry.
% - Compute global half-extents Hx,Hy,Hz from per-cluster spreads (max |coordinate - cluster_center|), across OUTPUT6..10.
% - When rendering, center axes on the current cluster's centroid but use fixed half-extents (Hx,Hy,Hz) -> constant scale.
% - Save SVGs for all OUTPUT6..10 into corresponding subfolders.

% =======================
% === User parameters ===
% =======================
SHOW_GUI       = false;   % false => offscreen
parent_path    = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Figure_S7/Figure_S7D/Aii_0.800_Aoo_0.750_Aio_0.800_BLii_0.150_BLoo_0.000_BLio_0.000_BLoi_0.000';
OUTPUTS        = 6:10;    % compute + render for these OUTPUT folders

% Time range
T_min          = 501;
T_step         = 75;
T_max          = 1251;

% Plot styling & clustering
cell_radius    = 1;                  % ellipsoid radius (world units)
contact_thresh = 2*cell_radius;      % cluster if distance <= 2r
threshold_G2   = 0.95;               % Gene-2 threshold (red vs blue)
ellip_res      = 100;                % ellipsoid mesh resolution

% Bounds options
USE_CUBIC_BOUNDS = true;             % enforce Hx=Hy=Hz = max(Hx,Hy,Hz)
EXTRA_MARGIN     = 0;                % extra world-units on top of cell_radius

% Output directory
save_dir       = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Figure_S7/Figure_S7D/png';

% =========================
% === Pre-run setup     ===
% =========================
fig_visibility = 'off';
if SHOW_GUI, fig_visibility = 'on'; end
if ~exist(save_dir, 'dir'), mkdir(save_dir); end

% Build time list (clamped)
T_list = T_min:T_step:T_max;
T_list = T_list(T_list <= T_max);

fprintf('Compute global half-extents from cluster SPREAD across OUTPUT%d..OUTPUT%d; t=%d:%d:%d (|T|=%d)\n', ...
    OUTPUTS(1), OUTPUTS(end), T_min, T_step, T_max, numel(T_list));

% Store per (OUTPUT,t): cluster indices, cluster center
cluster_index_map = containers.Map('KeyType','char', 'ValueType','any');
cluster_center_map= containers.Map('KeyType','char', 'ValueType','any');

% =========================
% === PASS 1: compute global half-extents from cluster spreads
% =========================
Hx = 0; Hy = 0; Hz = 0;   % global half-extents (to be maximized)

for s = OUTPUTS
    out_dir_s = fullfile(parent_path, sprintf('OUTPUT%d', s));
    for t = T_list
        key = sprintf('OUTPUT%d_t%d', s, t);

        % Data paths
        file_path_P = fullfile(out_dir_s, sprintf('WorkSpace_MatrixP_%d.csv', t));
        file_path_G = fullfile(out_dir_s, sprintf('WorkSpace_MatrixG_%d.csv', t));

        if ~isfile(file_path_P) || ~isfile(file_path_G)
            fprintf('  [skip] Missing files for %s (P? %d, G? %d)\n', ...
                key, isfile(file_path_P), isfile(file_path_G));
            continue
        end

        MatrixP = readmatrix(file_path_P);   % x,y,z
        MatrixG = readmatrix(file_path_G);   % gene1,gene2,gene3

        if isempty(MatrixP) || size(MatrixP,2) < 3 || isempty(MatrixG) || size(MatrixG,2) < 2
            fprintf('  [skip] Invalid data for %s\n', key);
            continue
        end

        N = size(MatrixP,1);
        if N == 0
            fprintf('  [skip] No cells in %s\n', key);
            continue
        end

        % Global inner/outer counts (for asymmetry weighting)
        expr_all        = MatrixG(:,2);
        N_inner_global  = nnz(expr_all == 0);
        N_outer_global  = nnz(expr_all == 1);

        % --- Find largest cluster; tie-break by higher asymmetry ---
        if N == 1
            idx_cluster_best = 1;
        else
            D  = pdist2(MatrixP(:,1:3), MatrixP(:,1:3));
            A  = (D <= contact_thresh) & ~eye(N);
            Gc = graph(sparse(triu(A,1)), 'upper');
            comp  = conncomp(Gc);
            sizes = accumarray(comp(:), 1);
            max_size   = max(sizes);
            labels_max = find(sizes == max_size);

            asym_list = nan(numel(labels_max), 1);
            for m = 1:numel(labels_max)
                idx_c   = find(comp == labels_max(m));
                pos_c   = MatrixP(idx_c, 1:3);
                expr_c  = MatrixG(idx_c, 2);

                n_in = nnz(expr_c == 0);
                n_ot = nnz(expr_c == 1);

                if n_in == 0 || n_ot == 0
                    asym_list(m) = 0;
                    continue
                end

                center_geom = mean(pos_c, 1);
                r_geom      = mean(vecnorm(pos_c - center_geom, 2, 2));
                if r_geom <= eps
                    asym_list(m) = NaN;
                else
                    center_ot = mean(pos_c(expr_c == 1, :), 1);
                    center_in = mean(pos_c(expr_c == 0, :), 1);
                    ri = n_in / max(N_inner_global, 1);
                    ro = n_ot / max(N_outer_global, 1);
                    w  = ri * ro;
                    asym_list(m) = (norm(center_ot - center_in) / r_geom) * w;
                end
            end

            [~, rel_best] = max(asym_list);
            if isnan(asym_list(rel_best)), rel_best = 1; end
            label_best       = labels_max(rel_best);
            idx_cluster_best = find(comp == label_best);
        end

        % Save cluster indices
        cluster_index_map(key) = idx_cluster_best;

        % --- Compute cluster center and half-extents (spread) ---
        pos_c = MatrixP(idx_cluster_best, 1:3);
        ccent = mean(pos_c, 1);
        dev   = pos_c - ccent;           % deviations from centroid
        hx    = max(abs(dev(:,1)));
        hy    = max(abs(dev(:,2)));
        hz    = max(abs(dev(:,3)));

        % Update global half-extents (based on spread only)
        Hx = max(Hx, hx);
        Hy = max(Hy, hy);
        Hz = max(Hz, hz);

        % Save cluster center for reuse during rendering
        cluster_center_map(key) = ccent;
    end
end

% Add margin (cell_radius + extra) to each half-extent
half_margin = cell_radius + EXTRA_MARGIN;
Hx = Hx + half_margin;
Hy = Hy + half_margin;
Hz = Hz + half_margin;

% Optional cubic half-extent
if USE_CUBIC_BOUNDS
    Hmax = max([Hx, Hy, Hz]);
    Hx = Hmax; Hy = Hmax; Hz = Hmax;
end

% Print global half-extents and full spans
fprintf('GLOBAL half-extents from cluster SPREAD (after margin%s):\n', ...
    ternary_str(USE_CUBIC_BOUNDS, ', cubic', ''));
fprintf('  Hx=%.3f  Hy=%.3f  Hz=%.3f\n', Hx, Hy, Hz);
fprintf('  Full spans -> X: %.3f, Y: %.3f, Z: %.3f\n', 2*Hx, 2*Hy, 2*Hz);

% =========================
% === PASS 2: Render ALL OUTPUTS, center per-frame, fixed scale, save SVG
% =========================
for s = OUTPUTS
    out_subdir = fullfile(save_dir, sprintf('OUTPUT%d_time_series', s));
    if ~exist(out_subdir, 'dir'), mkdir(out_subdir); end

    fprintf('Rendering OUTPUT%d (SVG), fixed scale from SPREAD, centered per frame...\n', s);

    for ti = 1:numel(T_list)
        t = T_list(ti);
        key = sprintf('OUTPUT%d_t%d', s, t);

        % Paths
        file_path_P = fullfile(parent_path, sprintf('OUTPUT%d', s), ...
                               sprintf('WorkSpace_MatrixP_%d.csv', t));
        file_path_G = fullfile(parent_path, sprintf('OUTPUT%d', s), ...
                               sprintf('WorkSpace_MatrixG_%d.csv', t));

        if ~isfile(file_path_P) || ~isfile(file_path_G)
            fprintf('  [skip] Missing P/G for %s\n', key);
            continue
        end

        MatrixP = readmatrix(file_path_P);
        MatrixG = readmatrix(file_path_G);
        if isempty(MatrixP) || size(MatrixP,2) < 3 || isempty(MatrixG) || size(MatrixG,2) < 2
            fprintf('  [skip] Invalid data for %s\n', key);
            continue
        end

        % Retrieve indices and center; if missing (unlikely), recompute quick
        if isKey(cluster_index_map, key) && isKey(cluster_center_map, key)
            idx_cluster = cluster_index_map(key);
            ccent       = cluster_center_map(key);
        else
            % Quick recompute (same logic as above, compact)
            N = size(MatrixP,1);
            if N == 0, fprintf('  [skip] No cells in %s\n', key); continue; end
            if N == 1
                idx_cluster = 1;
            else
                D  = pdist2(MatrixP(:,1:3), MatrixP(:,1:3));
                A  = (D <= contact_thresh) & ~eye(N);
                Gc = graph(sparse(triu(A,1)), 'upper');
                comp  = conncomp(Gc);
                sizes = accumarray(comp(:), 1);
                max_size   = max(sizes);
                labels_max = find(sizes == max_size);

                expr_all = MatrixG(:,2);
                N_inner_global  = nnz(expr_all == 0);
                N_outer_global  = nnz(expr_all == 1);

                asym_list = nan(numel(labels_max), 1);
                for m = 1:numel(labels_max)
                    idx_c  = find(comp == labels_max(m));
                    pos_c  = MatrixP(idx_c, 1:3);
                    expr_c = MatrixG(idx_c, 2);
                    n_in = nnz(expr_c == 0); n_ot = nnz(expr_c == 1);
                    if n_in == 0 || n_ot == 0
                        asym_list(m) = 0;
                    else
                        cg = mean(pos_c,1);
                        rg = mean(vecnorm(pos_c - cg,2,2));
                        if rg <= eps
                            asym_list(m) = NaN;
                        else
                            co = mean(pos_c(expr_c==1,:),1);
                            ci = mean(pos_c(expr_c==0,:),1);
                            ri = n_in / max(N_inner_global,1);
                            ro = n_ot / max(N_outer_global,1);
                            w  = ri*ro;
                            asym_list(m) = (norm(co-ci)/rg)*w;
                        end
                    end
                end
                [~, rel_best] = max(asym_list);
                if isnan(asym_list(rel_best)), rel_best = 1; end
                label_best  = labels_max(rel_best);
                idx_cluster = find(comp == label_best);
            end
            ccent = mean(MatrixP(idx_cluster,1:3), 1);
        end

        % --- Figure ---
        f = figure('Visible', fig_visibility, 'Position', [50, 50, 500, 500], ...
                   'Color', 'w', 'Renderer', 'opengl');
        ax = axes('Parent', f); hold(ax, 'on'); axis(ax, 'equal'); axis(ax, 'off');

        % Fixed scale from SPREAD, centered on current cluster center
        xlim(ax, [ccent(1)-Hx, ccent(1)+Hx]);
        ylim(ax, [ccent(2)-Hy, ccent(2)+Hy]);
        zlim(ax, [ccent(3)-Hz, ccent(3)+Hz]);

        % Draw ONLY the cluster
        pos = MatrixP(idx_cluster, 1:3);
        g2  = MatrixG(idx_cluster, 2);
        for n = 1:size(pos,1)
            cx = pos(n,1); cy = pos(n,2); cz = pos(n,3);
            [rx, ry, rz] = ellipsoid(cx, cy, cz, cell_radius, cell_radius, cell_radius, ellip_res);
            if g2(n) > threshold_G2
                c = [1 0 0];   % red
            else
                c = [0 0 1];   % blue
            end
            surf(ax, rx, ry, rz, 'FaceColor', c, 'FaceAlpha', 1, ...
                 'EdgeColor', 'none', 'FaceLighting', 'gouraud');
        end

        % Camera & lighting
        view(ax, [-165, -70]);
        camlight(ax, 'left');
        material(ax, 'dull');

        % % Save as SVG into per-sample subfolder
        % base_name = sprintf('Sample_%d_t%04d', s, t);
        % svg_path  = fullfile(out_subdir, [base_name '.svg']);
        % 
        % try
        %     exportgraphics(f, svg_path, 'ContentType','vector', 'BackgroundColor','white');
        % catch
        %     print(f, svg_path, '-dsvg');
        % end
        % fprintf('  ✅ SVG saved: %s\n', svg_path);


        % Save as PNG into per-sample subfolder
        base_name = sprintf('Sample_%d_t%04d', s, t);
        png_path  = fullfile(out_subdir, [base_name '.png']);
        
        try
            % High-quality PNG (vector content will rasterize at set resolution)
            exportgraphics(f, png_path, 'Resolution', 300, 'BackgroundColor','white');
        catch
            % Fallback if exportgraphics is not available
            print(f, png_path, '-dpng', '-r300');   % -r300 = 300 dpi
        end
        
        fprintf('  ✅ PNG saved: %s\n', png_path);

        if ~SHOW_GUI, close(f); end
    end
end

fprintf('Done. Rendered SVG frames for OUTPUT%d..OUTPUT%d with fixed SCALE from cluster SPREAD.\n', OUTPUTS(1), OUTPUTS(end));

% ---- tiny inline helper for printing only (keeps this a script) ----
function s = ternary_str(cond, a, b)
if cond, s = a; else, s = b; end
end
