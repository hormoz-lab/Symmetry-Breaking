%% =================== Force vs Distance (Main Script) ===================
close all;

%% ---------- User Parameters ----------
D1             = 2;                % Decay exponent
betaL_values   = [0.15 0.075 -0.075 -0.15];
d_min          = 0.1;              % avoid division by zero
d_max          = 10;
num_points     = 400;

% Axes control
x_lim          = [0 2];
y_lim          = [-2 2];
x_ticks        = 0.5:0.5:2;
y_ticks        = -2:0.5:2;

% Aesthetics
font_size      = 25;
legend_font    = 25;
line_width     = 2.5;
axis_lw        = 1.5;

% Legend placement
betaL_legend_location = 'northeast';
betaL_legend_position = [];

% Axis label positions
xlabel_pos = [0.96 -0.07 0];
ylabel_pos = [-0.10 0.96 0];

% Output
out_dir  = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Supplementary_Figures/Supplement_Process';
out_name = 'Figure_SB.svg';

%% ---------- Derived ----------
d  = linspace(d_min, d_max, num_points);
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
out_file = fullfile(out_dir, out_name);

%% ---------- Figure & Axes ----------
fig = figure('Color','w','Position',[210 210 900 650], ...
             'MenuBar','none','ToolBar','none','DockControls','off', ...
             'InvertHardcopy','off','Renderer','painters');
ax = axes('Parent', fig); hold(ax, 'on'); box(ax, 'off');
set(ax,'FontName','Arial','FontSize',font_size, ...
       'XColor','none','YColor','k','LineWidth',axis_lw, ... % hide default x-axis
       'XGrid','off','YGrid','off','Color','w','Layer','top');

%% ---------- Curves ----------
C = lines(numel(betaL_values));
for i = 1:numel(betaL_values)
    betaL = betaL_values(i);
    F = betaL ./ (d.^D1);   % simplified equation
    plot(ax, d, F, 'LineWidth', line_width, 'Color', C(i,:), ...
        'DisplayName', sprintf('\\beta = %.3f', betaL));
end

%% ---------- Limits, ticks, labels ----------
xlim(ax, x_lim); ylim(ax, y_lim);
yticks(ax, y_ticks); % keep only y-ticks

xlabel(ax, '|{\bf\itd}_{\itn,m}|', 'Interpreter','tex', ...
       'FontSize', font_size, 'FontName','Arial', 'Color','k');
ylabel(ax, '{\itF}_{\itn,m}^{long}', 'Interpreter','tex', ...
       'FontSize', font_size, 'FontName','Arial', 'Color','k', ...
       'Rotation', 0);

% --- Custom x-axis at y=0 with black ticks & labels ---
plot(ax, x_lim, [0 0], 'k-', 'LineWidth', axis_lw, 'HandleVisibility','off');
tick_len = 0.04;  % vertical length of tick marks (data units)
for xt = x_ticks
    % tick mark
    plot([xt xt], [0 -tick_len], 'k', 'LineWidth', axis_lw, 'HandleVisibility','off'); 
    % tick label
    text(xt, -0.1, num2str(xt), ...
        'FontSize', font_size, 'FontName','Arial', 'Color','k', ...
        'HorizontalAlignment','center','VerticalAlignment','top', ...
        'Clipping','on');
end

% Apply label positions
ax.XLabel.Units = 'normalized'; ax.XLabel.Position = xlabel_pos;
ax.YLabel.Units = 'normalized'; ax.YLabel.Position = ylabel_pos;

%% ---------- Legend ----------
lgd = legend(ax,'show','Interpreter','tex');
lgd.Box = 'off'; lgd.FontSize = legend_font; lgd.FontName = 'Arial';
lgd.TextColor = 'k'; lgd.Color = 'w';
set(lgd,'Location', betaL_legend_location);
if ~isempty(betaL_legend_position)
    set(lgd, 'Units','normalized', 'Position', betaL_legend_position);
end

%% ---------- Save ----------
print(fig, out_file, '-dsvg');
fprintf('✅ Saved SVG to: %s\n', out_file);

