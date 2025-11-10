%% =================== Headless & Rendering ===================
set(0, 'DefaultFigureVisible', 'off');
set(groot, 'defaultFigureRenderer', 'painters');

%% =================== Output ===================
out_svg = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Figure_2/fake_grey_scatter.svg';
out_dir = fileparts(out_svg);
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

%% =================== Config (same as your main code) ===================
axis_limits = [0.6 1 0.6 1 0.6 1];
axis_ticks  = [0.65 0.75 0.85 0.95];

front_axis_color = [0 0 0];
back_grid_color  = [0.85 0.85 0.85];
marker_size      = 50;
AX_LW            = 1.0;
GRID_ALPHA       = 1.0;
CMAP_N           = 256;
CMAP             = parula(CMAP_N);

% Text settings
set(groot, 'defaultTextInterpreter','none', ...
           'defaultAxesTickLabelInterpreter','none', ...
           'defaultLegendInterpreter','none', ...
           'defaultAxesFontName','Arial', ...
           'defaultTextFontName','Arial');
sizeFS = 19;
TICK_FS = sizeFS; XLAB_FS = sizeFS; YLAB_FS = sizeFS; ZLAB_FS = sizeFS;

% Figure geometry
fig_pos = [80 80 900 650];

% Layout knobs
ax_width_scale  = 0.53;
ax_height_scale = 0.68;
ax_dy_up        = 0.02;
BOTTOM_PAD      = 0.12;

% Colorbar
CBAR_TICKS       = [0 1 2];
CBAR_LABEL       = 'Morphological Asymmetry ({\itA}{\rm)}';
CBAR_AXIS_LW     = 1.0;
CBAR_GAP_Y       = 0.10;
CBAR_HEIGHT      = 0.05;
CBAR_EXTRA_DROP  = 0.00;
CBAR_NPATCH      = 256;

% Dummy clim so the colorbar looks the same
global_clim = [0 2];

%% =================== Fake data ===================
vals = linspace(0.65, 0.95, 13);   % adjust N here
[Xi, Yi, Zi] = ndgrid(vals, vals, vals);
X = Xi(:); Y = Yi(:); Z = Zi(:);

%% =================== Figure & Axes ===================
f = figure('Visible','off','Color','w','Position',fig_pos, ...
           'InvertHardcopy','off','HandleVisibility','off', ...
           'MenuBar','none','ToolBar','none','DockControls','off', ...
           'Renderer','painters');

ax = axes('Parent', f, 'Color','w'); hold(ax,'on'); grid(ax,'on'); box(ax,'off');
ax.PositionConstraint = 'innerposition';
ax.FontName = 'Arial';
ax.TickLabelInterpreter = 'none';

%% =================== Plot ===================
scatter3(ax, X, Y, Z, marker_size, ...
    'filled', ...
    'MarkerFaceColor', [0.6 0.6 0.6], ...  % grey fill
    'MarkerEdgeColor', 'k', ...            % black outline
    'LineWidth', 0.1);

% Camera/view/aspect
view(ax, 3);
camproj(ax, 'orthographic');
axis(ax, axis_limits);
pbaspect(ax, [1 1 1]); daspect(ax, [1 1 1]); axis(ax, 'vis3d');

% Labels & ticks
xticks(ax, axis_ticks); yticks(ax, axis_ticks); zticks(ax, axis_ticks);
ax.XTickLabel = compose('%.2f', axis_ticks);
ax.YTickLabel = compose('%.2f', axis_ticks);
ax.ZTickLabel = compose('%.2f', axis_ticks);

set(ax, 'XTickMode','manual','XTickLabelMode','manual', ...
        'YTickMode','manual','YTickLabelMode','manual', ...
        'ZTickMode','manual','ZTickLabelMode','manual');
xtickangle(ax,0); ytickangle(ax,0); ztickangle(ax,0);

xlabel(ax, '\alpha_{i-i}', 'Interpreter','tex','FontSize',XLAB_FS,'Color','k','FontName','Arial');
ylabel(ax, '\alpha_{o-o}', 'Interpreter','tex','FontSize',YLAB_FS,'Color','k','FontName','Arial');
zlabel(ax, '\alpha_{i-o}', 'Interpreter','tex','FontSize',ZLAB_FS,'Color','k','FontName','Arial');

ax.XColor = front_axis_color; ax.YColor = front_axis_color; ax.ZColor = front_axis_color;
ax.GridColor = back_grid_color; ax.GridAlpha = GRID_ALPHA;
ax.TickDir = 'out'; ax.LineWidth = AX_LW; ax.FontSize = TICK_FS;

% Reapply layout scaling
drawnow;
ax.Units = 'normalized';
pos = ax.Position;
pos(3) = pos(3) * ax_width_scale;
pos(4) = pos(4) * ax_height_scale;
pos(2) = pos(2) + ax_dy_up + BOTTOM_PAD;
ax.Position = pos;

% %% --------- Colorbar (full, same as real plots) ---------
% cax = axes('Parent', f, 'Units','normalized','Color','w','Box','on', ...
%            'XColor','k','YColor','k','LineWidth', CBAR_AXIS_LW);
% cax.Position = [ pos(1), ...
%                  max(0.02, pos(2) - CBAR_GAP_Y - CBAR_HEIGHT - CBAR_EXTRA_DROP), ...
%                  pos(3), CBAR_HEIGHT ];
% hold(cax,'on');
% 
% cmin = global_clim(1); cmax = global_clim(2);
% for i = 1:CBAR_NPATCH
%     t0 = (i-1)/CBAR_NPATCH; t1 = i/CBAR_NPATCH;
%     x0 = cmin + t0*(cmax-cmin);
%     x1 = cmin + t1*(cmax-cmin);
%     idx = max(1, min(size(CMAP,1), round(1 + (i-1)*(size(CMAP,1)-1)/(CBAR_NPATCH-1))));
%     patch(cax, [x0 x1 x1 x0], [0 0 1 1], CMAP(idx,:), 'EdgeColor','none');
% end
% 
% xlim(cax, [cmin cmax]); ylim(cax, [0 1]);
% cax.YTick = [];
% cax.FontName = 'Arial'; cax.FontSize = TICK_FS;
% cax.TickDir = 'out';
% cax.XTick = CBAR_TICKS;
% cax.XTickLabel = compose('%g', CBAR_TICKS);
% 
% xlabel(cax, CBAR_LABEL, 'Interpreter','tex','FontName','Arial', ...
%        'FontSize', XLAB_FS,'HorizontalAlignment','center', ...
%        'VerticalAlignment','top','Color','k');

% =================== Export ===================
print(f, out_svg, '-dsvg', '-painters');
close(f);
fprintf('Saved: %s\n', out_svg);



