%% Step 1: USER SETTINGS
% Input and output files
file_path   = '/Users/linda0122/Desktop/Materials/Tables/OUTPUT6_10_asymmetry_cluster_weighted_summary_confirm_101425_combined_ranked.csv';
out_dir     = '/Users/linda0122/Desktop/Materials/Figures/Figure 3/Figure 3B';
filename    = 'Figure_3B';
TOP_PERCENT = 1; 

% Figure layout configuration 
FIG_SIZE    = 900;   
FONT_SIZE   = 40;
BOX_WIDTH   = 0.60;
LINE_WIDTH  = 1.5;   

% Set axis limits & ticks 
x_limit = [0.25, 3.75];
x_ticks = 1:3;
y_limit = [0.60 0.85];
y_ticks = [0.65 0.75 0.85 0.95];



%% Step 2: Load table, select top percentage rows, and generate the figure
% Read table and select the top percentage rows
T     = readtable(file_path);
selected_rows = (T.betaL_ii == 0) & ...
                (T.betaL_oo == 0) & ...
                (T.betaL_io == 0) & ...
                (T.betaL_oi == 0);
T_subset = T(selected_rows, :);   % subset table
T_top = get_top_table(T_subset, 'asymmetry_avg', TOP_PERCENT);

% Extract alpha values for plotting
Aii   = T_top.alpha_ii;
Aoo   = T_top.alpha_oo;
Aio   = T_top.alpha_io;

% Generate and save the boxplot figure as svg file
f = draw_alpha_boxplot(Aii, Aoo, Aio, ...
                       FIG_SIZE, FONT_SIZE, BOX_WIDTH, LINE_WIDTH, ...
                       x_limit, x_ticks, y_limit, y_ticks);
save_svg(out_dir, filename, f);
close(f);



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


function T_top = get_top_table(T, col_name, percentage)
% GET_TOP_TABLE  Return the top percentage of rows sorted by a column.
% Inputs
%   T          : input table
%   col_name   : column name to sort by (string or char)
%   percentage : real percentage (e.g., 1 means top 1%)
% Output
%   T_top      : table containing the top percentage of rows
    n_rows   = height(T);
    idx_max  = max(1, floor(n_rows * percentage / 100));
    T_sorted = sortrows(T, col_name, 'descend');
    T_top    = T_sorted(1:idx_max, :);
end


function f = draw_alpha_boxplot(Aii, Aoo, Aio, FIG_SIZE, FONT_SIZE, BOX_WIDTH, LINE_WIDTH, x_limit, x_ticks, y_limit, y_ticks)
% DRAW_ALPHA_BOXPLOT  Draw a 3-group alpha boxplot.
% Inputs
%   Aii        : vector of α_{i-i} values
%   Aoo        : vector of α_{o-o} values
%   Aio        : vector of α_{i-o} values
%   FIG_SIZE   : figure width/height in pixels (square figure)
%   FONT_SIZE  : font size for tick labels and axis labels
%   BOX_WIDTH  : relative width of boxplots (0–1)
%   LINE_WIDTH : line width for boxes, medians, and whiskers
%   x_limit    : [xmin xmax] for x-axis
%   x_ticks    : vector of x tick locations (1, 2, 3 recommended)
%   y_limit    : [ymin ymax] for y-axis
%   y_ticks    : vector of y tick locations
% 
% Output
%   f          : handle to the figure created

    % Step 1: Create the figure and axes
    f  = figure('Color','w', ...
               'Position', [100 100 FIG_SIZE FIG_SIZE]);
    ax = axes(f, 'Color','w'); 
    ax.TickDir    = 'out';
    ax.FontSize   = FONT_SIZE;
    ax.LineWidth  = LINE_WIDTH;
    ax.Position   = [0.24 0.22 0.70 0.70];
    hold(ax,'on');

    % Step 2: Draw boxplot
    data  = [Aii; Aoo; Aio];
    group = [ones(numel(Aii),1); 2 * ones(numel(Aoo),1); 3 * ones(numel(Aio),1)];
    boxplot(ax, data, group, ...
               'Colors', 'k', ...
               'Symbol', 'k.', ...
               'Widths', BOX_WIDTH); 
    set(findobj(ax,'Tag','Box'),                 'LineWidth', LINE_WIDTH, 'LineStyle','-');
    set(findobj(ax,'Tag','Median'),              'LineWidth', LINE_WIDTH, 'LineStyle','-');
    set(findobj(ax,'Tag','Upper Whisker'),       'LineWidth', LINE_WIDTH, 'LineStyle','-');
    set(findobj(ax,'Tag','Lower Whisker'),       'LineWidth', LINE_WIDTH, 'LineStyle','-');
    set(findobj(ax,'Tag','Upper Adjacent Value'),'LineWidth', LINE_WIDTH, 'LineStyle','-');
    set(findobj(ax,'Tag','Lower Adjacent Value'),'LineWidth', LINE_WIDTH, 'LineStyle','-');

    % Step 3: Configure axis limits and tick marks
    pbaspect(ax, [1 1 1]);                         % Enforce a square plotting region (equal data scaling on X and Y)
    % X-axis configuration
    ax.XLim       = x_limit;                       % Set X-axis range
    ax.XTick      = x_ticks;                       % Set X ticks
    ax.XColor     = 'k';                           % Draw X-axis in black
    ax.TickLabelInterpreter = 'tex';
    ax.XTickLabel = {'\alpha_{i-i}','\alpha_{o-o}','\alpha_{i-o}'};
    % Y-axis configuration
    ax.YLim       = y_limit;                       % Set Y-axis range
    ax.YTick      = y_ticks;                       % Set Y ticks
    ax.YColor     = 'k';                           % Draw Y-axis in black 
    ylabel(ax, '\alpha values with top 1% {\itA}', 'FontSize', FONT_SIZE);
    
    % Step 4: Polish the plot
    fontname(f,"Arial"); % Set all the text within the figure be Arial
    box(ax, 'off');
    grid(ax,'off');
end
