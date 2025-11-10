%% Step 1: Configuration Parameters
%  Directory Paths 
%  The variable 'output_name' can be set to OUTPUT6, OUTPUT7, OUTPUT8, OUTPUT9, or OUTPUT10 to specify which dataset to process.
parent_path  = '/n/data1/hms/sysbio/hormoz/users/guoye_g';
output_name  = 'OUTPUT6';    
sample_path  = fullfile(parent_path, output_name);
output_path  = '/n/data1/hms/sysbio/hormoz/users/suxuan';
summary_csv  = fullfile(output_path, [output_name '_asymmetry_cluster_weighted_summary_confirm_101425_D1_4.csv']);

%  Parameters 
r              = 1.0;              % cell radius used for "contact"
contact_thresh = 2*r;              % two cells are connected if cell-cell distance <= contact_thresh


%% Step 2: Scan and Sort Input Files Alphabetically
%  Scan for MatrixP, G files 
MatrixP_all = dir(fullfile(sample_path, '*_MatrixP_Final.csv'));
MatrixG_all = dir(fullfile(sample_path, '*_MatrixG_Final.csv'));

%  Validate and Count
if isempty(MatrixP_all) || isempty(MatrixG_all)
    error('No MatrixP_Final or MatrixG_Final files found in %s', sample_path);
end

nP = numel(MatrixP_all); nG = numel(MatrixG_all);
if nP ~= nG
    error('File count mismatch: %d MatrixP files vs %d MatrixG files found in %s.\nPlease check your directory before continuing.', ...
          nP, nG, sample_path);
end

nPairs = nP;                       % counts are equal, so we can safely use nP (or nG)
fprintf('✅ File counts match: %d paired MatrixP / MatrixG files.\n\n', nPairs);

%  Sort files alphabetically to ensure consistent pairing
MatrixP_all = sortrows(struct2table(MatrixP_all), 'name'); MatrixP_all = table2struct(MatrixP_all);
MatrixG_all = sortrows(struct2table(MatrixG_all), 'name'); MatrixG_all = table2struct(MatrixG_all);


%% Step 3: Process pairs in alphabetical order
results  = nan(nPairs, 11);        % [Aii Aoo Aio BLii BLoo BLio BLoi D1 dt asymmetry loss]
last_pct = -1;                     % track last printed percent
barWidth = 40;

for k = 1:nPairs

    % Step 3.0: (Optional) Progress bar
    pct = floor(k / nPairs * 100); % compute integer percent
    if pct > last_pct              % only print if new percent reached
        numHashes = round(barWidth * pct / 100);
        fprintf('\r[%s%s] %3d%% (%d/%d)', repmat('#',1,numHashes), repmat('-',1,barWidth-numHashes), pct, k, nPairs);
        last_pct = pct;
    end

    % Step 3.1: Load paired files and extract shared key (prefix) and parameters
    % Construct full file paths for the MatrixP and MatrixG files
    fileP = fullfile(MatrixP_all(k).folder, MatrixP_all(k).name);
    fileG = fullfile(MatrixG_all(k).folder, MatrixG_all(k).name);

    % Extract prefix and parameters from filename
    [prefP, paramsP] = get_prefix(MatrixP_all(k).name, '_MatrixP_Final.csv');
    [prefG, ~]       = get_prefix(MatrixG_all(k).name, '_MatrixG_Final.csv');

    if ~strcmp(prefP, prefG)
        error('Prefix mismatch at index %d. P: %s | G: %s.', k, prefP, prefG);
    end

    Aii  = paramsP(1);  
    Aoo  = paramsP(2);  
    Aio  = paramsP(3);
    BLii = paramsP(4); 
    BLoo = paramsP(5); 
    BLio = paramsP(6); 
    BLoi = paramsP(7);
    D1   = paramsP(8);  
    dt   = paramsP(9);

    MatrixP = readmatrix(fileP);
    MatrixG = readmatrix(fileG);

    if size(MatrixP, 1) ~= size(MatrixG, 1)
        error('Row mismatch for %s.', prefP);
    end

    % Step 3.2: Identify the largest cell cluster and compute asymmetry and cell loss
    idx_clusters = find_largest_cluster(MatrixP, contact_thresh);

    % Step 3.2.1: Compute asymmetry for the largest cluster 
    N_inner_global = nnz(MatrixG(:, 2) == 0);
    N_outer_global = nnz(MatrixG(:, 2) == 1);
    asymmetry_list = nan(1, numel(idx_clusters));
    for i = 1:numel(idx_clusters)
        idx_i = idx_clusters{i};
        asymmetry_list(i) = compute_asymmetry( ...
            MatrixP(idx_i, 1:3), ...   % Positions x, y, z
            MatrixG(idx_i, 2),   ...   % Gene 2
            N_inner_global, ...
            N_outer_global);
    end
    
    % Average asymmetry across tied largest clusters (omit NaNs)
    if any(~isnan(asymmetry_list))
        asymmetry_cluster = mean(asymmetry_list, 'omitnan');
    else
        error('Degenerate largest clusters for %s. Asymmetry is NaN. Aborting.', prefP);
    end

    % Step 3.2.2: Compute cell loss based on the number of cells in the largest cluster
    N        = size(MatrixP, 1);
    max_size = numel(idx_clusters{1});
    loss     = (N - max_size) / N;

    % Step 3.3: Record parameters together with computed asymmetry and loss for the largest cluster
    results(k,:) = [Aii Aoo Aio BLii BLoo BLio BLoi D1 dt asymmetry_cluster loss];
end
fprintf('\n✅ Computation complete: processed %d parameter sets successfully.\n', nPairs);


%% Step 4: Build the results table and organize data for saving
T = array2table(results, 'VariableNames', { ...
    'alpha_ii', ...
    'alpha_oo', ...
    'alpha_io', ...
    'betaL_ii', ...
    'betaL_oo', ...
    'betaL_io', ...
    'betaL_oi', ...
    'D1', ...
    'dt', ...
    'asymmetry', ...
    'loss'});   

% Grouping masks
all_zero = T.betaL_ii==0 & T.betaL_oo==0 & T.betaL_io==0 & T.betaL_oi==0;
only_ii  = T.betaL_ii~=0 & T.betaL_oo==0 & T.betaL_io==0 & T.betaL_oi==0;
only_oo  = T.betaL_ii==0 & T.betaL_oo~=0 & T.betaL_io==0 & T.betaL_oi==0;
only_io  = T.betaL_ii==0 & T.betaL_oo==0 & T.betaL_io~=0 & T.betaL_oi==0;
only_oi  = T.betaL_ii==0 & T.betaL_oo==0 & T.betaL_io==0 & T.betaL_oi~=0;

% Sort rules per group (keep your parameter-first ordering)
T0   = sortrows(T(all_zero,:),            {'alpha_ii','alpha_oo','alpha_io'},          {'ascend','ascend','ascend'});
Tii  = sortrows(T(only_ii, :), {'betaL_ii','alpha_ii','alpha_oo','alpha_io'}, {'ascend','ascend','ascend','ascend'});
Too  = sortrows(T(only_oo, :), {'betaL_oo','alpha_ii','alpha_oo','alpha_io'}, {'ascend','ascend','ascend','ascend'});
Tio  = sortrows(T(only_io, :), {'betaL_io','alpha_ii','alpha_oo','alpha_io'}, {'ascend','ascend','ascend','ascend'});
Toi  = sortrows(T(only_oi, :), {'betaL_oi','alpha_ii','alpha_oo','alpha_io'}, {'ascend','ascend','ascend','ascend'});

% Concatenate in your desired order
T_sorted = [T0; Tii; Too; Tio; Toi];

% Save final sorted CSV 
writetable(T_sorted, summary_csv);
fprintf('✅ Summary table successfully saved to: %s\n', summary_csv);





%% Helper Functions
function [prefix, params] = get_prefix(filename, suffix)
% GET_PREFIX
% Remove a suffix and extract numeric parameters from a filename.
%
% Input:
%   filename = 'Aii_0.775_Aoo_0.950_Aio_0.875_BLii_0.000_BLoo_0.135_BLio_0.000_BLoi_0.000_D1_2_dt_0.20_MatrixP_Final.csv' 
%   suffix   = '_MatrixP_Final.csv'
% 
% Output:
%   prefix   = 'Aii_0.775_Aoo_0.950_Aio_0.875_BLii_0.000_BLoo_0.135_BLio_0.000_BLoi_0.000_D1_2_dt_0.20'
%   params   = [0.775  0.95  0.875  0  0.135  0  0  2  0.2]

    % Remove suffix 
    prefix = erase(filename, suffix);

    % Regular expression pattern for 9 numeric parameters
    pat = ['Aii_([-\d\.eE]+)_' ...
           'Aoo_([-\d\.eE]+)_' ...
           'Aio_([-\d\.eE]+)_' ...
           'BLii_([-\d\.eE]+)_' ...
           'BLoo_([-\d\.eE]+)_' ...
           'BLio_([-\d\.eE]+)_' ...
           'BLoi_([-\d\.eE]+)_' ...
           'D1_([-\d\.eE]+)_' ...
           'dt_([-\d\.eE]+)'];

    % Extract numeric tokens and convert to double
    tok = regexp(prefix, pat, 'tokens', 'once');
    if isempty(tok)
        params = nan(1,9);
    else
        params = str2double(tok);
    end
end


function idx_clusters = find_largest_cluster(MatrixP, contact_thresh)
% FIND_LARGEST_CLUSTER
% Returns indices for ALL clusters that tie for the largest size (i.e. maximum number of cells).
% Output is a cell array: each cell contains the row indices (into MatrixP/MatrixG) for one largest cluster.
%
% Inputs
%   MatrixP : N×3 positions [x y z]
%   contact_thresh : scalar; adjacency if cell-cell distance <= contact_thresh
%
% Output
%   idx_clusters : 1×M cell; each element is a vector of row indices for a largest cluster

    % Step 1: build adjacency by distance <= contact_thresh 
    N                = size(MatrixP,1);
    distance         = pdist2(MatrixP, MatrixP);
    distance_contact = (distance <= contact_thresh) & ~eye(N);

    % Step 2: connected components 
    graph_contact    = graph(sparse(triu(distance_contact,1)),'upper');
    cluster_labels   = conncomp(graph_contact);
    cluster_sizes    = accumarray(cluster_labels(:), 1);

    % Step 3: largest size & all labels that achieve it
    max_size   = max(cluster_sizes);
    labels_max = find(cluster_sizes == max_size);

    % Step 4: return ALL largest clusters 
    idx_clusters = cell(1, numel(labels_max));
    for i = 1:numel(labels_max)
        idx_clusters{i} = find(cluster_labels == labels_max(i));
    end

    % % (Optional)
    % if numel(labels_max) == 1
    %     fprintf('✅ Found one largest cluster (label=%d) with %d cells.\n', labels_max, numel(idx_clusters{1}));
    % else
    %     fprintf('✅ Found %d tied largest clusters (size=%d each). Returning all.\n', numel(labels_max), max_size);
    % end
end


function asymmetry = compute_asymmetry(position_cluster, gene_2_cluster, N_inner_global, N_outer_global)
% COMPUTE_ASYMMETRY
% Inputs
%   position_cluster : N×3 positions (x,y,z)
%   gene_2_cluster   : N×1 (0=inner, 1=outer)
%   N_inner_global   : scalar, total number of inner cells 
%   N_outer_global   : scalar, total number of outer cells
%
% Output
%   Returns a scalar asymmetry score >= 0
%   asymmetry = (||center_outer - center_inner|| / distance_center_avg) * (N_inner_local/N_inner_global) * (N_outer_local/N_outer_global)

    % Step 1: counts within the cluster
    N_inner_local = nnz(gene_2_cluster == 0);
    N_outer_local = nnz(gene_2_cluster == 1);

    % No separation if only one cell type present
    if N_inner_local == 0 || N_outer_local == 0
        asymmetry = 0;        
        return;
    end

    % Step 2: compute geometric center and mean distance to center
    center_cluster      = mean(position_cluster, 1);
    distance_center_avg = mean(vecnorm(position_cluster - center_cluster, 2, 2));  

    % Step 3: centers of outer/inner subsets
    center_outer = mean(position_cluster(gene_2_cluster == 1, :), 1);
    center_inner = mean(position_cluster(gene_2_cluster == 0, :), 1);

    % Step 4: compute weight based on cell number in the largest cluster versus the entire cell population
    inner_ratio = N_inner_local / N_inner_global;
    outer_ratio = N_outer_local / N_outer_global;
    weight  = inner_ratio * outer_ratio;

    % Step 5: compute asymmetry
    asymmetry = (norm(center_outer - center_inner) / distance_center_avg) * weight;
end