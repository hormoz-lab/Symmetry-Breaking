%% Step 1: USER SETTINGS
% Input and output files
input_file = '/Users/linda0122/Desktop/Materials/Figures/Figure 4/Figure 4F/Figure_4F.csv';
out_dir    = '/Users/linda0122/Desktop/Materials/Figures/Figure 4/Figure 4F';
filename   = 'Figure_4F';

% Figure layout configuration 
FIG_SIZE    = 2000;
FONT_SIZE   = 35;
AX_WIDTH    = 0.5; 
BAR_WIDTH   = 0.2;
BAR_COLOR   = 'k';
LINK_WIDTH  = 0.5; 
DOT_SIZE    = 6;     
DOT_COLOR   = [0.2 0.4 0.8];

% Set axis limits & ticks      
x_ticks     = 0:0.03:0.15;
y_ticks     = [0, 0.5, 1.0, 1.5, 2.0];

%% Step 2: Read table and compute max, min, mean of asymmetry_avg for each betaL_oo value
% Step 2.1: Read table and extract asymmetry_avg columns for each betaL_oo values 
T              = readtable(input_file);
col_names      = T.Properties.VariableNames;
filter         = startsWith(col_names, "asymmetry_avg_betaL_oo_"); 
col_beta       = col_names(filter);
beta_values    = nan(numel(col_beta), 1);

asymmetry_min  = nan(numel(col_beta), 1);
asymmetry_max  = nan(numel(col_beta), 1);
asymmetry_mean = nan(numel(col_beta), 1);

% Step 2.2: Loop through each asymmetry_avg columns 
for i = 1:numel(col_beta)

    % Step 2.2: Extract the numeric beta values from column names
    parts          = split(col_beta{i}, '_');           % Example column name: "asymmetry_avg_betaL_oo_0_045"
    beta_str       = parts{end-1} + "." + parts{end};   % "0" + "." + "045"
    beta_values(i) = str2double(beta_str);            

    % Step 2.3: Compute min, avg, max over all alpha combinations for each betaL_oo value
    col = T.(col_beta{i});
    asymmetry_min(i)  = min(col);
    asymmetry_max(i)  = max(col);
    asymmetry_mean(i) = mean(col);
end


%% Step 3: Plotting
% Step 3.1: Create the figure and axes
f = figure('Color','w', ...
           'Position',[100 100 FIG_SIZE FIG_SIZE]);
ax = axes('Parent', f); 
ax.Color     = 'w';
ax.TickDir   = 'out';
ax.FontSize  = FONT_SIZE;
ax.Position  = [0.18 0.18 0.74 0.74];
ax.LineWidth = AX_WIDTH;
grid(ax,'off');
hold(ax,'on');

% Step 3.2: Configure axis limits and tick marks
pbaspect(ax, [1 1 1]);                                     % Enforce a square plotting region (equal data scaling on X and Y)
% X-axis configuration
xlim(ax, [-0.005, 0.155]);                                 % Set X-axis range
xticks(ax, x_ticks);                                       % Set X ticks
ax.XTickLabel = compose('%.2f', x_ticks);              
ax.XColor     = 'k';                                       % Draw X-axis in black 
set(ax, 'XTickMode','manual', 'XTickLabelMode','manual');  % Prevent MATLAB from modifying ticks
ax.XAxis.TickLabelRotation = 0;                            % Force horizontal X tick labels 
% Y-axis configuration
ylim(ax, [0, max(asymmetry_max)]);                         % Set Y-axis range
yticks(ax, y_ticks);                                       % Set Y ticks
ax.YTickLabel = compose('%.1f', y_ticks);                
ax.YColor     = 'k';                                       % Draw Y-axis in black
set(ax, 'YTickMode','manual', 'YTickLabelMode','manual');  % Prevent MATLAB from modifying ticks
ax.YAxis.TickLabelRotation = 0;                            % Force horizontal Y tick labels 

% Step 3.3: Draw the vertical max–min range bars
for i = 1:numel(beta_values)
    line('Parent', ax, ...
         'XData', [beta_values(i) beta_values(i)], ...
         'YData', [asymmetry_min(i) asymmetry_max(i)], ...
         'LineWidth', BAR_WIDTH, ...
         'Color', BAR_COLOR);
end

% Step 3.4: Plot dots for min / mean / max asymmetry 
plot(ax, beta_values, asymmetry_max, 'o', 'MarkerSize', DOT_SIZE, ...
     'MarkerFaceColor', DOT_COLOR, 'MarkerEdgeColor', 'k');
plot(ax, beta_values, asymmetry_min, 'o', 'MarkerSize', DOT_SIZE, ...
     'MarkerFaceColor', DOT_COLOR, 'MarkerEdgeColor', 'k');
plot(ax, beta_values, asymmetry_mean, 'o', 'MarkerSize', DOT_SIZE, ...
     'MarkerFaceColor', DOT_COLOR, 'MarkerEdgeColor', 'k');

% Step 3.5: Link max / min / mean trajectories across β values
plot(ax, beta_values, asymmetry_max,  '-', 'Color', BAR_COLOR, 'LineWidth', LINK_WIDTH);
plot(ax, beta_values, asymmetry_min,  '-', 'Color', BAR_COLOR, 'LineWidth', LINK_WIDTH);
plot(ax, beta_values, asymmetry_mean, '-', 'Color', BAR_COLOR, 'LineWidth', LINK_WIDTH);

% Step 3.6: Axis labels 
xlabel(ax, '\beta_{o→o}', ...
           'FontSize', FONT_SIZE, ...
           'Color','k');
ylabel(ax, {'Morphological', 'Asymmetry ({\itA})'}, ...
           'FontSize', FONT_SIZE, ...
           'Color','k');

% Step 3.7: Set all the text within the figure be Arial
fontname(f,"Arial");

% Step 3.8: Save as SVG file
save_svg(out_dir, filename, f);  



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