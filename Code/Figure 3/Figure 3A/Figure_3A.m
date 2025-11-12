%% Step 1: USER SETTINGS
% Input and output files
current_script_path = fileparts(mfilename('fullpath'));   
parent_dir  = fileparts(fileparts(fileparts(current_script_path)));  % Get parent folder (three levels above this script)
file_path   = fullfile(parent_dir, 'Tables/Table_1.csv');
out_dir     = fullfile(parent_dir, 'Figures/Figure 3/Figure 3A');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
filename    = 'Figure_3A';

% Figure layout configuration
% Overall figure
FIG_WIDTH            = 900;  
FIG_HEIGHT           = 600;
FONT_SIZE            = 20;
AX_WIDTH             = 1.0;
% Scatter plot
GRID_COLOR           = [0.85 0.85 0.85];
GRID_TRANSPARENCY    = 1.0;
COLORMAP             = parula(256);
DOT_SIZE             = 45;
AXES_LIMITS          = [0.6 1];  
AXES_TICKS           = [0.65 0.75 0.85 0.95];
SCATTER_Y_UP         = 0.14;
SCATTER_WIDTH_SCALE  = 0.50;
SCATTER_HEIGHT_SCALE = 0.68;
% Colorbar
COLORBAR_TICKS       = [0 1 2];
COLORBAR_HEIGHT      = 0.05;  
COLORBAR_POSITION_Y  = 0.09;   



%% Step 2: Load table and extract specific rows 
% Read table and select the top percentage rows
T        = readtable(file_path);
selected_rows = (T.betaL_ii == 0) & ...
                (T.betaL_oo == 0) & ...
                (T.betaL_io == 0) & ...
                (T.betaL_oi == 0);
T_subset = T(selected_rows, :);   % subset table

% asymmetry range 
asymmetry_avg_min   = min(T.asymmetry_avg);
asymmetry_avg_max   = max(T.asymmetry_avg);
asymmetry_avg_range = [asymmetry_avg_min asymmetry_avg_max];



%% Step 3: Plotting
% Step 3.1: Create the overall figure
f  = figure('Visible','off', ...
            'Color','w', ...
            'Position', [0 0 FIG_WIDTH FIG_HEIGHT]);

% Step 3.2: Draw the scatter plot
% Step 3.2.1: Create the axe for the scatter plot
scatter_ax = axes('Parent', f, 'Color','w'); 
scatter_ax.TickDir   = 'out'; 
scatter_ax.FontSize  = FONT_SIZE;
scatter_ax.LineWidth = AX_WIDTH; 
scatter_ax.GridColor = GRID_COLOR;
scatter_ax.GridAlpha = GRID_TRANSPARENCY;
hold(scatter_ax,'on'); 
grid(scatter_ax,'on');
box(scatter_ax,'off');
scatter_ax.PositionConstraint = 'innerposition';  % <- fixes axis squeeze

% Step 3.2.2: Plot the scatter plot
x     = T_subset.alpha_ii;
y     = T_subset.alpha_oo;
z     = T_subset.alpha_io;
color = T_subset.asymmetry_avg;
scatter3(scatter_ax, x, y, z, DOT_SIZE, color, 'filled');
colormap(scatter_ax, COLORMAP);
clim(scatter_ax, asymmetry_avg_range);
view(scatter_ax, 3);
% [caz,cel] = view(scatter_ax, 3);
% caz;
% cel;

% Step 3.2.3: Configure x, y, z axis limits, tick marks, and labels
% X-axis configuration
xlim(scatter_ax, AXES_LIMITS);                                       % Set X limits  
xticks(scatter_ax, AXES_TICKS);                                      % Set X ticks
scatter_ax.XTickLabel = compose('%.2f', AXES_TICKS);              
scatter_ax.XColor     = 'k';                                         % Draw X-axis in black 
set(scatter_ax, 'XTickMode','manual', 'XTickLabelMode','manual');    % Prevent MATLAB from modifying ticks
scatter_ax.XAxis.TickLabelRotation = 0;                              % Force horizontal X tick labels 
xl = xlabel(scatter_ax, '\alpha_{i-i}', 'FontSize', FONT_SIZE, 'Color', 'k');
% Y-axis configuration
ylim(scatter_ax, AXES_LIMITS);                                       % Set Y limits  
yticks(scatter_ax, AXES_TICKS);                                      % Set Y ticks
scatter_ax.YTickLabel = compose('%.2f', AXES_TICKS);              
scatter_ax.YColor     = 'k';                                         % Draw Y-axis in black 
set(scatter_ax, 'YTickMode','manual', 'YTickLabelMode','manual');    % Prevent MATLAB from modifying ticks
scatter_ax.YAxis.TickLabelRotation = 0;                              % Force horizontal Y tick labels 
yl = ylabel(scatter_ax, '\alpha_{o-o}', 'FontSize', FONT_SIZE, 'Color', 'k');
% Z-axis configuration
zlim(scatter_ax, AXES_LIMITS);                                       % Set Z limits  
zticks(scatter_ax, AXES_TICKS);                                      % Set Z ticks
scatter_ax.ZTickLabel = compose('%.2f', AXES_TICKS);              
scatter_ax.ZColor     = 'k';                                         % Draw Z-axis in black 
set(scatter_ax, 'ZTickMode','manual', 'ZTickLabelMode','manual');    % Prevent MATLAB from modifying ticks
scatter_ax.ZAxis.TickLabelRotation = 0;                              % Force horizontal Z tick labels 
zl = zlabel(scatter_ax, '\alpha_{i-o}', 'FontSize', FONT_SIZE, 'Color', 'k');

% Step 3.2.4: Adjust the scatter plot layout
drawnow;
scatter_position = scatter_ax.Position;
scatter_position(2) = scatter_position(2) + SCATTER_Y_UP;
scatter_position(3) = scatter_position(3) * SCATTER_WIDTH_SCALE;
scatter_position(4) = scatter_position(4) * SCATTER_HEIGHT_SCALE;
scatter_ax.Position = scatter_position;

% Step 3.3: Draw the colorbar
% Step 3.3.1: Create the axe for the colorbar
color_ax = axes('Parent', f, ...
                'Color','w', ...
                'Box','on', ...
                'XColor','k', ...
                'YColor','k', ...
                'LineWidth', AX_WIDTH);
color_ax.Position = [scatter_position(1), COLORBAR_POSITION_Y, ...
                     scatter_position(3), COLORBAR_HEIGHT];
color_ax.FontSize = FONT_SIZE;
color_ax.TickDir  = 'out';
hold(color_ax,'on');

% Step 3.3.2: Plot the colorbar 
num_color = size(COLORMAP, 1);
for i = 1:num_color
    % Fractional position across the color range
    t0 = (i - 1) / num_color; 
    t1 = i / num_color;
    % Convert to actual x coordinates
    x0 = asymmetry_avg_min + t0 * (asymmetry_avg_max - asymmetry_avg_min);
    x1 = asymmetry_avg_min + t1 * (asymmetry_avg_max - asymmetry_avg_min);
    % Draw the rectangle with the i-th colormap color
    patch(color_ax, [x0 x1 x1 x0], ...    % x coordinate of the colored rectangle
                    [0  0  1  1 ], ...    % y coordinate of the colored rectangle, height = 1
                    COLORMAP(i, :), ...   % one color from the colormap
                    'EdgeColor','none');  % no borders (clean gradient)
end

% Step 3.2.3: Configure x, y axis limits, tick marks, and labels
% X-axis configuration
xlim(color_ax, asymmetry_avg_range); 
color_ax.XTick = COLORBAR_TICKS;
color_ax.XTickLabel = compose('%d', COLORBAR_TICKS);
xlabel(color_ax, 'Morphological Asymmetry ({\itA})', ...
       'Color','k', ...
       'FontSize', FONT_SIZE, ...
       'VerticalAlignment','top', ...
       'HorizontalAlignment','center');
% Y-axis configuration
ylim(color_ax, [0 1]);
color_ax.YTick = [];

% Step 3.4: Set all figure text to Arial and preserve TeX formatting
set(findall(f,'Type','text'), 'FontName','Arial', 'Interpreter','tex');

% Step 3.5: Save as SVG file
save_svg(out_dir, filename, f)



%% Helper Functions
function save_svg(out_dir, filename, fig)
% SAVE_SVG  Save a figure as an SVG (vector) file.
% Inputs
%   out_dir   : folder to save the .svg file into
%   filename  : base name WITHOUT extension
%   fig       : figure handle

    out_svg = fullfile(out_dir, filename);                         
    try
        print(fig, out_svg, '-dsvg', '-vector');  
        fprintf('Saved SVG: %s\n', out_svg);
    catch ME
        warning('Failed to save SVG: %s\n%s', out_svg, ME.message);
    end
end
