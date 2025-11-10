%% Step 1: USER SETTINGS
% Input and output files
file_path     = '/n/data1/hms/sysbio/hormoz/users/suxuan/OUTPUT6_10_asymmetry_cluster_weighted_summary_confirm_101425_combined_ranked_D1_2_4.csv';
out_dir       = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Materials/Figures/Figure S15';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

TOP_PERCENT   = 100;                                                         % 100 → use top 100% highest-asymmetry entries
filename      = sprintf('Figure_4A_top_%dpercent', TOP_PERCENT);

% Figure layout configuration    
FIG_HEIGHT    = 2000;
FIG_WIDTH     = 2000;



%% Step 2: Load data and select top entries by asymmetry
alpha_cols    = {'alpha_ii','alpha_oo','alpha_io'};
beta_cols     = {'betaL_ii', 'betaL_oo', 'betaL_io', 'betaL_oi'};
asymmetry_avg = 'asymmetry_avg';
loss_avg      = 'loss_avg';

keep_cols     = [alpha_cols, beta_cols, asymmetry_avg, loss_avg];
n_alpha       = numel(alpha_cols);
n_beta        = numel(beta_cols);
n_columns     = numel(keep_cols);

T             = readtable(file_path, 'PreserveVariableNames', true);
n_rows        = height(T);
top_n         = max(1, floor(n_rows * TOP_PERCENT / 100));
T_top         = T(1:top_n, keep_cols);  
T_top_matrix  = T_top{:, :};                                                 % Convert the table having top rows to a numeric matrix

fprintf('Loaded %d rows × %d columns. Using top %d rows (%.2f%%).\n', n_rows, n_columns, top_n, TOP_PERCENT);



%% Step 3: RENDERING BLOCK
% Step 3.1: Initialize an image matrix (RGB mosaic: top_n × n_columns × 3) 
img = zeros(top_n, n_columns, 3, 'double');

% Step 3.2: Render alpha columns — black (α = 0.65) → green (α = 0.95)
% Each alpha value is linearly normalized from [0.65, 0.95] to [0, 1], and mapped to the green channel intensity.
iA          = 1:n_alpha;                                                     % alpha column indices
ALPHA_MIN   = 0.65;                                                          % alpha boundary
ALPHA_MAX   = 0.95;                                         
ALPHA_RANGE = ALPHA_MAX - ALPHA_MIN; 
for k = 1:n_alpha
    col_idx            = iA(k);                                              % alpha column index in T_top_matrix
    col_val            = T_top_matrix(:, col_idx);                           % alpha value
    normalized_val     = (col_val - ALPHA_MIN) / ALPHA_RANGE;                % alpha value normalized
    img(:, col_idx, 2) = normalized_val;                                     % GREEN channel: 0 → 1 as alpha 0.65 → 0.95
end

% Step 3.3: Render BETA columns — blue (β < 0) → black (β = 0) → red (β > 0)
% Each β value is symmetrically normalized around zero:
%   negative β values contribute to the BLUE channel,
%   positive β values contribute to the RED channel,
%   β = 0 appears BLACK.
iB          = n_alpha + (1:n_beta);                                          % beta column indices
BETA_MIN    = -0.15;                                                         % beta boundary
BETA_MAX    =  0.15;                         
BETA_CAP    = max(abs([BETA_MIN, BETA_MAX]));                                % symmetric cap for scaling
for k = 1:n_beta
    col_idx            = iB(k);                                              % beta column index in T_top_matrix
    col_val            = T_top_matrix(:, col_idx);                           % beta value 
    normalized_val     = abs(col_val) / BETA_CAP;                            % beta value normalized
    is_positive        = (col_val > 0);                                      % mask for beta > 0 → red
    is_negative        = (col_val < 0);                                      % mask for beta < 0 → blue
    img(:, col_idx, 1) = normalized_val .* is_positive;                      % RED   channel: 0 → 1 as beta 0 →  0.15
    img(:, col_idx, 2) = 0;                                                  % GREEN channel: unused
    img(:, col_idx, 3) = normalized_val .* is_negative;                      % BLUE  channel: 0 → 1 as beta 0 → -0.15
end

% Step 3.4: Render ASYMMETRY column — white (low) → orange (high)
% Each asymmetry value is normalized based on the FULL dataset (global min/max),
% then mapped to a white→orange gradient:
%   low asymmetry  → white  (1,1,1)
%   high asymmetry → orange (1,0.5,0)
jAsym            = n_alpha + n_beta + 1;                                     % asymmetry_avg column index
asym_all         = T{:, asymmetry_avg};                                      % asymmetry_avg bounds from the entire dataset
ASYM_MIN         = min(asym_all);
ASYM_MAX         = max(asym_all);
ASYM_RANGE       = ASYM_MAX - ASYM_MIN; 
col_val          = T_top_matrix(:, jAsym);                                   % asymmetry_avg value
normalized_val   = (col_val - ASYM_MIN) / ASYM_RANGE;                        % asymmetry_avg value normalized
img(:, jAsym, 1) = 1.0;                                                      % RED   channel: fixed at 1  
img(:, jAsym, 2) = 1 - 0.5 * normalized_val;                                 % GREEN channel: 1 → 0.5 as asymmetry_avg increases  
img(:, jAsym, 3) = 1 - normalized_val;                                       % BLUE  channel: 1 → 0   as asymmetry_avg increases

% Step 3.5: Render LOSS column — orange (low) → white (high)
% Values ≥ LOSS_MAX appear fully white.
jLs            = n_alpha + n_beta + 2;                                       % loss_avg column index
LOSS_MIN       = 0.0;                                                        % loss_avg boundary
LOSS_MAX       = 0.05;                                                       % values >= LOSS_MAX map to white
LOSS_RANGE     = LOSS_MAX - LOSS_MIN;
col_val        = T_top_matrix(:, jLs);                                       % loss_avg value
normalized_val = (col_val - LOSS_MIN) / LOSS_RANGE;                          % loss_avg value normalized
normalized_val = min(max(normalized_val, 0), 1); 
img(:, jLs, 1) = 1.0;                                                        % RED   channel: fixed at 1
img(:, jLs, 2) = 0.5 + 0.5 * normalized_val;                                 % GREEN channel: 0.5 → 1 as loss_avg increases
img(:, jLs, 3) = normalized_val;                                             % BLUE  channel: 0   → 1 as loss_avg increases



%% Step 4: Save as SVG file
% 4.1: Create figure 
fig = figure('Visible','off', 'Position',[0 0 FIG_WIDTH FIG_HEIGHT], 'Color','w');
ax  = axes('Parent',fig, 'Position',[0 0 1 1]);

% 4.2: Draw the mosaic (each image cell → one filled rectangle)
[nr, nc, ~] = size(img);                                                     % Image dimensions: rows × columns × RGB
for i = 1:nr
    for j = 1:nc
        rgb = squeeze(img(i,j,:))';                                          % Extract RGB triplet for cell [i,j]
        rectangle('Parent', ax, ...
                  'Position', [j-1, i-1, 1, 1], ...                          % Lower-left corner (j-1, i-1), unit width & height
                  'FaceColor', rgb, ...
                  'EdgeColor', 'none');                                      % Disable grid lines between cells
    end
end
axis(ax,'ij');                                                               % Flip Y-axis so row 1 is at the top
axis(ax,'off');

% 4.3: Export the SVG file
save_svg(out_dir, filename, fig); 
close(fig)



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