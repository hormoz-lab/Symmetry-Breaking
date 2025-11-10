%% Blue Sphere (High-Res, Transparent Background, Minimal & Robust)

r = 1;                           % Sphere radius
[X, Y, Z] = sphere(200);         % Dense mesh for smoothness
X = r*X; Y = r*Y; Z = r*Z;

output_path = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Figure_2';
if ~exist(output_path, 'dir'); mkdir(output_path); end

f = figure('Position', [50, 50, 1600, 1600], 'Color', 'none', 'Renderer', 'opengl');
ax = axes('Parent', f); set(ax, 'Color', 'none'); hold(ax, 'on');

h = surf(ax, X, Y, Z, ...
    'FaceColor', [0 0 1], ...   % BLUE (RGB)
    'FaceAlpha', 1, ...
    'EdgeColor', 'none', ...
    'FaceLighting', 'gouraud', ...     % Smooth lighting on the surface
    'AmbientStrength', 0.3, ...
    'DiffuseStrength', 0.8, ...
    'SpecularStrength', 0.2, ...
    'SpecularExponent', 20);

axis(ax, 'equal'); axis(ax, 'off'); axis(ax, 'vis3d');
view(ax, 3);
camlight(ax, 'left');            % Add a light source

exportgraphics(f, fullfile(output_path, 'BlueSphere.png'), ...
    'BackgroundColor','none', 'ContentType','image', 'Resolution', 600);

fprintf('✅ Red sphere saved to %s\n', fullfile(output_path, 'BlueSphere.png'));