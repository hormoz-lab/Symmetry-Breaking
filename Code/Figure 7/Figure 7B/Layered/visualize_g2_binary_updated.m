% File: visualize_g2_binary.m

%User settings
sampleIdx = 1;          % which OUTPUT folder
r         = 1;          % cell radius used in your sims
thr       = 0.99;       % "fully expressing" threshold for G2

azDeg     = -165;       % default azimuth
elDeg     = 1.5;         % default elevation

%Export settings
dpi              = 1200;        % very high resolution for print
figWidthInches   = 6.0;         % width 
figHeightInches  = 6.0;         % height
bgColor          = 'white';     % figure background
rasterFormat     = 'png';       % 'png' 
vectorFormat     = 'svg';       % 'svg' 

%Load matrix
fname = sprintf('OUTPUT%d/WorkSpace_Matrix_Final.csv', sampleIdx);
if ~isfile(fname)
    error('File not found: %s', fname);
end

M       = readmatrix(fname);
P       = M(:,1:3);       % positions
G       = M(:,4:end);     % genes
CellNum = size(P,1);

% pairwise distances
dx = P(:,1) - P(:,1)'; 
dy = P(:,2) - P(:,2)'; 
dz = P(:,3) - P(:,3)';
D  = sqrt(dx.^2 + dy.^2 + dz.^2);

%Figure & axes
fig = figure('Visible','on', 'Color', bgColor);  
ax  = axes('Parent',fig); 
hold(ax,'on');

% Fix physical size for reproducible exports
set(fig, 'Units','inches', 'Position',[1 1 figWidthInches figHeightInches], ...
         'PaperUnits','inches', 'PaperPosition',[0 0 figWidthInches figHeightInches], ...
         'PaperPositionMode','auto', 'InvertHardcopy','off');

axis(ax,'equal'); axis(ax,'off');
set(ax, 'LooseInset',[0 0 0 0], 'Position',[0 0 1 1]);

view(ax, [azDeg, elDeg]);                
set(ax, 'XDir','normal', ...
        'YDir','normal', ...
        'ZDir','normal', ...
        'CameraUpVector',[0 0 1], ...
        'CameraTargetMode','auto', ...
        'CameraPositionMode','auto', ...
        'CameraViewAngleMode','auto');

%Draw cells (unchanged logic)
if size(G,2) < 2
    error('Matrix has fewer than 2 gene columns; cannot check G2.');
end

for n = 1:CellNum
    if nnz(D(n,:) < 2*r) > 1
        isG2on = (G(n,2) >= thr);
        if isG2on
            c = [1 0 0];          % red
        else
            c = [0.75 0.75 0.75]; % light gray
        end

        % keep mesh density identical to your original (20)
        [rx, ry, rz] = ellipsoid(P(n,1), P(n,2), P(n,3), r, r, r, 20);
        surf(ax, rx, ry, rz, 'FaceAlpha', 1, 'FaceColor', c, 'EdgeColor', 'none', ...
             'PickableParts','none','HitTest','off');
    end
end

camlight(ax);
lighting(ax, 'gouraud');
hold(ax,'off');

%Save(PNG + SVG)
outBase = sprintf('OUTPUT%d/G2_Binary', sampleIdx);
outPNG  = sprintf('%s.png', outBase);
outSVG  = sprintf('%s.svg', outBase);

drawnow;           

exportgraphics(fig, outPNG, 'Resolution', 1200, 'BackgroundColor','white');

saveas(fig, outSVG, 'svg');

fprintf('Saved: %s\n', outPNG);
fprintf('Saved: %s\n', outSVG);

