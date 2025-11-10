%% Visualization: Final Cell State (Full Spheres) with Cross-Section Exclusion (fixed ranges & square PNG)

Sample = 6;                     % Index of simulation replicate
r = 1;                          % Cell radius
threshold_G2 = 0.95;            % Threshold for Gene 2 activity (coloring)

% --- Cross-section control ---
z_plane   = 0;                  % Cross-section plane: z = z_plane
draw_side = 'above';            % 'above' | 'below' | 'both_outside'

% -------- Output image size controls --------
out_px   = 1200;    % final PNG: out_px x out_px
out_dpi  = 300;     % export resolution (dpi)
out_in   = out_px / out_dpi;    % figure size in inches for exact pixels

% -------- Fixed axis ranges --------
x_lim = [-12, 12];
y_lim = [-12, 12];
z_lim = [-12, 12];

% -------- Load data --------
parent_path = '/Users/linda0122/Desktop/gastruloids_1500_25%_check';
file_path_P = fullfile(parent_path, ['OUTPUT', num2str(Sample)], 'WorkSpace_MatrixP_Initial.csv');
MatrixP = cell2mat(table2cell(readtable(file_path_P)));

file_path_G = fullfile(parent_path, ['OUTPUT', num2str(Sample)], 'WorkSpace_MatrixG_Initial.csv');
MatrixG = cell2mat(table2cell(readtable(file_path_G)));

% -------- Figure (transparent, square, no margins) --------
figure('Color','none','Units','inches','Position',[0.5 0.5 out_in out_in]);
ax = axes('Parent', gcf);
set(ax, 'Color','none', 'Units','normalized', 'Position',[0 0 1 1]);
set(ax, 'LooseInset', [0 0 0 0]);  % remove outer padding
hold(ax, 'on');

% -------- Loop through cells and draw only if outside cross-section --------
nCells = size(MatrixP, 1);
for N = 1:nCells
    x = MatrixP(N,1); y = MatrixP(N,2); zc = MatrixP(N,3);
    dz = zc - z_plane;

    switch lower(draw_side)
        case 'above'
            should_draw = (dz > r);      % sphere fully above plane
        case 'below'
            should_draw = (-dz > r);     % sphere fully below plane
        case 'both_outside'
            should_draw = (abs(dz) > r); % sphere does not intersect plane
        otherwise
            error('draw_side must be ''above'', ''below'', or ''both_outside''.');
    end

    if ~should_draw
        continue;
    end

    [rx, ry, rz] = ellipsoid(x, y, zc, r, r, r, 50);

    if MatrixG(N, 2) > threshold_G2
        color = 'r';
    else
        color = 'b';
    end

    surf(ax, rx, ry, rz, ...
         'FaceColor', color, ...
         'FaceAlpha', 1, ...
         'EdgeColor', 'none', ...
         'FaceLighting', 'gouraud');
end

% -------- Camera & axes --------
xlim(ax, x_lim); ylim(ax, y_lim); zlim(ax, z_lim);
axis(ax, 'equal');
pbaspect(ax, [1 1 1]);    % keep cubic aspect ratio
axis(ax, 'off');
axis(ax, 'vis3d');

view(ax, [-165, -70]);
camlight(ax, 'left');
material(ax, 'dull');

% -------- Export --------
output_path = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Figure_2';
if ~exist(output_path, 'dir'); mkdir(output_path); end

output_file = fullfile(output_path, ...
    sprintf('Initial_Cell_State_RedBlue_Sample%d_crossSectionFiltered_%s.png', Sample, draw_side));

exportgraphics(gcf, output_file, ...
    'BackgroundColor','none', ...
    'ContentType','image', ...
    'Resolution', out_dpi);

fprintf('✅ Saved %s (%dx%d px)\n', output_file, out_px, out_px);


