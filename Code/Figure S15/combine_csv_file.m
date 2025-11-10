%% Step 1: Define file paths
file_path_D1_2 = '/Users/linda0122/Desktop/Materials/Tables/OUTPUT6_10_asymmetry_cluster_weighted_summary_confirm_101425_combined.csv';
file_path_D1_4 = '/Users/linda0122/Desktop/Materials/Tables/OUTPUT6_10_asymmetry_cluster_weighted_summary_confirm_101425_D1_4_combined.csv';

%% Step 2: Load both CSVs as tables
T1 = readtable(file_path_D1_2);
T2 = readtable(file_path_D1_4);
T_combined = [T1; T2];               % Combine vertically

%% Step 3: Sort by 'asymmetry_avg' (descending)
[~, sort_idx] = sort(T_combined.asymmetry_avg, 'descend');
T_sorted = T_combined(sort_idx, :);

%% Step 4: Save the ranked combined table
output_path = '/Users/linda0122/Desktop/Materials/Tables/OUTPUT6_10_asymmetry_cluster_weighted_summary_confirm_101425_combined_ranked_D1_2_4.csv';
writetable(T_sorted, output_path);

fprintf('✅ Combined and ranked table saved to:\n%s\n', output_path);
