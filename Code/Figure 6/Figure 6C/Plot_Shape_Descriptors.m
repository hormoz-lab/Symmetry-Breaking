function Plot_Shape_Descriptors()
% Plot_Shape_Descriptors

    %timing (same as your other plots)
    Tmax       = 75;     
    dt         = 0.02;  
    numTimepts = round(Tmax / dt);
    timeArray  = linspace(0, Tmax, numTimepts);

    %compute descriptors for OUTPUT1
    outputFolder = 'OUTPUT1';
    files = dir(fullfile(outputFolder, 'WorkSpace_Matrix_*.csv'));
    if isempty(files)
        error('No WorkSpace_Matrix_*.csv files found in %s', outputFolder);
    end

    idx = [];
    for k = 1:numel(files)
        t = regexp(files(k).name, 'WorkSpace_Matrix_(\d+)\.csv', 'tokens');
        if ~isempty(t)
            idx(end+1) = str2double(t{1}{1});
        end
    end
    idx = sort(idx);
    sampledIdx = round(linspace(idx(1), idx(end), numTimepts));

    D = NaN(12, numTimepts);

    % constants
    shrinkFactor = 0.9;   % for boundary surface
    epsv = 1e-12;

    for t = 1:numTimepts
        csvFile = fullfile(outputFolder, sprintf('WorkSpace_Matrix_%d.csv', sampledIdx(t)));
        if ~isfile(csvFile), continue; end
        M = readmatrix(csvFile);
        if size(M,2) < 3, continue; end
        P = M(:,1:3);

        %geometric quantities
        [cellVol, cellSurf] = clusterVolumeSurface(P, shrinkFactor);
        [convVol, convSurf] = convexHullVolumeSurface(P);
        [a,b,c] = obbExtents(P);

        %guard
        cellVol = max(cellVol, epsv); cellSurf = max(cellSurf, epsv);
        convVol = max(convVol, epsv); convSurf = max(convSurf, epsv);
        a = max(a, epsv); b = max(b, epsv); c = max(c, epsv);

        %descriptors
        GS  = ((36*pi*cellVol.^2).^(1/3)) ./ cellSurf;        % 1 General Sphericity
        DS  = ((6*cellVol/pi).^(1/3)) ./ a;                   % 2 Diameter Sphericity
        IS  = (b*c/a^2).^(1/3);                               % 3 Intercept Sphericity
        MPS = (c^2/(a*b)).^(1/3);                             % 4 Maximum Projection Sphericity
        HR  = cellVol ./ (cellSurf * (a*b*c)^(1/3));          % 5 Hayakawa Roundness
        SI  = ((36*pi*convVol.^2).^(1/3)) ./ convSurf;        % 6 Spreading Index
        ER  = a/b;                                            % 7 Elongation Ratio
        PI  = c/b;                                            % 8 Pivotability Index
        HF  = (a + b) / (2*c);                                % 9 Hayakawa Flatness
        WF  = c/a;                                            % 10 Wilson Flatness
        HSF = (b + c) / (2*a);                                % 11 Huang Shape Factor
        CSF = c / sqrt(a*b);                                  % 12 Corey-like shape factor

        D(:,t) = [GS; DS; IS; MPS; HR; SI; ER; PI; HF; WF; HSF; CSF];
    end

    % indices for the three/four you want (same names you had)
    iCSF = 12;   % Corey Shape Factor 
    pvi  = 8;    %Pivotability Index
    DS_i = 2;    % Diameter Sphericity
    IS_i = 3;    % Intercept Sphericity
    iSI  = 6;    % Spreading Index
    iHF  = 9;    % Hayakawa Flatness

    %Parameters here can be changed / were changed to best fit data for figure
    makeFig(timeArray, D(IS_i,:), 'Intercept Sphericity',   [0.7 1.00], 0.5, 7,  '%.2f', fullfile(outputFolder, 'Paper_CSF.svg'));
    makeFig(timeArray, D(iSI ,:), 'Spreading Index',        [0.90 1.00], 0.02, 6, '%.2f', fullfile(outputFolder, 'Paper_SI.svg'));
    makeFig(timeArray, D(iHF ,:), 'Hayakawa Flatness',      [0.90 1.50],  0.1, 7,  '%.2f', fullfile(outputFolder, 'Paper_HF.svg'));
    makeFig(timeArray, D(DS_i ,:), 'Diameter Sphericity',   [0.65 1.0], 0.05, 7, '%.2f', fullfile(outputFolder, 'Paper_PVI.svg'));

    fprintf('Saved:\n  %s\n  %s\n  %s\n  %s\n', ...
        fullfile(outputFolder,'Paper_CSF.svg'), ...
        fullfile(outputFolder,'Paper_SI.svg'), ...
        fullfile(outputFolder,'Paper_HF.svg'), ...
        fullfile(outputFolder,'Paper_PVI.svg'));
end


%helpers

function [V, A] = clusterVolumeSurface(P, shrink)
% Estimate non-convex cluster volume & surface via boundary triangulation.
% shrink in [0,1] (0 -> convex hull; 1 -> very tight)
    V = 0; A = 0;
    if size(P,1) < 4, return; end
    try
        [K, V] = boundary(P(:,1), P(:,2), P(:,3), shrink);
        A = triSurfaceArea(P, K);
    catch
        % Fallback to convex hull
        [K, V] = convhulln(P);
        A = triSurfaceArea(P, K);
    end
end

function [V, A] = convexHullVolumeSurface(P)
% Convex hull volume & surface area
    V = 0; A = 0;
    if size(P,1) < 4, return; end
    try
        [K, V] = convhulln(P);
        A = triSurfaceArea(P, K);
    catch
        V = 0; A = 0;
    end
end

function A = triSurfaceArea(P, K)
% Sum of triangle areas given vertices P and triangle indices K
    if isempty(K)
        A = 0;
        return;
    end
    v1 = P(K(:,2),:) - P(K(:,1),:);
    v2 = P(K(:,3),:) - P(K(:,1),:);
    cr = cross(v1, v2, 2);
    A  = 0.5 * sum(sqrt(sum(cr.^2, 2)));
end

function [a, b, c] = obbExtents(P)
% Oriented bounding box side lengths via PCA principal axes
% Returns a >= b >= c
    if size(P,1) < 3
        a = 0; b = 0; c = 0;
        return;
    end
    Pc = P - mean(P,1);
    % Try pca first
    try
        coeff = pca(Pc, 'Algorithm','svd', 'Centered', true);
    catch
        C = cov(Pc);
        [V, ~] = eig(C);
        coeff = V(:, [3 2 1]); % rough reorder; will sort by ranges below anyway
    end
    proj = Pc * coeff;  % N x 3
    ext  = max(proj,[],1) - min(proj,[],1);
    ext  = sort(ext, 'descend');
    a = ext(1); b = ext(2); c = ext(3);
end

function makeFig(timeArray, series, ylab, ylims, step, nTicks, fmt, outFile)
% helper to make/export one figure with exact ticks
    fig = figure('Visible','off');
    plot(timeArray, series, 'LineWidth', 2); 
    grid off;

    ax = gca;
    ax.Box = 'off';

    %ticks manual
    ax.FontUnits = 'points';
    ax.FontSize  = 26;                               
    if isprop(ax,'FontSizeMode'), ax.FontSizeMode = 'manual'; end
    ax.LabelFontSizeMultiplier = 1;
    ax.TitleFontSizeMultiplier = 1;

    %X label manual
    hX = xlabel(ax, 'Time', 'Interpreter','none');
    hX.FontUnits   = 'points';
    hX.FontSize    = 38;
    if isprop(hX,'FontSizeMode'), hX.FontSizeMode = 'manual'; end

    %Y label manual
    hY = ylabel(ax, ylab, 'Interpreter','none');
    hY.FontUnits   = 'points';
    hY.FontSize    = 38;
    if isprop(hY,'FontSizeMode'), hY.FontSizeMode = 'manual'; end

    ax.YLim = ylims;

    dec_fmt  = max(0, sscanf(regexprep(fmt,'%.|f',''),'%d'));
    if isempty(dec_fmt), dec_fmt = 0; end
    dec_step = max(0, -floor(log10(step + eps)));
    decimals = min(max(dec_fmt, dec_step), 6);

    ticks = ylims(1):step:ylims(2);
    ticks = round(ticks, decimals);

    if numel(ticks) ~= nTicks
        ticks = linspace(ylims(1), ylims(2), nTicks);
        ticks = round(ticks, decimals);
    end

    ax.YTick = ticks;
    ax.YMinorTick = 'off';
    ax.YAxis.Exponent = 0;            
    ytickformat(ax, sprintf('%%.%df', decimals));

    %export as SVG
    print(fig, outFile, '-dsvg');
    close(fig);
end
