%% VisualizeTimeLapseStrip_CS_FACE_SHIFTED_HQ
% Saves: OUTPUT<simIdx>/TimeLapseStrip_CS_FACE_G<gene>.png

%User Settings
simIdx  = 1;               % which OUTPUT<simIdx> folder to read
r       = 1.0;             % cell radius
gene    = 2;               % which gene to color by (1, 2, or 3)
AZEL    = [-60 15];        % [az el] in degrees

%[first frame after initial : frame spacing : Last frame grabbed]

idxList = 825:75:1875;    %Change this depending on simulation/output

% Quality / framing controls
perTilePx     = 300;       
padAbs        = 3*r;      
gapAlongRight = 2.5*r;

%I/O
outDir = sprintf('OUTPUT%d', simIdx);
if ~isfolder(outDir), error('Folder %s not found.', outDir); end

%Figure
nAfter = numel(idxList);
nTiles = 1 + nAfter;
figW   = perTilePx * nTiles;                
figH   = round(240 * (perTilePx/220));       

fig = figure('Visible','off','Color','w','Units','pixels',...
             'Position',[100 100 figW figH], ...
             'InvertHardcopy','off');       


set(fig,'Renderer','opengl');               
fig.GraphicsSmoothing = 'off';            

ax  = axes('Parent', fig, 'Units','normalized', 'Position',[0 0 1 1]);
axis(ax,'off'); hold(ax,'on');


set(ax,'Projection','orthographic');     
set(ax,'SortMethod','depth');               
axis(ax,'vis3d');                       

view(ax, AZEL(1), AZEL(2));
camproj(ax,'orthographic');
camup(ax, [0 0 1]);                    
camtarget(ax, [0 0 0]);
drawnow;                                     

pos = campos(ax); tgt = camtarget(ax); upv = camup(ax);
fwd   = (tgt - pos);  fwd = fwd / norm(fwd); 
upv   = upv / norm(upv);
right = cross(fwd, upv);  right = right / norm(right);  
camdir = fwd;                                               

%Helpers
function render_frame_cs(ax, MP, MG, r, k, step, right, gene, camdir)
    [Pcs, Gcs] = filterCS_FacingCamera(MP, MG, camdir); 
    Pcs = Pcs + (k*step).*right;                        
    renderCells_GeneRamp(ax, Pcs, Gcs, r, gene);     
end

%Load initial, compute cross-section
[MP0_full, MG0_full] = loadMatrixFrame(outDir, 'initial', []);
[Pcs0, Gcs0] = filterCS_FacingCamera(MP0_full, MG0_full, camdir);

s0       = Pcs0 * right(:);               
span     = (max(s0) - min(s0)) + 2*r;      
tileStep = span + gapAlongRight;          

%Render initial 
render_frame_cs(ax, MP0_full, MG0_full, r, 0, tileStep, right, gene, camdir);

%Render intermediates + final
for k = 1:nAfter
    if k == nAfter
        [MP, MG] = loadMatrixFrame(outDir, 'final', idxList(k));
    else
        [MP, MG] = loadMatrixFrame(outDir, 'index', idxList(k));
    end
    render_frame_cs(ax, MP, MG, r, k, tileStep, right, gene, camdir);
end

%Camera + overall limits that cover the whole strip
min0 = min(Pcs0,[],1) - r;
max0 = max(Pcs0,[],1) + r;

shiftMax = nAfter * tileStep * right;
xmin = min( [min0(1), min0(1)+shiftMax(1)] );
xmax = max( [max0(1), max0(1)+shiftMax(1)] );
ymin = min( [min0(2), min0(2)+shiftMax(2)] );
ymax = max( [max0(2), max0(2)+shiftMax(2)] );
zmin = min( [min0(3), min0(3)+shiftMax(3)] );
zmax = max( [max0(3), max0(3)+shiftMax(3)] );

%absolute padding 
xmin = xmin - padAbs;  xmax = xmax + padAbs;
ymin = ymin - padAbs;  ymax = ymax + padAbs;
zmin = zmin - padAbs;  zmax = zmax + padAbs;

axis(ax,'equal','off');
xlim(ax,[xmin xmax]); ylim(ax,[ymin ymax]); zlim(ax,[zmin zmax]);

view(ax, AZEL(1), AZEL(2));
camproj(ax,'orthographic');
camtarget(ax, [(xmin+xmax)/2, (ymin+ymax)/2, (zmin+zmax)/2]);

delete(findobj(ax,'Type','light'));   
camlight(ax,'headlight'); 
lighting(ax,'gouraud');

%Export
outPNG = fullfile(outDir, sprintf('TimeLapseStrip_CS_FACE_G%d.png', gene));
exportgraphics(fig, outPNG, 'Resolution', 600, 'BackgroundColor', 'white');
close(fig);
fprintf('Saved camera-facing cross-section strip to %s\n', outPNG);

%More Helpers
function [MatrixP, MatrixG] = loadMatrixFrame(outDir, kind, idx)
switch lower(kind)
    case 'initial'
        paths = { fullfile(outDir,'WorkSpace_MatrixP_Initial.csv'), ...
                  fullfile(outDir,'WorkSpace_Matrix_Initial.csv') };
    case 'final'
        paths = { fullfile(outDir,'WorkSpace_Matrix_Final.csv'), ...
                  fullfile(outDir, sprintf('WorkSpace_Matrix_%d.csv', idx)) };
    otherwise
        paths = { fullfile(outDir, sprintf('WorkSpace_Matrix_%d.csv', idx)) };
end
fileFound = '';
for p = paths
    if isfile(p{1}), fileFound = p{1}; break; end
end
if isempty(fileFound)
    error('Missing matrix file for %s (idx=%s) in %s.', kind, string(idx), outDir);
end
M = readmatrix(fileFound);
if size(M,2) < 3, error('Matrix file %s lacks XYZ columns.', fileFound); end
MatrixP = M(:,1:3); MatrixG = [];
if size(M,2) > 3, MatrixG = M(:,4:end); end
end

function [Pcs, Gcs] = filterCS_FacingCamera(P, G, camdir)
    c  = mean(P, 1, 'omitnan'); if any(isnan(c)), c = [0 0 0]; end
    Pc = P - c;
    camdir = camdir(:) / norm(camdir);
    depth  = Pc * camdir;
    keep   = depth >= -1e-9;     
    Pcs = Pc(keep, :);
    if ~isempty(G), Gcs = G(keep, :); else, Gcs = []; end
end

function renderCells_GeneRamp(ax, MatrixP, MatrixG, r, gene)
Distance = sqrt( (MatrixP(:,1) - MatrixP(:,1)').^2 + ...
                 (MatrixP(:,2) - MatrixP(:,2)').^2 + ...
                 (MatrixP(:,3) - MatrixP(:,3)').^2 );
N = size(MatrixP,1);
baseGray = [0.80 0.80 0.80]; red = [1 0 0];
for i = 1:N
    if nnz(Distance(i,:) < 2*r) > 1
        [rx, ry, rz] = ellipsoid(MatrixP(i,1), MatrixP(i,2), MatrixP(i,3), r, r, r, 20);
        g = 0;
        if ~isempty(MatrixG) && size(MatrixG,2) >= gene
            g = MatrixG(i, gene); if isnan(g), g = 0; end
            g = max(0, min(1, g));
        end
        colorVal = baseGray + g*(red - baseGray);
        surf(ax, rx, ry, rz, 'FaceAlpha', 1, 'FaceColor', colorVal, 'EdgeColor', 'none');
    end
end
end
