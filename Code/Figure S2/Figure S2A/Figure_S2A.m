%% =================== Force vs Distance (Main Script) ===================
close all;

%% ---------- User Parameters ----------
r              = 1;
alpha_values   = [1 0.95 0.85 0.75 0.65];
d_min          = 0;                 % sampling start
d_max          = 10;                % sampling end
num_points     = 400;

% Axes control
x_lim          = [0 2];           % extend slightly beyond 2
y_lim          = [-1 1];
x_ticks        = 0.5:0.5:2;           % label only up to 2
y_ticks        = -1:0.5:1;

% Aesthetics
font_size      = 25;
legend_font    = 25;
line_width     = 2.5;               % curve width
axis_lw        = 1.5;               % axis line width

% Legend placement
alpha_legend_location = 'southwest';
alpha_legend_position = [];  % leave empty to use keyword

% Axis label positions
xlabel_pos = [0.96 0.1 0];
ylabel_pos = [-0.12 0.90 0];

% Output
out_dir  = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Supplementary_Figures/Supplement_Process';
out_name = 'Figure_SA.svg';

%% ---------- Derived ----------
f0 = 1;
d  = linspace(d_min, d_max, num_points);
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
out_file = fullfile(out_dir, out_name);

%% ---------- Figure & Axes ----------
fig = figure('Color','w','Position',[210 210 900 650], ...
             'MenuBar','none','ToolBar','none','DockControls','off', ...
             'InvertHardcopy','off','Renderer','painters');
ax = axes('Parent', fig); hold(ax, 'on'); box(ax, 'off');
set(ax,'FontName','Arial','FontSize',font_size, ...
       'XColor','none', ...                 % hide default x-axis
       'YColor','k','LineWidth',axis_lw, ...
       'XGrid','off','YGrid','off','Color','w','Layer','top');
xlim(ax, x_lim); ylim(ax, y_lim);
xticks(ax, x_ticks); yticks(ax, y_ticks);
ax.TickDir = 'out';
ax.XTickLabel = [];                        % remove default tick labels (we'll draw our own)

%% ---------- Curves (stop EXACTLY at x = 2) ----------
C = lines(numel(alpha_values));
for i = 1:numel(alpha_values)
    a0 = alpha_values(i);
    F_all  = -(f0 ./ (2 * r * a0)) .* d + f0;

    % clip to d <= 2 and guarantee the last point is exactly at d = 2
    mask = d <= 2;
    d_plot = d(mask); F_plot = F_all(mask);
    if abs(d_plot(end) - 2) > 1e-12
        d_plot(end+1) = 2;
        F_plot(end+1) = -(f0 / (2*r*a0)) * 2 + f0;
    end

    plot(ax, d_plot, F_plot, 'LineWidth', line_width, 'Color', C(i,:), ...
        'DisplayName', sprintf('\\alpha = %.2f', a0));
end

%% ---------- Labels ----------
xlabel(ax, '|{\bf\itd}_{\itn,m}|', 'Interpreter','tex', ...
       'FontSize', font_size, 'FontName','Arial', 'Color','k');
ylabel(ax, '{\itF}_{\itn,m}^{short}', 'Interpreter','tex', ...
       'FontSize', font_size, 'FontName','Arial', 'Color','k', ...
       'Rotation', 0);

% Apply label positions
ax.XLabel.Units = 'normalized'; ax.XLabel.Position = xlabel_pos;
ax.YLabel.Units = 'normalized'; ax.YLabel.Position = ylabel_pos;

%% ---------- Custom x-axis at y = 0 (with black ticks & labels) ----------
% axis line
plot(ax, x_lim, [0 0], 'k-', 'LineWidth', axis_lw, 'HandleVisibility','off');

% ticks and labels (BLACK)
tick_len = 0.02;  % vertical length of tick marks (data units)
for xt = x_ticks
    plot(ax, [xt xt], [0 -tick_len], 'k', 'LineWidth', axis_lw, 'HandleVisibility','off'); % ticks
    text(xt, -0.08, num2str(xt), ...
        'FontSize', font_size, 'FontName','Arial', 'Color','k', ...
        'HorizontalAlignment','center','VerticalAlignment','top');        % labels (black)
end

%% ---------- Legend (only alpha curves) ----------
lgd = legend(ax,'show','Interpreter','tex');
lgd.Box = 'off'; lgd.FontSize = legend_font; lgd.FontName = 'Arial';
lgd.TextColor = 'k'; lgd.Color = 'w';
set(lgd,'Location', alpha_legend_location);
if ~isempty(alpha_legend_position)
    set(lgd, 'Units','normalized', 'Position', alpha_legend_position);
end

%% ---------- Save ----------
print(fig, out_file, '-dsvg');
fprintf('✅ Saved SVG to: %s\n', out_file);
