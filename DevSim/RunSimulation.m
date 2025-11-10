function RunSimulation(params)

population   = params.population;
Tmax         = params.Tmax;
kappaG       = params.kappaG;
kappaF       = params.kappaF;
r            = params.radius;
alphaMIN     = params.alphaMin;
alphaMAX     = params.alphaMax;
alpha        = (alphaMAX + alphaMIN) / 2;
Morphogen    = params.MorphogenStrength;
H            = params.HillCoefficient;
D            = params.DistancePower;
betaS        = params.ShortRangeForceStrength;
betaL        = params.LongRangeForceStrength;
dt           = params.dt;
friction     = params.friction;

GeneNum      = double(params.GeneNum);
NumPathways  = double(params.NumPathways);

totalSims    = params.sampleCount;
workers      = params.parallelWorkers;

activeDir = fullfile(pwd,'Active');
if ~isfolder(activeDir), mkdir(activeDir); end

% Custom Hill switch from GUI
useCustomHill = isfield(params,'UseCustomHillCoefficients') && logical(params.UseCustomHillCoefficients);

% Unchangeable
Cycle = 5;
f0    = 1;

usePar = isfield(params,'parallel') && logical(params.parallel);
if ~usePar
    workers = 1;
end

pool = gcp('nocreate');
if usePar
    if isempty(pool) || pool.NumWorkers ~= workers
        if ~isempty(pool), delete(pool); end
        parpool('local', workers);
    end
else
    if ~isempty(pool)
        delete(pool);
    end
end

hasQ = isfield(params,'progressQueue') && ~isempty(params.progressQueue);
if hasQ && usePar
    qConst = parallel.pool.Constant(params.progressQueue);   % to use on workers
else
    qConst = [];
end

% clean OUTPUT folders
outputFolders = dir('OUTPUT*');
for i = 1:length(outputFolders)
    folderName = outputFolders(i).name;
    if outputFolders(i).isdir
        rmdir(folderName, 's');
    end
end
disp('All OUTPUT folders have been deleted.');

disp([population, GeneNum, Tmax, dt, Cycle]);
disp((Tmax*Cycle/dt));

%Noise prep
for sample = 1:totalSims
    Noise = cat(2, ...
        randn([population, 3, (Tmax*Cycle/dt)]) * kappaF, ...
        randn([population, GeneNum, (Tmax*Cycle/dt)]) * kappaG);

    folder = ['OUTPUT', num2str(sample)];
    if ~exist(folder, 'dir')
        mkdir(folder);
    end
    save([folder '/WorkSpace_Noise'], 'Noise', '-v7.3');
end

%Set margin and calculate dynamic cube dimensions
margin = 0.15;
k = ((3/(4*pi)) * population * (1 + margin))^(1/3);
NNN = 2 * ceil(k) + 1;

%preparation phase
batchSize    = workers;
numBatches   = ceil(totalSims / batchSize);
sampleCounter = 1;

for batch = 1:numBatches
    simsThisBatch = min(batchSize, totalSims - (batch - 1)*batchSize);
    baseIdx       = sampleCounter;

    if usePar
        parfor i = 1:simsThisBatch
            prepWorkerBody( ...
                i, baseIdx, ...                 
                NNN, r, alpha, population, ...  
                dt, Tmax, Cycle, f0, ...        
                hasQ, usePar, qConst, params.progressQueue); 
        end
    else
        for i = 1:simsThisBatch
            prepWorkerBody( ...
                i, baseIdx, ...
                NNN, r, alpha, population, ...
                dt, Tmax, Cycle, f0, ...
                hasQ, usePar, qConst, params.progressQueue);
        end
    end

    sampleCounter = sampleCounter + simsThisBatch;

    if params.stopCallback()
        fprintf('Simulation canceled by user.\n');
        return;
    end
end

%Excel Reader
xlsx = fullfile(activeDir,'Network Settings.xlsx');
if ~isfile(xlsx)
    error('Expected workbook not found: %s', xlsx);
end

%Gene Information
lastRow = 3 + GeneNum;
Leak    = readmatrix(xlsx, 'Sheet','Gene Information', ...
                     'Range', sprintf('B4:B%d', lastRow));
Degra   = readmatrix(xlsx, 'Sheet','Gene Information', ...
                     'Range', sprintf('C4:C%d', lastRow));
Initial = readmatrix(xlsx, 'Sheet','Gene Information', ...
                     'Range', sprintf('D4:D%d', lastRow));

Leak(isnan(Leak))     = 0;
Degra(isnan(Degra))   = 0;
Initial(isnan(Initial)) = 0;

%Gene Regulatory Network (K) 
Response = zeros(GeneNum, 2*GeneNum, NumPathways);
baseRowStart = 4;  
baseColStart = 3;   

for p = 1:NumPathways
    % step by N (no blank row)
    rowStart = baseRowStart + (p-1)*GeneNum;
    rowEnd   = rowStart + GeneNum - 1;

    c1_int = baseColStart;
    c2_int = baseColStart + GeneNum - 1;

    c1_ext = c2_int + 1;
    c2_ext = c1_ext + GeneNum - 1;

    InternalRange = sprintf('%s%d:%s%d', excelCol(c1_int), rowStart, excelCol(c2_int), rowEnd);
    Aint = readmatrix(xlsx, 'Sheet','Gene Regulatory Network (K)', 'Range', InternalRange);
    Aint = sanitizeBlock(Aint, GeneNum);

    ExternalRange = sprintf('%s%d:%s%d', excelCol(c1_ext), rowStart, excelCol(c2_ext), rowEnd);
    Aext = readmatrix(xlsx, 'Sheet','Gene Regulatory Network (K)', 'Range', ExternalRange);
    Aext = sanitizeBlock(Aext, GeneNum);

    Response(:, 1:GeneNum, p)           = Aint;
    Response(:, GeneNum+1:2*GeneNum, p) = Aext;
end

%Hill coeffs
HillResp = H * ones(GeneNum, 2*GeneNum, NumPathways);

if useCustomHill
    for p = 1:NumPathways
        rowStart = baseRowStart + (p-1)*GeneNum;
        rowEnd   = rowStart + GeneNum - 1;

        c1_int = baseColStart;
        c2_int = baseColStart + GeneNum - 1;
        c1_ext = c2_int + 1;
        c2_ext = c1_ext + GeneNum - 1;

        % internal
        HIntRange = sprintf('%s%d:%s%d', excelCol(c1_int), rowStart, excelCol(c2_int), rowEnd);
        HIntFull  = readmatrix(xlsx, 'Sheet','Gene Regulatory Network (H)', 'Range', HIntRange);
        HInt      = sanitizeBlock(HIntFull, GeneNum).';
        maskInt   = ~isnan(HInt) & (HInt > 0);
        Hin       = HillResp(:, 1:GeneNum, p);
        Hin(maskInt) = HInt(maskInt);
        HillResp(:, 1:GeneNum, p) = Hin;

        % external
        HExtRange = sprintf('%s%d:%s%d', excelCol(c1_ext), rowStart, excelCol(c2_ext), rowEnd);
        HExtFull  = readmatrix(xlsx, 'Sheet','Gene Regulatory Network (H)', 'Range', HExtRange);
        HExt      = sanitizeBlock(HExtFull, GeneNum).';
        maskExt   = ~isnan(HExt) & (HExt > 0);
        Hout      = HillResp(:, GeneNum+1:end, p);
        Hout(maskExt) = HExt(maskExt);
        HillResp(:, GeneNum+1:end, p) = Hout;
    end
end

%Short-Range Force Network (α)
shortLast = 1 + GeneNum;
Short = readmatrix(xlsx, 'Sheet','Short-Range Force Network (α)', ...
                   'Range', sprintf('B2:B%d', shortLast));
Short = Short(1:GeneNum);
Short(isnan(Short)) = 0;

%Long-Range Force Network (β)
c1 = 2;               
c2 = 2 + GeneNum - 1;
r1 = 3;
r2 = 3 + GeneNum - 1;
LongRange = sprintf('%s%d:%s%d', excelCol(c1), r1, excelCol(c2), r2);
Long = readmatrix(xlsx, 'Sheet','Long-Range Force Network (β)', 'Range', LongRange);
Long = sanitizeBlock(Long, GeneNum);
Long(isnan(Long)) = 0;

% Save meta in current folder (like before, just with more vars)
try
    save('WorkSpace_RegulationMeta.mat', ...
        'Response','HillResp','useCustomHill','H', ...
        'Leak','Degra','Short','Long','Initial','-v7.3');
catch
end

%Simulation phase
batchSize     = workers;
numBatches    = ceil(totalSims / batchSize);
sampleCounter = 1;

for batch = 1:numBatches
    simsThisBatch = min(batchSize, totalSims - (batch - 1)*batchSize);
    baseIdx       = sampleCounter;

    if usePar
        parfor i = 1:simsThisBatch
            simWorkerBody( ...
                i, baseIdx, ...
                Tmax, dt, Cycle, f0, D, ...              
                r, alphaMIN, alphaMAX, friction, ...      
                GeneNum, NumPathways, Morphogen, ...     
                Response, HillResp, Leak, Degra, Short, Long, Initial, betaS, betaL, ... 
                hasQ, usePar, qConst, params.progressQueue);              
        end
    else
        for i = 1:simsThisBatch
            simWorkerBody( ...
                i, baseIdx, ...
                Tmax, dt, Cycle, f0, D, ...
                r, alphaMIN, alphaMAX, friction, ...
                GeneNum, NumPathways, Morphogen, ...
                Response, HillResp, Leak, Degra, Short, Long, Initial, betaS, betaL, ...
                hasQ, usePar, qConst, params.progressQueue);
        end
    end

    sampleCounter = sampleCounter + simsThisBatch;

    if params.stopCallback()
        fprintf('Simulation canceled by user.\n');
        return;
    end
end

end  %end RunSimulation


% Subfunctions
function prepWorkerBody(i, baseIdx, NNN, r, alpha, population, dt, Tmax, Cycle, f0, hasQ, usePar, qConst, progressQueue)
    SampleIndex = baseIdx + i - 1;

    % Build initial cubic grid then trim by radius
    InitialPosition = [];
    for x = 1:NNN
        for y = 1:NNN
            for z = 1:NNN
                InitialPosition = [InitialPosition; [x, y, z] - (NNN+1)/2];
            end
        end
    end
    InitialPosition = InitialPosition * 2 * r * alpha;
    InitialPosition = InitialPosition(randperm(size(InitialPosition,1)), :);

    Distance = sqrt(sum(InitialPosition.^2, 2));
    Distance0 = sort(Distance);
    Seed = find(Distance <= Distance0(population));
    InitialPosition = InitialPosition(Seed(1:population), :);

    MatrixP = InitialPosition;
    Alpha   = alpha * ones(population);
    Alpha(1:population + 1:end) = NaN;

    % Load noise
    folder = ['OUTPUT', num2str(SampleIndex)];
    S      = load([folder '/WorkSpace_Noise']);
    Noise  = S.Noise;

    for t = dt:dt:Tmax*2
        if hasQ && mod(round(t/dt), 25)==0
            tfrac = t/(Tmax*Cycle);
            local_send(hasQ, usePar, qConst, progressQueue, ...
                struct('kind','sim-step','simIdx',SampleIndex,'tfrac',tfrac));
        end
        MatrixF = zeros(size(MatrixP));

        % Distances and directions
        DX = MatrixP(:,1) - MatrixP(:,1)';
        DY = MatrixP(:,2) - MatrixP(:,2)';
        DZ = MatrixP(:,3) - MatrixP(:,3)';
        Distance = sqrt(DX.^2 + DY.^2 + DZ.^2);

        for N = 1:population
            interact = intersect(find(~isnan(Alpha(N,:))), find(Distance(N,:) < 2*r));
            if isempty(interact), continue; end

            direction = [DX(N,interact)', DY(N,interact)', DZ(N,interact)'] ./ ...
                        (Distance(N,interact)' * ones(1, 3));
            alpha0    = alpha * ones(length(interact), 3);
            dist_mat  = Distance(N, interact)' * ones(1, 3);
            force     = -f0 ./ (2*r*alpha0) .* dist_mat + f0;
            f         = f0 * force .* direction;

            if size(f, 1) == 1
                MatrixF(N,:) = MatrixF(N,:) + f;
            else
                MatrixF(N,:) = MatrixF(N,:) + sum(f);
            end
        end

        MatrixP = MatrixP + MatrixF * dt + sqrt(dt) * Noise(:,1:3,round(t/dt));
    end

    % Recentering and save
    MatrixP = MatrixP - mean(MatrixP,1);
    writematrix(MatrixP, [folder '/WorkSpace_MatrixP_Initial.csv']);

    if hasQ
        local_send(hasQ, usePar, qConst, progressQueue, ...
            struct('kind','sim-step','simIdx',SampleIndex,'tfrac',min(2/Cycle,1)));
        local_send(hasQ, usePar, qConst, progressQueue, ...
            struct('kind','note','msg',sprintf('Prep finished for Sim %d', SampleIndex)));
    end
end


function simWorkerBody(i, baseIdx, ...
    Tmax, dt, Cycle, f0, D, ...
    r, alphaMIN, alphaMAX, friction, ...
    GeneNum, NumPathways, Morphogen, ...
    Response, HillResp, Leak, Degra, Short, Long, Initial, betaS, betaL, ...
    hasQ, usePar, qConst, progressQueue)

    SampleIndex = baseIdx + i - 1;

    folder  = ['OUTPUT', num2str(SampleIndex)];
    S       = load([folder '/WorkSpace_Noise']);
    Noise   = S.Noise;

    MatrixP = cell2mat(table2cell(readtable([folder '/WorkSpace_MatrixP_Initial.csv'])));
    cellnum = size(MatrixP,1);
    Matrix  = [MatrixP, repmat(Initial', cellnum, 1)];
    Matrix(:,4:end) = max(0, min(1, Matrix(:,4:end)));

    for t = Tmax*2+dt : dt : Tmax*Cycle

        tfrac = t/(Tmax*Cycle);
        if hasQ && mod(round(t/dt), 25)==0
            local_send(hasQ, usePar, qConst, progressQueue, ...
                struct('kind','sim-step','simIdx',SampleIndex,'tfrac',tfrac));
        end

        writematrix(Matrix, [folder '/WorkSpace_Matrix_', num2str(round(t/dt)), '.csv']);
        MatrixP = Matrix(:,1:3);
        MatrixG = Matrix(:,4:end);

        % Pairwise distances
        Diff     = MatrixP(:,:,ones(1,cellnum)) - permute(MatrixP(:,:,ones(1, cellnum)),[3,2,1]);
        Distance = sqrt(sum(Diff.^2,2));
        Distance(1:cellnum+1:end) = Inf;
        Distance = squeeze(Distance);
        DistanceD = (1 ./ Distance) .^ D;

        Intensity = [MatrixG, max(0, min(1, Morphogen * (DistanceD * MatrixG)))];

        ResponseE  = repmat(Response, [1, 1, 1, cellnum]);
        IntensityE = repmat(reshape(Intensity', [1, GeneNum*2, 1, cellnum]), ...
                            [GeneNum, 1, NumPathways, 1]);
        HillE      = repmat(HillResp, [1, 1, 1, cellnum]);

        if all(HillResp(:) == round(HillResp(:)))
            RespPow = (ResponseE .^ HillE);
        else
            RespPow = (abs(ResponseE) .^ HillE);
        end
        IntPow  = (IntensityE .^ HillE);
        Den     = RespPow + IntPow;
        Term    = 1 + sign(ResponseE) .* (0.5 - RespPow ./ Den) - 0.5 * sign(abs(ResponseE));

        Regulation = squeeze(prod(Term, 2));
        Regulation(Regulation==1) = 0;
        Regulation = squeeze(sum(Regulation, 2))';

        MatrixG = MatrixG + dt*(Regulation - MatrixG .* Degra' + Leak') + sqrt(dt) * Noise(:, 4:end, round(t / dt));
        MatrixG = max(0, min(1, MatrixG));
        X = 0.5 - MatrixG;

        % Short-Range Force Strength
        ShortRange = NaN*ones(cellnum,cellnum);
        TermSR = [];
        for I=1:size(Short,1)
            if  Short(I,1)==0
                TermSR = cat(3,TermSR,ones(size(ShortRange)));
            end
            if  abs(Short(I,1))==1
                TermSR = cat(3,TermSR,(0.5 - sign(Short(I,1)).*X(:,I))*(0.5 - sign(Short(I,1)).*X(:,I))');
            end
            if  abs(Short(I,1))==2
                TermSR = cat(3,TermSR,(0.5 - sign(Short(I,1)).*(X(:,I)+X(:,I)')/2));
            end
        end
        Change     = prod(TermSR,3);
        ShortRange = alphaMAX - betaS*Change;
        ShortRange = max(alphaMIN, min(alphaMAX, ShortRange));
        ShortRange(1:cellnum+1:end) = NaN;

        % Short-range force
        interact  = (~isnan(ShortRange)) & (Distance < 2*r);
        DistanceX = MatrixP(:,1)-MatrixP(:,1)'; DirectionX=DistanceX./Distance; DirectionX(isnan(DirectionX))=0;
        DistanceY = MatrixP(:,2)-MatrixP(:,2)'; DirectionY=DistanceY./Distance; DirectionY(isnan(DirectionY))=0;
        DistanceZ = MatrixP(:,3)-MatrixP(:,3)'; DirectionZ=DistanceZ./Distance; DirectionZ(isnan(DirectionZ))=0;
        force     = -f0./(2*r*ShortRange).*Distance + f0;  force(~interact)=0;
        MatrixF   = [sum(force.*DirectionX,2), sum(force.*DirectionY,2), sum(force.*DirectionZ,2)];

        % Long-Range Force Strength
        LongRange = NaN*ones(cellnum,GeneNum);
        MatrixGE  = repmat(X,[1,1,GeneNum]);
        LongE     = permute(repmat(Long',[1,1,cellnum]),[3,1,2]);
        ValidL    = permute((sign(sum(abs(Long),2))*ones(1,GeneNum))',[3,1,2]);
        LongRange = betaL*squeeze(prod((floor(1./(abs(LongE)+1)) + abs(LongE).*(0.5 - sign(LongE).*MatrixGE)).*ValidL,2));

        % Long-range force
        Diffusion = MatrixP - permute(MatrixP,[3,2,1]);
        DistanceL = squeeze(sqrt(sum(Diffusion.^2,2))); DistanceL(1:cellnum+1:end)=Inf;
        DistanceL = repmat(reshape(DistanceL,[cellnum,1,cellnum]),[1,3,1]);
        Valid     = DistanceL > 2*r;
        Receptor  = repmat(LongRange,[1,1,cellnum]);
        Ligand    = repmat(reshape(MatrixG',[1,GeneNum,cellnum]),[cellnum,1,1]);
        ForceLR   = squeeze(sum(Receptor.*Ligand,2));
        ForceLR   = repmat(reshape(ForceLR,[cellnum,1,cellnum]),[1,3,1]);
        Resultant = squeeze(sum((ForceLR.*Diffusion./DistanceL.^(D+1).*Valid),3));
        MatrixF   = MatrixF - Resultant;

        % Static friction outside contact
        if friction > 0
            Fnorm      = sqrt(sum(MatrixF.^2, 2));
            hasContact = any(interact, 2);
            zeroMask   = (~hasContact) & (Fnorm <= friction);
            if any(zeroMask)
                MatrixF(zeroMask, :) = 0;
            end
            moveMask = (~hasContact) & (Fnorm > friction);
            if any(moveMask)
                scale = (Fnorm(moveMask) - friction) ./ (Fnorm(moveMask) + eps);
                MatrixF(moveMask, :) = MatrixF(moveMask, :) .* scale;
            end
        end

        % Position update
        MatrixP = MatrixP + MatrixF * dt + sqrt(dt) * Noise(:,1:3, round(t/dt));

        % Combine
        Matrix = [MatrixP, MatrixG];
    end

    % Save final and progress
    writematrix(Matrix, [folder '/WorkSpace_Matrix_Final.csv']);
    if hasQ
        local_send(hasQ, usePar, qConst, progressQueue, ...
            struct('kind','sim-step','simIdx',SampleIndex,'tfrac',1.0));
        local_send(hasQ, usePar, qConst, progressQueue, ...
            struct('kind','note','msg',sprintf('Sim %d finished', SampleIndex)));
    end
end


function local_send(hasQ, usePar, qConst, progressQueue, payload)
    if ~hasQ
        return;
    end
    if usePar
        send(qConst.Value, payload);
    else
        send(progressQueue, payload);
    end
end

%helpers
function A = sanitizeBlock(Ain, N)
    if isempty(Ain)
        A = zeros(N,N);
        return;
    end
    A = Ain(1:min(end,N), 1:min(size(Ain,2),N));
    if ~isequal(size(A), [N N])
        B = zeros(N,N);
        B(1:size(A,1), 1:size(A,2)) = A;
        A = B;
    end
    A(isnan(A)) = 0;
end

function s = excelCol(n)
    s = "";
    while n > 0
        r = mod(n-1, 26);
        s = char('A' + r) + s;
        n = floor((n-1)/26);
    end
    s = char(s);
end
