clear; clc;

%User Settings
outDir           = 'OUTPUT1';
fileFmt          = 'WorkSpace_Matrix_%d.csv';
idxList          = 751:5:1875;
dt               = 0.02;

Tmax     = 75;
time     = (idxList - idxList(1)) * Tmax / (idxList(end) - idxList(1));

% Graph / model params
cell_radius      = 1;
contact_thresh   = 2;

% CSV layout assumptions
posCols          = 1:3;
geneStartCol     = 4;
gene_col_in_G    = 2;      % G2 (relative to geneStartCol)

% Strict typing thresholds (hysteresis)
hi_th = 0.95;   % G2+ if >= 0.95
lo_th = 0.05;   % G2- if <= 0.05
min_labeled_frac = 0.2;   % require at least 20% of cells to be labeled globally


% If either type has fewer than these counts, treat as "absent" (=> asym=0 or drop)
min_global_per_type = 8;  
min_local_per_type  = 4;   

% Saving
save_csv_path    = fullfile(outDir, 'Asymmetry_TimeSeries.csv');
save_fig_path    = fullfile(outDir, 'Asymmetry_TimeSeries.png');
save_svg_path    = fullfile(outDir, 'Asymmetry_TimeSeries.svg');


nFrames  = numel(idxList);
asymVals = nan(nFrames,1);
lossVals = nan(nFrames,1);
nPlus    = nan(nFrames,1);
nMinus   = nan(nFrames,1);
clusterN = nan(nFrames,1);
readOK   = false(nFrames,1);

for k = 1:nFrames
    idx    = idxList(k);
    csvRel = sprintf(fileFmt, idx);
    csvAbs = fullfile(outDir, csvRel);

    if ~isfile(csvAbs)
        fprintf('[%5d/%5d] MISSING -> %s\n', k, nFrames, csvAbs);
        continue;
    end

    fprintf('[%5d/%5d] Reading %s ... ', k, nFrames, csvRel);

    try
        [MatrixP, MatrixG] = robust_load_workspace_csv(csvAbs, posCols, geneStartCol);
        readOK(k) = true;
        fprintf('OK | N=%d\n', size(MatrixP,1));
    catch ME
        fprintf('FAIL (%s)\n', ME.message);
        continue;
    end

g2 = MatrixG(:, gene_col_in_G);

cells_plus_global  = (g2 >= hi_th);
cells_minus_global = (g2 <= lo_th);
N = size(MatrixP,1);

N_plus_global   = nnz(cells_plus_global);
N_minus_global  = nnz(cells_minus_global);
frac_labeled_glb = (N_plus_global + N_minus_global) / max(N,1);

nPlus(k)  = N_plus_global;
nMinus(k) = N_minus_global;

if N <= 1
    asymVals(k) = 0;  lossVals(k) = 0;  clusterN(k) = N;
    fprintf('        Single/empty frame -> asym=0, loss=0\n');
    continue;
end

%Frames with insufficient representation of either subtype (fewer than X
%cells of a subtype of < Y% labeled overall) were retained but excluded
%from asymmetry and plotted as 0
if frac_labeled_glb < min_labeled_frac || ...
   (N_plus_global  < min_global_per_type) || ...
   (N_minus_global < min_global_per_type)
    % Still compute loss for context
    Dtmp  = pdist2(MatrixP, MatrixP);
    Atmp  = (Dtmp <= contact_thresh) & ~eye(N);
    Gctmp = graph(sparse(triu(Atmp,1)),'upper');
    compT = conncomp(Gctmp);
    sizesT= accumarray(compT(:),1);
    lossVals(k) = (N - max(sizesT)) / N;
    clusterN(k)  = max(sizesT);
    asymVals(k)  = 0;
    fprintf('        (global gate) labeled=%.2f  asym=0  loss=%.3f  (largest=%d)\n', ...
            frac_labeled_glb, lossVals(k), clusterN(k));
    continue;
end


    D  = pdist2(MatrixP, MatrixP);
    A  = (D <= contact_thresh) & ~eye(N);
    Gc = graph(sparse(triu(A,1)), 'upper');
    comp  = conncomp(Gc);
    sizes = accumarray(comp(:), 1);
    [max_size, ~] = max(sizes);
    clusterN(k) = max_size;
    lossVals(k) = (N - max_size) / N;

    labels_max = find(sizes == max_size);
    asym_list  = nan(numel(labels_max),1);

    for m = 1:numel(labels_max)
        mask = (comp == labels_max(m));
        P    = MatrixP(mask,1:3);
        g2cl = g2(mask);

        cells_plus  = (g2cl >= hi_th);
        cells_minus = (g2cl <= lo_th);



        n_out = nnz(cells_plus);
        n_in  = nnz(cells_minus);

        if (n_in < min_local_per_type) || (n_out < min_local_per_type)
            asym_list(m) = 0;   
            continue
        end

        % Geometric center and normalization radius
        c_all = mean(P,1);
        rvec  = vecnorm(P - c_all, 2, 2);
        r     = mean(rvec);

        if r <= eps
            asym_list(m) = NaN; 
            continue
        end

        % Centroids per type and separation
        c_plus  = mean(P(cells_plus,:),  1);
        c_minus = mean(P(cells_minus,:), 1);
        sep     = norm(c_plus - c_minus);

        %weighting by global representation
        w = (n_in / N_minus_global) * (n_out / N_plus_global);

        asym_list(m) = (sep / r) * w;
    end

    % Average across tied largest components, omitting NaNs
    asymVals(k) = mean(asym_list, 'omitnan');
    if isnan(asymVals(k)), asymVals(k) = 0; end

    fprintf('        asym=%.4f  loss=%.3f  (largest=%d)\n', ...
        asymVals(k), lossVals(k), clusterN(k));
end

%Plot / Save

T = table(time(:), idxList(:), asymVals(:), lossVals(:), nMinus(:), nPlus(:), clusterN(:), readOK(:), ...
    'VariableNames', {'time','index','asymmetry','loss','N_G2minus','N_G2plus','largest_cluster_size','read_ok'});
writetable(T, save_csv_path);

fprintf('---------------------------------------------\n');
fprintf('Read OK: %d/%d frames. CSV -> %s\n', nnz(readOK), nFrames, save_csv_path);

ok = readOK & ~isnan(asymVals);

fig = figure('Color','w');
fig.Units = 'inches';
pos = fig.Position;
fig.Position = [pos(1) pos(2) pos(3)*1.75 pos(4)]; 

plot(time(ok), asymVals(ok), 'LineWidth', 2, 'Color', [0 0 0]); hold on;

grid off;

ax = gca;

% Axis range & ticks
xmax = ceil(max(time(ok))/10)*10;
xlim([0 xmax]);
xticks(0:5:xmax);          
xtickformat('%.0f');

ax.FontSize  = 25;  
ax.LineWidth = 1.5;
ax.TickLength = [0.01 0.01];
ax.XMinorTick = 'off';
ax.YMinorTick = 'off';
ax.LabelFontSizeMultiplier = 1;   
ax.TitleFontSizeMultiplier = 1;

% hx = xlabel('\itin silico\rm time for pattern formation','Interpreter','tex');
% hy = ylabel('Morphological Asymmetry (A)');
hx.FontSize = 25;      hy.FontSize = 25;
hx.FontName = 'Arial';  hy.FontName = 'Arial';
hx.FontSizeMode = 'manual'; 
hy.FontSizeMode = 'manual';

% Save SVG (vector)
save_svg_path = fullfile(outDir, 'Asymmetry_TimeSeries.svg');
set(gcf,'Renderer','painters');
print(gcf, save_svg_path, '-dsvg');   


%Helper
function [MatrixP, MatrixG] = robust_load_workspace_csv(csvPath, posCols, geneStartCol)
    try
        M = readmatrix(csvPath);
        if isempty(M) || all(isnan(M), 'all')
            error('Empty or non-numeric after readmatrix.');
        end
    catch
        opts = detectImportOptions(csvPath);
        T    = readtable(csvPath, opts);
        M    = table2array(T);
        if isempty(M) || all(isnan(M), 'all')
            error('Empty or non-numeric after readtable.');
        end
    end
    maxCol = max([posCols(:); geneStartCol]);
    if size(M,2) < maxCol
        error('CSV has only %d cols; needs at least %d for pos/gene layout.', size(M,2), maxCol);
    end
    MatrixP = M(:, posCols);
    MatrixG = M(:, geneStartCol:end);

    if size(MatrixP,2) < 3
        error('Position columns must include X,Y,Z (got %d).', size(MatrixP,2));
    end
    if size(MatrixG,2) < 2
        error('Need at least 2 gene columns so that G2 exists (got %d).', size(MatrixG,2));
    end

    %Remove rows with NaNs
    bad = any(isnan(MatrixP),2) | any(isnan(MatrixG),2);
    if any(bad)
        MatrixP(bad,:) = [];
        MatrixG(bad,:) = [];
    end
end
