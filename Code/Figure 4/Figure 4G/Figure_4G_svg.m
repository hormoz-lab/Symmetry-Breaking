%% Step 1: USER SETTINGS
% Input and output files
input_file     = '/Users/linda0122/Desktop/Materials/Figures/Figure 4/Figure 4G/Figure_4G.csv';
out_dir        = '/Users/linda0122/Desktop/Materials/Figures/Figure 4/Figure 4G';
filename       = 'Figure_4G';
n_pink_lines   = 0;                                        % Initialize pink lines counter

% Figure layout configuration 
FIG_SIZE       = 2000;
FONT_SIZE      = 35;
AX_WIDTH       = 0.5;
DOT_SIZE       = 6;
DOT_COLOR      = 'k';       
LINK_WIDTH     = 0.1;
COLOR_BASE     = [0.45 0.45 0.45];                         % Color for lines that do NOT satisfy the condition (grey)
COLOR_SELECTED = [0.90 0.20 0.60];                         % Color for lines that satisfy the condition (pink)

% Set axis limits & ticks 
x_ticks = 0:0.03:0.15;
y_ticks = [-0.5, 0, 0.5, 1.0, 1.5, 2.0];

%% Step 2: Read table and compute max, min, mean of asymmetry_avg for each betaL_oo value
% Step 2.1: Read table and extract asymmetry_diff columns for each betaL_oo values 
T              = readtable(input_file);
col_names      = T.Properties.VariableNames;
filter         = startsWith(col_names, "asymmetry_diff_betaL_oo_"); 
col_beta       = col_names(filter);
beta_values    = nan(numel(col_beta), 1);

% Step 2.2: Loop through each asymmetry_diff columns and extract the numeric beta values from column names
for i = 1:numel(col_beta)
    parts          = split(col_beta{i}, '_');              % Example column name: "asymmetry_avg_betaL_oo_0_045"
    beta_str       = parts{end-1} + "." + parts{end};      % "0" + "." + "045"
    beta_values(i) = str2double(beta_str);            
end

% Step 2.3: Organize the beta values and asymmetry_diff columns 
[beta_sorted, ord] = sort(beta_values);                    % Sort by beta value so plotting is left→right
col_beta           = col_beta(ord);



%% Step 3: Plotting
% Step 3.1: Create the figure and axes
f = figure('Color','w', ...
           'Position', [100 100 FIG_SIZE FIG_SIZE]);
ax = axes('Parent', f); 
ax.Color     = 'w';
ax.TickDir   = 'out';
ax.FontSize  = FONT_SIZE;
ax.Position  = [0.21 0.21 0.74 0.74];
ax.LineWidth = AX_WIDTH;
grid(ax,'off');
hold(ax,'on');

% Step 3.2: Configure axis limits and tick marks
pbaspect(ax, [1 1 1]);                                     % Enforce a square plotting region (equal data scaling on X and Y)
% X-axis configuration
xticks(ax, x_ticks);                                       % Set X ticks
ax.XTickLabel = compose('%.2f', x_ticks);              
ax.XColor     = 'k';                                       % Draw X-axis in black 
set(ax, 'XTickMode','manual', 'XTickLabelMode','manual');  % Prevent MATLAB from modifying ticks
ax.XAxis.TickLabelRotation = 0;                            % Force horizontal X tick labels 
% Y-axis configuration
yticks(ax, y_ticks);                                       % Set Y ticks
ax.YTickLabel = compose('%.1f', y_ticks);                
ax.YColor     = 'k';                                       % Draw Y-axis in black
set(ax, 'YTickMode','manual', 'YTickLabelMode','manual');  % Prevent MATLAB from modifying ticks
ax.YAxis.TickLabelRotation = 0;                            % Force horizontal Y tick labels 

% Step 3.3: Loop through each row of the table to draw the lines
for r = 1:height(T)

    % Step 3.3.1: Extract all the asymmetry_diff columns for this row 
    asymmetry_diffs = nan(size(beta_sorted));
    for k = 1:numel(col_beta)
        asymmetry_diffs(k) = T.(col_beta{k})(r);
    end

    % Step 3.3.2: Link the dots (drawn later) within same alpha combination across β values 
    % Rule: if ALL asymmetry_diff values at β > 0 are > 0 → highlight the lines with pink
    mask                   = (beta_sorted ~= 0);   
    asymmetry_diffs_masked = asymmetry_diffs(mask);        % asymmetry_diffs for non-zero β values
    if all(asymmetry_diffs_masked > 0)
        line_color = COLOR_SELECTED;                       % pink: all non-zero-β diffs are positive
        n_pink_lines = n_pink_lines + 1;                   % Update number of pink lines
    else
        line_color = COLOR_BASE;                           % grey: at least one non-zero-β diff ≤ 0
    end

    % Draw line segments between adjacent β values 
    for c = 1:(numel(beta_sorted)-1)
        plot(ax, beta_sorted(c:c+1), ...
                 asymmetry_diffs(c:c+1), ...
                 '-', 'Color', line_color, ...
                 'LineWidth', LINK_WIDTH);
    end
end

% Step 3.4: Loop through each row of the table to draw the dots
for r = 1:height(T)
    % Step 3.4.1: Extract all the asymmetry_diff columns for this row 
    asymmetry_diffs = nan(size(beta_sorted));
    for k = 1:numel(col_beta)
        asymmetry_diffs(k) = T.(col_beta{k})(r);
    end

    % Step 3.4.2: Draw the dots 
    scatter(ax, beta_sorted, asymmetry_diffs, ...
            DOT_SIZE, 'filled', ...
            'MarkerFaceColor', DOT_COLOR);
end

% Step 3.5: Axis labels 
xlabel(ax, '\beta_{o→o}', ...
           'FontSize', FONT_SIZE, ...
           'Color','k');
ylabel(ax, {'Morphological'...
            'Asymmetry Change', ...
            '({\itA}_{\beta_{o→o}} - {\itA}_{\beta_{o→o}=0})'}, ...
            'FontSize',FONT_SIZE, ...
            'Color','k');

% Step 3.6: Set all the text within the figure be Arial
fontname(f,"Arial");

% Step 3.7: Save as SVG file
save_svg(out_dir, filename, f); 
pct = 100 * n_pink_lines / height(T);
fprintf('Alpha-groups with positive asymmetry change at all β_{oo} > 0: %d / %d (%.1f%%)\n', ...
    n_pink_lines, height(T), pct);



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

