%% Step 1: Load table
% Input and output files
input_file  = '/Users/linda0122/Desktop/Materials/Tables/Table 1/OUTPUT6_10_asymmetry_cluster_weighted_summary_confirm_101425_combined_ranked.csv';
output_file = '/Users/linda0122/Desktop/Materials/Figures/Figure 4/Figure 4G/Figure_4G.csv';

% Read table
T = readtable(input_file);

%% Step 2: Build baseline table
% Build baseline table (all betas = 0)
base_table = (T.betaL_ii == 0) ...
           & (T.betaL_oo == 0) ... 
           & (T.betaL_io == 0) ...
           & (T.betaL_oi == 0);
base_table = T(base_table, {'alpha_ii','alpha_oo','alpha_io','asymmetry_avg'});            % Extract only the columns you want
base_table = sortrows(base_table, {'alpha_ii','alpha_oo','alpha_io'});                     % Sort by the three alphas
base_table.Properties.VariableNames{'asymmetry_avg'} = 'asymmetry_avg_base';               % Rename baseline asymmetry column

%% Step 3: Compute asymmetry difference 
% Step 3.1: Extract unique beta_oo values >= 0
beta_values = unique(T.betaL_oo);
beta_values = beta_values(beta_values >= 0);
beta_values = sort(beta_values)';

% Step 3.2: Loop through all beta_oo values
for beta_value = beta_values

    % Step 3.2.1: Select rows for the current beta_oo
    compare_table = (T.betaL_ii == 0) ...
                  & (T.betaL_oo == beta_value) ... 
                  & (T.betaL_io == 0) ...
                  & (T.betaL_oi == 0); 
    compare_table = T(compare_table, {'alpha_ii','alpha_oo','alpha_io','asymmetry_avg'});  % Extract only the columns you want
    compare_table = sortrows(compare_table, {'alpha_ii','alpha_oo','alpha_io'});           % Sort by the three alphas
    
    % Step 3.2.2: Double check alpha matching 
    if ~isequal(compare_table.alpha_ii, base_table.alpha_ii) || ...
       ~isequal(compare_table.alpha_oo, base_table.alpha_oo) || ...
       ~isequal(compare_table.alpha_io, base_table.alpha_io)
        error('Alpha mismatch for beta_oo = %.3f', b);
    end
    
    % Step 3.2.3: Compute asymmetry difference relative to baseline
    asymmetry_diff = compare_table.asymmetry_avg - base_table.asymmetry_avg_base;          % Compute asymmetry differences
    col_name_diff  = sprintf('asymmetry_diff_betaL_oo_%.3f', beta_value);                  % Create column name
    col_name_diff   = strrep(col_name_diff, '.', '_');
    base_table.(col_name_diff) = asymmetry_diff;                                           % Append as new column
end

%% Step 4: Save output table
writetable(base_table, output_file);
fprintf(['Computed asymmetry differences for betaL_oo values from %.3f to %.3f ', ...
         'relative to the baseline (all beta values = 0).\n' ...
         'CSV file saved to:\n%s\n'], ...
         min(beta_values), max(beta_values), output_file);
