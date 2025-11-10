%% =================== Headless (must be FIRST) ===================
set(0, 'DefaultFigureVisible', 'off');
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
file_path = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Results/Asymmetry_Weighted_Summary/OUTPUT6_10_asymmetry_cluster_weighted_summary_avg.csv';
out_svg   = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Figure_2/plot_avg_betaLoo_0.135_asymmetry_avg.svg';
out_dir   = fileparts(out_svg);
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

metric_field = 'asymmetry_avg';

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
sizeFS     = 19;
TICK_FS    = sizeFS;
XLAB_FS    = sizeFS;
YLAB_FS    = sizeFS;
ZLAB_FS    = sizeFS;

% ---- Layout knobs ----
ax_width_scale  = 0.53;
ax_height_scale = 0.68;
ax_dy_up        = 0.02;

% ---- Extra bottom padding for main axes ----
BOTTOM_PAD       = 0.12;

% ---- NEW: Extra left margin to make room for LEFT colorbar label ----
LEFT_PAD         = 0.10;   % try 0.08–0.12 if you want finer control

% ---- Colorbar (horizontal, below main axes) ----
CBAR_TICKS       = [0 1 2];
CBAR_LABEL       = 'Morphological Asymmetry ({\itA}{\rm)}';
CBAR_AXIS_LW     = 1.0;
CBAR_GAP_Y       = 0.10;
CBAR_HEIGHT      = 0.05;
CBAR_EXTRA_DROP  = 0.00;
CBAR_NPATCH      = 256;

% ---- Numeric tolerance ----
tol = 1e-9;

%% =================== Load table & global color limits ===================
T = readtable(file_path);

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
global_clim = [cmin cmax];  % use global scale for visual consistency

%% =================== Filter: beta_oo=0.135, others=0 ===================
mask = (abs(T.betaL_ii) < tol) & (abs(T.betaL_io) < tol) & (abs(T.betaL_oi) < tol) & ...
       (abs(T.betaL_oo - 0.135) < tol);

S = T(mask, :);
if isempty(S)
    warning('No rows matched the filter (betaL_oo = 0.135; others = 0). No figure saved.');
    return;
end

%% =================== Plot (single SVG) ===================
f = figure('Visible','on','Color','w','Position',fig_pos, ...
           'InvertHardcopy','off','HandleVisibility','off', ...
           'MenuBar','none','ToolBar','none','DockControls','off', ...
           'Renderer','painters');

ax = axes('Parent', f, 'Color','w'); hold(ax,'on'); grid(ax,'on'); box(ax,'off');
ax.PositionConstraint = 'innerposition';
ax.FontName = 'Arial';
ax.TickLabelInterpreter = 'none';

% Extract & finite-filter
X = S.alpha_ii;  Y = S.alpha_oo;  Z = S.alpha_io;  C = S.(metric_field);
finite_mask = isfinite(X) & isfinite(Y) & isfinite(Z) & isfinite(C);
X = X(finite_mask); Y = Y(finite_mask); Z = Z(finite_mask); C = C(finite_mask);

% Scatter colored by asymmetry_avg
scatter3(ax, X, Y, Z, marker_size, C, 'filled', ...
         'MarkerEdgeColor','none', 'LineWidth',0.5);
view(ax, 3);
camproj(ax, 'orthographic');      % stable size/look
axis(ax, axis_limits);
pbaspect(ax, [1 1 1]); daspect(ax, [1 1 1]); axis(ax, 'vis3d');

colormap(f, CMAP);
caxis(ax, global_clim);

% Labels & ticks
xlabel(ax, '\alpha_{i-i}', 'Interpreter','tex','FontSize',XLAB_FS,'Color','k','FontName','Arial');
ylabel(ax, '\alpha_{o-o}', 'Interpreter','tex','FontSize',YLAB_FS,'Color','k','FontName','Arial');
zlabel(ax, '\alpha_{i-o}', 'Interpreter','tex','FontSize',ZLAB_FS,'Color','k','FontName','Arial');

xticks(ax, axis_ticks); yticks(ax, axis_ticks); zticks(ax, axis_ticks);
ax.XTickLabel = compose('%.2f', axis_ticks);
ax.YTickLabel = compose('%.2f', axis_ticks);
ax.ZTickLabel = compose('%.2f', axis_ticks);

set(ax, 'XTickMode','manual','XTickLabelMode','manual', ...
        'YTickMode','manual','YTickLabelMode','manual', ...
        'ZTickMode','manual','ZTickLabelMode','manual');
xtickangle(ax,0); ytickangle(ax,0); ztickangle(ax,0);

ax.XColor = front_axis_color; ax.YColor = front_axis_color; ax.ZColor = front_axis_color;
ax.GridColor = back_grid_color; ax.GridAlpha = GRID_ALPHA;
ax.TickDir = 'out'; ax.LineWidth = AX_LW; ax.FontSize = TICK_FS;

% ===== Apply layout scaling and padding =====
drawnow;
ax.Units = 'normalized';
pos = ax.Position;
pos(3) = pos(3) * ax_width_scale;
pos(4) = pos(4) * ax_height_scale;
pos(2) = pos(2) + ax_dy_up + BOTTOM_PAD;

% ===== NEW: shift everything to the RIGHT to make room on the left =====
pos(1) = pos(1) + LEFT_PAD;
ax.Position = pos;

% --------- Horizontal colorbar (custom axes with patches) ---------
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
cax.FontName = 'Arial'; cax.FontSize = TICK_FS;
cax.TickDir = 'out';
cax.XTick = CBAR_TICKS;
cax.XTickLabel = compose('%g', CBAR_TICKS);

xlabel(cax, CBAR_LABEL, 'Interpreter','tex','FontName','Arial', ...
       'FontSize', XLAB_FS,'HorizontalAlignment','center', ...
       'VerticalAlignment','top','Color','k');

% --------- Vertical colorbar (custom axes on the RIGHT) ---------
cax = axes('Parent', f, 'Units','normalized','Color','w','Box','on', ...
           'XColor','k','YColor','k','LineWidth', CBAR_AXIS_LW);

% Position: to the RIGHT of main axes
CBAR_WIDTH = 0.04;   % relative width of colorbar
gap_x      = 0.05;   % gap between main plot and colorbar
cax.Position = [pos(1) + pos(3) + gap_x, pos(2), CBAR_WIDTH, pos(4)];

hold(cax,'on');

cmin = global_clim(1); 
cmax = global_clim(2);
for i = 1:CBAR_NPATCH
    t0 = (i-1)/CBAR_NPATCH; 
    t1 = i/CBAR_NPATCH;
    y0 = cmin + t0*(cmax-cmin);
    y1 = cmin + t1*(cmax-cmin);
    idx = max(1, min(size(CMAP,1), ...
             round(1 + (i-1)*(size(CMAP,1)-1)/(CBAR_NPATCH-1))));
    patch(cax, [0 1 1 0], [y0 y0 y1 y1], CMAP(idx,:), 'EdgeColor','none');
end

xlim(cax,[0 1]); ylim(cax,[cmin cmax]);
cax.XTick = []; % hide x axis
cax.YTick = CBAR_TICKS;
cax.YTickLabel = compose('%g', CBAR_TICKS);

cax.FontName = 'Arial'; 
cax.FontSize = TICK_FS;
cax.TickDir = 'out';

hY = ylabel(cax, CBAR_LABEL, 'Interpreter','tex','FontName','Arial', ...
       'FontSize', YLAB_FS, 'Color','k', ...
       'Rotation',270, ...
       'HorizontalAlignment','left', ...
       'VerticalAlignment','middle');

% Shift slightly right so it clears the ticks
hY.Position(1) = hY.Position(1) + 3; 
hY.Position(2) = hY.Position(2) + 1; 

% --------- Vertical colorbar (custom axes on the LEFT) ---------
cax = axes('Parent', f, 'Units','normalized','Color','w','Box','on', ...
           'XColor','k','YColor','k','LineWidth', CBAR_AXIS_LW);

% Position: to the LEFT of main axes (now shifted right by LEFT_PAD)
CBAR_WIDTH = 0.04;   
gap_x      = 0.1;   % slightly tighter gap is fine
cax.Position = [pos(1) - gap_x - CBAR_WIDTH, pos(2), CBAR_WIDTH, pos(4)];

hold(cax,'on');

cmin = global_clim(1); 
cmax = global_clim(2);
for i = 1:CBAR_NPATCH
    t0 = (i-1)/CBAR_NPATCH; 
    t1 = i/CBAR_NPATCH;
    y0 = cmin + t0*(cmax-cmin);
    y1 = cmin + t1*(cmax-cmin);
    idx = max(1, min(size(CMAP,1), ...
             round(1 + (i-1)*(size(CMAP,1)-1)/(CBAR_NPATCH-1))));
    patch(cax, [0 1 1 0], [y0 y0 y1 y1], CMAP(idx,:), 'EdgeColor','none');
end

xlim(cax,[0 1]); ylim(cax,[cmin cmax]);
cax.XTick = [];                 
cax.YTick = CBAR_TICKS;
cax.YTickLabel = compose('%g', CBAR_TICKS);
cax.YAxisLocation = 'left';

cax.FontName = 'Arial'; 
cax.FontSize = TICK_FS;
cax.TickDir = 'out';

% ---- Title on the LEFT, placed with normalized units (bottom -> top) ----
hY = ylabel(cax, CBAR_LABEL, 'Interpreter','tex','FontName','Arial', ...
       'FontSize', YLAB_FS, 'Color','k', ...
       'Rotation', 90, ...
       'HorizontalAlignment','center', ...
       'VerticalAlignment','middle', ...
       'Clipping','off');
set(hY, 'Units','normalized');
hY.Position = [-1.2, 0.5, 0];   % just outside ticks but inside figure; try -0.10 to -0.20 if needed

% =================== Export ===================
print(f, out_svg, '-dsvg', '-painters');
% Alternative (R2021a+):
% exportgraphics(f, out_svg, 'ContentType','vector', 'BackgroundColor','none', 'Padding',5);

close(f);
fprintf('Saved: %s\n', out_svg);

