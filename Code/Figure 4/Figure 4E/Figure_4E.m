%% Step 1: USER SETTINGS
% Input and output files
input_file = '/Users/linda0122/Desktop/Materials/Tables/Table 1/OUTPUT6_10_asymmetry_cluster_weighted_summary_confirm_101425_combined_ranked.csv';
out_dir    = '/Users/linda0122/Desktop/Materials/Figures/Figure 4/Figure 4E';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% Figure layout configuration  
DOT_SIZE         = 60;                 
COLOR_BASE       = [0.45 0.45 0.45];               % Color for points that do NOT satisfy the condition (grey)
COLOR_SELECTED   = [0.90 0.20 0.60];               % Color for points that satisfy the condition (pink)
REF_LINE_COLOR   = [0.6 0.6 0.6];                  % Color for reference lines 
REF_LINE_WIDTH   = 1.0;
FIG_HEIGHT       = 2000;
FIG_WIDTH        = 1200;
FONT_SIZE        = 90;

% Set axis limits & ticks 
x_limit = [0.0, 0.30];
y_limit = [0.0, 2.0];



%% Step 2: Load CSV table and generate plots for each beta case
% Step 2.1: Read input table and define beta cases
T         = readtable(input_file);
beta_cols = {'betaL_ii','betaL_oo','betaL_io','betaL_oi'};
beta_list = [NaN, 0.03, 0.06, 0.09, 0.12, 0.15];   % NaN means "all betas = 0"

% Step 2.2: Loop over each β case
for idx = 1:numel(beta_list)

    beta_value = beta_list(idx);

    % Step 2.2.2: Case A - all betas = 0
    if isnan(beta_value)
        filter     = all(T{:, beta_cols} == 0, 2); % require all four beta columns be 0
        T_filtered = T(filter, :);
        base_title = '\beta_{o→o} = 0';
        filename   = 'Figure 4E_beta_all_0.svg';
    
    % Step 2.2.3: Case B - only betaL_oo = beta_value, betaL_ii, io, oi = 0
    else
        filter     = (round(T.betaL_oo, 4) == round(beta_value, 4)) ...   
                   & (T.betaL_ii == 0) ...                                
                   & (T.betaL_io == 0) ...
                   & (T.betaL_oi == 0);
        T_filtered = T(filter, :);
        base_title = sprintf('\\beta_{o→o} = %.2f', beta_value);   
        filename   = sprintf('Figure 4E_beta_oo_%.3f.svg', beta_value);
    end

    % Step 2.3: Plotting 
    % Step 2.3.1 : Create the figure and axes
    f = figure('Visible','off', ...
               'Color','w', ...
               'Position',[100 100 FIG_WIDTH FIG_HEIGHT]); 
    ax = axes('Parent', f, ...
              'Color','w', ...
              'Position', [0.15 0.15 0.7 0.7]); 
    hold(ax,'on'); 
    grid(ax,'off'); 
    box(ax,'on');                     
    ax.FontSize = FONT_SIZE;

    % Step 2.3.2: Configure axis limits and tick marks
    pbaspect(ax, [1 1 1]);                         % Enforce a square plotting region (equal data scaling on X and Y)
    % X-axis configuration
    xlim(ax, x_limit);                             % Set X-axis range
    xticks(ax, 0.0:0.1:0.3);                       % Set X ticks at 0.0,0.1,0.2,0.3
    ax.XTickLabel = compose('%.1f', 0.0:0.1:0.3);  % Display X tick labels as 0.0, 0.1, 0.2, 0.3
    ax.XColor = 'k';                               % Draw X-axis in black
    set(ax, 'XTickMode','manual', ...              % Prevent MATLAB from modifying ticks
            'XTickLabelMode','manual'); 
    ax.XAxis.TickLabelRotation = 0;                % Force horizontal X tick labels 
    % Y-axis configuration
    ylim(ax, y_limit);                             % Set Y-axis range
    yticks(ax, 0:1:2);                             % Set Y ticks at 0, 1, 2
    ax.YTickLabel = compose('%d', 0:1:2);          % Display Y tick labels as 0, 1, 2
    ax.YColor = 'k';                               % Draw Y-axis in black

    % Step 2.3.3: Plot data points split by the condition: asymmetry_avg > 1 and loss_avg <= 0.1
    % Compute percentage of points fall into asymmetry_avg > 1 and loss_avg <= 0.1
    [mask, pct] = compute_pct(T_filtered);
    % Base (non-selected) points - grey
    scatter(ax, T_filtered.loss_avg(~mask), T_filtered.asymmetry_avg(~mask), DOT_SIZE, ...
            'filled', 'MarkerFaceColor', COLOR_BASE) 
    % Highlighted (selected) points - pink
    scatter(ax, T_filtered.loss_avg(mask), T_filtered.asymmetry_avg(mask), DOT_SIZE, ...
            'filled', 'MarkerFaceColor', COLOR_SELECTED) 

    % Step 2.3.4: Draw reference lines
    xline(ax, 0.1,'-', 'Color', REF_LINE_COLOR, 'LineWidth', REF_LINE_WIDTH);  % Vertical line at loss_avg = 0.1
    yline(ax, 1,  '-', 'Color', REF_LINE_COLOR, 'LineWidth', REF_LINE_WIDTH);  % Horizontal line at asymmetry_avg = 1

    % Step 2.3.5: Axis labels 
    xlabel(ax, 'Cell Loss ({\itL})', ...
           'FontSize', FONT_SIZE, ...
           'Color','k');
    ylabel(ax, {'Morphological','Asymmetry ({\itA})'}, ...
           'FontSize', FONT_SIZE, ...
           'Color','k')

    % Step 2.3.6: Add two header annotations above the axes 
    % β title (black)
    annotation(f, 'textbox', ...
               'Position', [0 0.81 1 0.05], ...
               'String', base_title, ...
               'FontSize', FONT_SIZE, ...
               'Color','k', ...
               'HorizontalAlignment','center', ...
               'FitBoxToText','off', ...
               'EdgeColor','none');   

    % Percentage title (pink)
    pct_str = sprintf('%.0f%%', pct);
    annotation(f, 'textbox', ...
               'Position', [0 0.73 1 0.05], ...
               'String', pct_str, ...
               'FontSize', FONT_SIZE, ...
               'Color', COLOR_SELECTED, ...
               'HorizontalAlignment','center', ...
               'FitBoxToText','off', ...
               'EdgeColor','none');

    % Step 2.3.7: Set all the text within the figure be Arial
    fontname(f,"Arial");

    % Step 2.3.8: Save as SVG file
    save_svg(out_dir, filename, f);  
    num_selected = sum(mask);                      % Selected points
    num_total    = height(T_filtered);             % Total points
    fprintf('Pink points: %d / %d (%.1f%%)\n', ... % Print summary to console
            num_selected, num_total, pct); 
    close(f);
end



%% Helper Functions
function [mask, pct] = compute_pct(T)
% COMPUTE_PCT
% Compute percentage of rows satisify the condition where asymmetry_avg > 1 and loss_avg <= 0.1
% Input: T, a table with columns loss_avg, asymmetry_avg
% Output: 
%   mask, logical index vector marking rows that satisfy the condition
%   pct, percentage (0 to 100) of rows satisfying the condition
    n_rows   = height(T);
    mask     = (T.asymmetry_avg > 1) & (T.loss_avg <= 0.1); % Logical mask of rows satisfying the condition
    n_points = sum(mask);                                   % Count satisfying rows
    pct      = 100 * (n_points / n_rows);                   % Compute percentage 
end

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