%% =================== Headless (must be FIRST) ===================
set(0, 'DefaultFigureVisible', 'off');  % suppress GUI figure popups

% Force stable vector rendering (avoid OpenGL/exportgraphics crashes on mac/headless)
set(groot, 'defaultFigureRenderer', 'painters');

% Clear any legacy CreateFcn defaults that might throw errors
try
    set(groot,'defaultFigureCreateFcn','remove');
    set(groot,'defaultAxesCreateFcn','remove');
catch
    set(groot,'defaultFigureCreateFcn','');
    set(groot,'defaultAxesCreateFcn','');
end

%% =================== Config (user controls) ===================
% ---- I/O ----
file_path    = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Results/Asymmetry_Weighted_Summary/OUTPUT6_10_asymmetry_cluster_weighted_summary_avg.csv';

out_dir_zero  = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Figure_3/Figure_3A';
out_dir_other = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Supplementary_Figures/Supplement_A';

metric_field = 'asymmetry_avg';   % e.g., 'asymmetry_avg' or 'loss_avg'

% ---- Axes limits & ticks ----
axis_limits = [0.6 1 0.6 1 0.6 1];   % [xmin xmax ymin ymax zmin zmax]
axis_ticks  = [0.65 0.75 0.85 0.95];

% ---- Colors & style ----
front_axis_color = [0 0 0];
back_grid_color  = [0.85 0.85 0.85];
marker_size      = 50;
AX_LW            = 1.0;
GRID_ALPHA       = 1.0;
CMAP_N           = 256;
CMAP             = parula(CMAP_N);

% === Text settings: Arial for numbers/ticks ===
set(groot, 'defaultTextInterpreter','none', ...
           'defaultAxesTickLabelInterpreter','none', ...
           'defaultLegendInterpreter','none', ...
           'defaultAxesFontName','Arial', ...
           'defaultTextFontName','Arial');

% ---- Figure geometry ----
fig_pos = [80 80 900 650];

% ---- Font sizes ----
size        = 20;
TICK_FS     = size;
XLAB_FS     = size;
YLAB_FS     = size;
ZLAB_FS     = size;
TITLE_FS    = size;
SUBTITLE_FS = size;

% ---- Layout knobs ----
ax_width_scale    = 0.53;
ax_height_scale   = 0.68;
ax_dy_up          = 0.02;

% ---- Extra bottom padding for main axes ----
BOTTOM_PAD       = 0.12;   % was 0.08

% ---- Colorbar (horizontal, below main axes) ----
CBAR_TICKS       = [0 1 2];
CBAR_LABEL       = 'Morphological Asymmetry ({\itA}{\rm)}';
CBAR_AXIS_LW     = 1.0;
CBAR_GAP_Y       = 0.10;   % was 0.06
CBAR_HEIGHT      = 0.05;
CBAR_EXTRA_DROP  = 0.00;   % was 0.02
CBAR_NPATCH      = 256;

% ---- Color limits ----
USE_FIXED_CLIM   = false;
FIXED_CLIM       = [0 2];

% ---- Numeric tolerance ----
tol = 1e-9;

% ---- Title toggles ----
SHOW_TITLE_FOR_ZERO  = false;
SHOW_TITLE_FOR_OTHER = false;

%% =================== Load table ===================
T = readtable(file_path);

% ---- Global color scale ----
allC  = T.(metric_field);
maskF = isfinite(allC);
if ~any(maskF)
    cmin = 0; cmax = 1;
else
    cmin = min(allC(maskF));
    cmax = max(allC(maskF));
    if cmax <= cmin + eps(max(1,abs(cmin)))
        pad  = max(1e-12, 1e-6*max(1,abs(cmin)));
        cmin = cmin - pad;
        cmax = cmax + pad;
    end
end
global_clim_data = [cmin cmax];
if USE_FIXED_CLIM
    global_clim = FIXED_CLIM;
else
    global_clim = global_clim_data;
end

% Ensure output directories exist
if ~exist(out_dir_zero,  'dir'); mkdir(out_dir_zero);  end
if ~exist(out_dir_other, 'dir'); mkdir(out_dir_other); end

%% =================== Case A: all betas are zero ===================
mask_allzero = (abs(T.betaL_ii) < tol & abs(T.betaL_oo) < tol & ...
                abs(T.betaL_io) < tol & abs(T.betaL_oi) < tol);
S0 = T(mask_allzero, :);

if ~isempty(S0)
    base_name = sprintf('plot_avg_betaL_allzero_%s.svg', metric_field);

    out_svg_A = fullfile(out_dir_zero,  base_name);
    out_svg_B = fullfile(out_dir_other, base_name);

    try
        make_plot_svg_main(S0, [], [], metric_field, ...
            axis_limits, axis_ticks, ...
            front_axis_color, back_grid_color, ...
            marker_size, fig_pos, ...
            TICK_FS, XLAB_FS, YLAB_FS, ZLAB_FS, TITLE_FS, SUBTITLE_FS, ...
            AX_LW, GRID_ALPHA, ...
            ax_width_scale, ax_height_scale, ax_dy_up, ...
            BOTTOM_PAD, ...
            global_clim, CMAP, ...
            out_svg_A, SHOW_TITLE_FOR_ZERO, ...
            CBAR_TICKS, CBAR_LABEL, CBAR_AXIS_LW, CBAR_GAP_Y, CBAR_HEIGHT, CBAR_EXTRA_DROP, CBAR_NPATCH);
    catch ME
        warning('Failed (all-beta-zero): %s', ME.message);
    end

    try
        make_plot_svg_main(S0, [], [], metric_field, ...
            axis_limits, axis_ticks, ...
            front_axis_color, back_grid_color, ...
            marker_size, fig_pos, ...
            TICK_FS, XLAB_FS, YLAB_FS, ZLAB_FS, TITLE_FS, SUBTITLE_FS, ...
            AX_LW, GRID_ALPHA, ...
            ax_width_scale, ax_height_scale, ax_dy_up, ...
            BOTTOM_PAD, ...
            global_clim, CMAP, ...
            out_svg_B, SHOW_TITLE_FOR_ZERO, ...
            CBAR_TICKS, CBAR_LABEL, CBAR_AXIS_LW, CBAR_GAP_Y, CBAR_HEIGHT, CBAR_EXTRA_DROP, CBAR_NPATCH);
    catch ME
        warning('Failed (all-beta-zero): %s', ME.message);
    end
end

%% =================== Case B–E: one betaL nonzero ===================
betaL_types_raw = {'ii','oo','io','oi'};

for b = 1:numel(betaL_types_raw)
    bl_raw  = betaL_types_raw{b};
    bl_disp = fmt_beta_index(bl_raw);
    col_this = ['betaL_' bl_raw];
    others   = setdiff(betaL_types_raw, bl_raw);

    others_zero_mask = true(height(T),1);
    for o = 1:numel(others)
        others_zero_mask = others_zero_mask & (abs(T.(['betaL_' others{o}])) < tol);
    end

    vals_nonzero = unique(T.(col_this)(others_zero_mask & abs(T.(col_this)) > tol));
    vals_nonzero = vals_nonzero(~isnan(vals_nonzero));
    vals = sort(unique([vals_nonzero; 0]));

    for v = reshape(vals,1,[])
        if abs(v) < tol
            mask = others_zero_mask & (abs(T.(col_this)) < tol);
            if ~any(mask), mask = mask_allzero; end
        else
            mask = others_zero_mask & (abs(T.(col_this) - v) < tol);
        end
        S = T(mask, :);
        if isempty(S), continue; end

        out_svg = fullfile(out_dir_other, sprintf('plot_avg_betaL%s_%0.3f_%s.svg', bl_raw, v, metric_field));

        try
            make_plot_svg_main(S, bl_disp, v, metric_field, ...
                axis_limits, axis_ticks, ...
                front_axis_color, back_grid_color, ...
                marker_size, fig_pos, ...
                TICK_FS, XLAB_FS, YLAB_FS, ZLAB_FS, TITLE_FS, SUBTITLE_FS, ...
                AX_LW, GRID_ALPHA, ...
                ax_width_scale, ax_height_scale, ax_dy_up, ...
                BOTTOM_PAD, ...
                global_clim, CMAP, ...
                out_svg, SHOW_TITLE_FOR_OTHER, ...
                CBAR_TICKS, CBAR_LABEL, CBAR_AXIS_LW, CBAR_GAP_Y, CBAR_HEIGHT, CBAR_EXTRA_DROP, CBAR_NPATCH);
        catch ME
            warning('Plot failed for %s: %s', out_svg, ME.message);
        end
    end
end

%% =================== Helper: main plot ===================
function make_plot_svg_main(S, bl, v, metric_field, ...
    axis_limits, axis_ticks, ...
    front_axis_color, back_grid_color, ...
    marker_size, fig_pos, ...
    TICK_FS, XLAB_FS, YLAB_FS, ZLAB_FS, TITLE_FS, SUBTITLE_FS, ...
    AX_LW, GRID_ALPHA, ...
    ax_width_scale, ax_height_scale, ax_dy_up, ...
    BOTTOM_PAD, ...
    global_clim, CMAP, ...
    out_svg, SHOW_BETA_SUBTITLE, ...
    CBAR_TICKS, CBAR_LABEL, CBAR_AXIS_LW, CBAR_GAP_Y, CBAR_HEIGHT, CBAR_EXTRA_DROP, CBAR_NPATCH)

    f = figure('Visible','off','Color','w','Position',fig_pos, ...
               'InvertHardcopy','off','HandleVisibility','off', ...
               'MenuBar','none','ToolBar','none','DockControls','off', ...
               'Renderer','painters');
    ax = axes('Parent', f, 'Color','w'); hold(ax,'on'); grid(ax,'on'); box(ax,'off');
    ax.TickLabelInterpreter = 'none';
    ax.FontName = 'Arial';
    ax.PositionConstraint = 'innerposition';  % <- fixes axis squeeze

    % Extract & finite-filter
    X = S.alpha_ii;  Y = S.alpha_oo;  Z = S.alpha_io;  C = S.(metric_field);
    mask = isfinite(X) & isfinite(Y) & isfinite(Z) & isfinite(C);
    X = X(mask); Y = Y(mask); Z = Z(mask); C = C(mask);
    if isempty(C), close(f); return; end

    % Plot
    scatter3(ax, X, Y, Z, marker_size, C, 'filled');
    view(ax, 3);
    colormap(f, CMAP);
    caxis(ax, global_clim);

    % Labels
    xl = xlabel(ax, '\alpha_{i-i}', 'Interpreter','tex','FontSize',XLAB_FS,'Color','k');
    yl = ylabel(ax, '\alpha_{o-o}', 'Interpreter','tex','FontSize',YLAB_FS,'Color','k');
    zl = zlabel(ax, '\alpha_{i-o}', 'Interpreter','tex','FontSize',ZLAB_FS,'Color','k');
    
    if SHOW_BETA_SUBTITLE
        if isempty(bl)
            t2 = '\beta_{L} = 0';
        else
            t2 = sprintf('\\beta_{L,%s} = %.3f', bl, v);
        end
        % Use 'tex' or 'none' for Interpreter — but control font explicitly
        title(ax, t2, ...
            'Interpreter','tex', ...     % still renders \beta nicely
            'FontName','Arial', ...      % force Arial font
            'FontWeight','normal', ...   % remove bold
            'FontAngle','normal', ...    % remove italics (optional)
            'FontSize',TITLE_FS, ...
            'Color','k');
    end

    
    axis(ax, axis_limits);
    xticks(ax, axis_ticks); yticks(ax, axis_ticks); zticks(ax, axis_ticks);
    
    % Force label text with 2 decimals (exact 0.65, 0.75, 0.85, 0.95)
    ax.XTickLabel = compose('%.2f', axis_ticks);
    ax.YTickLabel = compose('%.2f', axis_ticks);
    ax.ZTickLabel = compose('%.2f', axis_ticks);
    
    % === LOCK TICKS & FORCE HORIZONTAL LABELS (put HERE) ===
    set(ax, 'XTickMode','manual','XTickLabelMode','manual');
    set(ax, 'YTickMode','manual','YTickLabelMode','manual');
    set(ax, 'ZTickMode','manual','ZTickLabelMode','manual');
    
    try
        ax.XAxis.TickLabelRotation = 0;
        ax.YAxis.TickLabelRotation = 0;
        ax.ZAxis.TickLabelRotation = 0;
    catch
        xtickangle(ax, 0);
        ytickangle(ax, 0);
        ztickangle(ax, 0);
    end
    % === 
    
    ax.XColor = front_axis_color; ax.YColor = front_axis_color; ax.ZColor = front_axis_color;
    ax.GridColor = back_grid_color;
    ax.GridAlpha = GRID_ALPHA;
    ax.TickDir = 'out'; ax.LineWidth = AX_LW; ax.FontSize = TICK_FS;

    % --- position after layout is done
    drawnow;
    ax.Units = 'normalized';
    pos = ax.Position;
    pos(3) = pos(3)*ax_width_scale;
    pos(4) = pos(4)*ax_height_scale;
    pos(2) = pos(2) + ax_dy_up + BOTTOM_PAD;
    ax.Position = pos;

    % --------- Colorbar ----------
    cax = axes('Parent', f, 'Units','normalized','Color','w','Box','on', ...
               'XColor','k','YColor','k','LineWidth', CBAR_AXIS_LW);
    cax.Position = [ pos(1), ...
                     max(0.02, pos(2) - CBAR_GAP_Y - CBAR_HEIGHT - CBAR_EXTRA_DROP), ...
                     pos(3), CBAR_HEIGHT ];
    hold(cax,'on');

    cmin = global_clim(1); cmax = global_clim(2);
    for i = 1:CBAR_NPATCH
        t0 = (i-1)/CBAR_NPATCH; t1 = i/CBAR_NPATCH;
        x0 = cmin + t0*(cmax-cmin);
        x1 = cmin + t1*(cmax-cmin);
        idx = max(1, min(size(CMAP,1), round(1 + (i-1)*(size(CMAP,1)-1)/(CBAR_NPATCH-1))));
        patch(cax, [x0 x1 x1 x0], [0 0 1 1], CMAP(idx,:), 'EdgeColor','none');
    end

    xlim(cax, [cmin cmax]); ylim(cax, [0 1]);
    cax.YTick = [];
    cax.TickDir = 'out';
    cax.FontName = 'Arial';
    cax.FontSize = TICK_FS;
    ticks_in = CBAR_TICKS(CBAR_TICKS >= cmin & CBAR_TICKS <= cmax);
    cax.XTick = ticks_in;
    cax.XTickLabel = compose('%g', ticks_in);

    xlabel(cax, CBAR_LABEL, 'Interpreter','tex','FontName','Arial', ...
        'FontSize', XLAB_FS,'HorizontalAlignment','center', ...
        'VerticalAlignment','top','Color','k');

    % Export
    try
        print(f, out_svg, '-dsvg', '-painters');
    catch ME
        warning('Failed to write %s: %s', out_svg, ME.message);
    end
    drawnow limitrate;
    pause(0.01);
    close(f);
end

%% =================== Helper: display index formatter ===================
function s = fmt_beta_index(raw)
    switch raw
        case 'ii', s = 'i-i';
        case 'oo', s = 'o-o';
        case 'io', s = 'i-o';
        case 'oi', s = 'o-i';
        otherwise, s = raw;
    end
end


