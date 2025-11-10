function Plot_Gene_Time_Series(Tmax, dt, GeneNum)
% Standalone replica of DevSim's VisualizeGeneExpressionOverTimeGraphs,

    if nargin < 1 || isempty(Tmax), Tmax = 75; end
    if nargin < 2 || isempty(dt),   dt   = 0.02; end

    outputFolder = 'OUTPUT1';
    if ~isfolder(outputFolder)
        error('Folder %s not found.', outputFolder);
    end

    % === detect indices ===
    files   = dir(fullfile(outputFolder, 'WorkSpace_Matrix_*.csv'));
    indices = [];
    for k = 1:numel(files)
        token = regexp(files(k).name, 'WorkSpace_Matrix_(\d+)\.csv', 'tokens');
        if ~isempty(token)
            indices(end+1) = str2double(token{1}{1}); 
        end
    end
    if isempty(indices)
        warning('No matrix files found in %s', outputFolder);
        return;
    end
    indices = sort(indices);
    idx_min = min(indices);
    idx_max = max(indices);

    numTimepts = max(2, round(Tmax / dt));
    sampledIdx = round(linspace(idx_min, idx_max, numTimepts));
    timeArray  = linspace(0, Tmax, numTimepts);

    %read first matrix to get cell/gene counts
    firstFile   = fullfile(outputFolder, sprintf('WorkSpace_Matrix_%d.csv', sampledIdx(1)));
    firstMatrix = readmatrix(firstFile);
    numCells    = size(firstMatrix, 1);
    if nargin < 3 || isempty(GeneNum)
        GeneNum = max(1, size(firstMatrix, 2) - 3); % genes start at col 4
    end

    %per-gene loop
    for g = 1:GeneNum
        GeneTrajectories = NaN(numCells, numTimepts);

        for t = 1:numTimepts
            cycle = sampledIdx(t);
            fname = fullfile(outputFolder, sprintf('WorkSpace_Matrix_%d.csv', cycle));
            if ~isfile(fname), continue; end
            data = readmatrix(fname);
            GeneTrajectories(:, t) = data(:, 3 + g);
        end

        %plot trajectories
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
        ax.FontSize  = 32;
        if isprop(ax,'FontSizeMode'), ax.FontSizeMode = 'manual'; end
        ax.LabelFontSizeMultiplier = 1;
        ax.TitleFontSizeMultiplier = 1;
        ax.FontName = 'Arial';

        hX = xlabel(ax, 'Time', 'Interpreter','none');
        hY = ylabel(ax, sprintf('Gene %d Expression', g), 'Interpreter','none');
        hX.FontUnits = 'points'; hY.FontUnits = 'points';
        hX.FontSize  = 32;       hY.FontSize  = 32;
        hX.FontName  = 'Arial';  hY.FontName  = 'Arial';

        %axis limits for aesthetics: Gene 3 special case
        if g == 3
            ylim([0.2 1]);
            yticks(0.2:0.2:1);
        else
            ylim([0 1]);
            yticks(0:0.2:1);
        end

        grid off;

        %save SVG
        outname = fullfile(outputFolder, sprintf('GeneExpressionOverTime_Gene%d.svg', g));
        print(fig, outname, '-dsvg');
        close(fig);
    end
end