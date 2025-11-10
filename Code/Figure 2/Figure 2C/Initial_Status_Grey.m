%% Visualization: Initial Cell State in 3D plot with Transparent Background (fixed ranges & square PNG)

Sample = 6;                     % Index of simulation replicate
r = 1;                          % Cell radius

% -------- Output image size controls (exact pixel size) --------
out_px   = 1200;    % final PNG: out_px x out_px
out_dpi  = 300;     % export resolution (dpi)
out_in   = out_px / out_dpi;  % figure size in inches to get exact pixels

% -------- Fixed axis ranges (edit as needed) --------
x_lim = [-12, 12];
y_lim = [-12, 12];
z_lim = [-12, 12];

% -------- Load data --------
parent_path = '/Users/linda0122/Desktop/Model_Scanning_Project/gastruloids_1500_25%_check';
file_path_P = fullfile(parent_path, ['OUTPUT', num2str(Sample)], 'WorkSpace_MatrixP_Initial.csv');
MatrixP = cell2mat(table2cell(readtable(file_path_P)));

file_path_G = fullfile(parent_path, ['OUTPUT', num2str(Sample)], 'WorkSpace_MatrixG_Initial.csv');
MatrixG = cell2mat(table2cell(readtable(file_path_G)));

% -------- Figure (transparent, square, no margins) --------
figure('Color','none','Units','inches','Position',[0.5 0.5 out_in out_in]);  % exact square size
ax = axes('Parent', gcf);
set(ax, 'Color','none', 'Units','normalized', 'Position',[0 0 1 1]);        % fill canvas
set(ax, 'LooseInset', [0 0 0 0]);  % remove extra padding

hold(ax, 'on');

% -------- Plot cells as grey spheres --------
nCells = size(MatrixP,1);
for N = 1:nCells
    [rx, ry, rz] = ellipsoid(MatrixP(N,1), MatrixP(N,2), MatrixP(N,3), r, r, r, 50);
    surf(ax, rx, ry, rz, ...
        'FaceColor', [0.6 0.6 0.6], ...
        'FaceAlpha', 1, ...
        'EdgeColor', 'none', ...
        'FaceLighting','gouraud');
end

% -------- Camera, lighting, and axes formatting --------
xlim(ax, x_lim); ylim(ax, y_lim); zlim(ax, z_lim);
axis(ax, 'equal');           
pbaspect(ax, [1 1 1]);       % keep cube aspect
axis(ax, 'off');
axis(ax, 'vis3d');           % lock aspect ratio

view(ax, [-165, -70]);
camlight(ax, 'left');
material(ax, 'dull');

% -------- Export (transparent background, exact square pixels) --------
output_path = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Figure_2';
if ~exist(output_path, 'dir'); mkdir(output_path); end

output_file = fullfile(output_path, sprintf('Initial_Cell_Status_Grey_Sample%d.png', Sample));
exportgraphics(gcf, output_file, ...
    'BackgroundColor','none', ...
    'ContentType','image', ...
    'Resolution', out_dpi);

fprintf('✅ Saved %s (%dx%d px)\n', output_file, out_px, out_px);
