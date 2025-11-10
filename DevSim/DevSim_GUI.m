classdef DevSim_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        StatusLabel                     matlab.ui.control.Label
        ProgressBG                      matlab.ui.container.Panel
        ProgressFill                    matlab.ui.container.Panel
        ProgressLabel                   matlab.ui.control.Label
        SimulationControlsPanel         matlab.ui.container.Panel
        ExportOutputFilesButton         matlab.ui.control.Button
        TotalSimulationsSlider          matlab.ui.control.Slider
        TotalSimulationsSliderLabel     matlab.ui.control.Label
        TotalSimulationEditField        matlab.ui.control.NumericEditField
        ParallelPoolSizeDropDown        matlab.ui.control.DropDown
        ParallelPoolSizeDropDownLabel   matlab.ui.control.Label
        UseParallelPoolCheckBox         matlab.ui.control.CheckBox
        StopCancelButton                matlab.ui.control.Button
        RunSimulationButton             matlab.ui.control.Button
        NetworkDiagramPanel             matlab.ui.container.Panel
        ShowMechanicalRegulationCheckBox  matlab.ui.control.CheckBox
        PathwaySelectionDropDown        matlab.ui.control.DropDown
        PathwaySelectionDropDownLabel   matlab.ui.control.Label
        ShowRegulationNumberCheckBox    matlab.ui.control.CheckBox
        RefreshDiagramButton            matlab.ui.control.Button
        NetworkAxes                     matlab.ui.control.UIAxes
        GeneticMechanicalRegulatoryNetworkPanel  matlab.ui.container.Panel
        ExportTemplateButton            matlab.ui.control.Button
        LoadTemplateButton              matlab.ui.control.Button
        LoadParametersButton            matlab.ui.control.Button
        SaveParametersButton            matlab.ui.control.Button
        UseCustomHillCoefficientsCheckBox  matlab.ui.control.CheckBox
        HillCoefficientEditField        matlab.ui.control.NumericEditField
        GlobalHillCoefficientLabel      matlab.ui.control.Label
        NumberofPathwaysDropDown        matlab.ui.control.DropDown
        NumberofPathwaysDropDownLabel   matlab.ui.control.Label
        NumberofGenesDropDown           matlab.ui.control.DropDown
        NumberofGenesDropDownLabel      matlab.ui.control.Label
        EditParametersButton            matlab.ui.control.Button
        EditNetworkButton               matlab.ui.control.Button
        VisualizationPanel              matlab.ui.container.Panel
        ExportImagesButton              matlab.ui.control.Button
        SelectorDropDown                matlab.ui.control.DropDown
        VisualizationModeDropDown       matlab.ui.control.DropDown
        VisualizationModeDropDownLabel  matlab.ui.control.Label
        RefreshDropdownButton           matlab.ui.control.Button
        SimulationSelectionDropDown     matlab.ui.control.DropDown
        SimulationSelectionDropDownLabel  matlab.ui.control.Label
        AutoVisualizeAfterSimulationLabel  matlab.ui.control.Label
        AutoVisualizeCheckBox           matlab.ui.control.CheckBox
        VisualizeResultsButton          matlab.ui.control.Button
        ExportMovieButton               matlab.ui.control.Button
        ButtonGroup                     matlab.ui.container.ButtonGroup
        ShapeDescriptionsButton         matlab.ui.control.RadioButton
        GeneExpressionButton            matlab.ui.control.RadioButton
        FinalVisualization              matlab.ui.control.UIAxes
        GeneExpressionOverTimeGraph     matlab.ui.control.UIAxes
        ParametersPanel                 matlab.ui.container.Panel
        FrictionEditField               matlab.ui.control.NumericEditField
        FrictionCoefficientLabel        matlab.ui.control.Label
        TimeStepdtEditField             matlab.ui.control.NumericEditField
        TimeStepdtEditFieldLabel        matlab.ui.control.Label
        betaLEditField                  matlab.ui.control.NumericEditField
        LongRangeForceStrengthbetaLLabel  matlab.ui.control.Label
        betaSEditField                  matlab.ui.control.NumericEditField
        ShortRangeForceStrengthbetaSLabel  matlab.ui.control.Label
        DistancePowerEditField          matlab.ui.control.NumericEditField
        DistancePowerDLabel             matlab.ui.control.Label
        MorphogenStrengthEditField      matlab.ui.control.NumericEditField
        MorphogenStrengthLabel          matlab.ui.control.Label
        ForceNoisekappaFLabel           matlab.ui.control.Label
        GeneNoisekappaGLabel            matlab.ui.control.Label
        AlphaMaxSlider                  matlab.ui.control.Slider
        AlphaMaxSliderLabel             matlab.ui.control.Label
        AlphaMinEditField               matlab.ui.control.NumericEditField
        AlphaMaxEditField               matlab.ui.control.NumericEditField
        MaximumTimeEditField            matlab.ui.control.NumericEditField
        MaximumTimeEditFieldLabel       matlab.ui.control.Label
        RadiusEditField                 matlab.ui.control.NumericEditField
        RadiusEditFieldLabel            matlab.ui.control.Label
        AlphaMinSlider                  matlab.ui.control.Slider
        AlphaMinLabel                   matlab.ui.control.Label
        PopulationSizeEditField         matlab.ui.control.NumericEditField
        PopulationSizeEditFieldLabel    matlab.ui.control.Label
        PopulationSizeMathLabel         matlab.ui.control.Label
        RadiusMathLabel                 matlab.ui.control.Label
        MaximumTimeMathLabel            matlab.ui.control.Label
        TimeStepMathLabel               matlab.ui.control.Label
        BetaSMathLabel                  matlab.ui.control.Label
        BetaLMathLabel                  matlab.ui.control.Label
        GeneNoiseMathLabel              matlab.ui.control.Label
        ForceNoiseMathLabel             matlab.ui.control.Label
        MorphogenMathLabel              matlab.ui.control.Label
        DistancePowerMathLabel          matlab.ui.control.Label
        HillMathLabel                   matlab.ui.control.Label
        ResetParametersButton           matlab.ui.control.Button
        kappaFEditField                 matlab.ui.control.NumericEditField
        kappaGEditField                 matlab.ui.control.NumericEditField
        NumberofGenesDisplay            matlab.ui.control.NumericEditField
        NumberofPathwaysDisplay         matlab.ui.control.NumericEditField
    end

    
properties (Access = private)
    SimFile char  = 'UserParams.xlsx'
    NetFile char  = 'Network Settings.xlsx'

    ConfigRoot char = 'DevSim'
    ActiveFolder char = 'Active'
    TemplatesFolder char = 'Templates'

    SimColName char  = 'Parameter Name'
    SimColValue char = 'Value'
    SimSheet char    = 'Params' 

    SimStartCell char = 'A2'
    SimTitle char = 'Simulation Parameters'

    SimMap struct

    IsDirty logical = false
    InitDone logical = false


    SimTotal double = 0
    PrepDoneCount double = 0
    SimProgVec     double = []
    isVizMode  logical = false
end

    
    methods (Access = private)

    function [GeneNum, NumPathways] = detectGeneAndPathwayCounts(app)
    file  = fullfile(app.ActiveFolder, app.NetFile);
    sheet = 'Gene Information';

    GeneNum     = 1;
    NumPathways = 1;

    if ~isfile(file), return; end

    try
        g = readmatrix(file,'Sheet',sheet,'Range','C2:C2','UseExcel',false);
        p = readmatrix(file,'Sheet',sheet,'Range','F2:F2','UseExcel',false);
    catch
        g = readmatrix(file,'Sheet',sheet,'Range','C2:C2','UseExcel',true);
        p = readmatrix(file,'Sheet',sheet,'Range','F2:F2','UseExcel',true);
    end

    if ~isempty(g), GeneNum     = round(g(1)); end
    if ~isempty(p), NumPathways = round(p(1)); end
end




        function rgb = parseColorFlexible(cstr)
    rgb = [0.75 0.75 0.75];
    if isa(cstr,'string') || ischar(cstr), s = strtrim(char(cstr));
    else, return; end
    if isempty(s), return; end

    if s(1) == '#' && (numel(s)==7 || numel(s)==4)
        try
            if numel(s)==7
                rgb = [hex2dec(s(2:3)),hex2dec(s(4:5)),hex2dec(s(6:7))]/255;
            else 
                rgb = [hex2dec(repmat(s(2),1,2)),hex2dec(repmat(s(3),1,2)),hex2dec(repmat(s(4),1,2))]/255;
            end
            return;
        catch, end
    end

    if contains(s,',')
        try
            q = sscanf(s, '%f,%f,%f');
            if numel(q)==3
                if max(q) > 1.01, q = q/255; end
                rgb = max(0,min(1,q(:)')). return;
            end
        catch, end
    end

    % Named fallback
    cmap = containers.Map( ...
        {'Red','Green','Blue','Magenta','Cyan','Yellow','Orange','Purple','Lime','Pink','Gray','Grey','Black','White'}, ...
        { [1,0,0],[0,1,0],[0,0,1],[1,0,1],[0,1,1],[1,1,0],[1,0.5,0],[0.5,0,0.5],[0.5,1,0],[1,0.4,0.6],[0.75,0.75,0.75],[0.75,0.75,0.75],[0,0,0],[1,1,1]});
    if cmap.isKey(s), rgb = cmap(s); end
end



%These functions are to help the GUI stay on top
function localFrontPing(app)
    try
        if isprop(app.UIFigure,'WindowStyle')
            prev = app.UIFigure.WindowStyle;
            app.UIFigure.WindowStyle = 'alwaysontop';
            drawnow limitrate nocallbacks
            app.UIFigure.WindowStyle = prev;   
        else
            app.UIFigure.Visible = 'off';
            drawnow limitrate nocallbacks
            app.UIFigure.Visible = 'on';
        end
    catch
    end
end



        
        %RenderGeneExpressionPNG's Function
        function RenderGeneExpressionPNG(app, simIdx, geneIdx)

            file = sprintf('OUTPUT%d/GeneExpressionOverTime_Gene%d.png', simIdx, geneIdx);
            if isfile(file)
                imshow(imread(file), ...
                    'Parent', app.GeneExpressionOverTimeGraph, ...
                    'InitialMagnification', 'fit');
                title(app.GeneExpressionOverTimeGraph, sprintf('Simulation %d', simIdx));
            else
                title(app.GeneExpressionOverTimeGraph, ...
                    sprintf('Gene %d PNG not found for Sim %d', geneIdx, simIdx));
            end
        end
      
        %Loads PNG for the visualization
        function loadFinalSnapshotPNG(app, simIdx)

            resetAxesForImage(app)
        
            imageFile = sprintf('OUTPUT%d/FinalSnapshot.png', simIdx);
            if isfile(imageFile)
                imshow(imread(imageFile), ...
                    'Parent', app.FinalVisualization, ...
                    'InitialMagnification', 'fit');
        

                set(app.FinalVisualization, ...
                    'CameraPositionMode', 'auto', ...
                    'CameraTargetMode', 'auto', ...
                    'CameraUpVectorMode', 'auto', ...
                    'CameraViewAngleMode', 'auto', ...
                    'Projection', 'orthographic', ...
                    'XLimMode', 'auto', ...
                    'YLimMode', 'auto', ...
                    'ZLimMode', 'auto');
        
                rotate3d(app.FinalVisualization, 'off');
        
                title(app.FinalVisualization, sprintf('Simulation %d (Quick View)', simIdx));
            else
                title(app.FinalVisualization, sprintf('Simulation %d not found', simIdx));
            end
        end  
        

        %Generate 12 shape descriptors
        function VisualizeShapeDescriptorsOverTime(app)
        % Output (per OUTPUT# folder):
        %   ShapeOverTime_GeneralSphericity.png
        %   ShapeOverTime_DiameterSphericity.png
        %   ShapeOverTime_InterceptSphericity.png
        %   ShapeOverTime_MaximumProjectionSphericity.png
        %   ShapeOverTime_HayakawaRoundness.png
        %   ShapeOverTime_SpreadingIndex.png
        %   ShapeOverTime_ElongationRatio.png
        %   ShapeOverTime_PivotabilityIndex.png
        %   ShapeOverTime_HayakawaFlatness.png
        %   ShapeOverTime_WilsonFlatness.png
        %   ShapeOverTime_HuangShapeFactor.png
        %   ShapeOverTime_CoreyShapeFactor.png
        
            % === Global timing / sampling (mirror your gene plots) ===
            Tmax       = app.MaximumTimeEditField.Value;
            dt         = app.TimeStepdtEditField.Value;
            totalSims  = app.TotalSimulationEditField.Value;
            numTimepts = round(Tmax / dt);
            timeArray  = linspace(0, Tmax, numTimepts);
        
            % Boundary tightness for cluster surface (0.0 = convex hull, 1.0 = very tight)
            shrinkFactor = 0.9;
        
            % Descriptor names (for titles + filenames)
            descNames = { ...
                'General Sphericity', ...
                'Diameter Sphericity', ...
                'Intercept Sphericity', ...
                'Max. Projection Sphericity', ...
                'Hayakawa Roundness', ...
                'Spreading Index', ...
                'Elongation Ratio', ...
                'Pivotability Index', ...
                'Hayakawa Flatness', ...
                'Wilson Flatness', ...
                'Huang Shape Factor', ...
                'Corey Shape Factor'};
        
            fileTags = { ...
                'GeneralSphericity', ...
                'DiameterSphericity', ...
                'InterceptSphericity', ...
                'MaximumProjectionSphericity', ...
                'HayakawaRoundness', ...
                'SpreadingIndex', ...
                'ElongationRatio', ...
                'PivotabilityIndex', ...
                'HayakawaFlatness', ...
                'WilsonFlatness', ...
                'HuangShapeFactor', ...
                'CoreyShapeFactor'};
        
            for simIdx = 1:totalSims
                outputFolder = sprintf('OUTPUT%d', simIdx);
        
                %detect available matrix indices
                files = dir(fullfile(outputFolder, 'WorkSpace_Matrix_*.csv'));
                indices = [];
                for k = 1:numel(files)
                    t = regexp(files(k).name, 'WorkSpace_Matrix_(\d+)\.csv', 'tokens');
                    if ~isempty(t), indices(end+1) = str2double(t{1}{1}); end %#ok<AGROW>
                end
                if isempty(indices)
                    warning('No matrix files found in %s', outputFolder);
                    continue;
                end
                indices = sort(indices);
                idx_min = min(indices);  
                idx_max = max(indices);
                sampledIdx = round(linspace(indices(1), idx_max, numTimepts));
        
                %allocate descriptor time series
                D = NaN(12, numTimepts);
        
                for t = 1:numTimepts
                    cycle    = sampledIdx(t);
                    csvFile  = fullfile(outputFolder, sprintf('WorkSpace_Matrix_%d.csv', cycle));
                    if ~isfile(csvFile)
                        continue;
                    end
                    M = readmatrix(csvFile);
                    if size(M,2) < 3
                        warning('Expected XYZ in first 3 columns: %s', csvFile);
                        continue;
                    end
                    P = M(:,1:3);  % Nx3 point cloud (cells)
        
                    % Compute raw geometric quantities
                    [cellVol, cellSurf] = app.clusterVolumeSurface(P, shrinkFactor);  % boundary-based
                    [convVol, convSurf] = app.convexHullVolumeSurface(P);             % convex hull
                    [a, b, c]           = app.obbExtents(P);                          % OBB extents (a>=b>=c)
        
                    % Guard against zeros / degeneracy
                    epsv = 1e-12;
                    cellVol = max(cellVol, epsv); cellSurf = max(cellSurf, epsv);
                    convVol = max(convVol, epsv); convSurf = max(convSurf, epsv);
                    a = max(a, epsv); b = max(b, epsv); c = max(c, epsv);
        
                    %12 descriptors (Membranes 2024 definitions)
                    GS  = ((36*pi*cellVol.^2).^(1/3)) ./ cellSurf;
                    DS  = ((6*cellVol/pi).^(1/3)) ./ a;
                    IS  = (b*c/a^2).^(1/3);
                    MPS = (c^2/(a*b)).^(1/3);
                    HR  = cellVol ./ (cellSurf * (a*b*c)^(1/3));
                    SI  = ((36*pi*convVol.^2).^(1/3)) ./ convSurf;
                    ER  = a/b;
                    PI  = c/b;
                    HF  = (a + b) / (2*c);
                    WF  = c/a;
                    HSF = (b + c) / (2*a);
                    CSF = c / sqrt(a*b);
        
                    D(:, t) = [GS; DS; IS; MPS; HR; SI; ER; PI; HF; WF; HSF; CSF];
                end
        
                               %save one PNG per descriptor
                for j = 1:12
                    fig = figure('Visible','off');
                    plot(timeArray, D(j,:), 'LineWidth', 2); grid off;
                    
                    ax = gca;
                    
                    %ticks vs. label sizes
                    tickFont   = 26;   
                    yLabelFont = 32; 
                    
                    ax.FontSize = tickFont;          
                    ax.LabelFontSizeMultiplier = 1;     
                    
                    hY = ylabel(ax, descNames{j}, 'Interpreter','none');  
                    hY.FontSize     = yLabelFont;           
                    hY.FontSizeMode = 'manual';            
                    
                    xlabel(ax, 'Time', 'FontSize', 32);   
                   
                    app.applyExactNiceYTicks(ax, D(j,:), 6);  
                    ax.YMinorTick = 'off';

                    
                    saveas(fig, fullfile(outputFolder, sprintf('ShapeOverTime_%s.png', fileTags{j})));
                    close(fig);

                end

            end      
        end
        
       function applyExactNiceYTicks(app, ax, dataVec, targetTicks)

    data = dataVec(isfinite(dataVec));
    if isempty(data); return; end

    dmin = min(data); dmax = max(data);
    if dmax == dmin
        pad = max(1e-6, (abs(dmax)+1)*1e-3);
        dmin = dmin - pad; dmax = dmax + pad;
    end

    %small headroom to avoid clipping
    marginFrac  = 0.02;                 
    padAbs      = (dmax - dmin) * marginFrac;
    paddedMin   = dmin - padAbs;
    paddedMax   = dmax + padAbs;
    paddedRange = paddedMax - paddedMin;

    idealStep = paddedRange / (targetTicks - 1);
    step      = app.ceilNiceStep(idealStep);  
    span      = step * (targetTicks - 1);

    vmax = paddedMax;
    vmin = vmax - span;

    % apply limits & ticks
    ax.YLim  = [vmin, vmax];
    ax.YTick = vmin:step:vmax;
    ax.YMinorTick = 'off';

    % dynamic label precision (no duplicate-looking ticks)
    dec = max(0, ceil(-log10(step) + 1e-12)); 
    dec = min(dec, 6);
    ytickformat(ax, sprintf('%%.%df', dec));
end

function s = ceilNiceStep(app, ideal)
    if ideal <= 0
        s = ideal; return;
    end
    pow  = floor(log10(ideal));
    base = 10^pow;
    mant = [1 1.25 1.5 2 2.5 3 4 5 6 8 10];
    cands = base * mant;
    s = cands(find(cands >= ideal, 1, 'first'));
    if isempty(s), s = 10^(pow+1); end
end


        function [V, A] = clusterVolumeSurface(app, P, shrink)
        % Estimate non-convex cluster volume & surface via boundary triangulation.
        % shrink in [0,1] (0 -> convex hull; 1 -> very tight)
            V = 0; A = 0;
            if size(P,1) < 4, return; end
            try
                [K, V] = boundary(P(:,1), P(:,2), P(:,3), shrink);
                A = app.triSurfaceArea(P, K);
            catch
                % Fallback to convex hull
                [K, V] = convhulln(P);
                A = app.triSurfaceArea(P, K);
            end
        end
        
        function [V, A] = convexHullVolumeSurface(app, P)
        % Convex hull volume & surface area
            V = 0; A = 0;
            if size(P,1) < 4, return; end
            try
                [K, V] = convhulln(P);
                A = app.triSurfaceArea(P, K);
            catch
                V = 0; A = 0;
            end
        end
        
        function A = triSurfaceArea(app, P, K)
            if isempty(K), A = 0; return; end
            v1 = P(K(:,2),:) - P(K(:,1),:);
            v2 = P(K(:,3),:) - P(K(:,1),:);
            cr = cross(v1, v2, 2);
            A  = 0.5 * sum(sqrt(sum(cr.^2, 2)));
        end
        
        function [a, b, c] = obbExtents(app, P)
        % Oriented bounding box side lengths via PCA principal axes
            if size(P,1) < 3
                a = 0; b = 0; c = 0;
                return;
            end
            Pc = P - mean(P,1);
            % Use PCA if available; otherwise fallback to eigen-decomposition of covariance
            try
                coeff = pca(Pc, 'Algorithm','svd', 'Centered', true);
            catch
                C = cov(Pc);
                [V, ~] = eig(C);
                coeff = V(:, [3 2 1]); % sort approx; will sort by ranges below anyway
            end
            proj = Pc * coeff;  % N x 3
            ext  = max(proj,[],1) - min(proj,[],1);
            ext  = sort(ext, 'descend');
            a = ext(1); b = ext(2); c = ext(3);
        end
        
        %Render's the Gallery View page
        function renderGalleryView(app, pageNumber)

           resetAxesForImage(app)
            
        
            filename = sprintf('OUTPUT_Page%d.png', pageNumber);
            if isfile(filename)
                imshow(imread(filename), ...
                    'Parent', app.FinalVisualization, ...
                    'InitialMagnification', 'fit');
        
                title(app.FinalVisualization, sprintf('Gallery Page %d', pageNumber));
            else
                title(app.FinalVisualization, sprintf('Gallery Page %d not found', pageNumber));
            end
        end
        
        %Reset Axes after rotation function 
        function resetAxesForImage(app)
            cla(app.FinalVisualization, 'reset');
            hold(app.FinalVisualization, 'off');
            axis(app.FinalVisualization, 'off', 'image');
            set(app.FinalVisualization, ...
                'CameraPositionMode', 'auto', ...
                'CameraTargetMode', 'auto', ...
                'CameraUpVectorMode', 'auto', ...
                'CameraViewAngleMode', 'auto', ...
                'Projection', 'orthographic', ...
                'YDir', 'normal', ...
                'XLimMode', 'auto', ...
                'YLimMode', 'auto', ...
                'ZLimMode', 'auto');
            rotate3d(app.FinalVisualization, 'off');
        end

        
        function mode = getCurrentMode(app)
        % Returns 'gene' or 'shape' based on the radio selection
            if app.GeneExpressionButton.Value
                mode = 'gene';
            else
                mode = 'shape';
            end
            
        end
        
       function populateSelectorItems(app)
            % Rebuilds the SelectorDropDown items based on mode
            switch getCurrentMode(app)
                case 'gene'
                    G = app.getGeneNum();  
                    items = arrayfun(@(i) sprintf('Gene %d', i), 1:G, 'UniformOutput', false);
                    if isempty(items)
                        items = {'Gene 1'};
                    end
                    app.SelectorDropDown.Items = items;
                    if ~isempty(items)
                        app.SelectorDropDown.Value = items{1};
                    end
                case 'shape'
                    items = { ...
                        'General Sphericity', 'Diameter Sphericity', 'Intercept Sphericity', ...
                        'Max. Projection Sphericity', 'Hayakawa Roundness', 'Spreading Index', ...
                        'Elongation Ratio', 'Pivotability Index', 'Hayakawa Flatness', ...
                        'Wilson Flatness', 'Huang Shape Factor', 'Corey Shape Factor' };
                    app.SelectorDropDown.Items = items;
                    app.SelectorDropDown.Value = items{1};
            end
        end



        
        function RenderShapeDescriptorPNG(app, simIdx, descriptorName)
            % Map dropdown text saved PNG tag
            map = containers.Map( ...
                {'General Sphericity','Diameter Sphericity','Intercept Sphericity', ...
                 'Max. Projection Sphericity','Hayakawa Roundness','Spreading Index', ...
                 'Elongation Ratio','Pivotability Index','Hayakawa Flatness', ...
                 'Wilson Flatness','Huang Shape Factor','Corey Shape Factor'}, ...
                {'GeneralSphericity','DiameterSphericity','InterceptSphericity', ...
                 'MaximumProjectionSphericity','HayakawaRoundness','SpreadingIndex', ...
                 'ElongationRatio','PivotabilityIndex','HayakawaFlatness', ...
                 'WilsonFlatness','HuangShapeFactor','CoreyShapeFactor'} );
        
            if ~isKey(map, descriptorName)
                title(app.GeneExpressionOverTimeGraph, 'Unknown descriptor');
                return;
            end
        
            tag = map(descriptorName);
            file = sprintf('OUTPUT%d/ShapeOverTime_%s.png', simIdx, tag);
        
            if isfile(file)
                imshow(imread(file), 'Parent', app.GeneExpressionOverTimeGraph, 'InitialMagnification', 'fit');
                title(app.GeneExpressionOverTimeGraph, sprintf('Simulation %d', simIdx));
            else
                title(app.GeneExpressionOverTimeGraph, sprintf('%s PNG not found for Sim %d', descriptorName, simIdx));
            end
        end
   
        function ensureConfigLayout(app)
            if ~isfolder(app.ActiveFolder), mkdir(app.ActiveFolder); end
            simPath = fullfile(app.ActiveFolder, app.SimFile);
            if ~isfile(simPath)
                app.writeSim2Col(simPath);
            end
        end


        function buildSimMap(app)
            function s = M(label, kind, h), s = struct('label',label,'kind',kind,'h',h); end
        
            app.SimMap = [ ...
                M('Population',                           'num',  app.PopulationSizeEditField), ...
                M('Radius',                               'num',  app.RadiusEditField), ...
                M('Maximum Time',                         'num',  app.MaximumTimeEditField), ...
                M('Time Step',                            'num',  app.TimeStepdtEditField), ...
                M('Alpha Min',                            'num',  app.AlphaMinSlider), ...
                M('Alpha Max',                            'num',  app.AlphaMaxSlider), ...
                M('Gene Noise (kappaG)',                  'num',  app.kappaGEditField), ...
                M('Force Noise (kappaF)',                 'num',  app.kappaFEditField), ...
                M('Morphogen Strength',                   'num',  app.MorphogenStrengthEditField), ...
                M('Distance Power (D)',                   'num',  app.DistancePowerEditField), ...
                M('Short-Range Force Strength (betaS)',   'num',  app.betaSEditField), ...
                M('Long-Range Force Strength (betaL)',    'num',  app.betaLEditField), ...
                M('Friction Coefficient',                 'num',  app.FrictionEditField), ...
                M('Number of Genes',                      'num',  app.NumberofGenesDisplay), ...
                M('Number of Pathways',                   'num',  app.NumberofPathwaysDisplay), ...
                M('Global Hill Coefficient',              'num',  app.HillCoefficientEditField), ...
            ];
        end

        function loadAllFromActive(app)
            app.loadSim2Col(fullfile(app.ActiveFolder, app.SimFile));   % UserParams.xlsx
            app.loadNetwork(fullfile(app.ActiveFolder, app.NetFile));   % Network Settings.xlsx
            app.setDirty(false);
        end

        
        function saveAllToActive(app)
            app.writeSim2Col(fullfile(app.ActiveFolder, app.SimFile));
            app.setDirty(false);
        end

        
     function loadSim2Col(app, filename)
    T = readtable(filename, ...
        'Sheet', app.SimSheet, ...
        'Range', app.SimStartCell, ...
        'TextType','string', ...
        'VariableNamingRule','preserve', ...
        'ReadVariableNames', true);

    vars    = T.Properties.VariableNames;
    nameVar = app.SimColName;
    valVar  = app.SimColValue;

    if ~ismember(nameVar, vars) || ~ismember(valVar, vars)
        n2 = matlab.lang.makeValidName(nameVar);
        v2 = matlab.lang.makeValidName(valVar);
        if ismember(n2, vars), nameVar = n2; end
        if ismember(v2, vars), valVar  = v2; end
    end

    if ~ismember(nameVar, vars) || ~ismember(valVar, vars)
        error('UserParams missing expected columns "%s" / "%s" at %s.', ...
              app.SimColName, app.SimColValue, app.SimStartCell);
    end

    names  = strip(string(T.(nameVar)));
    values = string(T.(valVar));

    for k = 1:numel(app.SimMap)
        idx = find(strcmpi(names, app.SimMap(k).label), 1, 'first');
        if isempty(idx), continue; end
        sval = strip(values(idx));

        switch app.SimMap(k).kind
            case 'num'
                v = str2double(sval);
                if isnan(v)
                    rawCol = T.(valVar);
                    if isnumeric(rawCol) || islogical(rawCol)
                        v = double(rawCol(idx));
                    else
                        continue;
                    end
                end

                app.setVal(app.SimMap(k).h, v);

                if app.SimMap(k).h == app.AlphaMinSlider
                    app.AlphaMinEditField.Value = v;
                elseif app.SimMap(k).h == app.AlphaMaxSlider
                    app.AlphaMaxEditField.Value = v;
                end

            case 'bool'
                s = lower(sval);
                if any(s == ["true","1","on","yes"])
                    b = true;
                elseif any(s == ["false","0","off","no"])
                    b = false;
                else
                    rawCol = T.(valVar);
                    if islogical(rawCol)
                        b = rawCol(idx);
                    elseif isnumeric(rawCol)
                        b = rawCol(idx) ~= 0;
                    else
                        b = false;
                    end
                end
                app.setVal(app.SimMap(k).h, b);

            otherwise
                app.setVal(app.SimMap(k).h, sval);
        end
    end
end


%%Progress bar
        function setProgress(app, frac, msg)
            % Clamp and set UI width
            frac = max(0, min(1, double(frac)));
        
            bg   = app.ProgressBG;
            fill = app.ProgressFill;
        
            % Reduce to scalars for logical ops
            if isempty(bg) || isempty(fill)
                return;
            end
            if ~all(isvalid(bg(:))) || ~all(isvalid(fill(:)))
                return;
            end
        
            oldUnits = fill.Units;
            fill.Units = 'normalized';
            fill.Position = [0 0 frac 1];
            fill.Units = oldUnits;
        
            if isprop(app,'ProgressLabel') && ~isempty(app.ProgressLabel) && all(isvalid(app.ProgressLabel(:)))
                app.ProgressLabel.Text = sprintf('%.0f%%', round(frac*100));
            end
        
            if nargin >= 3 && ~isempty(msg) && isprop(app,'StatusLabel') && ~isempty(app.StatusLabel) && all(isvalid(app.StatusLabel(:)))
                app.StatusLabel.Text = string(msg);
            end
        
            drawnow limitrate nocallbacks
        end

        
            function initProgressSimulation(app, totalSims)
                app.isVizMode   = false;
                app.SimTotal     = totalSims;
                app.PrepDoneCount = 0;
                app.SimProgVec    = zeros(1, max(1,totalSims));
                app.setProgress(0, "Preparing simulation… (0%)");
            end

            function updateFromQueue(app, msg)
                try
                    if ~isstruct(msg) || ~isfield(msg,'kind')
                        return;  
                    end
                
                    switch msg.kind
                        case 'sim-step'
                            if isfield(msg,'simIdx') && isfield(msg,'tfrac')
                                idx = max(1, min(numel(app.SimProgVec), double(msg.simIdx)));
                                app.SimProgVec(idx) = max(0, min(1, double(msg.tfrac)));
                                frac = mean(app.SimProgVec);
                                app.setProgress(frac, sprintf('Running simulations… (%.0f%%)', 100*frac));
                            end
                
                        case 'note'
                            if isfield(msg,'msg') && isprop(app,'StatusLabel')
                                app.StatusLabel.Text = string(msg.msg);
                            end
                    end
                catch ME
                    warning('updateFromQueue error: %s', ME.message);
                end
                end


        
            function finishProgress(app, msg)
                app.setProgress(1, msg);
            end

            function vizInit(app)
                app.isVizMode = true;
                app.progressWireUp();         
                app.setProgress(0, "Visualizing results… (0%)");
                drawnow
            end

            function vizStep(app, frac, label)
                if ~app.isVizMode, return; end
                app.setProgress(frac, label);
            end
            
            function vizDone(app)
                if ~app.isVizMode, return; end
                app.finishProgress("Visualization complete!");
                app.isVizMode = false;
            end

            function progressWireUp(app)
            if isempty(app.ProgressBG) || ~isvalid(app.ProgressBG), return; end
            if isempty(app.ProgressFill) || ~isvalid(app.ProgressFill), return; end
        
            try
                app.ProgressFill.Parent = app.ProgressBG;
            catch

            end
        
 
            app.ProgressBG.Units   = 'normalized';
            app.ProgressFill.Units = 'normalized';
            app.ProgressFill.Position = [0 0 0 1];
        

            if isprop(app,'ProgressLabel') && ~isempty(app.ProgressLabel)
                app.ProgressLabel.Text = "0%";
            end
        end
        
        function writeSim2Col(app, filename)
            names  = strings(0,1); values = strings(0,1);
            for k = 1:numel(app.SimMap)
                names(end+1,1)  = string(app.SimMap(k).label);
                values(end+1,1) = app.toStr(app.getVal(app.SimMap(k).h), app.SimMap(k).kind);
            end
            T = table(names, values, 'VariableNames', {app.SimColName, app.SimColValue});
        
            tmp = [tempname, '.xlsx'];
            % Title at A1
            writecell({app.SimTitle}, tmp, 'Sheet', app.SimSheet, 'Range', 'A1');
            % Table header+data starting A2
            writetable(T, tmp, 'Sheet', app.SimSheet, 'Range', app.SimStartCell, ...
                'WriteVariableNames', true);
        
            if isfile(filename)
                try, delete(filename); catch, end
            end
            [ok,msg] = movefile(tmp, filename, 'f');
            if ~ok
                error('Could not write "%s": %s', filename, msg);
            end
        end

        
        function v = getVal(~, h)
            if isprop(h,'Value'), v = h.Value;
            elseif isprop(h,'Text'), v = h.Text;
            else, error('Control missing Value/Text.'); end
        end
        
        function setVal(~, h, v)
    % Support scalar or array of handles by iterating
    for hh = reshape(h,1,[])
        if isprop(hh,'Items') && isprop(hh,'Value')
            try
                if isstring(v) || ischar(v)
                    % If value is present in Items, set it; otherwise just assign string(v)
                    it = string(get(hh,'Items'));
                    vv = string(v);
                    if any(strcmp(it, vv)), hh.Value = vv;
                    else, hh.Value = vv;
                    end
                else
                    hh.Value = v;
                end
            catch
                hh.Value = v;
            end
        elseif isprop(hh,'Value')
            hh.Value = v;
        elseif isprop(hh,'Text')
            hh.Text = string(v);
        else
            error('Cannot set control.');
        end
    end
end

        
        function s = toStr(~, v, kind)
            switch kind
                case 'num'
                    if isstring(v)||ischar(v), v = str2double(v); end
                    s = string(v);
                case 'str'
                    s = string(v);
                case 'bool'
                    s = string(logical(v)); 
            end
        end

        function loadGeneParams(app, filename)
            try
                % initVals = readmatrix(filename,'Range','E4:E13'); app.applyInitialExpression(initVals);
                % colorNames = readcell(filename,'Range','F4:F13');  app.applyGeneColors(colorNames);
            catch ME
                uialert(app.UIFigure, sprintf('GeneParameters load failed:\n%s', ME.message), 'Load Error');
            end
        end

        
        function loadNetwork(app, filename)
            try
                % Aint = readmatrix(filename,'Sheet','Internal');
                % Aext = readmatrix(filename,'Sheet','External');
                % app.setNetworkMatrices(Aint, Aext); app.RefreshDiagramButtonPushed();
            catch ME
                uialert(app.UIFigure, sprintf('GRN load failed:\n%s', ME.message), 'Load Error');
            end
        end

        function scanTemplatePacks(app)
            if isprop(app,'TemplatePackDropDown')
                if ~isfolder(app.TemplatesFolder), mkdir(app.TemplatesFolder); end
                L = dir(app.TemplatesFolder);
                packs = {};
                for k = 1:numel(L)
                    if L(k).isdir && ~startsWith(L(k).name,'.')
                        p = fullfile(app.TemplatesFolder, L(k).name);
                        if all(isfile(fullfile(p, {app.SimFile, app.NetFile})))
                            packs{end+1} = L(k).name; %#ok<AGROW>
                        end
                    end
                end
                if isempty(packs), packs = {'(none)'}; end
                app.TemplatePackDropDown.Items = packs;
                app.TemplatePackDropDown.Value = packs{1};
            end
        end

        
        function LoadTemplatePackButtonPushed(app, event)
            packName = '';
            if isprop(app,'TemplatePackDropDown') && ~isempty(app.TemplatePackDropDown.Items)
                packName = app.TemplatePackDropDown.Value;
            end
            if isempty(packName) || strcmp(packName,'(none)')
                packPath = uigetdir(app.TemplatesFolder, 'Choose template pack folder');
                if isequal(packPath,0), return; end
            else
                packPath = fullfile(app.TemplatesFolder, packName);
            end
        
            c = uiconfirm(app.UIFigure, "Replace Active parameter files with this pack?", ...
                "Load Template Pack", 'Options',{'Load','Cancel'}, 'DefaultOption',1, 'CancelOption',2);
            if ~strcmp(c,'Load'), return; end
        
            req = {app.SimFile, app.NetFile};
            for k = 1:numel(req)
                src = fullfile(packPath, req{k});
                if ~isfile(src)
                    uialert(app.UIFigure, sprintf('Pack missing: %s', req{k}), 'Template Error');
                    return;
                end
            end
       
            copyfile(fullfile(packPath, app.SimFile), fullfile(app.ActiveFolder, app.SimFile), 'f');
            copyfile(fullfile(packPath, app.NetFile), fullfile(app.ActiveFolder, app.NetFile), 'f');
        
            app.loadAllFromActive();
            if isprop(app,'StatusLabel'), app.StatusLabel.Text = "Template pack loaded."; end
        end

        
        function ExportTemplatePackButtonPushed(app, event)
            app.writeSim2Col(fullfile(app.ActiveFolder, app.SimFile));  % ensure fresh write
        
            d = uiputfile('*.mat','Name your template pack (we only use the name)');
            if isequal(d,0), return; end
            [~, name] = fileparts(d);
            outDir = fullfile(app.TemplatesFolder, name);
            if ~isfolder(outDir), mkdir(outDir); end
        
            copyfile(fullfile(app.ActiveFolder, app.SimFile), fullfile(outDir, app.SimFile));
            copyfile(fullfile(app.ActiveFolder, app.NetFile), fullfile(outDir, app.NetFile));
        
            app.scanTemplatePacks();
            if isprop(app,'StatusLabel'), app.StatusLabel.Text = "Template pack exported."; end
        end

        
        function attachSimListeners(app)
            for k = 1:numel(app.SimMap)
                h = app.SimMap(k).h;
                if isprop(h,'ValueChangedFcn')
                    prev = h.ValueChangedFcn;
                    h.ValueChangedFcn = @(src,evt)app.onSimChanged(src,evt,prev);
                end
            end
        end
        
        function onSimChanged(app, src, evt, prevFcn)
            if ~isempty(prevFcn), try, feval(prevFcn, src, evt); catch, end, end
            app.setDirty(true);
        end
        
        function setDirty(app, tf)
            app.IsDirty = logical(tf);
            base = 'DevSim';
            if app.IsDirty, app.UIFigure.Name = [base ' • unsaved'];
            else,           app.UIFigure.Name = base; end
        end

        function packPath = pickTemplatePack(app)
            % Try dropdown if present; otherwise open a folder picker inside Templates/
            packPath = "";
            if isprop(app,'TemplatePackDropDown') && ~isempty(app.TemplatePackDropDown.Items)
                val = app.TemplatePackDropDown.Value;
                if ~strcmp(val,'(none)')
                    pp = fullfile(app.TemplatesFolder, val);
                    if isfolder(pp), packPath = pp; return; end
                end
            end
            if ~isfolder(app.TemplatesFolder), mkdir(app.TemplatesFolder); end
            p = uigetdir(app.TemplatesFolder, 'Choose a template pack folder');
            if isequal(p,0), return; end
            packPath = string(p);
        end     

           function startupFcn(app)
            app.ensureInit();
           end
        
       function ensureInit(app)
            % One-time initializer
            % --- ensure folders every time (cheap + safe) ---
            app.ActiveFolder    = fullfile(pwd, 'Active');
            app.TemplatesFolder = fullfile(pwd, 'Templates');
            if ~isfolder(app.ActiveFolder),    mkdir(app.ActiveFolder);    end
            if ~isfolder(app.TemplatesFolder), mkdir(app.TemplatesFolder); end
        
            % If already initialized, do NOT reload from disk
            if app.InitDone
                return;
            end
        
            % --- (first run only) guard old location & initial load ---
            legacy  = fullfile('DevSim','Active','UserParams.xlsx');
            current = fullfile(app.ActiveFolder, 'UserParams.xlsx');
            if isfile(legacy) && isfile(current)
                try
                    dOld = dir(legacy); dNew = dir(current);
                    if dOld.bytes ~= dNew.bytes || abs(datenum(dOld.date)-datenum(dNew.date))>eps
                        uialert(app.UIFigure, sprintf([ ...
                            'Two parameter files detected.\n\nUsing pwd/Active only:\n  %s\n\n' ...
                            'Consider archiving/removing the legacy file:\n  %s'], ...
                            current, legacy), 'Dual UserParams Detected');
                    end
                catch
                end
            end
        
            % Build map and ensure we have an initial file once
            app.buildSimMap();
            simPath = fullfile(app.ActiveFolder, app.SimFile);
            if ~isfile(simPath)
                app.writeSim2Col(simPath);   % seed with current GUI values
            end
        
            % Initial load ONCE at startup
            app.loadAllFromActive();
            app.attachSimListeners();
            app.progressWireUp();
            app.InitDone = true;
        
            if isprop(app,'StatusLabel'), app.StatusLabel.Text = "Ready."; end
        end



        %Quick View Generator
function VisualizeResultsAsPNGs(app, totalSims, r)
    activeDir = app.ActiveFolder;

    GeneNum   = app.NumberofGenesDisplay.Value;
    geneRGBs  = app.getGeneRGBsFromNetFile(GeneNum);

    for simIdx = 1:totalSims
        filename = sprintf('OUTPUT%d/WorkSpace_Matrix_Final.csv', simIdx);
        if ~isfile(filename), continue; end

        Matrix  = readmatrix(filename);
        MatrixP = Matrix(:, 1:3);
        MatrixG = Matrix(:, 4:end);

        nGfile  = size(MatrixG, 2);
        nG      = min(GeneNum, nGfile);
        MatrixG = MatrixG(:, 1:nG);

        geneRGBsUsed = geneRGBs(1:nG, :); 

        CellNum = size(MatrixP, 1);
        fig = figure('Visible','off');
        hold on;

        Distance = sqrt( (MatrixP(:,1) - MatrixP(:,1)').^2 + ...
                         (MatrixP(:,2) - MatrixP(:,2)').^2 + ...
                         (MatrixP(:,3) - MatrixP(:,3)').^2 );

        for N = 1:CellNum
            if nnz(Distance(N,:) < 2*r) > 1
                [rx, ry, rz] = ellipsoid(MatrixP(N,1), MatrixP(N,2), MatrixP(N,3), r, r, r, 20);

                geneLevels = MatrixG(N, :);
                sumExpr    = sum(geneLevels);

                % Gray when no expression (your rule)
                if sumExpr <= 0
                    colorVal = [0.75 0.75 0.75];
                else
                    weights  = geneLevels / sumExpr;
                    colorVal = weights * geneRGBsUsed;
                end

                surf(rx, ry, rz, 'FaceAlpha', 1, 'FaceColor', colorVal, 'EdgeColor', 'none');
            end
        end

        axis equal off;
        camlight('headlight'); lighting gouraud;
        outname = sprintf('OUTPUT%d/FinalSnapshot.png', simIdx);
        saveas(fig, outname);
        close(fig);
    end
end



        
        function colorMap = getColorMap(app)
            colorMap = containers.Map( ...
                {'Red','Green','Blue','Magenta','Cyan','Yellow', ...
                 'Orange','Purple','Lime','Pink'}, ...
                { [1.0, 0.0, 0.0], ...
                  [0.0, 1.0, 0.0], ...
                  [0.0, 0.0, 1.0], ...
                  [1.0, 0.0, 1.0], ...
                  [0.0, 1.0, 1.0], ...
                  [1.0, 1.0, 0.0], ...
                  [1.0, 0.5, 0.0], ...
                  [0.5, 0.0, 0.5], ...
                  [0.5, 1.0, 0.0], ...
                  [1.0, 0.4, 0.6] } );
        end


function VisualizeResultsInteractive3D(app, simIdx, r, axesHandle)
% Interactive 3D visualization with live az/el updates (App Designer safe)

% Reset camera and directions to ensure consistent starting orientation
view(axesHandle, [-135, 30]);          % your default correct az/el
set(axesHandle, 'XDir','normal', ...
                'YDir','normal', ...
                'ZDir','normal', ...
                'CameraUpVector',[0 0 1], ...
                'CameraTargetMode','auto', ...
                'CameraPositionMode','auto', ...
                'CameraViewAngleMode','auto');

    function localAlert(msg)
        try
            fig0 = ancestor(axesHandle,'figure');
            if ~isempty(fig0) && isvalid(fig0)
                try, uialert(fig0, msg, 'File Error'); return; catch, end
            end
            warning('%s', msg);
        catch
            warning('%s', msg);
        end
    end

    GeneNum  = app.getGeneNum();
    geneRGBs = app.getGeneRGBsFromNetFile(GeneNum); 

    filename = sprintf('OUTPUT%d/WorkSpace_Matrix_Final.csv', simIdx);
    if ~isfile(filename)
        cla(axesHandle);
        title(axesHandle, sprintf('Simulation %d not found', simIdx));
        axis(axesHandle,'off');
        return;
    end
    Matrix  = readmatrix(filename);
    if size(Matrix,2) < 4
        cla(axesHandle); title(axesHandle, 'Matrix missing gene columns'); axis(axesHandle,'off');
        return;
    end
    MatrixP = Matrix(:,1:3);
    MatrixG = Matrix(:,4:end);
    if isempty(MatrixP)
        cla(axesHandle); title(axesHandle, 'No cells to render'); axis(axesHandle,'off');
        return;
    end

    MatrixG = MatrixG(:, 1:min(GeneNum, size(MatrixG,2)));

    need        = size(MatrixG,2);
    geneRGBsUsed = geneRGBs(1:need, :);

    cla(axesHandle);
    hold(axesHandle, 'on');
    axis(axesHandle, 'equal');
    axis(axesHandle, 'off');

    dx = MatrixP(:,1) - MatrixP(:,1)'; 
    dy = MatrixP(:,2) - MatrixP(:,2)'; 
    dz = MatrixP(:,3) - MatrixP(:,3)';
    Distance = sqrt(dx.^2 + dy.^2 + dz.^2);

    for k = 1:size(MatrixP,1)
        if nnz(Distance(k,:) < 2*r) > 1
            [rx, ry, rz] = ellipsoid(MatrixP(k,1), MatrixP(k,2), MatrixP(k,3), r, r, r, 20);
            gl = MatrixG(k,:);
            s  = sum(gl);

            % Gray when no expression
            if s <= 0
                c = [0.75 0.75 0.75];
            else
                w = gl / s;
                c = w * geneRGBsUsed;
            end

            srf = surf(axesHandle, rx, ry, rz, ...
                'FaceAlpha', 1, 'FaceColor', c, 'EdgeColor', 'none');
            set(srf,'PickableParts','none','HitTest','off');
        end
    end

    camlight(axesHandle, 'headlight');
    lighting(axesHandle, 'gouraud');
    title(axesHandle, sprintf('Simulation %d (Interactive 3D)', simIdx));

    try, rotate3d(axesHandle,'off'); end
    try, disableDefaultInteractivity(axesHandle); end
    try, axesHandle.Interactions = []; end

    initAz = 135; initEl = 90; speed = 0.4;
    view(axesHandle, -initAz + 135, initEl);
    fig = ancestor(axesHandle,'figure');

    hud = uilabel(fig, ...
        'Text', sprintf('az = %.1f° | el = %.1f°', initAz, initEl), ...
        'Position', [0 -10 220 22], ...
        'FontName','Arial','FontSize',12, ...
        'BackgroundColor',[0.94 0.94 0.94], ...
        'HorizontalAlignment','left');

    function placeHUD()
        try
            axPix = getpixelposition(axesHandle, true);
            if isvalid(hud)
                hud.Position = [axPix(1)+8, axPix(2)+8, 220, 22];
            end
        catch
        end
    end
    placeHUD();

    function syncHUD()
        try
            [azNow, elNow] = view(axesHandle);
            if isvalid(hud)
                hud.Text = sprintf('az = %.1f° | el = %.1f°', azNow, elNow);
            end
        catch
        end
    end

    try
        oldFcn = fig.SizeChangedFcn;
        fig.SizeChangedFcn = @(src,evt) safePlaceHUD(oldFcn,src,evt);
    catch
    end
    try, axesHandle.SizeChangedFcn = @(~,~) placeHUD(); end

    function safePlaceHUD(oldFcn,src,evt)
        try, if isa(oldFcn,'function_handle'), oldFcn(src,evt); end; catch, end
        placeHUD();
    end

    try
        tPrev = getappdata(fig,'devsim_hudTimer');
        if ~isempty(tPrev) && isvalid(tPrev), stop(tPrev); delete(tPrev); end
        hudTimer = timer('ExecutionMode','fixedSpacing', ...
                         'Period',0.05, ...
                         'TimerFcn',@(~,~)syncHUD);
        start(hudTimer);
        setappdata(fig,'devsim_hudTimer',hudTimer);
        addlistener(fig,'ObjectBeingDestroyed',@(~,~)cleanupHudTimer());
    catch
    end

    function cleanupHudTimer()
        try
            t = getappdata(fig,'devsim_hudTimer');
            if ~isempty(t) && isvalid(t)
                stop(t); delete(t);
            end
        catch
        end
    end

    %manual drag rotation
    setappdata(fig,'isDragging',false);
    setappdata(fig,'speed',speed);
    axesHandle.ButtonDownFcn = @startDrag;
    fig.WindowButtonMotionFcn = @doDrag;
    fig.WindowButtonUpFcn = @stopDrag;

    function startDrag(~,~)
        setappdata(fig,'isDragging',true);
        setappdata(fig,'lastPt',getPoint(fig));
        try, fig.Pointer = 'hand'; end
    end

    function doDrag(~,~)
        if ~getappdata(fig,'isDragging'), return; end
        pt = getPoint(fig);
        last = getappdata(fig,'lastPt');
        d = pt - last;
        setappdata(fig,'lastPt',pt);
        sp = getappdata(fig,'speed');

        [az, el] = view(axesHandle);
        az = az - sp * d(1);
        el = el - sp * d(2);
        el = max(-89.9,min(89.9,el));

        view(axesHandle,az,el);
        syncHUD();
        drawnow limitrate;
    end

    function stopDrag(~,~)
        if getappdata(fig,'isDragging')
            setappdata(fig,'isDragging',false);
            try, fig.Pointer = 'arrow'; end
            syncHUD();
        end
    end

    function pt = getPoint(figHandle)
        try
            p = figHandle.CurrentPoint;
            pt = double(p(1,1:2));
        catch
            p = get(figHandle,'CurrentPoint');
            pt = double(p(1,1:2));
        end
    end
end







        % Visualize Gene Expression Graphs
        function VisualizeGeneExpressionOverTimeGraphs(app)
        
            Tmax       = app.MaximumTimeEditField.Value;
            dt         = app.TimeStepdtEditField.Value;
            totalSims  = app.TotalSimulationEditField.Value;
            GeneNum    = app.getGeneNum();           % <- use helper
            numTimepts = round(Tmax / dt);

            
            for simIdx = 1:totalSims
                outputFolder = sprintf('OUTPUT%d', simIdx);
            
                files   = dir(fullfile(outputFolder, 'WorkSpace_Matrix_*.csv'));
                indices = [];
                for k = 1:length(files)
                    token = regexp(files(k).name, 'WorkSpace_Matrix_(\d+)\.csv', 'tokens');
                    if ~isempty(token)
                        indices(end+1) = str2double(token{1}{1}); 
                    end
                end
                if isempty(indices)
                    warning('No matrix files found in %s', outputFolder);
                    continue;
                end
                indices = sort(indices);
                idx_min = min(indices);
                idx_max = max(indices);
            
                sampledIdx = round(linspace(idx_min, idx_max, numTimepts));
                timeArray  = linspace(0, Tmax, numTimepts);
            
                firstFile   = fullfile(outputFolder, sprintf('WorkSpace_Matrix_%d.csv', sampledIdx(1)));
                firstMatrix = readmatrix(firstFile);
                numCells    = size(firstMatrix, 1);
                nGfile      = max(0, size(firstMatrix,2) - 3); 
                nG          = min(GeneNum, nGfile);         
            
                for g = 1:nG
                    GeneTrajectories = NaN(numCells, numTimepts);
            
                    for t = 1:numTimepts
                        cycle = sampledIdx(t);
                        fname = fullfile(outputFolder, sprintf('WorkSpace_Matrix_%d.csv', cycle));
            
                        if ~isfile(fname)
                            warning('Missing file: %s', fname);
                            continue;
                        end
            
                        data = readmatrix(fname);
                        GeneTrajectories(:, t) = data(:, 3 + g);
                    end
            
                    fig = figure('Visible','off');
                    hold on;
                    colors = hsv(numCells);
                    for c = 1:numCells
                        plot(timeArray, GeneTrajectories(c, :), ...
                            'Color', [colors(c,:), 0.35], 'LineWidth', 0.5);
                    end
                    hold off;
                    ax = gca; ax.Box = 'off';
            
                    ax.FontUnits = 'points';
                    ax.FontSize  = 26;
                    if isprop(ax,'FontSizeMode'), ax.FontSizeMode = 'manual'; end
                    ax.LabelFontSizeMultiplier = 1;
                    ax.TitleFontSizeMultiplier = 1;
            
                    hX = xlabel(ax, 'Time', 'Interpreter','none');
                    hX.FontUnits = 'points';
                    hX.FontSize  = 32;
                    if isprop(hX,'FontSizeMode'), hX.FontSizeMode = 'manual'; end
            
                    hY = ylabel(ax, sprintf('Gene %d Expression', g), 'Interpreter','none');
                    hY.FontUnits = 'points';
                    hY.FontSize  = 32;
                    if isprop(hY,'FontSizeMode'), hY.FontSizeMode = 'manual'; end
            
                    grid off;
            
                    outname = fullfile(outputFolder, sprintf('GeneExpressionOverTime_Gene%d.png', g));
                    saveas(fig, outname);
                    close(fig);
                end
            end

        end

    function renderGalleryViewAndSave(app, radius, pageNumber, totalSims)
            GeneNum  = app.NumberofGenesDisplay.Value;
            geneRGBs = app.getGeneRGBsFromNetFile(GeneNum); 
        
            simsPerPage = 25;
            startIdx = (pageNumber - 1) * simsPerPage + 1;
            endIdx   = min(totalSims, startIdx + simsPerPage - 1);
            if endIdx < startIdx, warning('No simulations on page %d.', pageNumber); return; end
            simsOnPage = startIdx:endIdx;
        
            cols = ceil(sqrt(numel(simsOnPage)));
            rows = ceil(numel(simsOnPage) / cols);
        
            fig = figure('Visible','off','Color',[1 1 1]);
            try
                for i = 1:numel(simsOnPage)
                    ax = subplot(rows, cols, i, 'Parent', fig);
                    simIdx  = simsOnPage(i);
                    filename = sprintf('OUTPUT%d/WorkSpace_Matrix_Final.csv', simIdx);
        
                    if ~isfile(filename)
                        cla(ax); axis(ax,'off'); title(ax, sprintf('Simulation %d not found', simIdx), 'FontSize', 8);
                        continue;
                    end
        
                    M = readmatrix(filename);
                    if size(M,2) < 4
                        cla(ax); axis(ax,'off'); title(ax, sprintf('Sim %d: bad matrix', simIdx), 'FontSize', 8);
                        continue;
                    end
        
                    P = M(:,1:3);
                    G = M(:,4:end);
                    nG = min(GeneNum, size(G,2));
                    G  = G(:, 1:nG);
        
                    geneRGBsUsed = geneRGBs(1:nG, :); 
        
                    cla(ax); hold(ax,'on');
        
                    dx = P(:,1) - P(:,1)'; dy = P(:,2) - P(:,2)'; dz = P(:,3) - P(:,3)';
                    D  = sqrt(dx.^2 + dy.^2 + dz.^2);
        
                    for k = 1:size(P,1)
                        if nnz(D(k,:) < 2*radius) > 1
                            [rx, ry, rz] = ellipsoid(P(k,1), P(k,2), P(k,3), radius, radius, radius, 20);
                            gl = G(k,:);
                            s  = sum(gl);
        
                            if s <= 0
                                c = [0.75 0.75 0.75];  
                            else
                                w = gl / s;
                                c = w * geneRGBsUsed;
                            end
        
                            surf(ax, rx, ry, rz, 'FaceAlpha',1, 'FaceColor',c, 'EdgeColor','none');
                        end
                    end
        
                    axis(ax,'equal'); axis(ax,'off'); view(ax, [0, 90]);
                    camlight(ax,'headlight'); lighting(ax,'gouraud');
                    title(ax, sprintf('Sample %d', simIdx), 'FontSize', 8);
                end
        
                outname = sprintf('OUTPUT_Page%d.png', pageNumber);
                saveas(fig, outname, 'png');
            catch ME
                close(fig); rethrow(ME);
            end
            close(fig);
        end



         function ExportMovieForSim(app, simIdx, fps, tStart, tEnd, r, outFile, frameStride, viewCode, customAzEl)
    if nargin < 8 || isempty(frameStride), frameStride = 1; end
    if nargin < 9 || isempty(viewCode),    viewCode    = 'iso'; end
    if nargin < 10,                        customAzEl  = [];    end

    outDir = fullfile(pwd, sprintf('OUTPUT%d', simIdx));
    if ~isfolder(outDir), error('Folder %s not found.', outDir); end

    S = dir(fullfile(outDir, 'WorkSpace_Matrix_*.csv'));
    if isempty(S), error('No frame CSVs found in %s.', outDir); end

    idx = zeros(numel(S),1);
    for k = 1:numel(S)
        m = regexp(S(k).name, 'WorkSpace_Matrix_(\d+)\.csv$', 'tokens', 'once');
        if ~isempty(m), idx(k) = str2double(m{1}); end
    end
    idx(idx==0) = [];
    if isempty(idx), error('No valid frame indices found in %s.', outDir); end
    idx      = sort(idx);
    firstIdx = idx(1);
    lastIdx  = idx(end);

    Cycle  = 5;
    TmaxUI = app.MaximumTimeEditField.Value;

    A_from_last = lastIdx / Cycle;
    A_from_span = (lastIdx - firstIdx + 1) / (Cycle - 2);
    A = (A_from_last + A_from_span) / 2;

    map_time_to_idx = @(t) round( A * ( 2 + 3*(t / max(TmaxUI, eps)) ) );
    startIdx = max(firstIdx, map_time_to_idx(tStart));
    endIdx   = min(lastIdx,  map_time_to_idx(tEnd));
    if endIdx < startIdx
        error('No frames in requested time range (start=%g, end=%g).', tStart, tEnd);
    end

    frameList    = startIdx:frameStride:endIdx;
    plannedCount = numel(frameList);

    app.vizStep(0.07, "Preloading…");
    probePos = 1;
    while probePos <= plannedCount && ~isfile(fullfile(outDir, sprintf('WorkSpace_Matrix_%d.csv', frameList(probePos))))
        probePos = probePos + 1;
    end
    if probePos > plannedCount
        error('No actual CSVs found between %d and %d.', startIdx, endIdx);
    end
    probeIdx = frameList(probePos);

    M0  = readmatrix(fullfile(outDir, sprintf('WorkSpace_Matrix_%d.csv', probeIdx)));
    P0  = M0(:,1:3);
    G0  = M0(:,4:end);
    nG0 = size(G0,2);

    padFrac     = 0.10; 
    minXYZ_glob = [ inf  inf  inf];
    maxXYZ_glob = [-inf -inf -inf];

    scanStride = max(1, floor(numel(frameList)/300));
    for q = 1:scanStride:numel(frameList)
        qIdx  = frameList(q);
        qPath = fullfile(outDir, sprintf('WorkSpace_Matrix_%d.csv', qIdx));
        if ~isfile(qPath), continue; end
        Mq = readmatrix(qPath);
        Pq = Mq(:,1:3);
        minXYZ_glob = min(minXYZ_glob, min(Pq,[],1));
        maxXYZ_glob = max(maxXYZ_glob, max(Pq,[],1));
    end

    if any(~isfinite(minXYZ_glob))
        minXYZ_glob = min(P0,[],1);
        maxXYZ_glob = max(P0,[],1);
    end

    box    = maxXYZ_glob - minXYZ_glob;
    xyzMin = minXYZ_glob - (padFrac.*box + r);
    xyzMax = maxXYZ_glob + (padFrac.*box + r);


    geneRGBsUsed = app.getGeneRGBsFromNetFile(nG0); 

    vw = VideoWriter(outFile, 'MPEG-4');
    vw.FrameRate = max(1, round(fps));
    vw.Quality   = 95;
    open(vw);

    fig = figure('Visible','off','Color','w','Renderer','opengl');
    fig.Position = [100 100 1024 768];
    co = onCleanup(@() app.closeSafely(fig));

    app.vizStep(0.10, "Initializing renderer…");

    p0 = 0.12; renderCount = 0;

    for fidx = frameList
        fname = fullfile(outDir, sprintf('WorkSpace_Matrix_%d.csv', fidx));
        if ~isfile(fname)
            renderCount = renderCount + 1;
            frac = p0 + (1 - p0) * (renderCount / max(plannedCount,1));
            app.vizStep(frac, sprintf('Exporting movie… (%d/%d)', renderCount, plannedCount));
            continue;
        end

        M = readmatrix(fname);
        P = M(:,1:3);
        G = M(:,4:end);
        if size(G,2) > nG0, G = G(:,1:nG0); end
        G = max(0, min(1, G));

        clf(fig);
        ax = axes('Parent',fig);
        hold(ax,'on');
        axis(ax,'equal'); axis(ax,'off'); axis(ax,'vis3d'); daspect(ax,[1 1 1]);
        set(ax,'XLim',double([xyzMin(1) xyzMax(1)]), ...
               'YLim',double([xyzMin(2) xyzMax(2)]), ...
               'ZLim',double([xyzMin(3) xyzMax(3)]));

        D = sqrt( (P(:,1)-P(:,1)').^2 + (P(:,2)-P(:,2)').^2 + (P(:,3)-P(:,3)').^2 );

        CellNum = size(P,1);
        for N = 1:CellNum
            if nnz(D(N,:) < 2*r) > 1
                [rx, ry, rz] = ellipsoid(P(N,1), P(N,2), P(N,3), r, r, r, 20);

                s = sum(G(N,:));
                if s <= 0
                    colorVal = [0.75 0.75 0.75];            
                else
                    w = G(N,:) / s;
                    colorVal = max(0, min(1, w * geneRGBsUsed));
                end

                surf(ax, rx, ry, rz, 'FaceAlpha',1, 'FaceColor',colorVal, 'EdgeColor','none');
            end
        end
        hold(ax,'off');

        switch viewCode
            case 'top',    view(ax, [0   90]);
            case 'front',  view(ax, [0    0]);
            case 'side',   view(ax, [90   0]);
            case 'iso',    view(ax, [-37.5 30]);
            case 'custom', view(ax, customAzEl);
        end

        try
            lighting(ax,'gouraud'); axes(ax); camlight('left');
        catch
        end

        drawnow limitrate nocallbacks;
        fr = getframe(gcf);
        im = frame2im(fr);
        writeVideo(vw, im);

        renderCount = renderCount + 1;
        frac = p0 + (1 - p0) * (renderCount / max(plannedCount,1));
        app.vizStep(frac, sprintf('Exporting movie… (%d/%d)', renderCount, plannedCount));
    end

    close(vw);
end

 
        function closeSafely(app, h)
            if isempty(h)
                return;
            end
            try
                if all(isvalid(h(:)))
                    close(h);
                end
            catch

            end
        end

        function G = getGeneNum(app)
            G = double(app.NumberofGenesDisplay.Value);
            if isempty(G) || ~isfinite(G) || G < 1
                G = 1;              
            end
            G = round(G);       
        end

        function geneRGBs = getGeneRGBsFromNetFile(app, GeneNum)

    file  = fullfile(app.ActiveFolder, app.NetFile);
    sheet = 'Gene Information';
    if ~isfile(file)
        warning('Network Settings file not found: %s', file);
        geneRGBs = repmat([0.75 0.75 0.75], max(1,GeneNum), 1);
        return;
    end

    lastRow = 3 + max(1, GeneNum);  
    try
        R = readmatrix(file, 'Sheet', sheet, 'Range', sprintf('E4:E%d', lastRow));
        G = readmatrix(file, 'Sheet', sheet, 'Range', sprintf('F4:F%d', lastRow));
        B = readmatrix(file, 'Sheet', sheet, 'Range', sprintf('G4:G%d', lastRow));
    catch

        R = readmatrix(file, 'Sheet', sheet, 'Range', sprintf('E4:E%d', lastRow), 'UseExcel', true);
        G = readmatrix(file, 'Sheet', sheet, 'Range', sprintf('F4:F%d', lastRow), 'UseExcel', true);
        B = readmatrix(file, 'Sheet', sheet, 'Range', sprintf('G4:G%d', lastRow), 'UseExcel', true);
    end

    n   = min([numel(R), numel(G), numel(B), GeneNum]);
    R   = R(1:n); G = G(1:n); B = B(1:n);
    R(~isfinite(R)) = 0; G(~isfinite(G)) = 0; B(~isfinite(B)) = 0;

    geneRGBs = [R(:), G(:), B(:)];

if max(geneRGBs,[],'all') > 1.5
    geneRGBs = geneRGBs ./ 255;
end

geneRGBs = max(0, min(1, geneRGBs));

zeroRow = all(geneRGBs == 0, 2);
geneRGBs(zeroRow, :) = 0.75;     


    if size(geneRGBs,1) < GeneNum
        padN = GeneNum - size(geneRGBs,1);
        geneRGBs = [geneRGBs; repmat([0.75 0.75 0.75], padN, 1)];
    elseif size(geneRGBs,1) > GeneNum
        geneRGBs = geneRGBs(1:GeneNum, :);
    end
end


    end

                       
    methods (Access = private)

        % Callback function: ParametersPanel, RunSimulationButton
        function RunSimulationButtonPushed(app, event)
           app.ensureInit();

           app.RefreshDiagramButtonPushed();

           %Save current parameters
           app.SaveParametersButtonPushed();

           

            
            %Clear Flag
            app.UIFigure.UserData.StopFlag = false;
            
            %Gather GUI inputs here
            params.population = app.PopulationSizeEditField.Value;
            params.radius = app.RadiusEditField.Value;
            params.Tmax = app.MaximumTimeEditField.Value;
            params.dt = app.TimeStepdtEditField.Value;
            params.alphaMin = app.AlphaMinSlider.Value;
            params.alphaMax = app.AlphaMaxSlider.Value;
            params.kappaG = app.kappaGEditField.Value;
            params.kappaF = app.kappaFEditField.Value;
            params.MorphogenStrength = app.MorphogenStrengthEditField.Value;
            params.HillCoefficient = app.HillCoefficientEditField.Value;
            params.DistancePower = app.DistancePowerEditField.Value;
            params.ShortRangeForceStrength = app.betaSEditField.Value;
            params.LongRangeForceStrength = app.betaLEditField.Value;
            params.GeneNum = app.NumberofGenesDisplay.Value;
            params.NumPathways = app.NumberofPathwaysDisplay.Value;
            params.friction = app.FrictionEditField.Value;

            %Custom Hill Coefficients
            params.UseCustomHillCoefficients = app.UseCustomHillCoefficientsCheckBox.Value;
            
            
            %Other
            params.sampleCount = app.TotalSimulationEditField.Value;
            params.parallelWorkers = str2double(app.ParallelPoolSizeDropDown.Value);
            
            %Optional parpool and save output files
            params.parallel = app.UseParallelPoolCheckBox.Value;

            %DataQueue
            dq = parallel.pool.DataQueue;
            afterEach(dq, @(data) app.updateFromQueue(data));
            
            %Progress Bar
            params.progressQueue = dq;  

            %Stop Flag
            params.stopCallback  = @() logical(getfield(app.UIFigure,'UserData').StopFlag);  
            
            app.initProgressSimulation(params.sampleCount);  % 40% prep + 60% sim


            %Call the simulationfunction
            send(dq, struct('kind','note','msg','Starting simulation...'));
            RunSimulation(params)
            app.finishProgress("Simulation complete!")
            
            %Update UI log status
            app.StatusLabel.Text = "Simulation complete!";

            %Auto-visualize if enabled
                if isprop(app,'AutoVisualizeCheckBox') && logical(app.AutoVisualizeCheckBox.Value)
                    try
                        app.StatusLabel.Text = "Visualizing results…";
                        drawnow;
                        % Reuse the existing button handler so we keep logic in one place
                        app.VisualizeResultsButtonPushed(event);
                    catch vizErr
                        uialert(app.UIFigure, getReport(vizErr), 'Auto-Visualization Error');
                    end
                end

            app.RefreshDropdownButtonPushed(event);


            
        end

        % Value changed function: PopulationSizeEditField
        function PopulationSizeEditFieldValueChanged(app, event)
            value = app.PopulationSizeEditField.Value;
            app.StatusLabel.Text = "Simulation complete!";
        end

        % Button pushed function: RefreshDiagramButton
        function RefreshDiagramButtonPushed(app, event)
app.ensureInit();

    try
        [gCount, pCount] = app.detectGeneAndPathwayCounts();

        if isprop(app,'NumberofGenesDisplay')
            app.NumberofGenesDisplay.Value = gCount;
        end
        if isprop(app,'NumberofPathwaysDisplay')
            app.NumberofPathwaysDisplay.Value = pCount;
        end
    catch ME
        warning('Count detection failed: %s', ME.message);
        return; % bail if we can't read counts
    end

    filename    = fullfile(app.ActiveFolder, app.NetFile);
    N           = gCount;        % number of genes
    NumPathways = pCount;        % number of pathways

N           = max(1, gCount);
NumPathways = max(1, pCount);

% Displays (numeric)
if isprop(app,'NumberofGenesDisplay') && ~isempty(app.NumberofGenesDisplay) && isvalid(app.NumberofGenesDisplay)
    app.NumberofGenesDisplay.Value = N;
end
if isprop(app,'NumberofPathwaysDisplay') && ~isempty(app.NumberofPathwaysDisplay) && isvalid(app.NumberofPathwaysDisplay)
    app.NumberofPathwaysDisplay.Value = NumPathways;
end

% Dropdown helpers
toItems = @(m) arrayfun(@num2str, 1:max(1,m), 'UniformOutput', false);


% PathwaySelectionDropDown
if isprop(app,'PathwaySelectionDropDown') && ~isempty(app.PathwaySelectionDropDown) && isvalid(app.PathwaySelectionDropDown)
    items = [{'All'}, arrayfun(@(k) sprintf('Pathway %d',k), 1:NumPathways, 'UniformOutput', false)];
    app.PathwaySelectionDropDown.Items = items;
    curVal = app.PathwaySelectionDropDown.Value;
    if isempty(curVal) || ~any(strcmp(curVal, items))
        app.PathwaySelectionDropDown.Value = 'All';
    end
end


R0 = 4;      % first data row
C0 = 3;      % first data col ("C")
sheetName = 'Gene Regulatory Network (K)';

% Build one rectangle that covers ALL pathways and BOTH (internal+external) blocks
totalRows = NumPathways * N;
totalCols = 2 * N;                    % internal N + external N
rangeAll  = sprintf('%s%d:%s%d', ...
    idx2col(C0), R0, ...
    idx2col(C0 + totalCols - 1), R0 + totalRows - 1);

GRN_FULL = readmatrix(filename, 'Sheet', sheetName, 'Range', rangeAll, 'UseExcel', false);
GRN_FULL(isnan(GRN_FULL)) = 0;


% Preallocate outputs
All_Internal     = cell(NumPathways,1);
All_External     = cell(NumPathways,1);
All_Adj_Internal = cell(NumPathways,1);
All_Adj_External = cell(NumPathways,1);

% Slice each pathway from the single big array
for p = 1:NumPathways
    r1 = (p-1)*N + 1;
    r2 =  p   *N;
    internal  = GRN_FULL(r1:r2, 1:N);
    external  = GRN_FULL(r1:r2, N+1:2*N);

    IntP = internal.';               % keep your convention
    ExtP = external.';

    All_Internal{p}     = IntP;
    All_External{p}     = ExtP;
    All_Adj_Internal{p} = double(IntP ~= 0);
    All_Adj_External{p} = double(ExtP ~= 0);
end


function s = idx2col(n)
    s = '';
    while n > 0
        r = mod(n-1, 26);
        s = [char(65 + r) s];
        n = floor((n-1)/26);
    end
end


selection = app.PathwaySelectionDropDown.Value;

if strcmp(selection, 'All')
    Adj_Internal = false(N);
    Adj_External = false(N);
    for p = 1:NumPathways
        Adj_Internal = Adj_Internal | (All_Adj_Internal{p} ~= 0);
        Adj_External = Adj_External | (All_Adj_External{p} ~= 0);
    end
    Adj_Internal = double(Adj_Internal);
    Adj_External = double(Adj_External);

else
    pathwayNum = sscanf(selection, 'Pathway %d');
    if isempty(pathwayNum) || pathwayNum < 1 || pathwayNum > NumPathways
        error('Invalid pathway selection: %s', selection);
    end
    Adj_Internal = All_Adj_Internal{pathwayNum};
    Adj_External = All_Adj_External{pathwayNum};
end

InternalInDegree  = sum(Adj_Internal, 1);
InternalOutDegree = sum(Adj_Internal, 2);
ExternalInDegree  = sum(Adj_External, 1);
ExternalOutDegree = sum(Adj_External, 2);

nodeLabels = arrayfun(@(i) ...
    sprintf('Int In=%d Out=%d\nExt In=%d Out=%d', ...
        InternalInDegree(i), InternalOutDegree(i), ...
        ExternalInDegree(i), ExternalOutDegree(i)), ...
    1:N, 'UniformOutput', false);

geneNames = arrayfun(@(n) sprintf('Gene %d', n), 1:N, 'UniformOutput', false);


% Generate symmetric XY layout around a vertical axis
layoutXY = zeros(N, 2);
radius = 1.3;

% Generate symmetric XY layout around a vertical axis
layoutXY = zeros(N, 2);
radius = 1.3;

if N == 1
    layoutXY = [0, 0];

elseif N == 2
    layoutXY = [-1, 0; 1, 0];

elseif N == 3
    angles = [pi/2, -pi/6, -5*pi/6];
    x = radius * cos(angles);
    y = radius * sin(angles);
    layoutXY = [x', y'];

elseif N == 4
    angles = deg2rad([45, -45, -135, -225]);  % square
    x = radius * cos(angles);
    y = radius * sin(angles);
    layoutXY = [x', y'];

elseif N == 5
    angles = deg2rad([90, 18, -54, -126, -198]);  % symmetric pentagon
    x = radius * cos(angles);
    y = radius * sin(angles);
    layoutXY = [x', y'];

elseif N == 6
    angles = deg2rad([90, 30, -30, -90, -150, 150]);  % hexagon
    x = radius * cos(angles);
    y = radius * sin(angles);
    layoutXY = [x', y'];

elseif N == 7
    angles = deg2rad([90, 38, -14, -66, -118, -170, 146]);  % heptagon
    x = radius * cos(angles);
    y = radius * sin(angles);
    layoutXY = [x', y'];

elseif N == 8
    angles = deg2rad([90, 45, 0, -45, -90, -135, 180, 135]);  % octagon
    x = radius * cos(angles);
    y = radius * sin(angles);
    layoutXY = [x', y'];

elseif N == 9
    angles = deg2rad([90, 50, 10, -30, -70, -110, -150, 170, 130]);  % 9-node
    x = radius * cos(angles);
    y = radius * sin(angles);
    layoutXY = [x', y'];

elseif N == 10
    angles = deg2rad([90, 54, 18, -18, -54, -90, -126, -162, -198, -234]); %10-node
    x = radius * cos(angles);
    y = radius * sin(angles);
    layoutXY = [x', y'];

else
    %generic regular-polygon fallback (top node at 12 o’clock)
    ang = linspace(pi/2, pi/2 - 2*pi, N+1);
    ang(end) = [];
    x = radius * cos(ang);  y = radius * sin(ang);
    layoutXY = [x', y'];
end



cla(app.NetworkAxes);
hold(app.NetworkAxes, 'on');

% Load mechanical data
mechFile = fullfile(app.ActiveFolder, app.NetFile);

startRow = 3;          % B3
startCol = 2;          % B
endRow   = startRow + N - 1;
endCol   = startCol + N - 1;

% Build ranges
longRange  = sprintf('B3:%s%d', excelCol(endCol), endRow);  % N×N block from B3
shortRange = sprintf('B2:B%d',  endRow - 1);                    % N×1 vector from B3

% Read
A_long       = readmatrix(mechFile, 'Sheet','Long-Range Force Network (β)',  'Range', longRange);
adhesionVals = readmatrix(mechFile, 'Sheet','Short-Range Force Network (α)', 'Range', shortRange);

% Clean and enforce shapes
A_long(isnan(A_long))         = 0;
adhesionVals(isnan(adhesionVals)) = 0;
A_long       = A_long(1:N, 1:N);
adhesionVals = adhesionVals(1:N, 1);

betaL = app.betaLEditField.Value;         % GUI value
A_mag = abs(A_long);                      % use magnitudes, ignore sign in sheet

if betaL > 0
    chemotaxisAttr = A_mag;               % all long-range -> attraction
    chemotaxisRep  = zeros(N);
elseif betaL < 0
    chemotaxisAttr = zeros(N);
    chemotaxisRep  = A_mag;               % all long-range -> repulsion
else
    chemotaxisAttr = zeros(N);
    chemotaxisRep  = zeros(N);            % beta_L == 0 -> no long-range
end

% Row/col involvement flags (unchanged logic, but now based on routed blocks)
attrRow = any(chemotaxisAttr ~= 0, 2);
attrCol = any(chemotaxisAttr ~= 0, 1).';
toCA    = attrRow | attrCol;

repRow  = any(chemotaxisRep  ~= 0, 2);
repCol  = any(chemotaxisRep  ~= 0, 1).';
toCR    = repRow | repCol;


% Row/col involvement flags (as in your original logic)
attrRow = any(chemotaxisAttr ~= 0, 2);
attrCol = any(chemotaxisAttr ~= 0, 1).';
toCA    = attrRow | attrCol;

repRow  = any(chemotaxisRep  ~= 0, 2);
repCol  = any(chemotaxisRep  ~= 0, 1).';
toCR    = repRow | repCol;

%Helper Function
function s = excelCol(c)
% Convert 1-based column index to Excel letters (1->A, 26->Z, 27->AA, ...)
    s = "";
    while c > 0
        r = mod(c-1, 26);
        s = char(r + double('A')) + s;
        c = floor((c - 1) / 26);
    end
    s = char(s);
end


    if app.ShowMechanicalRegulationCheckBox.Value
    
        % Add A, C_A (attraction), C_R (repulsion) to layout
        layoutXY = [layoutXY; [-0.8, -1.6]; [0.6, -1.6]; [1.0, -1.6]];
        A_idx   = N + 1;
        CA_idx  = N + 2;
        CR_idx  = N + 3;
    
        % Plot adhesion node
        scatter(app.NetworkAxes, layoutXY(A_idx,1), layoutXY(A_idx,2), 240, [0.8 0.8 0.8], 'filled', 'MarkerEdgeColor', 'k');
        text(app.NetworkAxes, layoutXY(A_idx,1), layoutXY(A_idx,2) - 0.18, ...
            'A', 'HorizontalAlignment', 'center', 'FontSize', 13, 'FontWeight', 'bold');
    
        % Plot chemotaxis nodes
        scatter(app.NetworkAxes, layoutXY(CA_idx,1), layoutXY(CA_idx,2), 240, [0.8 0.8 0.8], 'filled', 'MarkerEdgeColor', 'k');
        text(app.NetworkAxes, layoutXY(CA_idx,1), layoutXY(CA_idx,2) - 0.18, ...
            'C_A', 'HorizontalAlignment', 'center', 'FontSize', 13, 'FontWeight', 'bold');
    
        scatter(app.NetworkAxes, layoutXY(CR_idx,1), layoutXY(CR_idx,2), 240, [0.8 0.8 0.8], 'filled', 'MarkerEdgeColor', 'k');
        text(app.NetworkAxes, layoutXY(CR_idx,1), layoutXY(CR_idx,2) - 0.18, ...
            'C_R', 'HorizontalAlignment', 'center', 'FontSize', 13, 'FontWeight', 'bold');
    
        mechColor = [0.4 0.4 0.4];
        mechStyle = ':';
    
    arrowFrac = 0.90;
    removalLen = 9;
    arrowLen = 0.15;
    arrowW = 0.05;
    arrowShift = 0.05
    
    %Adhesion Arrows
    for i = 1:N
        if ~isnan(adhesionVals(i)) && adhesionVals(i) ~= 0
            x1 = layoutXY(i,1); y1 = layoutXY(i,2);
            x2 = layoutXY(A_idx,1); y2 = layoutXY(A_idx,2);
            mx = (x1 + x2)/2; my = (y1 + y2)/2;
            dx = x2 - x1; dy = y2 - y1;
            L = sqrt(dx^2 + dy^2); dx = dx/L; dy = dy/L;
            perpX = -dy; perpY = dx;
            cx = mx + 0.2 * perpX;
            cy = my + 0.2 * perpY;
            t = linspace(0,1,100);
            curveX = (1 - t).^2 * x1 + 2*(1 - t).*t*cx + t.^2 * x2;
            curveY = (1 - t).^2 * y1 + 2*(1 - t).*t*cy + t.^2 * y2;
    
            %Trim after arrowhead
            idx = round(arrowFrac * numel(t));
            idx = max(3, min(idx, length(t)-2));
            startCut = mod(idx + 1, length(t));
            endCut   = mod(startCut + removalLen - 1, length(t));
            if startCut == 0, startCut = 1; end
            if endCut == 0, endCut = 1; end
    
            if endCut < startCut
                seg1_X = curveX(1:endCut); seg1_Y = curveY(1:endCut);
                seg2_X = curveX(startCut:end); seg2_Y = curveY(startCut:end);
            else
                seg1_X = curveX(1:startCut-1); seg1_Y = curveY(1:startCut-1);
                seg2_X = curveX(endCut+1:end); seg2_Y = curveY(endCut+1:end);
            end
            plot(app.NetworkAxes, seg1_X, seg1_Y, mechStyle, 'Color', mechColor, 'LineWidth', 2);
            plot(app.NetworkAxes, seg2_X, seg2_Y, mechStyle, 'Color', mechColor, 'LineWidth', 2);
    
            %Arrowhead
            ux = curveX(idx+1) - curveX(idx-1);
            uy = curveY(idx+1) - curveY(idx-1);
            L = sqrt(ux^2 + uy^2); ux = ux/L; uy = uy/L;
            %Apply arrowShift along the unit direction
            ux = curveX(idx+1) - curveX(idx-1);
            uy = curveY(idx+1) - curveY(idx-1);
            L = sqrt(ux^2 + uy^2); ux = ux/L; uy = uy/L;
            
            tipX = curveX(idx) + arrowShift * ux;
            tipY = curveY(idx) + arrowShift * uy;
            baseX = tipX - arrowLen * ux; baseY = tipY - arrowLen * uy;
            perpX = -uy; perpY = ux;
            fill(app.NetworkAxes, ...
                [tipX, baseX + arrowW*perpX, baseX - arrowW*perpX], ...
                [tipY, baseY + arrowW*perpY, baseY - arrowW*perpY], ...
                mechColor, 'EdgeColor', mechColor, 'LineStyle', 'none');
        end
    end
    
      %Chemotaxis arrows (row OR column involvement) ===
    for i = 1:N
        if toCA(i)
            drawMechArrow(app.NetworkAxes, layoutXY, i, CA_idx, mechStyle, mechColor, ...
                          arrowFrac, removalLen, arrowLen, arrowW, arrowShift);
        end
        if toCR(i)
            drawMechArrow(app.NetworkAxes, layoutXY, i, CR_idx, mechStyle, mechColor, ...
                          arrowFrac, removalLen, arrowLen, arrowW, arrowShift);
        end
    end
end





        InternalColors = [
        0 0 1;         % 1 - Blue
        1 0 0;         % 2 - Red
        0 0.5 0;       % 3 - Dark Green
        0.75 0 0.75;   % 4 - Purple
        1 0.5 0;       % 5 - Orange
        0 0.7 0.7;     % 6 - Teal
        0.6 0.3 0;     % 7 - Brown
        0.5 0 0;       % 8 - Dark Red
        0 0 0;         % 9 - Black
        0.4 0.4 0.4    % 10 - Gray
    ];

ExternalColors = InternalColors;

if NumPathways > size(InternalColors,1)
    bigPal = lines(NumPathways);          % vivid, distinct palette
    InternalColors = bigPal;
    ExternalColors = bigPal;              % keep internal/external matched
end

%% All Pathways

if strcmp(selection, 'All')
    BaseGraph = digraph(zeros(N));
    plot(app.NetworkAxes, BaseGraph, ...
        'XData', layoutXY(1:N,1), ...
        'YData', layoutXY(1:N,2), ...
        'NodeLabel', {}, ...
        'NodeColor', 'k', ...
        'EdgeColor', 'none', ...
        'MarkerSize', 10);

    %Count edge usage and reversals
    InternalEdgeCount = zeros(N, N);
    ReverseEdgePresent = false(N, N);
    for p = 1:NumPathways
        Adj = All_Adj_Internal{p};
        InternalEdgeCount = InternalEdgeCount + Adj;
        ReverseEdgePresent = ReverseEdgePresent | (Adj' > 0);
    end

    %Draw internal arrows with curveห
    for p = 1:NumPathways
        Adj = All_Adj_Internal{p};
        for src = 1:N
            for tgt = 1:N
                if ~Adj(src, tgt), continue; end

                if src == tgt
                    continue; %skip loop for now, will use digraph overlay
                end

                x1 = layoutXY(src,1); y1 = layoutXY(src,2);
                x2 = layoutXY(tgt,1); y2 = layoutXY(tgt,2);

                hasOpposite  = InternalEdgeCount(tgt, src) > 0;
                hasMultiples = InternalEdgeCount(src, tgt) > 1;

                if true
                    %Curved line
                    mx = (x1 + x2)/2; my = (y1 + y2)/2;
                    dx = x2 - x1; dy = y2 - y1;
                    L = sqrt(dx^2 + dy^2) + eps;
                    dx = dx / L; dy = dy / L;
                    perpX = -dy; perpY = dx;
                    curvatureAmount = 0.4 * (p - (NumPathways + 1.5)/2);
                    cx = mx + curvatureAmount * perpX;
                    cy = my + curvatureAmount * perpY;

                    t = linspace(0,1,100);
                    curveX = (1 - t).^2 * x1 + 2*(1 - t).*t*cx + t.^2 * x2;
                    curveY = (1 - t).^2 * y1 + 2*(1 - t).*t*cy + t.^2 * y2;

                    %Trim curved line after arrowhead
                    arrowFrac = max(0.72, 0.88 - 0.04 * (p - 1));
                    arrowIdxSafe = max(3, min(round(arrowFrac * length(t)), length(t)-2));
                    
                    removalLen = round((1 - arrowFrac) * length(t)) - 2;
                    removalLen = max(removalLen, 3);

                    startCut = mod(arrowIdxSafe + 1, length(t));
                    endCut   = mod(startCut + removalLen - 1, length(t));
                    
                    if startCut == 0, startCut = 1; end
                    if endCut == 0, endCut = 1; end
                    
                    if endCut < startCut
                        seg1_X = curveX(1:endCut);
                        seg1_Y = curveY(1:endCut);
                        seg2_X = curveX(startCut:end);
                        seg2_Y = curveY(startCut:end);
                    else
                        seg1_X = curveX(1:startCut-1);
                        seg1_Y = curveY(1:startCut-1);
                        seg2_X = curveX(endCut+1:end);
                        seg2_Y = curveY(endCut+1:end);
                    end
                    
                    % Plot trimmed segments
                    plot(app.NetworkAxes, seg1_X, seg1_Y, '-', 'Color', InternalColors(p,:), 'LineWidth', 2);
                    plot(app.NetworkAxes, seg2_X, seg2_Y, '-', 'Color', InternalColors(p,:), 'LineWidth', 2);


                    % Fan out the arrowhead placement slightly by pathway index
                
                arrowIdx = round(arrowFrac * length(t));
                arrowIdx = max(4, min(arrowIdx, length(t)-2));
                dx = curveX(arrowIdx+1) - curveX(arrowIdx-1);
                dy = curveY(arrowIdx+1) - curveY(arrowIdx-1);

                    L = sqrt(dx^2 + dy^2) + eps;
                    ux = dx / L; uy = dy / L;
                    
                    arrowShift = 0.10
                    tipX = curveX(arrowIdx) + arrowShift * ux; 
                    tipY = curveY(arrowIdx) + arrowShift * uy;
                    perpX = -uy; perpY = ux;

                    %All Arrow Parameters
                    arrowLength = 0.20;   % Length from base to tip
                    arrowWidth  = 0.06;   % Half-width of the base

                    inhilength = 0.01;
                    inhiWidth = 0.06;

                    regVal = All_Internal{p}(src, tgt);
                    if regVal > 0
                        baseX = tipX - arrowLength * ux;
                        baseY = tipY - arrowLength * uy;
                        leftX  = baseX + arrowWidth * perpX;
                        leftY  = baseY + arrowWidth * perpY;
                        rightX = baseX - arrowWidth * perpX;
                        rightY = baseY - arrowWidth * perpY;
                        fill(app.NetworkAxes, [tipX, leftX, rightX], [tipY, leftY, rightY], ...
                             InternalColors(p,:), 'EdgeColor', InternalColors(p,:), 'LineStyle', 'none');
                    elseif regVal < 0
                        cx = tipX - (arrowShift * ux) - (inhilength * ux);
                        cy = tipY - (arrowShift * uy) - (inhilength * uy);
                        leftX = cx + inhiWidth * perpX;
                        leftY = cy + inhiWidth * perpY;
                        rightX = cx - inhiWidth * perpX;
                        rightY = cy - inhiWidth * perpY;
                        line(app.NetworkAxes, [leftX, rightX], [leftY, rightY], ...
                             'Color', InternalColors(p,:), 'LineWidth', 2.5);
                    end
                end
            end
        end
    end

% Define loop visual parameters
a_int = 0.34; b_int = 0.24;         % Internal loop size
a_ext = 0.42; b_ext = 0.22;         % External loop size
arrowLen = 0.22; arrowW = 0.055;
fanSpread = 2*pi/3;
protectedArc = pi/6;                % Reserved arc near center
maxLoops = 2 * NumPathways;         % interleaved internal + external

for loopType = 1:2  % 1 = internal, 2 = external
    for p = 1:NumPathways
        if loopType == 1
            Aloop = diag(diag(All_Adj_Internal{p}));
            style = '-'; 
            color = InternalColors(p,:);
            a = a_int; b = b_int;
            loopLabel = 'internal';
        else
            Aloop = diag(diag(All_Adj_External{p}));
            style = '--';  
            color = ExternalColors(p,:);
            a = a_ext; b = b_ext;
            loopLabel = 'external';
        end

        if ~any(Aloop(:)), continue; end

        disp(['Pathway ', num2str(p), ' ', loopLabel, ...
              ' self-loops: ', mat2str(diag(Aloop)')]);

        for i = 1:N
            if Aloop(i,i) == 0, continue; end

            %Parametric ellipse
            t = linspace(0, 2*pi, 100);
            ellipseLocal = [a * cos(t); b * sin(t)];

            %Outward radial angle of this node
            node = layoutXY(i,:)';
            theta = atan2(node(2), node(1));

            %Interleaved fan offset
            posIdx = 2*(p-1) + loopType - 1;  % 0-indexed slot
            fanOffset = -fanSpread/2 + (posIdx + 0.5) * (fanSpread / maxLoops);

            %Final rotation angle (local to node)
            rotationAngle = theta + fanOffset;

            %Rotate ellipse
            R = [cos(rotationAngle), -sin(rotationAngle);
                 sin(rotationAngle),  cos(rotationAngle)];
            ellipseRot = R * ellipseLocal;

            %Find apex (furthest point in direction of loop)
            dir = [cos(rotationAngle); sin(rotationAngle)];
            dots = ellipseRot' * dir;
            [~, idx_apex] = max(dots);
            apex = ellipseRot(:, idx_apex);

            %Align apex to node center
            loopX = ellipseRot(1,:) - apex(1) + node(1);
            loopY = ellipseRot(2,:) - apex(2) + node(2);
            
            %Final correction: Flip ellipse 180° around the node
            loopX = 2 * node(1) - loopX;
            loopY = 2 * node(2) - loopY;
            
            %Recalculate apex index after flip (for arrowhead)
            ellipseFlipped = [loopX; loopY] - node;  % now centered at origin
            dots = ellipseFlipped' * dir;
            [~, idx_apex] = max(dots);


            disp(['Drawing loop for Gene ', num2str(i), ...
                  ', Pathway ', num2str(p), ...
                  ', Type: ', loopLabel, ...
                  ', Style: ', style, ...
                  ', Color: ', mat2str(color)]);

            arrowOffset = -15;  %negative = earlier along loop

            removalLen = 12;  % Adjust this by trial
            arrowIdxSafe = mod(idx_apex + arrowOffset, length(t));
            startCut = mod(arrowIdxSafe + 1, length(t));
            endCut   = mod(startCut + removalLen - 1, length(t));
            
            if startCut == 0, startCut = 1; end
            if endCut == 0, endCut = 1; end
            
            if endCut < startCut
                seg1_X = loopX(1:endCut);
                seg1_Y = loopY(1:endCut);
                seg2_X = loopX(startCut:end);
                seg2_Y = loopY(startCut:end);
            else
                seg1_X = loopX(1:startCut-1);
                seg1_Y = loopY(1:startCut-1);
                seg2_X = loopX(endCut+1:end);
                seg2_Y = loopY(endCut+1:end);
            end
            
            plot(app.NetworkAxes, seg1_X, seg1_Y, style, 'Color', color, 'LineWidth', 2);
            plot(app.NetworkAxes, seg2_X, seg2_Y, style, 'Color', color, 'LineWidth', 2);

            arrowIdx = mod(idx_apex + arrowOffset, length(t));
            
            prevIdx = mod(arrowIdx - 1, length(t)) + 1;
            nextIdx = mod(arrowIdx + 1, length(t)) + 1;
            
            dx = loopX(nextIdx) - loopX(prevIdx);
            dy = loopY(nextIdx) - loopY(prevIdx);
            L = sqrt(dx^2 + dy^2) + eps;
            ux = dx / L; uy = dy / L;
            
            loopInset = -0.12;  
            tipX = loopX(arrowIdx) - loopInset * ux;
            tipY = loopY(arrowIdx) - loopInset * uy;
            baseX = tipX - arrowLen * ux;
            baseY = tipY - arrowLen * uy;
            perpX = -uy; perpY = ux;
            
            leftX  = baseX + arrowW * perpX;
            leftY  = baseY + arrowW * perpY;
            rightX = baseX - arrowW * perpX;
            rightY = baseY - arrowW * perpY;
            
            if loopType == 1
            regVal = All_Internal{p}(i, i);
            else
                regVal = All_External{p}(i, i);
            end
            
            if regVal > 0
                fill(app.NetworkAxes, [tipX, leftX, rightX], ...
                     [tipY, leftY, rightY], ...
                     color, 'EdgeColor', color, 'LineStyle', 'none');
            elseif regVal < 0
                cx = tipX - 0.075 * ux;
                cy = tipY - 0.075 * uy;
                leftX = cx + 0.06 * perpX;
                leftY = cy + 0.06 * perpY;
                rightX = cx - 0.06 * perpX;
                rightY = cy - 0.06 * perpY;
                line(app.NetworkAxes, [leftX, rightX], [leftY, rightY], ...
                     'Color', color, 'LineWidth', 2.5);
            end
        end
    end
end





    baseInternalCurve = 0.50;
    maxInternalOffset = baseInternalCurve * (NumPathways / 2);
    externalCurveBase = maxInternalOffset + 0.4;
    
    for p = 1:NumPathways
        externalCurveAmount = externalCurveBase + 0.3*(p - (NumPathways+1)/2);
    
      if loopType == 1
    loopLabel = 'internal';
else
    loopLabel = 'external';
end

disp(['Pathway ', num2str(p), ' ', loopLabel, ...
      ' self-loops: ', mat2str(diag(Aloop)')]);

        plotCurvedExternalEdges(app.NetworkAxes, layoutXY, ...
            All_Adj_External{p}, ...     % binary: for “is there an edge”
            All_External{p}, ...         % signed: for + / –
            '--', ExternalColors(p,:), externalCurveAmount);
    end

BaseGraph = digraph(zeros(N));
plot(app.NetworkAxes, BaseGraph, ...
    'XData', layoutXY(1:N,1), ...
    'YData', layoutXY(1:N,2), ...
    'NodeLabel', {}, ...
    'NodeColor', 'k', ...
    'EdgeColor', 'none', ...
    'MarkerSize', 10);

%% Single Pathway Mode
else
    pathwayNum = sscanf(selection, 'Pathway %d');
    if isempty(pathwayNum) || pathwayNum < 1 || pathwayNum > NumPathways
        error('Invalid pathway selection: %s', selection);
    end

    % Extract adjacency matrices
    Adj_Internal = All_Adj_Internal{pathwayNum};
    Adj_External = All_Adj_External{pathwayNum};

    internalColor = InternalColors(pathwayNum,:);
    externalColor = ExternalColors(pathwayNum,:);

    %Draw internal edges (Single Pathway Mode, All-Mode Logic)
for src = 1:N
    for tgt = 1:N
        if ~Adj_Internal(src, tgt) || src == tgt, continue; end

        x1 = layoutXY(src,1); y1 = layoutXY(src,2);
        x2 = layoutXY(tgt,1); y2 = layoutXY(tgt,2);

        hasOpposite  = Adj_Internal(tgt, src) > 0;
        hasMultiples = false;

        if hasOpposite || hasMultiples
            %Curved arrow
            mx = (x1 + x2)/2; my = (y1 + y2)/2;
            dx = x2 - x1; dy = y2 - y1;
            L = sqrt(dx^2 + dy^2) + eps;
            dx = dx / L; dy = dy / L;
            perpX = -dy; perpY = dx;
            curvatureAmount = 0.3;
            cx = mx + curvatureAmount * perpX;
            cy = my + curvatureAmount * perpY;

            t = linspace(0,1,100);
            curveX = (1 - t).^2 * x1 + 2*(1 - t).*t*cx + t.^2 * x2;
            curveY = (1 - t).^2 * y1 + 2*(1 - t).*t*cy + t.^2 * y2;

            %Trim curved line after arrowhead
            arrowFrac = 0.87;
            arrowIdxSafe = max(3, min(round(arrowFrac * length(t)), length(t)-2));
            removalLen = round((1 - arrowFrac) * length(t)) - 2;
            removalLen = max(removalLen, 3);

            startCut = mod(arrowIdxSafe + 1, length(t));
            endCut   = mod(startCut + removalLen - 1, length(t));

            if startCut == 0, startCut = 1; end
            if endCut == 0, endCut = 1; end

            if endCut < startCut
                seg1_X = curveX(1:endCut);
                seg1_Y = curveY(1:endCut);
                seg2_X = curveX(startCut:end);
                seg2_Y = curveY(startCut:end);
            else
                seg1_X = curveX(1:startCut-1);
                seg1_Y = curveY(1:startCut-1);
                seg2_X = curveX(endCut+1:end);
                seg2_Y = curveY(endCut+1:end);
            end

            plot(app.NetworkAxes, seg1_X, seg1_Y, '-', 'Color', internalColor, 'LineWidth', 2);
            plot(app.NetworkAxes, seg2_X, seg2_Y, '-', 'Color', internalColor, 'LineWidth', 2);

            %Arrowhead placement
            arrowIdx = round(arrowFrac * length(t));
            arrowIdx = max(4, min(arrowIdx, length(t)-2));

            dx = curveX(arrowIdx+1) - curveX(arrowIdx-1);
            dy = curveY(arrowIdx+1) - curveY(arrowIdx-1);
            L = sqrt(dx^2 + dy^2) + eps;
            ux = dx / L; uy = dy / L;

            arrowShift = 0.04;
            tipX = curveX(arrowIdx) + arrowShift * ux;
            tipY = curveY(arrowIdx) + arrowShift * uy;
            perpX = -uy; perpY = ux;

            arrowLength = 0.20;
            arrowWidth = 0.06;
            inhiLength = 0.01;
            inhiWidth = 0.06;

            regVal = All_Internal{pathwayNum}(src, tgt);
            if regVal > 0
                baseX = tipX - arrowLength * ux;
                baseY = tipY - arrowLength * uy;
                leftX  = baseX + arrowWidth * perpX;
                leftY  = baseY + arrowWidth * perpY;
                rightX = baseX - arrowWidth * perpX;
                rightY = baseY - arrowWidth * perpY;
                fill(app.NetworkAxes, [tipX, leftX, rightX], [tipY, leftY, rightY], ...
                     internalColor, 'EdgeColor', internalColor, 'LineStyle', 'none');
            elseif regVal < 0
                cx = tipX - inhiLength * ux;
                cy = tipY - inhiLength * uy;
                leftX = cx + inhiWidth * perpX;
                leftY = cy + inhiWidth * perpY;
                rightX = cx - inhiWidth * perpX;
                rightY = cy - inhiWidth * perpY;
                line(app.NetworkAxes, [leftX, rightX], [leftY, rightY], ...
                     'Color', internalColor, 'LineWidth', 2.5);
            end
        else
    %Straight arrow or inhibition
    arrowLength = 0.2;
    arrowWidth  = 0.06;
    arrowShift  = 0.2;
    inhiLength  = 0.2;
    inhiWidth   = 0.06;
    inhiShift   = 0.18;

    dx = x2 - x1; dy = y2 - y1;
    L = sqrt(dx^2 + dy^2) + eps;
    ux = dx / L; uy = dy / L;
    perpX = -uy; perpY = ux;

    regVal = All_Internal{pathwayNum}(src, tgt);

    %Trim line appropriately
    if regVal > 0
        x2_trim = x2 - (arrowLength + arrowShift) * ux;
        y2_trim = y2 - (arrowLength + arrowShift) * uy;
    else
        x2_trim = x2 - inhiShift * ux;
        y2_trim = y2 - inhiShift * uy;
    end

    plot(app.NetworkAxes, [x1 x2_trim], [y1 y2_trim], '-', ...
         'Color', internalColor, 'LineWidth', 2);

    %Arrowhead or inhibition marker
    tipX = x2 - (regVal > 0) * arrowShift * ux;
    tipY = y2 - (regVal > 0) * arrowShift * uy;

    if regVal > 0
        baseX = tipX - arrowLength * ux;
        baseY = tipY - arrowLength * uy;
        leftX  = baseX + arrowWidth * perpX;
        leftY  = baseY + arrowWidth * perpY;
        rightX = baseX - arrowWidth * perpX;
        rightY = baseY - arrowWidth * perpY;
        fill(app.NetworkAxes, [tipX, leftX, rightX], [tipY, leftY, rightY], ...
             internalColor, 'EdgeColor', internalColor, 'LineStyle', 'none');
    elseif regVal < 0
        cx = tipX - inhiLength * ux;
        cy = tipY - inhiLength * uy;
        leftX  = cx + inhiWidth * perpX;
        leftY  = cy + inhiWidth * perpY;
        rightX = cx - inhiWidth * perpX;
        rightY = cy - inhiWidth * perpY;
        line(app.NetworkAxes, [leftX, rightX], [leftY, rightY], ...
             'Color', internalColor, 'LineWidth', 2.5);
    end


        end
    end
end

a_int = 0.34; b_int = 0.24;
a_ext = 0.42; b_ext = 0.22;
arrowLen = 0.22; arrowW = 0.06;
fanSpread = 2*pi/3;
protectedArc = pi/6;
maxLoops = 2; 

for loopType = 1:2 
    if loopType == 1
        Aloop = diag(diag(Adj_Internal));
        style = '-'; 
        color = internalColor;
        a = a_int; b = b_int;
        loopLabel = 'internal';
    else
        Aloop = diag(diag(Adj_External));
        style = '--';  
        color = externalColor;
        a = a_ext; b = b_ext;
        loopLabel = 'external';
    end

    if ~any(Aloop(:)), continue; end

    disp(['Single Pathway ', num2str(pathwayNum), ' ', loopLabel, ...
          ' self-loops: ', mat2str(diag(Aloop)')]);

    for i = 1:N
        if Aloop(i,i) == 0, continue; end

        t = linspace(0, 2*pi, 100);
        ellipseLocal = [a * cos(t); b * sin(t)];

        node = layoutXY(i,:)';
        theta = atan2(node(2), node(1));
        posIdx = loopType - 1; 
        fanOffset = -fanSpread/2 + (posIdx + 0.5) * (fanSpread / maxLoops);
        rotationAngle = theta + fanOffset;

        R = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
        ellipseRot = R * ellipseLocal;

        dir = [cos(rotationAngle); sin(rotationAngle)];
        dots = ellipseRot' * dir;
        [~, idx_apex] = max(dots);
        apex = ellipseRot(:, idx_apex);

        loopX = ellipseRot(1,:) - apex(1) + node(1);
        loopY = ellipseRot(2,:) - apex(2) + node(2);

        loopX = 2 * node(1) - loopX;
        loopY = 2 * node(2) - loopY;

        ellipseFlipped = [loopX; loopY] - node;
        dots = ellipseFlipped' * dir;
        [~, idx_apex] = max(dots);

        %Trim loop before arrowhead (like All Pathways)
        arrowOffset = -15;  
        removalLen = 12;      
        arrowIdxSafe = mod(idx_apex + arrowOffset, length(t));
        startCut = mod(arrowIdxSafe + 1, length(t));
        endCut   = mod(startCut + removalLen - 1, length(t));
        
        if startCut == 0, startCut = 1; end
        if endCut == 0, endCut = 1; end
        
        if endCut < startCut
            seg1_X = loopX(1:endCut);
            seg1_Y = loopY(1:endCut);
            seg2_X = loopX(startCut:end);
            seg2_Y = loopY(startCut:end);
        else
            seg1_X = loopX(1:startCut-1);
            seg1_Y = loopY(1:startCut-1);
            seg2_X = loopX(endCut+1:end);
            seg2_Y = loopY(endCut+1:end);
        end
        
        plot(app.NetworkAxes, seg1_X, seg1_Y, style, 'Color', color, 'LineWidth', 2);
        plot(app.NetworkAxes, seg2_X, seg2_Y, style, 'Color', color, 'LineWidth', 2);


        arrowOffset = -15;
        arrowIdx = mod(idx_apex + arrowOffset, length(t));
        prevIdx = mod(arrowIdx - 1, length(t)) + 1;
        nextIdx = mod(arrowIdx + 1, length(t)) + 1;

        dx = loopX(nextIdx) - loopX(prevIdx);
        dy = loopY(nextIdx) - loopY(prevIdx);
        L = sqrt(dx^2 + dy^2) + eps;
        ux = dx / L; uy = dy / L;

        loopInset = -0.12; 
        tipX = loopX(arrowIdx) - loopInset * ux;
        tipY = loopY(arrowIdx) - loopInset * uy;
        baseX = tipX - arrowLen * ux;
        baseY = tipY - arrowLen * uy;
        perpX = -uy; perpY = ux;

        leftX  = baseX + arrowW * perpX;
        leftY  = baseY + arrowW * perpY;
        rightX = baseX - arrowW * perpX;
        rightY = baseY - arrowW * perpY;
        if loopType == 1
            regVal = All_Internal{pathwayNum}(i,i);
        else
            regVal = All_External{pathwayNum}(i,i);
        end
        
        if regVal > 0
            %Activation
            baseX = tipX - arrowLen * ux;
            baseY = tipY - arrowLen * uy;
            leftX  = baseX + arrowW * perpX;
            leftY  = baseY + arrowW * perpY;
            rightX = baseX - arrowW * perpX;
            rightY = baseY - arrowW * perpY;
            fill(app.NetworkAxes, [tipX, leftX, rightX], [tipY, leftY, rightY], ...
                 color, 'EdgeColor', color, 'LineStyle', 'none');
        elseif regVal < 0
            % Inhibition (flat bar)
            cx = tipX - 0.075 * ux;
            cy = tipY - 0.075 * uy;
            leftX = cx + 0.06 * perpX;
            leftY = cy + 0.06 * perpY;
            rightX = cx - 0.06 * perpX;
            rightY = cy - 0.06 * perpY;
            line(app.NetworkAxes, [leftX, rightX], [leftY, rightY], ...
                 'Color', color, 'LineWidth', 2.5);
        end

    end
end


   
 %Inline External Edges
curvatureAmount = 0.8; 
arrowShift = 0.04; 
arrowLength = 0.15;
arrowWidth  = 0.05;

N = size(Adj_External, 1);

W_ext = All_External{pathwayNum};


for src = 1:N
    for tgt = 1:N
        if Adj_External(src, tgt)
            regVal = W_ext(src, tgt);   % <-- signed value (+ activate, – inhibit)
            
            x1 = layoutXY(src,1); y1 = layoutXY(src,2);
            x2 = layoutXY(tgt,1); y2 = layoutXY(tgt,2);

            % Midpoint and direction
            mx = (x1 + x2) / 2;
            my = (y1 + y2) / 2;
            dx = x2 - x1; dy = y2 - y1;
            L = sqrt(dx^2 + dy^2) + eps;
            dx = dx / L; dy = dy / L;

            % Perpendicular control point
            perpX = -dy; perpY = dx;
            cx = mx + curvatureAmount * perpX;
            cy = my + curvatureAmount * perpY;

            % Generate curve
            t = linspace(0,1,100);
            curveX = (1 - t).^2 * x1 + 2*(1 - t).*t*cx + t.^2 * x2;
            curveY = (1 - t).^2 * y1 + 2*(1 - t).*t*cy + t.^2 * y2;

            % Trim after arrowhead
            arrowFrac = 0.87;
            arrowIdxSafe = max(3, min(round(arrowFrac * length(t)), length(t)-2));
            removalLen = 8;
            startCut = mod(arrowIdxSafe + 1, length(t));
            endCut   = mod(startCut + removalLen - 1, length(t));

            if startCut == 0, startCut = 1; end
            if endCut == 0, endCut = 1; end

            if endCut < startCut
                seg1_X = curveX(1:endCut);
                seg1_Y = curveY(1:endCut);
                seg2_X = curveX(startCut:end);
                seg2_Y = curveY(startCut:end);
            else
                seg1_X = curveX(1:startCut-1);
                seg1_Y = curveY(1:startCut-1);
                seg2_X = curveX(endCut+1:end);
                seg2_Y = curveY(endCut+1:end);
            end

            plot(app.NetworkAxes, seg1_X, seg1_Y, '--', 'Color', externalColor, 'LineWidth', 2);
            plot(app.NetworkAxes, seg2_X, seg2_Y, '--', 'Color', externalColor, 'LineWidth', 2);

            % === arrowhead / inhibition marker ===
            arrowIdx = round(arrowFrac * length(t));
            arrowIdx = max(3, min(arrowIdx, length(t)-2));

            dx = curveX(arrowIdx+1) - curveX(arrowIdx-1);
            dy = curveY(arrowIdx+1) - curveY(arrowIdx-1);
            L  = sqrt(dx^2 + dy^2) + eps;
            ux = dx / L; uy = dy / L;

            % shift a bit forward along curve
            tipX = curveX(arrowIdx) + arrowShift * ux;
            tipY = curveY(arrowIdx) + arrowShift * uy;

            baseX = tipX - arrowLength * ux;
            baseY = tipY - arrowLength * uy;
            perpX = -uy; perpY = ux;

            if regVal > 0
                % activation: triangle
                leftX  = baseX + arrowWidth * perpX;
                leftY  = baseY + arrowWidth * perpY;
                rightX = baseX - arrowWidth * perpX;
                rightY = baseY - arrowWidth * perpY;
                fill(app.NetworkAxes, [tipX, leftX, rightX], ...
                     [tipY, leftY, rightY], externalColor, ...
                     'EdgeColor', externalColor, 'LineStyle', 'none');
            elseif regVal < 0
                % inhibition: flat bar perpendicular to edge
                % (reuse same perpX/perpY, just draw a short segment)
                cx_bar = tipX - 0.05 * ux;   % pull back a bit
                cy_bar = tipY - 0.05 * uy;
                leftX  = cx_bar + 0.06 * perpX;
                leftY  = cy_bar + 0.06 * perpY;
                rightX = cx_bar - 0.06 * perpX;
                rightY = cy_bar - 0.06 * perpY;
                line(app.NetworkAxes, [leftX, rightX], [leftY, rightY], ...
                     'Color', externalColor, 'LineWidth', 2.5);
            else
                % regVal == 0 should not happen because Adj_External was true,
                % but we can just skip a marker here.
            end
        end
    end
end





    %Re-plot black gene nodes LAST so they are on top
    BaseGraph = digraph(zeros(N));
    plot(app.NetworkAxes, BaseGraph, ...
        'XData', layoutXY(1:N,1), ...
        'YData', layoutXY(1:N,2), ...
        'NodeLabel', {}, ...
        'NodeColor', 'k', ...
        'EdgeColor', 'none', ...
        'MarkerSize', 10);
end


    % Add gene labels
    for i = 1:N
        text(app.NetworkAxes, ...
            layoutXY(i,1), layoutXY(i,2) + 0.15, ...
            geneNames{i}, ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 12, ...
            'FontWeight', 'bold', ...
            'Interpreter', 'none');
    end

    % Degree info overlay if toggle on
    if app.ShowRegulationNumberCheckBox.Value
        for i = 1:N
            text(app.NetworkAxes, ...
                layoutXY(i,1), layoutXY(i,2) - 0.2, ...
                nodeLabels{i}, ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 10, ...
                'Color', [0.2 0.2 0.2], ...
                'Interpreter', 'none');
        end
    end

    % Final styling
    title(app.NetworkAxes, sprintf('%d-Node Genetic-Mechanical Regulatory Network', N));
    axis(app.NetworkAxes, 'equal');
    axis(app.NetworkAxes, 'off');
    hold(app.NetworkAxes, 'off');
    


function plotCurvedExternalEdges(ax, layoutXY, AdjMatrix, WMatrix, lineStyle, color, curvatureAmount)
    N = size(AdjMatrix,1);
    for src = 1:N
        for tgt = 1:N
            if AdjMatrix(src, tgt)
                w = WMatrix(src, tgt);
                x1 = layoutXY(src,1);
                y1 = layoutXY(src,2);
                x2 = layoutXY(tgt,1);
                y2 = layoutXY(tgt,2);

                % Midpoint between nodes
                mx = (x1 + x2) / 2;
                my = (y1 + y2) / 2;

                % Direction vector
                dx = x2 - x1;
                dy = y2 - y1;
                L = sqrt(dx^2 + dy^2) + eps;
                dx = dx / L;
                dy = dy / L;

                % Perpendicular direction
                perpX = -dy;
                perpY = dx;

                % Control point offset along perpendicular
                cx = mx + curvatureAmount * perpX;
                cy = my + curvatureAmount * perpY;

                % Generate Bezier curve
                t = linspace(0,1,100);
                curveX = (1 - t).^2 * x1 + 2*(1 - t).*t*cx + t.^2 * x2;
                curveY = (1 - t).^2 * y1 + 2*(1 - t).*t*cy + t.^2 * y2;

                %Trim after arrowhead
                removalLen = 8;
                arrowIdxSafe = max(3, min(round(0.87 * length(t)), length(t)-2));
                startCut = mod(arrowIdxSafe + 1, length(t));
                endCut   = mod(startCut + removalLen - 1, length(t));
                
                if startCut == 0, startCut = 1; end
                if endCut == 0, endCut = 1; end
                
                if endCut < startCut
                    seg1_X = curveX(1:endCut);
                    seg1_Y = curveY(1:endCut);
                    seg2_X = curveX(startCut:end);
                    seg2_Y = curveY(startCut:end);
                else
                    seg1_X = curveX(1:startCut-1);
                    seg1_Y = curveY(1:startCut-1);
                    seg2_X = curveX(endCut+1:end);
                    seg2_Y = curveY(endCut+1:end);
                end
                % draw the curve (same as before)
                plot(ax, seg1_X, seg1_Y, lineStyle, 'Color', color, 'LineWidth', 2);
                plot(ax, seg2_X, seg2_Y, lineStyle, 'Color', color, 'LineWidth', 2);

                % now, instead of always arrowhead:
                arrowIdx = round(0.87 * length(t) + 0.5);
                arrowIdx = max(3, min(arrowIdx, length(t)-2));

                dx = curveX(arrowIdx+1) - curveX(arrowIdx-1);
                dy = curveY(arrowIdx+1) - curveY(arrowIdx-1);
                L  = sqrt(dx^2 + dy^2) + eps;
                ux = dx / L; uy = dy / L;

                tipX = curveX(arrowIdx);
                tipY = curveY(arrowIdx);
                baseX = tipX - 0.15 * ux;
                baseY = tipY - 0.15 * uy;
                perpX = -uy; perpY = ux;

                if w > 0
                    % activation → triangle
                    leftX  = baseX + 0.05 * perpX;
                    leftY  = baseY + 0.05 * perpY;
                    rightX = baseX - 0.05 * perpX;
                    rightY = baseY - 0.05 * perpY;
                    fill(ax, [tipX, leftX, rightX], [tipY, leftY, rightY], ...
                         color, 'EdgeColor', color, 'LineStyle', 'none');
                elseif w < 0
                    % inhibition → flat bar perpendicular to direction
                    cx = tipX - 0.05 * ux;   % move a bit back
                    cy = tipY - 0.05 * uy;
                    leftX  = cx + 0.06 * perpX;
                    leftY  = cy + 0.06 * perpY;
                    rightX = cx - 0.06 * perpX;
                    rightY = cy - 0.06 * perpY;
                    line(ax, [leftX, rightX], [leftY, rightY], ...
                        'Color', color, 'LineWidth', 2.5);
                end
            end
        end
    end
end


function drawMechArrow(ax, layoutXY, srcIdx, dstIdx, mechStyle, mechColor, arrowFrac, removalLen, arrowLen, arrowW, arrowShift)
    x1 = layoutXY(srcIdx,1); y1 = layoutXY(srcIdx,2);
    x2 = layoutXY(dstIdx,1); y2 = layoutXY(dstIdx,2);

    mx = (x1 + x2)/2; my = (y1 + y2)/2;
    dx = x2 - x1; dy = y2 - y1; L = sqrt(dx^2 + dy^2) + eps;
    dx = dx / L; dy = dy / L;
    perpX = -dy; perpY = dx;
    cx = mx + 0.2 * perpX; cy = my + 0.2 * perpY;

    t = linspace(0,1,100);
    curveX = (1 - t).^2 * x1 + 2*(1 - t).*t*cx + t.^2 * x2;
    curveY = (1 - t).^2 * y1 + 2*(1 - t).*t*cy + t.^2 * y2;

    % trim after arrowhead
    idx = max(3, min(round(arrowFrac * numel(t)), numel(t)-2));
    startCut = mod(idx + 1, numel(t)); if startCut==0, startCut=1; end
    endCut   = mod(startCut + removalLen - 1, numel(t)); if endCut==0, endCut=1; end
    if endCut < startCut
        plot(ax, curveX(1:endCut),curveY(1:endCut), mechStyle, 'Color', mechColor, 'LineWidth', 2);
        plot(ax, curveX(startCut:end),curveY(startCut:end), mechStyle, 'Color', mechColor, 'LineWidth', 2);
    else
        plot(ax, curveX(1:startCut-1),curveY(1:startCut-1), mechStyle, 'Color', mechColor, 'LineWidth', 2);
        plot(ax, curveX(endCut+1:end),curveY(endCut+1:end), mechStyle, 'Color', mechColor, 'LineWidth', 2);
    end

    % arrowhead
    ux = curveX(idx+1) - curveX(idx-1);
    uy = curveY(idx+1) - curveY(idx-1);
    L = sqrt(ux^2 + uy^2) + eps; ux = ux/L; uy = uy/L;
    tipX  = curveX(idx) + arrowShift * ux;
    tipY  = curveY(idx) + arrowShift * uy;
    baseX = tipX - arrowLen * ux;
    baseY = tipY - arrowLen * uy;
    perpX = -uy; perpY = ux;
    fill(ax, [tipX, baseX + arrowW*perpX, baseX - arrowW*perpX], ...
            [tipY, baseY + arrowW*perpY, baseY - arrowW*perpY], ...
            mechColor, 'EdgeColor', mechColor, 'LineStyle', 'none');
end

        end

        % Value changed function: ShowRegulationNumberCheckBox
        function ShowRegulationNumberCheckBoxValueChanged(app, event)
           app.RefreshDiagramButtonPushed();
        
        end

        % Value changed function: PathwaySelectionDropDown
        function PathwaySelectionDropDownValueChanged(app, event)

            app.RefreshDiagramButtonPushed();
        end

        % Value changed function: AlphaMinSlider
        function AlphaMinSliderValueChanged(app, event)
            newVal = app.AlphaMinSlider.Value;
            newVal = max(0, min(1, newVal));

            if newVal > app.AlphaMaxSlider.Value
                newVal = app.AlphaMaxSlider.Value;
            end

            app.AlphaMinEditField.Value = newVal;
            app.AlphaMinSlider.Value = newVal;
        end

        % Value changed function: AlphaMinEditField
        function AlphaMinEditFieldValueChanged(app, event)
            newVal = app.AlphaMinEditField.Value;
            newVal = max(0, min(1, newVal));

            if newVal > app.AlphaMaxSlider.Value
                newVal = app.AlphaMaxSlider.Value;
            end

            app.AlphaMinEditField.Value = newVal;
            app.AlphaMinSlider.Value = newVal;
            
        end

        function AlphaMaxSliderValueChanged(app, event)
            newVal = app.AlphaMaxSlider.Value;
            newVal = max(0, min(1, newVal));
            if newVal < app.AlphaMinSlider.Value
                newVal = app.AlphaMinSlider.Value;
            end
            app.AlphaMaxEditField.Value = newVal;
            app.AlphaMaxSlider.Value    = newVal;
        end
        
        function AlphaMaxEditFieldValueChanged(app, event)
            newVal = app.AlphaMaxEditField.Value;
            newVal = max(0, min(1, newVal));
            if newVal < app.AlphaMinEditField.Value
                newVal = app.AlphaMinEditField.Value;
            end
            app.AlphaMaxEditField.Value = newVal;
            app.AlphaMaxSlider.Value    = newVal;
        end


        % Value changing function: AlphaMinSlider
        function AlphaMinSliderValueChanging(app, event)
            newVal = event.Value;
            newVal = max(0, min(1, newVal));

            if newVal > app.AlphaMaxSlider.Value
                newVal = app.AlphaMaxSlider.Value;
            end

            app.AlphaMinEditField.Value = newVal;
            
        end

        % Value changing function: AlphaMaxSlider
        function AlphaMaxSliderValueChanging(app, event)
            newVal = event.Value;
            newVal = max(0, min(1, newVal));

            if newVal < app.AlphaMinEditField.Value
                newVal = app.AlphaMinEditField.Value;
            end

            app.AlphaMaxEditField.Value = newVal;
            
        end

        % Button pushed function: StopCancelButton
        function StopCancelButtonPushed(app, event)
            app.UIFigure.UserData.StopFlag = true;
            
        end

        % Value changed function: TotalSimulationsSlider
        function TotalSimulationsSliderValueChanged(app, event)
            newVal = round(app.TotalSimulationsSlider.Value);
            newVal = max(1, min(500, newVal));

            app.TotalSimulationEditField.Value = newVal;
            app.TotalSimulationsSlider.Value = newVal;
        end

        % Value changed function: TotalSimulationEditField
        function TotalSimulationEditFieldValueChanged(app, event)
            newVal = round(app.TotalSimulationEditField.Value);
            newVal = max(1, min(500, newVal));

            app.TotalSimulationEditField.Value = newVal;
            app.TotalSimulationsSlider.Value = newVal;
        end

        % Value changing function: TotalSimulationsSlider
        function TotalSimulationsSliderValueChanging(app, event)
            newVal = round(event.Value);
            newVal = max(1, min(500, newVal));
            
            app.TotalSimulationEditField.Value = newVal;
            app.TotalSimulationsSlider.Value = newVal;
        end

        % Button pushed function: ResetParametersButton
        function ResetParametersButtonPushed(app, event)
            app.PopulationSizeEditField.Value = 1350;
            app.RadiusEditField.Value = 1;
            app.MaximumTimeEditField.Value = 50;

            app.AlphaMinSlider.Value = 0.65;
            app.AlphaMinEditField.Value = 0.65;
            app.AlphaMaxSlider.Value = 0.95;
            app.AlphaMaxEditField.Value = 0.95;

            app.kappaGEditField.Value = 0.0001;
            app.kappaFEditField.Value = 0.1;

            app.MorphogenStrengthEditField.Value = 0.0185;
            app.HillCoefficientEditField.Value = 2;
            app.DistancePowerEditField.Value = 2;

            app.betaSEditField.Value = 0.175;
            app.betaLEditField.Value = 0.125;

            app.ParallelPoolSizeDropDown.Value = '8';
            app.TotalSimulationEditField.Value = 8;
            app.TotalSimulationsSlider.Value = 8;
            
            app.UseParallelPoolCheckBox.Value = true;

            app.TimeStepdtEditField.Value = 0.2
            app.FrictionEditField.Value = 0
            
            if isprop(app, 'StatusLabel')
                app.StatusLabel.Text = 'Parameters reset to defaults.';
            end
        end

        % Button pushed function: VisualizeResultsButton
        function VisualizeResultsButtonPushed(app, event)
        app.vizInit();        
        app.ensureInit();

        %Save current parameters:
        app.SaveParametersButtonPushed();


    try
    % Gather user-specified parameters
    totalSims = app.TotalSimulationEditField.Value;
    radius = app.RadiusEditField.Value;

    % 1. Quick View PNGs (50%)
    app.VisualizeResultsAsPNGs(totalSims, radius);
    app.vizStep(0.20, "Generated quick-view PNGs");

    % 2. Gallery pages (20%)
    numPages = ceil(totalSims / 25);
    for page = 1:numPages
        app.renderGalleryViewAndSave(radius, page, totalSims);
        app.vizStep(0.20 + 0.20 * (page/numPages), ...
            sprintf("Rendered gallery page %d/%d…", page, numPages));
    end

    % 3. Gene expression (15%)
    app.VisualizeGeneExpressionOverTimeGraphs();
    app.vizStep(0.70, "Rendered gene expression time-series…");

    % 4. Shape descriptors (15%)
    app.VisualizeShapeDescriptorsOverTime();
    app.vizStep(1.00, "Rendered shape descriptors…");



        


        % 3. Refresh dropdown items
        mode = app.VisualizationModeDropDown.Value;
        if strcmp(mode, 'Gallery View')
            pageLabels = arrayfun(@(p) sprintf('Page %d', p), 1:numPages, 'UniformOutput', false);
            app.SimulationSelectionDropDown.Items = pageLabels;
            app.SimulationSelectionDropDown.Value = pageLabels{1};
            selected = 1;
        else
            simNumbers = arrayfun(@num2str, 1:totalSims, 'UniformOutput', false);
            app.SimulationSelectionDropDown.Items = simNumbers;
            app.SimulationSelectionDropDown.Value = simNumbers{1};
            selected = 1;
        end

        % 4. Immediately display first visualization
        if strcmp(mode, 'Quick View (PNG)')
            loadFinalSnapshotPNG(app, selected);
        elseif strcmp(mode, 'Interactive 3D View')
            cla(app.FinalVisualization);
            app.VisualizeResultsInteractive3D(selected, radius, app.FinalVisualization);
            rotate3d(app.FinalVisualization, 'on');
        elseif strcmp(mode, 'Gallery View')
            renderGalleryView(app, selected);
        end

        

        % 5. Update status
        app.StatusLabel.Text = "Visualization complete!";

try
    simVal = app.SimulationSelectionDropDown.Value;
    simIdx = str2double(simVal);
    if isnan(simIdx)
        simIdx = 1;  
    end

    app.populateSelectorItems();

    switch app.getCurrentMode()
        case 'gene'
            geneIdx = sscanf(app.SelectorDropDown.Value, 'Gene %d');
            if isempty(geneIdx), geneIdx = 1; end
            app.RenderGeneExpressionPNG(simIdx, geneIdx);

        case 'shape'
            app.RenderShapeDescriptorPNG(simIdx, app.SelectorDropDown.Value);
    end

catch err
    warning('Time-series render skipped: %s', err.message);
end



    catch ME
        uialert(app.UIFigure, getReport(ME), 'Visualization Error');
    end

app.RefreshDropdownButtonPushed(event);

        end

        % Button pushed function: RefreshDropdownButton
        function RefreshDropdownButtonPushed(app, event)
           app.ensureInit();

    outputFolders = dir('OUTPUT*');
    simNums = [];
    for i = 1:length(outputFolders)
        folderName = outputFolders(i).name;
        if outputFolders(i).isdir
            tokens = regexp(folderName, 'OUTPUT(\d+)', 'tokens');
            if ~isempty(tokens)
                simNums(end+1) = str2double(tokens{1}{1});
            end
        end
    end
    simNums = sort(simNums);

    app.SimulationSelectionDropDown.Items = arrayfun(@num2str, simNums, 'UniformOutput', false);

    if ~isempty(simNums)
        app.SimulationSelectionDropDown.Value = app.SimulationSelectionDropDown.Items{1};
    end
        end

        % Value changed function: SimulationSelectionDropDown
        function SimulationSelectionDropDownValueChanged(app, event)


    mode = app.VisualizationModeDropDown.Value;
    radius = app.RadiusEditField.Value;
    selection = app.SimulationSelectionDropDown.Value;
    geneSelection = app.SelectorDropDown.Value;
    geneIdx = sscanf(geneSelection, 'Gene %d');

    if strcmp(mode, 'Gallery View')
        pageNum = sscanf(selection, 'Page %d');
        if isempty(pageNum)
            uialert(app.UIFigure, 'Invalid gallery page selection.', 'Error');
            return;
        end
        renderGalleryView(app, pageNum);

    else
        simIdx = str2double(selection);
        if isnan(simIdx)
            uialert(app.UIFigure, 'Invalid simulation number.', 'Error');
            return;
        end
        if strcmp(mode, 'Quick View (PNG)')
            loadFinalSnapshotPNG(app, simIdx);
        elseif strcmp(mode, 'Interactive 3D View')
            cla(app.FinalVisualization);
            app.VisualizeResultsInteractive3D(simIdx, radius, app.FinalVisualization);
            rotate3d(app.FinalVisualization, 'on');
        end
    end

    switch app.getCurrentMode()
    case 'gene'
        simIdx = str2double(selection);
        geneIdx = sscanf(app.SelectorDropDown.Value, 'Gene %d');
        if isempty(geneIdx), geneIdx = 1; end
        app.RenderGeneExpressionPNG(simIdx, geneIdx);
    case 'shape'
        app.RenderShapeDescriptorPNG(simIdx, app.SelectorDropDown.Value);
    end

        end

        % Value changed function: VisualizationModeDropDown
        function VisualizationModeDropDownValueChanged(app, event)


    mode = app.VisualizationModeDropDown.Value;
try
    fig = ancestor(app.FinalVisualization,'figure');

    % Find only the az/el HUD label created in Interactive 3D
    hudList = findall(fig, 'Type', 'uilabel');
    for h = hudList'
        if isprop(h, 'Text') && contains(h.Text, 'az =') && contains(h.Text, 'el =')
            delete(h);
        end
    end

    % Stop and delete the periodic HUD timer if it exists
    t = getappdata(fig,'devsim_hudTimer');
    if ~isempty(t) && isvalid(t)
        stop(t);
        delete(t);
        rmappdata(fig,'devsim_hudTimer');
    end
catch
    % Ignore errors if nothing to clean up
end

    
    radius = app.RadiusEditField.Value;
    totalSims = app.TotalSimulationEditField.Value;

    % Build dropdown items
    if strcmp(mode, 'Gallery View')
        numPages = ceil(totalSims / 25);
        pageLabels = arrayfun(@(p) sprintf('Page %d', p), 1:numPages, 'UniformOutput', false);
        app.SimulationSelectionDropDown.Items = pageLabels;
        app.SimulationSelectionDropDown.Value = pageLabels{1};
        selected = 1;
    else
        simNumbers = arrayfun(@num2str, 1:totalSims, 'UniformOutput', false);
        app.SimulationSelectionDropDown.Items = simNumbers;
        app.SimulationSelectionDropDown.Value = simNumbers{1};
        selected = 1;
    end

    % Show initial view
    if strcmp(mode, 'Quick View (PNG)')
        loadFinalSnapshotPNG(app, selected);
        rotate3d(app.FinalVisualization, 'off');
    elseif strcmp(mode, 'Interactive 3D View')
        cla(app.FinalVisualization);
        app.VisualizeResultsInteractive3D(selected, radius, app.FinalVisualization);
        rotate3d(app.FinalVisualization, 'on');
    elseif strcmp(mode, 'Gallery View')
        renderGalleryView(app, selected);
        rotate3d(app.FinalVisualization, 'off');
    end



        end

        % Button pushed function: EditNetworkButton
        function EditNetworkButtonPushed(app, event)
         app.ensureInit();   

        filename = fullfile(app.ActiveFolder, app.NetFile);
            if isfile(filename)
                if ismac
                    system(['open -a "Microsoft Excel" "', filename, '"']);
                elseif ispc
                    winopen(filename);
                else
                    open(filename);
                end
            else
                uialert(app.UIFigure, 'Network Settings.xlsx not found.', 'File Error');
            end
        end

        function EditParametersButtonPushed(app, ~)
            app.ensureInit();
            filename = fullfile(app.ActiveFolder, app.SimFile);  % UserParams.xlsx
            if isfile(filename)
                if ismac
                    system(['open -a "Microsoft Excel" "', filename, '"']);
                elseif ispc
                    winopen(filename);
                else
                    open(filename);
                end
            else
                uialert(app.UIFigure, 'UserParams.xlsx not found.', 'File Error');
            end
        end


        % Value changed function: NumberofGenesDropDown
        function NumberofGenesDropDownValueChanged(app, event)
          newGeneNum = str2double(app.NumberofGenesDropDown.Value);

          newItems = ["All"]
          for i = 1:newGeneNum
        newItems(end+1) = string(i);
        end
    
        app.SelectorDropDown.Items = newItems;

        app.RefreshDiagramButtonPushed();

        if strcmp(app.getCurrentMode(), 'gene')
            app.populateSelectorItems();
        end

            
        end

        % Value changed function: NumberofPathwaysDropDown
        function NumberofPathwaysDropDownValueChanged(app, event)

    NumPathways = str2double(app.NumberofPathwaysDropDown.Value);

    items = {'All'};
    for p = 1:NumPathways
        items{end+1} = sprintf('Pathway %d', p);
    end

    app.PathwaySelectionDropDown.Items = items;
    app.RefreshDiagramButtonPushed();
        end

        % Value changed function: SelectorDropDown
        function SelectorDropDownValueChanged(app, event)

  simIdx = str2double(app.SimulationSelectionDropDown.Value);
if isnan(simIdx), return; end

switch app.getCurrentMode()
    case 'gene'
        geneIdx = sscanf(app.SelectorDropDown.Value, 'Gene %d');
        if isempty(geneIdx), geneIdx = 1; end
        app.RenderGeneExpressionPNG(simIdx, geneIdx);
    case 'shape'
        app.RenderShapeDescriptorPNG(simIdx, app.SelectorDropDown.Value);
end


        end

        % Value changed function: ShowMechanicalRegulationCheckBox
        function ShowMechanicalRegulationCheckBoxValueChanged(app, event)
            app.RefreshDiagramButtonPushed();
        end

        % Selection changed function: ButtonGroup
        function ButtonGroupSelectionChanged(app, event)
            app.populateSelectorItems();

            simIdx = str2double(app.SimulationSelectionDropDown.Value);
            if isnan(simIdx), return; end
        
            switch app.getCurrentMode()
                case 'gene'
                    geneIdx = sscanf(app.SelectorDropDown.Value, 'Gene %d');
                    if isempty(geneIdx), geneIdx = 1; end
                    app.RenderGeneExpressionPNG(simIdx, geneIdx);
                case 'shape'
                    app.RenderShapeDescriptorPNG(simIdx, app.SelectorDropDown.Value);
          
            end
        end

        function SaveParametersButtonPushed(app, ~)
            app.ensureInit();  
            try
                simPath = fullfile(app.ActiveFolder, app.SimFile);
                app.writeSim2Col(simPath);   
                app.setDirty(false);
                app.StatusLabel.Text = "Saved → " + string(simPath);
            catch ME
                uialert(app.UIFigure, sprintf('Save failed:\n%s', ME.message), 'Save Error');
            end
        end



        function LoadParametersButtonPushed(app, event)
            app.ensureInit();
            try
                if isprop(app,'IsDirty') && app.IsDirty
                    c = uiconfirm(app.UIFigure, ...
                        "Unsaved parameter changes will be lost. Continue?", ...
                        "Load Parameters", 'Options',{'Load','Cancel'}, ...
                        'DefaultOption',1,'CancelOption',2);
                    if ~strcmp(c,'Load'), return; end
                end
                simPath = fullfile(app.ActiveFolder, app.SimFile);
                app.loadSim2Col(simPath);
                if ismethod(app,'setDirty'), app.setDirty(false); end
                if isprop(app,'StatusLabel')
                    app.StatusLabel.Text = "Loaded ← " + string(simPath);  % <— add this
                end
            catch ME
                uialert(app.UIFigure, sprintf('Load failed:\n%s', ME.message), 'Load Error');
            end
        end


        function LoadTemplateButtonPushed(app, ~)
    app.ensureInit();
    try
        packPath = app.pickTemplatePack();
        if packPath == "" || packPath == "", return; end

        c = uiconfirm(app.UIFigure, ...
            "Load this template and replace ALL active parameter files (UserParams, Network Settings)?", ...
            "Load Template", 'Options',{'Load','Cancel'}, ...
            'DefaultOption',1,'CancelOption',2);
        if ~strcmp(c,'Load'), return; end

        req = {app.SimFile, app.NetFile}; % only these two now
        for k = 1:numel(req)
            if ~isfile(fullfile(packPath, req{k}))
                uialert(app.UIFigure, sprintf('Template is missing: %s', req{k}), 'Template Error');
                return;
            end
        end

        % Copy the pack into Active (overwrite)
        copyfile(fullfile(packPath, app.SimFile), fullfile(app.ActiveFolder, app.SimFile), 'f');
        copyfile(fullfile(packPath, app.NetFile), fullfile(app.ActiveFolder, app.NetFile), 'f');

        % Reload GUI from the new Active set
        app.loadSim2Col(fullfile(app.ActiveFolder, app.SimFile));
        app.loadNetwork(fullfile(app.ActiveFolder, app.NetFile));
        if ismethod(app,'setDirty'), app.setDirty(false); end

        if ismethod(app,'scanTemplatePacks'), app.scanTemplatePacks(); end
        if isprop(app,'StatusLabel')
            [~,pn] = fileparts(packPath);
            app.StatusLabel.Text = sprintf('Template loaded: %s', pn);
        end
    catch ME
        uialert(app.UIFigure, sprintf('Template load failed:\n%s', ME.message), 'Template Error');
    end
end


        function ExportTemplateButtonPushed(app, ~)
    app.ensureInit();
    try
        % ensure latest GUI params are saved
        app.writeSim2Col(fullfile(app.ActiveFolder, app.SimFile));

        defaultName = datestr(now,'yyyymmdd_HHMM');
        answer = inputdlg({'Template name:'}, 'Export Template', 1, {defaultName});
        if isempty(answer), return; end
        packName = strtrim(answer{1});
        if packName == "", return; end

        outDir = fullfile(app.TemplatesFolder, packName);
        if isfolder(outDir)
            c = uiconfirm(app.UIFigure, ...
                sprintf('Template "%s" already exists. Overwrite?', packName), ...
                'Overwrite Template', 'Options',{'Overwrite','Cancel'}, ...
                'DefaultOption',1,'CancelOption',2);
            if ~strcmp(c,'Overwrite'), return; end
        else
            mkdir(outDir);
        end

        copyfile(fullfile(app.ActiveFolder, app.SimFile), fullfile(outDir, app.SimFile), 'f');
        copyfile(fullfile(app.ActiveFolder, app.NetFile), fullfile(outDir, app.NetFile), 'f');

        if ismethod(app,'scanTemplatePacks'), app.scanTemplatePacks(); end
        if isprop(app,'StatusLabel')
            app.StatusLabel.Text = sprintf('Exported template: %s', packName);
        end
    catch ME
        uialert(app.UIFigure, sprintf('Export failed:\n%s', ME.message), 'Export Error');
    end
end


        % Value changed function: ParallelPoolSizeDropDown
        function ParallelPoolSizeDropDownValueChanged(app, event)
            value = app.ParallelPoolSizeDropDown.Value;
            
        end

        % Button pushed function: ExportImagesButton
        function ExportImagesButtonPushed(app, event)
              app.ensureInit();

            entries = dir();
            outNames = {};
            for k = 1:numel(entries)
                if entries(k).isdir
                    name = entries(k).name;
                    if ~startsWith(name, '.') && ~isempty(regexp(name, '^OUTPUT\d+$', 'once'))
                        outNames{end+1} = name;
                    end
                end
            end
            if isempty(outNames)
                uialert(app.UIFigure, ...
                    'No folders named OUTPUT# were found in the current directory.', ...
                    'Nothing to Export', 'Icon', 'warning');
                return;
            end
        
            destRoot = uigetdir(pwd, 'Choose destination folder for exported results');
            if isequal(destRoot, 0), return; end

            defaultName = sprintf('DevSim_Exports_%s', datestr(now, 'yyyymmdd_HHMMSS'));
            answer = inputdlg({'Parent folder name (will contain OUTPUT folders):'}, ...
                              'Export Results', 1, {defaultName});
            if isempty(answer), return; end
            parentName = strtrim(answer{1});
            if parentName == "", parentName = defaultName; end
        
            parentPath = fullfile(destRoot, parentName);
            if ~isfolder(parentPath)
                [ok, msg] = mkdir(parentPath);
                if ~ok
                    uialert(app.UIFigure, sprintf('Failed to create folder:\n%s\n\n%s', parentPath, msg), ...
                        'Export Error', 'Icon', 'error');
                    return;
                end
            end
        
            d = uiprogressdlg(app.UIFigure, ...
                'Title','Exporting', ...
                'Message','Preparing…', ...
                'Indeterminate','off', ...
                'Cancelable','off');
            cleaner = onCleanup(@() (isvalid(d) && delete(d)));
            
            n = numel(outNames);
            for i = 1:n
                d.Value = (i-0.999)/n;
                name = outNames{i};
                d.Message = sprintf('Copying PNGs from %s (%d/%d)…', name, i, n);
            
                src  = fullfile(pwd, name);
                dest = fullfile(parentPath, name);
            
                try
                    pngs = dir(fullfile(src,'*.png'));
                    if isempty(pngs)
                        continue;
                    end
            
                    if ~isfolder(dest)
                        mkdir(dest);
                    end
                    [ok,msg,msgid] = copyfile(fullfile(src,'*.png'), dest, 'f'); 
                    if ~ok
                        warning('DevSim export: failed to copy PNGs %s -> %s : %s (%s)', src, dest, msg, msgid);
                    end
                catch ME
                    warning('DevSim export: skipping %s due to error: %s', name, ME.message);
                end
            end

            galleryPngs = dir(fullfile(pwd,'OUTPUT_Page*.png'));
            if ~isempty(galleryPngs)
                for k = 1:numel(galleryPngs)
                    copyfile(fullfile(pwd,galleryPngs(k).name), parentPath, 'f');
                end
            end

            d.Value = 1;
            d.Message = 'Done.';
            pause(0.2);
            if isvalid(d), delete(d); end
            
            if isprop(app, 'StatusLabel')
                app.StatusLabel.Text = sprintf('Exported PNGs from %d OUTPUT folders to %s', n, parentPath);
            end

        end

        % Button pushed function: ExportMovieButton
        function ExportMovieButtonPushed(app, event)

            try
                app.ensureInit();
            
                defaultSim = "1";
                try
                    v = app.SimulationSelectionDropDown.Value;
                    vi = str2double(v);
                    if ~isnan(vi), defaultSim = v; end
                end
                TmaxUI = app.MaximumTimeEditField.Value;
                r      = app.RadiusEditField.Value;
            
                prompt   = {'Output # (e.g., 1):', ...
                            sprintf('Start time (0 .. %g):', TmaxUI), ...
                            sprintf('End time (0 .. %g):',   TmaxUI), ...
                            'Frames per second (FPS):'};
                dlgtitle = 'Export Movie Settings';
                definput = {defaultSim, '0', num2str(TmaxUI), '30'};
                answer   = inputdlg(prompt, dlgtitle, [1 60], definput);
                if isempty(answer), return; end
            
                simIdx = str2double(answer{1});
                tStart = str2double(answer{2});
                tEnd   = str2double(answer{3});
                fps    = str2double(answer{4});
                if any(isnan([simIdx,tStart,tEnd,fps])) || simIdx<1 || fps<=0
                    uialert(app.UIFigure, 'Invalid settings.', 'Export Movie');
                    return;
                end
                tStart = max(0, min(TmaxUI, tStart));
                tEnd   = max(0, min(TmaxUI, tEnd));
                if tEnd < tStart
                    uialert(app.UIFigure, 'End time must be ≥ Start time.', 'Export Movie');
                    return;
                end
            
                strideLabels = {'Full (1×)','Half (2×)','Quarter (4×)','Eighth (8×)','Custom…'};
                strideVals   = [1 2 4 8 -1];
                [sel, ok] = listdlg('PromptString','Resolution (frame stride):', ...
                                    'SelectionMode','single', ...
                                    'ListString',strideLabels, ...
                                    'InitialValue',1, ...
                                    'Name','Resolution');
                if ~ok, return; end
                stride = strideVals(sel);
                if stride == -1
                    ans2 = inputdlg({'Custom stride (positive integer):'}, 'Custom Resolution', 1, {'3'});
                    if isempty(ans2), return; end
                    stride = max(1, round(str2double(ans2{1})));
                    if isnan(stride) || stride<1
                        uialert(app.UIFigure, 'Stride must be a positive integer.', 'Export Movie'); return;
                    end
                end

                % ---- View / Camera selection ----
                viewLabels = { ...
                    'Top (X–Y plane)', ...
                    'Front (X–Z plane)', ...
                    'Side (Y–Z plane)', ...
                    'Isometric', ...
                    'Custom az,el…' };
                viewCodes  = {'top','front','side','iso','custom'};
                
                [isel, ok] = listdlg('PromptString','Choose movie viewpoint:', ...
                                     'SelectionMode','single', ...
                                     'ListString',viewLabels, ...
                                     'InitialValue',4, ...   
                                     'Name','View');
                if ~ok, return; end
                viewCode   = viewCodes{isel};
                customAzEl = [];
                if strcmp(viewCode,'custom')
                    ansV = inputdlg({'Azimuth (-180..180):','Elevation (-90..90):'}, ...
                                     'Custom View', 1, {'-165','-70'});
                    if isempty(ansV), return; end
                    customAzEl = [str2double(ansV{1}), str2double(ansV{2})];
                    if any(isnan(customAzEl))
                        uialert(app.UIFigure, 'Invalid azimuth/elevation.', 'Export Movie');
                        return;
                    end
                end


                [file, path] = uiputfile({'*.mp4','MPEG-4 Video (*.mp4)'}, ...
                                         'Save Movie As', sprintf('OUTPUT%d_movie.mp4', simIdx));
                if isequal(file,0), return; end
                outFile = fullfile(path, file);
            
                app.vizInit();
                app.vizStep(0.02, "Scanning frames…");
            
                app.ExportMovieForSim(simIdx, fps, tStart, tEnd, r, outFile, stride, viewCode, customAzEl);

            
                app.vizDone();
                app.StatusLabel.Text = "Movie export complete!";
            catch ME
                try, app.vizDone(); end 
                uialert(app.UIFigure, getReport(ME,'basic','hyperlinks','off'), 'Export Movie Error');
            end

        end

        % Button pushed function: ExportOutputFilesButton
        function ExportOutputFilesButtonPushed(app, event)
app.ensureInit();

    entries  = dir();
    outNames = {};
    for k = 1:numel(entries)
        if entries(k).isdir
            name = entries(k).name;
            if ~startsWith(name, '.') && ~isempty(regexp(name, '^OUTPUT\d+$', 'once'))
                outNames{end+1} = name; 
            end
        end
    end

    if isempty(outNames)
        uialert(app.UIFigure, ...
            'No folders named OUTPUT# were found in the current directory.', ...
            'Nothing to Export', 'Icon', 'warning');
        return;
    end


    destRoot = uigetdir(pwd, 'Choose destination folder for exported results');
    if isequal(destRoot, 0), return; end

    defaultName = sprintf('DevSim_Outputs_%s', datestr(now, 'yyyymmdd_HHMMSS'));
    answer = inputdlg({'Parent folder name (will contain OUTPUT and Active folders and gallery ):'}, ...
                      'Export Full Outputs', 1, {defaultName});
    if isempty(answer), return; end
    parentName = strtrim(answer{1});
    if parentName == "", parentName = defaultName; end

    parentPath = fullfile(destRoot, parentName);
    if ~isfolder(parentPath)
        [ok, msg] = mkdir(parentPath);
        if ~ok
            uialert(app.UIFigure, sprintf('Failed to create folder:\n%s\n\n%s', parentPath, msg), ...
                'Export Error', 'Icon', 'error');
            return;
        end
    end

    d = uiprogressdlg(app.UIFigure, ...
        'Title','Exporting', ...
        'Message','Preparing…', ...
        'Indeterminate','off', ...
        'Cancelable','off');
    cleaner = onCleanup(@() (isvalid(d) && delete(d)));

    nOut = numel(outNames);
    step = 0;
    totalSteps = nOut + 1 + 1; 

    for i = 1:nOut
        step = step + 1;
        d.Value   = step / totalSteps;
        name      = outNames{i};
        d.Message = sprintf('Copying all files from %s (%d/%d)…', name, i, nOut);

        src  = fullfile(pwd, name);
        dest = fullfile(parentPath, name);

        try
            if ~isfolder(dest), mkdir(dest); end
            [ok,msg,msgid] = copyfile(fullfile(src,'*'), dest, 'f');
            if ~ok
                warning('DevSim export: failed to copy %s -> %s : %s (%s)', src, dest, msg, msgid);
            end
        catch ME
            warning('DevSim export: skipping %s due to error: %s', name, ME.message);
        end
    end

    step = step + 1;
    d.Value   = step / totalSteps;
    d.Message = 'Copying gallery images (if any)…';

    try
        galleryPngs = dir(fullfile(pwd,'OUTPUT_Page*.png'));
        if ~isempty(galleryPngs)
            for k = 1:numel(galleryPngs)
                [ok,msg,msgid] = copyfile(fullfile(pwd, galleryPngs(k).name), parentPath, 'f');
                if ~ok
                    warning('DevSim export: failed to copy gallery %s -> %s : %s (%s)', ...
                        galleryPngs(k).name, parentPath, msg, msgid);
                end
            end
        end
    catch ME
        warning('DevSim export: gallery copy error: %s', ME.message);
    end

    step = step + 1;
    d.Value   = step / totalSteps;
    d.Message = 'Copying Active/ parameters (if present)…';

    try
        activeSrc = fullfile(pwd, 'Active');
        if isfolder(activeSrc)
            activeDest = fullfile(parentPath, 'Active');
            if ~isfolder(activeDest), mkdir(activeDest); end
            [ok,msg,msgid] = copyfile(fullfile(activeSrc,'*'), activeDest, 'f');
            if ~ok
                warning('DevSim export: failed to copy Active/ -> %s : %s (%s)', activeDest, msg, msgid);
            end
        else
            warning('DevSim export: Active/ folder not found; skipping parameter snapshot.');
        end
    catch ME
        warning('DevSim export: Active/ copy error: %s', ME.message);
    end

    d.Value   = 1;
    d.Message = 'Done.';
    pause(0.2);
    if isvalid(d), delete(d); end

    if isprop(app, 'StatusLabel')
        app.StatusLabel.Text = sprintf('Exported %d OUTPUT folders to %s', nOut, parentPath);
    end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1089 731];
            app.UIFigure.Name = 'MATLAB App';

            % Create ParametersPanel
            app.ParametersPanel = uipanel(app.UIFigure);
            app.ParametersPanel.TitlePosition = 'centertop';
            app.ParametersPanel.Title = 'Parameters';
            app.ParametersPanel.Scrollable = 'on';
            app.ParametersPanel.FontSize = 18;
            app.ParametersPanel.Position = [11 240 267 482];

            % Create kappaGEditField
            app.kappaGEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.kappaGEditField.Limits = [0 Inf];
            app.kappaGEditField.Position = [150 239 101 22];
            app.kappaGEditField.Value = 0.0001;

            % Create kappaFEditField
            app.kappaFEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.kappaFEditField.Limits = [0 Inf];
            app.kappaFEditField.Position = [150 212 101 22];
            app.kappaFEditField.Value = 0.1;

            % Create ResetParametersButton
            app.ResetParametersButton = uibutton(app.ParametersPanel, 'push');
            app.ResetParametersButton.ButtonPushedFcn = createCallbackFcn(app, @ResetParametersButtonPushed, true);
            app.ResetParametersButton.FontSize = 18;
            app.ResetParametersButton.Position = [22 9 211 31];
            app.ResetParametersButton.Text = 'Reset Parameters';

            % Create PopulationSizeEditFieldLabel
            app.PopulationSizeEditFieldLabel = uilabel(app.ParametersPanel);
            app.PopulationSizeEditFieldLabel.HorizontalAlignment = 'right';
            app.PopulationSizeEditFieldLabel.Position = [-34 424 130 22];

            % Text part (system font, no interpreter)
            app.PopulationSizeEditFieldLabel.Interpreter = 'none';
            app.PopulationSizeEditFieldLabel.Text = 'Population Size';
            
            % Math part (right next to it)
            app.PopulationSizeMathLabel = uilabel(app.ParametersPanel);
            app.PopulationSizeMathLabel.Interpreter = 'latex';
            app.PopulationSizeMathLabel.Text = ' $(N_{\mathrm{C}})$';
            % Position it just to the right of the first label:
            basePos = app.PopulationSizeEditFieldLabel.Position; % [x y w h]
            app.PopulationSizeMathLabel.Position = [basePos(1)+basePos(3)+4, basePos(2), 60, basePos(4)];

            % Create PopulationSizeEditField
            app.PopulationSizeEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.PopulationSizeEditField.ValueChangedFcn = createCallbackFcn(app, @PopulationSizeEditFieldValueChanged, true);
            app.PopulationSizeEditField.Position = [151 422 101 26];
            app.PopulationSizeEditField.Value = 1350;

            % Create AlphaMinLabel
            app.AlphaMinLabel = uilabel(app.ParametersPanel);
            app.AlphaMinLabel.HorizontalAlignment = 'center';
            app.AlphaMinLabel.Position = [13 311 36 30];

            app.AlphaMinLabel.Interpreter = 'latex';
            app.AlphaMinLabel.Text = '$\alpha_{\min}$';

            % Create AlphaMinSlider
            app.AlphaMinSlider = uislider(app.ParametersPanel);
            app.AlphaMinSlider.Limits = [0 1];
            app.AlphaMinSlider.MajorTicks = [0 1];
            app.AlphaMinSlider.ValueChangedFcn = createCallbackFcn(app, @AlphaMinSliderValueChanged, true);
            app.AlphaMinSlider.ValueChangingFcn = createCallbackFcn(app, @AlphaMinSliderValueChanging, true);
            app.AlphaMinSlider.Position = [66 329 130 3];
            app.AlphaMinSlider.Value = 0.65;

            % Create RadiusEditFieldLabel
            app.RadiusEditFieldLabel = uilabel(app.ParametersPanel);
            app.RadiusEditFieldLabel.Position = [13 396 38 22];

            app.RadiusEditFieldLabel.Interpreter = 'none';
            app.RadiusEditFieldLabel.Text = 'Radius';
            rPos = app.RadiusEditFieldLabel.Position;
            app.RadiusMathLabel = uilabel(app.ParametersPanel);
            app.RadiusMathLabel.Interpreter = 'latex';
            app.RadiusMathLabel.Text = ' $(l)$';
            app.RadiusMathLabel.Position = [rPos(1)+rPos(3)+4, rPos(2), 40, rPos(4)];


            % Create RadiusEditField
            app.RadiusEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.RadiusEditField.Limits = [0 Inf];
            app.RadiusEditField.Position = [151 396 101 22];
            app.RadiusEditField.Value = 1;

            % Create MaximumTimeEditFieldLabel
            app.MaximumTimeEditFieldLabel = uilabel(app.ParametersPanel);
            app.MaximumTimeEditFieldLabel.Position = [13 366 83 22];

            app.MaximumTimeEditFieldLabel.Interpreter = 'none';
            app.MaximumTimeEditFieldLabel.Text = 'Maximum Time';
            mtPos = app.MaximumTimeEditFieldLabel.Position;
            app.MaximumTimeMathLabel = uilabel(app.ParametersPanel);
            app.MaximumTimeMathLabel.Interpreter = 'latex';
            app.MaximumTimeMathLabel.Text = ' $(t_{\max})$';
            app.MaximumTimeMathLabel.Position = [mtPos(1)+mtPos(3)+4, mtPos(2), 70, mtPos(4)];


            % Create MaximumTimeEditField
            app.MaximumTimeEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.MaximumTimeEditField.Limits = [0 Inf];
            app.MaximumTimeEditField.Position = [151 366 100 22];
            app.MaximumTimeEditField.Value = 50;

            % Create AlphaMaxEditField
            app.AlphaMaxEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.AlphaMaxEditField.Limits = [0 1];
            app.AlphaMaxEditField.ValueChangedFcn = createCallbackFcn(app, @AlphaMaxEditFieldValueChanged, true);
            app.AlphaMaxEditField.Position = [213 282 39 22];
            app.AlphaMaxEditField.Value = 0.95;

            % Create AlphaMinEditField
            app.AlphaMinEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.AlphaMinEditField.Limits = [0 1];
            app.AlphaMinEditField.ValueChangedFcn = createCallbackFcn(app, @AlphaMinEditFieldValueChanged, true);
            app.AlphaMinEditField.Position = [212 308 40 22];
            app.AlphaMinEditField.Value = 0.65;

            % Create AlphaMaxSliderLabel
            app.AlphaMaxSliderLabel = uilabel(app.ParametersPanel);
            app.AlphaMaxSliderLabel.HorizontalAlignment = 'center';
            app.AlphaMaxSliderLabel.Position = [13 277 36 30];

            app.AlphaMaxSliderLabel.Interpreter = 'latex';
            app.AlphaMaxSliderLabel.Text = '$\alpha_{\max}$';

            % Create AlphaMaxSlider
            app.AlphaMaxSlider = uislider(app.ParametersPanel);
            app.AlphaMaxSlider.Limits = [0 1];
            app.AlphaMaxSlider.MajorTicks = [0 1];
            app.AlphaMaxSlider.ValueChangedFcn = createCallbackFcn(app, @AlphaMaxSliderValueChanged, true);
            app.AlphaMaxSlider.ValueChangingFcn = createCallbackFcn(app, @AlphaMaxSliderValueChanging, true);
            app.AlphaMaxSlider.Position = [63 295 130 3];
            app.AlphaMaxSlider.Value = 0.95;

            % Create GeneNoisekappaGLabel
            app.GeneNoisekappaGLabel = uilabel(app.ParametersPanel);
            app.GeneNoisekappaGLabel.HorizontalAlignment = 'center';
            app.GeneNoisekappaGLabel.Position = [10 239 64 22];

            app.GeneNoisekappaGLabel.Interpreter = 'none';
            app.GeneNoisekappaGLabel.Text = 'Gene Noise';
            gnPos = app.GeneNoisekappaGLabel.Position;
            app.GeneNoiseMathLabel = uilabel(app.ParametersPanel);
            app.GeneNoiseMathLabel.Interpreter = 'latex';
            app.GeneNoiseMathLabel.Text = ' $(\kappa_{\mathrm{G}})$';
            app.GeneNoiseMathLabel.Position = [gnPos(1)+gnPos(3)+4, gnPos(2), 90, gnPos(4)];


            % Create ForceNoisekappaFLabel
            app.ForceNoisekappaFLabel = uilabel(app.ParametersPanel);
            app.ForceNoisekappaFLabel.Position = [11 211 65 22];

            app.ForceNoisekappaFLabel.Interpreter = 'none';
            app.ForceNoisekappaFLabel.Text = 'Force Noise';
            fnPos = app.ForceNoisekappaFLabel.Position;
            app.ForceNoiseMathLabel = uilabel(app.ParametersPanel);
            app.ForceNoiseMathLabel.Interpreter = 'latex';
            app.ForceNoiseMathLabel.Text = ' $(\kappa_{r})$';
            app.ForceNoiseMathLabel.Position = [fnPos(1)+fnPos(3)+4, fnPos(2), 80, fnPos(4)];


            % Create MorphogenStrengthLabel
            % Morphogen Production label (2-line)
            app.MorphogenStrengthLabel = uilabel(app.ParametersPanel);
            app.MorphogenStrengthLabel.Interpreter = 'none';
            app.MorphogenStrengthLabel.Position = [12 177 64 30];  
            app.MorphogenStrengthLabel.Text = {'Morphogen', 'Production'};

            mpPos = app.MorphogenStrengthLabel.Position;
            app.MorphogenMathLabel = uilabel(app.ParametersPanel);
            app.MorphogenMathLabel.Interpreter = 'latex';
            app.MorphogenMathLabel.Text = ' $(M)$';
            app.MorphogenMathLabel.Position = [mpPos(1)+mpPos(3)+4, mpPos(2), 40, mpPos(4)];


            % Create MorphogenStrengthEditField
            app.MorphogenStrengthEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.MorphogenStrengthEditField.Limits = [0 Inf];
            app.MorphogenStrengthEditField.Position = [150 183 101 22];
            app.MorphogenStrengthEditField.Value = 0.0185;


            % Plain text label (no LaTeX)
            app.DistancePowerDLabel = uilabel(app.ParametersPanel);
            app.DistancePowerDLabel.Interpreter = 'none';
            app.DistancePowerDLabel.Text        = 'Distance Power';
            app.DistancePowerDLabel.Position    = [12 152 103 22];
            

                        % Create DistancePowerEditField
            app.DistancePowerEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.DistancePowerEditField.Limits = [0 Inf];
            app.DistancePowerEditField.Position = [150 152 101 22];
            app.DistancePowerEditField.Value = 2;
            
            % LaTeX badge just for "(D)", placed to the left of the field
            dpPos = app.DistancePowerEditField.Position;   
            app.DistancePowerMathLabel = uilabel(app.ParametersPanel);
            app.DistancePowerMathLabel.Interpreter         = 'latex';
            app.DistancePowerMathLabel.HorizontalAlignment = 'right';
            app.DistancePowerMathLabel.Text                = ' $(D)$';
            app.DistancePowerMathLabel.Position            = [dpPos(1)-52, dpPos(2)-2, 24, dpPos(4)];

            % --- Short-range force (betaS) ---

            % Label (two-line, regular font)
            app.ShortRangeForceStrengthbetaSLabel = uilabel(app.ParametersPanel);
            app.ShortRangeForceStrengthbetaSLabel.Position    = [12 118 107 30];
            app.ShortRangeForceStrengthbetaSLabel.Interpreter = 'none';
            app.ShortRangeForceStrengthbetaSLabel.Text        = {'Short-Range Force '; 'Strength'};
            
            % The numeric field (must be created BEFORE we query its Position)
            app.betaSEditField = uieditfield(app.ParametersPanel,'numeric');
            app.betaSEditField.Limits   = [0 Inf];
            app.betaSEditField.Position = [150 120 101 22];
            app.betaSEditField.Value    = 0.175;
            
            % LaTeX badge: K_alpha, placed just to the left of the field
            bsPos = app.betaSEditField.Position;
            app.BetaSMathLabel = uilabel(app.ParametersPanel);
            app.BetaSMathLabel.Interpreter = 'latex';
            app.BetaSMathLabel.Text        = ' $(K_{\alpha})$';
            app.BetaSMathLabel.HorizontalAlignment = 'right';
            app.BetaSMathLabel.Position    = [bsPos(1)-135, bsPos(2)-7.5, 74, bsPos(4)];


            % --- Long-range force (betaL) ---
            
            % Label (two-line, regular font)
            app.LongRangeForceStrengthbetaLLabel = uilabel(app.ParametersPanel);
            app.LongRangeForceStrengthbetaLLabel.Position    = [12 84 107 30];
            app.LongRangeForceStrengthbetaLLabel.Interpreter = 'none';
            app.LongRangeForceStrengthbetaLLabel.Text        = {'Long-Range Force'; 'Strength'};
            
            % Numeric field (create BEFORE querying Position)
            app.betaLEditField = uieditfield(app.ParametersPanel,'numeric');
            app.betaLEditField.Limits   = [-Inf Inf];   % keep your original range
            app.betaLEditField.Position = [150 88 101 22];
            app.betaLEditField.Value    = 0.125;
            
            % LaTeX badge: K_beta, placed just to the left of the field
            blPos = app.betaLEditField.Position;
            app.BetaLMathLabel = uilabel(app.ParametersPanel);
            app.BetaLMathLabel.Interpreter = 'latex';
            app.BetaLMathLabel.Text        = ' $(K_{\beta})$';
            app.BetaLMathLabel.HorizontalAlignment = 'right';
            app.BetaLMathLabel.Position    = [blPos(1)-135, blPos(2)-7.5, 74, blPos(4)];


            % Create TimeStepdtEditFieldLabel
            app.TimeStepdtEditFieldLabel = uilabel(app.ParametersPanel);
            app.TimeStepdtEditFieldLabel.Position = [13 338 55 22];

            app.TimeStepdtEditFieldLabel.Interpreter = 'none';
            app.TimeStepdtEditFieldLabel.Text = 'Time Step';
            tsPos = app.TimeStepdtEditFieldLabel.Position;
            app.TimeStepMathLabel = uilabel(app.ParametersPanel);
            app.TimeStepMathLabel.Interpreter = 'latex';
            app.TimeStepMathLabel.Text = ' $(\Delta T)$';
            app.TimeStepMathLabel.Position = [tsPos(1)+tsPos(3)+4, tsPos(2), 70, tsPos(4)];


            % Create TimeStepdtEditField
            app.TimeStepdtEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.TimeStepdtEditField.Limits = [0 Inf];
            app.TimeStepdtEditField.Position = [151 338 100 22];
            app.TimeStepdtEditField.Value = 0.2;

            % Create FrictionCoefficientLabel
            app.FrictionCoefficientLabel = uilabel(app.ParametersPanel);
            app.FrictionCoefficientLabel.Position = [13 53 106 30];
            app.FrictionCoefficientLabel.Text = 'Friction Coefficient';

            % Create FrictionEditField
            app.FrictionEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.FrictionEditField.Limits = [0 Inf];
            app.FrictionEditField.Position = [150 57 101 22];

            % Create VisualizationPanel
            app.VisualizationPanel = uipanel(app.UIFigure);
            app.VisualizationPanel.TitlePosition = 'centertop';
            app.VisualizationPanel.Title = 'Visualization';
            app.VisualizationPanel.FontSize = 18;
            app.VisualizationPanel.Position = [727 12 353 710];

            % Create GeneExpressionOverTimeGraph
            app.GeneExpressionOverTimeGraph = uiaxes(app.VisualizationPanel);
            title(app.GeneExpressionOverTimeGraph, 'Expression Over Time')
            app.GeneExpressionOverTimeGraph.XTick = [];
            app.GeneExpressionOverTimeGraph.YTick = [];
            app.GeneExpressionOverTimeGraph.Position = [4 444 344 236];

            % Create FinalVisualization
            app.FinalVisualization = uiaxes(app.VisualizationPanel);
            title(app.FinalVisualization, 'Final Visualization')
            app.FinalVisualization.XTick = [];
            app.FinalVisualization.YTick = [];
            app.FinalVisualization.Box = 'on';
            app.FinalVisualization.Position = [4 164 345 246];

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.VisualizationPanel);
            app.ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroupSelectionChanged, true);
            app.ButtonGroup.BorderWidth = 0;
            app.ButtonGroup.Position = [218 407 130 42];

            % Create GeneExpressionButton
            app.GeneExpressionButton = uiradiobutton(app.ButtonGroup);
            app.GeneExpressionButton.Text = 'Gene Expression';
            app.GeneExpressionButton.Position = [1 24 113 22];
            app.GeneExpressionButton.Value = true;

            % Create ShapeDescriptionsButton
            app.ShapeDescriptionsButton = uiradiobutton(app.ButtonGroup);
            app.ShapeDescriptionsButton.Text = 'Shape Descriptions';
            app.ShapeDescriptionsButton.Position = [1 1 127 22];

            % Create ExportMovieButton
            app.ExportMovieButton = uibutton(app.VisualizationPanel, 'push');
            app.ExportMovieButton.ButtonPushedFcn = createCallbackFcn(app, @ExportMovieButtonPushed, true);
            app.ExportMovieButton.FontSize = 18;
            app.ExportMovieButton.Position = [191 20 152 31];
            app.ExportMovieButton.Text = 'Export Movie';

            % Create VisualizeResultsButton
            app.VisualizeResultsButton = uibutton(app.VisualizationPanel, 'push');
            app.VisualizeResultsButton.ButtonPushedFcn = createCallbackFcn(app, @VisualizeResultsButtonPushed, true);
            app.VisualizeResultsButton.FontSize = 18;
            app.VisualizeResultsButton.Position = [142 59 200 31];
            app.VisualizeResultsButton.Text = 'Visualize Results';

            % Create AutoVisualizeCheckBox
            app.AutoVisualizeCheckBox = uicheckbox(app.VisualizationPanel);
            app.AutoVisualizeCheckBox.Text = '';
            app.AutoVisualizeCheckBox.Position = [16 59 14 31];
            app.AutoVisualizeCheckBox.Value = true;

            % Create AutoVisualizeAfterSimulationLabel
            app.AutoVisualizeAfterSimulationLabel = uilabel(app.VisualizationPanel);
            app.AutoVisualizeAfterSimulationLabel.HorizontalAlignment = 'center';
            app.AutoVisualizeAfterSimulationLabel.Position = [39 59 90 30];
            app.AutoVisualizeAfterSimulationLabel.Text = {'Auto-Visualize'; 'After Simulation'};

            % Create SimulationSelectionDropDownLabel
            app.SimulationSelectionDropDownLabel = uilabel(app.VisualizationPanel);
            app.SimulationSelectionDropDownLabel.HorizontalAlignment = 'right';
            app.SimulationSelectionDropDownLabel.Position = [9 139 115 22];
            app.SimulationSelectionDropDownLabel.Text = 'Simulation Selection';

            % Create SimulationSelectionDropDown
            app.SimulationSelectionDropDown = uidropdown(app.VisualizationPanel);
            app.SimulationSelectionDropDown.Items = {'1'};
            app.SimulationSelectionDropDown.ValueChangedFcn = createCallbackFcn(app, @SimulationSelectionDropDownValueChanged, true);
            app.SimulationSelectionDropDown.Position = [139 139 100 22];
            app.SimulationSelectionDropDown.Value = '1';

            % Create RefreshDropdownButton
            app.RefreshDropdownButton = uibutton(app.VisualizationPanel, 'push');
            app.RefreshDropdownButton.ButtonPushedFcn = createCallbackFcn(app, @RefreshDropdownButtonPushed, true);
            app.RefreshDropdownButton.FontSize = 10;
            app.RefreshDropdownButton.Position = [247 139 99 22];
            app.RefreshDropdownButton.Text = 'Refresh Dropdown';

            % Create VisualizationModeDropDownLabel
            app.VisualizationModeDropDownLabel = uilabel(app.VisualizationPanel);
            app.VisualizationModeDropDownLabel.HorizontalAlignment = 'right';
            app.VisualizationModeDropDownLabel.Position = [16 104 106 22];
            app.VisualizationModeDropDownLabel.Text = 'Visualization Mode';

            % Create VisualizationModeDropDown
            app.VisualizationModeDropDown = uidropdown(app.VisualizationPanel);
            app.VisualizationModeDropDown.Items = {'Quick View (PNG)', 'Interactive 3D View', 'Gallery View'};
            app.VisualizationModeDropDown.ValueChangedFcn = createCallbackFcn(app, @VisualizationModeDropDownValueChanged, true);
            app.VisualizationModeDropDown.Position = [137 104 132 22];
            app.VisualizationModeDropDown.Value = 'Quick View (PNG)';

            % Create SelectorDropDown
            app.SelectorDropDown = uidropdown(app.VisualizationPanel);
            app.SelectorDropDown.Items = {'Gene 1', 'Gene 2', 'Gene 3'};
            app.SelectorDropDown.ValueChangedFcn = createCallbackFcn(app, @SelectorDropDownValueChanged, true);
            app.SelectorDropDown.Position = [23 417 174 22];
            app.SelectorDropDown.Value = 'Gene 2';

            % Create ExportImagesButton
            app.ExportImagesButton = uibutton(app.VisualizationPanel, 'push');
            app.ExportImagesButton.ButtonPushedFcn = createCallbackFcn(app, @ExportImagesButtonPushed, true);
            app.ExportImagesButton.FontSize = 18;
            app.ExportImagesButton.Position = [23 20 152 31];
            app.ExportImagesButton.Text = 'Export Images';

            % Create GeneticMechanicalRegulatoryNetworkPanel
            app.GeneticMechanicalRegulatoryNetworkPanel = uipanel(app.UIFigure);
            app.GeneticMechanicalRegulatoryNetworkPanel.TitlePosition = 'centertop';
            app.GeneticMechanicalRegulatoryNetworkPanel.Title = 'Genetic-Mechanical Regulatory Network';
            app.GeneticMechanicalRegulatoryNetworkPanel.FontSize = 18;
            app.GeneticMechanicalRegulatoryNetworkPanel.Position = [289 62 426 242];

            % Create EditNetworkButton
            app.EditNetworkButton = uibutton(app.GeneticMechanicalRegulatoryNetworkPanel, 'push');
            app.EditNetworkButton.ButtonPushedFcn = createCallbackFcn(app, @EditNetworkButtonPushed, true);
            app.EditNetworkButton.FontSize = 18;
            app.EditNetworkButton.Position = [11 169 196 31];
            app.EditNetworkButton.Text = 'Edit Network';

            % Create EditParametersButton
            app.EditParametersButton = uibutton(app.GeneticMechanicalRegulatoryNetworkPanel, 'push');
            app.EditParametersButton.ButtonPushedFcn = createCallbackFcn(app, @EditParametersButtonPushed, true);
            app.EditParametersButton.FontSize = 18;
            app.EditParametersButton.Position = [11 129 196 31];
            app.EditParametersButton.Text = 'Edit Parameters';

            % Create NumberofGenesDropDownLabel
            app.NumberofGenesDropDownLabel = uilabel(app.GeneticMechanicalRegulatoryNetworkPanel);
            app.NumberofGenesDropDownLabel.HorizontalAlignment = 'right';
            app.NumberofGenesDropDownLabel.Position = [12 91 100 22];
            app.NumberofGenesDropDownLabel.Text = 'Number of Genes';

            %read-only numeric field for display
            app.NumberofGenesDisplay = uieditfield(app.GeneticMechanicalRegulatoryNetworkPanel, 'numeric');
            app.NumberofGenesDisplay.Position = [153 87 48 22];
            app.NumberofGenesDisplay.Editable = 'off';
            app.NumberofGenesDisplay.Tooltip = 'Detected from Excel (read-only)';

            % Create NumberofPathwaysDropDownLabel
            app.NumberofPathwaysDropDownLabel = uilabel(app.GeneticMechanicalRegulatoryNetworkPanel);
            app.NumberofPathwaysDropDownLabel.HorizontalAlignment = 'right';
            app.NumberofPathwaysDropDownLabel.Position = [13 59 117 22];
            app.NumberofPathwaysDropDownLabel.Text = 'Number of Pathways';

            % read-only numeric field for display
            app.NumberofPathwaysDisplay = uieditfield(app.GeneticMechanicalRegulatoryNetworkPanel, 'numeric');
            app.NumberofPathwaysDisplay.Position = [153 58 48 22];
            app.NumberofPathwaysDisplay.Editable = 'off';
            app.NumberofPathwaysDisplay.Tooltip = 'Detected from Excel (read-only)';

            % Create GlobalHillCoefficientLabel
            app.GlobalHillCoefficientLabel = uilabel(app.GeneticMechanicalRegulatoryNetworkPanel);
            app.GlobalHillCoefficientLabel.Position = [220 88 121 22];
            app.GlobalHillCoefficientLabel.Interpreter = 'none';
            app.GlobalHillCoefficientLabel.Text = 'Global Hill Coefficient';

            % Create HillCoefficientEditField
            app.HillCoefficientEditField = uieditfield(app.GeneticMechanicalRegulatoryNetworkPanel, 'numeric');
            app.HillCoefficientEditField.Position = [366 87 34 22];
            app.HillCoefficientEditField.Value = 2;

            % Add a tiny LaTeX badge just to the left of the field
            hPos = app.HillCoefficientEditField.Position;  
            app.HillMathLabel = uilabel(app.GeneticMechanicalRegulatoryNetworkPanel);
            app.HillMathLabel.Interpreter         = 'latex';
            app.HillMathLabel.HorizontalAlignment = 'right';
            app.HillMathLabel.Text                = '$(H)$';
            app.HillMathLabel.Position            = [hPos(1)-28, hPos(2), 22, hPos(4)]

            % Create UseCustomHillCoefficientsCheckBox
            app.UseCustomHillCoefficientsCheckBox = uicheckbox(app.GeneticMechanicalRegulatoryNetworkPanel);
            app.UseCustomHillCoefficientsCheckBox.Text = 'Use Custom Hill Coefficients';
            app.UseCustomHillCoefficientsCheckBox.Position = [230 59 176 22];

            % Create SaveParametersButton
            app.SaveParametersButton = uibutton(app.GeneticMechanicalRegulatoryNetworkPanel, 'push');
            app.SaveParametersButton.ButtonPushedFcn = createCallbackFcn(app, @SaveParametersButtonPushed, true);
            app.SaveParametersButton.FontSize = 18;
            app.SaveParametersButton.Position = [222 169 196 31];
            app.SaveParametersButton.Text = 'Save Parameters';

            % Create LoadParametersButton
            app.LoadParametersButton = uibutton(app.GeneticMechanicalRegulatoryNetworkPanel, 'push');
            app.LoadParametersButton.ButtonPushedFcn = createCallbackFcn(app, @LoadParametersButtonPushed, true);
            app.LoadParametersButton.FontSize = 18;
            app.LoadParametersButton.Position = [222 129 196 31];
            app.LoadParametersButton.Text = 'Load Parameters';

            % Create LoadTemplateButton
            app.LoadTemplateButton = uibutton(app.GeneticMechanicalRegulatoryNetworkPanel, 'push');
            app.LoadTemplateButton.ButtonPushedFcn = createCallbackFcn(app, @LoadTemplateButtonPushed, true);
            app.LoadTemplateButton.FontSize = 18;
            app.LoadTemplateButton.Position = [224 9 196 31];
            app.LoadTemplateButton.Text = 'Load Template';

            % Create ExportTemplateButton
            app.ExportTemplateButton = uibutton(app.GeneticMechanicalRegulatoryNetworkPanel, 'push');
            app.ExportTemplateButton.ButtonPushedFcn = createCallbackFcn(app, @ExportTemplateButtonPushed, true);
            app.ExportTemplateButton.FontSize = 18;
            app.ExportTemplateButton.Position = [13 9 196 31];
            app.ExportTemplateButton.Text = 'Export Template';

            % Create NetworkDiagramPanel
            app.NetworkDiagramPanel = uipanel(app.UIFigure);
            app.NetworkDiagramPanel.TitlePosition = 'centertop';
            app.NetworkDiagramPanel.Title = 'Network Diagram';
            app.NetworkDiagramPanel.FontSize = 18;
            app.NetworkDiagramPanel.Position = [289 312 426 410];

            % Create NetworkAxes
            app.NetworkAxes = uiaxes(app.NetworkDiagramPanel);
            app.NetworkAxes.XTick = [];
            app.NetworkAxes.YTick = [];
            app.NetworkAxes.Box = 'on';
            app.NetworkAxes.Position = [12 103 386 256];

            % Create RefreshDiagramButton
            app.RefreshDiagramButton = uibutton(app.NetworkDiagramPanel, 'push');
            app.RefreshDiagramButton.ButtonPushedFcn = createCallbackFcn(app, @RefreshDiagramButtonPushed, true);
            app.RefreshDiagramButton.FontSize = 18;
            app.RefreshDiagramButton.Position = [99 10 211 31];
            app.RefreshDiagramButton.Text = 'Refresh Diagram';

            % Create ShowRegulationNumberCheckBox
            app.ShowRegulationNumberCheckBox = uicheckbox(app.NetworkDiagramPanel);
            app.ShowRegulationNumberCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowRegulationNumberCheckBoxValueChanged, true);
            app.ShowRegulationNumberCheckBox.Text = 'Show Regulation Number';
            app.ShowRegulationNumberCheckBox.Position = [249 68 160 22];

            % Create PathwaySelectionDropDownLabel
            app.PathwaySelectionDropDownLabel = uilabel(app.NetworkDiagramPanel);
            app.PathwaySelectionDropDownLabel.HorizontalAlignment = 'right';
            app.PathwaySelectionDropDownLabel.Position = [12 62 104 22];
            app.PathwaySelectionDropDownLabel.Text = 'Pathway Selection';

            % Create PathwaySelectionDropDown
            app.PathwaySelectionDropDown = uidropdown(app.NetworkDiagramPanel);
            app.PathwaySelectionDropDown.Items = {'Pathway 1', 'Pathway 2', 'All'};
            app.PathwaySelectionDropDown.ValueChangedFcn = createCallbackFcn(app, @PathwaySelectionDropDownValueChanged, true);
            app.PathwaySelectionDropDown.Position = [125 61 100 22];
            app.PathwaySelectionDropDown.Value = 'Pathway 1';

            % Create ShowMechanicalRegulationCheckBox
            app.ShowMechanicalRegulationCheckBox = uicheckbox(app.NetworkDiagramPanel);
            app.ShowMechanicalRegulationCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowMechanicalRegulationCheckBoxValueChanged, true);
            app.ShowMechanicalRegulationCheckBox.Text = 'Show Mechanical Regulation';
            app.ShowMechanicalRegulationCheckBox.Position = [249 44 178 22];
            app.ShowMechanicalRegulationCheckBox.Value = true;

            % Create SimulationControlsPanel
            app.SimulationControlsPanel = uipanel(app.UIFigure);
            app.SimulationControlsPanel.TitlePosition = 'centertop';
            app.SimulationControlsPanel.Title = 'Simulation Controls';
            app.SimulationControlsPanel.FontSize = 18;
            app.SimulationControlsPanel.Position = [11 12 268 211];

            % Create RunSimulationButton
            app.RunSimulationButton = uibutton(app.SimulationControlsPanel, 'push');
            app.RunSimulationButton.ButtonPushedFcn = createCallbackFcn(app, @RunSimulationButtonPushed, true);
            app.RunSimulationButton.FontSize = 18;
            app.RunSimulationButton.Position = [21 74 211 31];
            app.RunSimulationButton.Text = 'Run Simulation';

            % Create StopCancelButton
            app.StopCancelButton = uibutton(app.SimulationControlsPanel, 'push');
            app.StopCancelButton.ButtonPushedFcn = createCallbackFcn(app, @StopCancelButtonPushed, true);
            app.StopCancelButton.FontSize = 18;
            app.StopCancelButton.Position = [20 37 211 31];
            app.StopCancelButton.Text = 'Stop/Cancel';

            % Create UseParallelPoolCheckBox
            app.UseParallelPoolCheckBox = uicheckbox(app.SimulationControlsPanel);
            app.UseParallelPoolCheckBox.Text = 'Use Parallel Pool';
            app.UseParallelPoolCheckBox.Position = [16 7 113 22];
            app.UseParallelPoolCheckBox.Value = true;

            % Create ParallelPoolSizeDropDownLabel
            app.ParallelPoolSizeDropDownLabel = uilabel(app.SimulationControlsPanel);
            app.ParallelPoolSizeDropDownLabel.HorizontalAlignment = 'right';
            app.ParallelPoolSizeDropDownLabel.Position = [17 112 94 22];
            app.ParallelPoolSizeDropDownLabel.Text = 'Parallel Pool Size';

            % Create ParallelPoolSizeDropDown
            app.ParallelPoolSizeDropDown = uidropdown(app.SimulationControlsPanel);
            app.ParallelPoolSizeDropDown.Items = {'1', '2', '3', '4', '5', '6', '7', '8'};
            app.ParallelPoolSizeDropDown.ValueChangedFcn = createCallbackFcn(app, @ParallelPoolSizeDropDownValueChanged, true);
            app.ParallelPoolSizeDropDown.Position = [151 112 99 22];
            app.ParallelPoolSizeDropDown.Value = '8';

            % Create TotalSimulationEditField
            app.TotalSimulationEditField = uieditfield(app.SimulationControlsPanel, 'numeric');
            app.TotalSimulationEditField.Limits = [0 500];
            app.TotalSimulationEditField.ValueChangedFcn = createCallbackFcn(app, @TotalSimulationEditFieldValueChanged, true);
            app.TotalSimulationEditField.Position = [211 154 39 22];
            app.TotalSimulationEditField.Value = 8;

            % Create TotalSimulationsSliderLabel
            app.TotalSimulationsSliderLabel = uilabel(app.SimulationControlsPanel);
            app.TotalSimulationsSliderLabel.HorizontalAlignment = 'center';
            app.TotalSimulationsSliderLabel.Position = [1 146 67 30];
            app.TotalSimulationsSliderLabel.Text = {'Total'; 'Simulations'};

            % Create TotalSimulationsSlider
            app.TotalSimulationsSlider = uislider(app.SimulationControlsPanel);
            app.TotalSimulationsSlider.Limits = [0 500];
            app.TotalSimulationsSlider.MajorTicks = [1 250 500];
            app.TotalSimulationsSlider.MajorTickLabels = {'1', '250', '500'};
            app.TotalSimulationsSlider.ValueChangedFcn = createCallbackFcn(app, @TotalSimulationsSliderValueChanged, true);
            app.TotalSimulationsSlider.ValueChangingFcn = createCallbackFcn(app, @TotalSimulationsSliderValueChanging, true);
            app.TotalSimulationsSlider.MinorTicks = [1 50 100 150 200 300 350 400 450];
            app.TotalSimulationsSlider.Position = [78 171 115 3];
            app.TotalSimulationsSlider.Value = 8;

            % Create ExportOutputFilesButton
            app.ExportOutputFilesButton = uibutton(app.SimulationControlsPanel, 'push');
            app.ExportOutputFilesButton.ButtonPushedFcn = createCallbackFcn(app, @ExportOutputFilesButtonPushed, true);
            app.ExportOutputFilesButton.FontSize = 10;
            app.ExportOutputFilesButton.Position = [151 7 102 22];
            app.ExportOutputFilesButton.Text = 'Export Output Files';

            % Create ProgressBG
            app.ProgressBG = uipanel(app.UIFigure);
            app.ProgressBG.Position = [289 25 427 30];

            % Create ProgressFill
            app.ProgressFill = uipanel(app.ProgressBG);
            app.ProgressFill.BorderWidth = 2;
            app.ProgressFill.BackgroundColor = [0.2 0.6 1];
            app.ProgressFill.Position = [1 0 425 30];

            % Create ProgressLabel
            app.ProgressLabel = uilabel(app.ProgressFill);
            app.ProgressLabel.Position = [2 3 85 22];
            app.ProgressLabel.Text = 'Progress Label';

            % Create StatusLabel
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.Position = [293 2 417 22];
            app.StatusLabel.Text = 'Status Label';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = DevSim_GUI

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end