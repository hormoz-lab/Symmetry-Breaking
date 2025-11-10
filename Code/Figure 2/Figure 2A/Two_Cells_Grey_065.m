%% Two Cells Squeezed Together (Y-view, Same Lighting as RedSphere)

% --- Parameters ---
r = 1;                   % Sphere radius
alpha = 0.65;
d = 2*r*alpha;             % Center distance = 1.2*r (squeezed)
%d = 2*r*0.8;
%d = 2*r*1;
c1 = [-d/2, 0, 0];       % Center 1
c2 = [ d/2, 0, 0];       % Center 2

% --- Output folder ---
output_path = '/Users/linda0122/Desktop/Model_Scanning_Project/Final_Material/Figures/Figure_2';
if ~exist(output_path, 'dir'); mkdir(output_path); end

% --- Smooth unit sphere mesh ---
[Xs, Ys, Zs] = sphere(200);
Xs = r*Xs; Ys = r*Ys; Zs = r*Zs;

% --- Figure / Axes (transparent) ---
f  = figure('Position',[50,50,1800,1800], 'Color','none', 'Renderer','opengl');
ax = axes('Parent',f); set(ax,'Color','none'); hold(ax,'on');

% --- Draw spheres (same material as your RedSphere script) ---
commonProps = { ...
    'FaceAlpha', 1, ...
    'EdgeColor', 'none', ...
    'FaceLighting', 'gouraud', ...
    'AmbientStrength', 0.3, ...
    'DiffuseStrength', 0.8, ...
    'SpecularStrength', 0.2, ...
    'SpecularExponent', 20};

surf(ax, Xs + c1(1), Ys + c1(2), Zs + c1(3), 'FaceColor',[0.6 0.6 0.6], commonProps{:}); % color in grey [0.6 0.6 0.6]
surf(ax, Xs + c2(1), Ys + c2(2), Zs + c2(3), 'FaceColor',[0.6 0.6 0.6], commonProps{:});

% --- View & lighting (match RedSphere) ---
axis(ax,'equal'); axis(ax,'off'); axis(ax,'vis3d');
% Look straight along +Y so squeeze along X is clear
view(ax, [0 1 0]);

% Same lighting call as your RedSphere script:
camlight(ax,'right');    % <— consistent with your single-sphere script

% (Optional) add a second light if you want a bit more depth:
% camlight(ax,'right');

% --- Export high-res transparent PNG ---
outfile = fullfile(output_path, 'TwoGreyCells_Squeezed_Yview_0.65.png');
exportgraphics(f, outfile, 'BackgroundColor','none', 'ContentType','image', 'Resolution', 600);

fprintf('✅ Saved: %s (r = %.3f, center distance = %.3f)\n', outfile, r, d);