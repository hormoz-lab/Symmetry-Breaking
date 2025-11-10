% Step 0: Define parent path to save the scanning library output
parent_path = '/n/scratch/users/s/suw469/gastruloids_1500_25%_check';

% Step 1: Initialize final scanning library
scanning_library = [];

% Step 2: Define alpha values
alpha_values       = 0.65:0.025:0.95;                                    % 13 values
[Aii, Aoo, Aio]    = ndgrid(alpha_values, alpha_values, alpha_values);
alpha_combinations = [Aii(:), Aoo(:), Aio(:)];                           % 13 x 13 x 13 = 2197 rows

% Step 3: all-zero betaL block
betaL_zero_block   = [alpha_combinations, zeros(size(alpha_combinations,1),4)];
scanning_library   = [scanning_library; betaL_zero_block];

% Step 4: Define betaL values (symmetric)
betaL_values         = -0.15:0.015:0.15;                                 % 21 values
betaL_values_nonzero = betaL_values(betaL_values ~= 0);                  % 20 values (exclude 0)

% Step 4: Loop over each betaL axis separately (betaL_ii, betaL_oo, betaL_io, betaL_oi)
for betaL_axis = 1:4
    for b = 1:length(betaL_values_nonzero)
        % Create betaL column with only one non-zero entry
        betaL_block = zeros(size(alpha_combinations, 1), 4);             % 4 columns for betaL ii, oo, io, oi
        betaL_block(:, betaL_axis) = betaL_values_nonzero(b);            % each time set only one type of betaL be non-zero

        % Combine alpha and betaL parts
        % [alpha_ii, alpha_oo, alpha_io, betaL_ii, betaL_oo, betaL_io, betaL_oi]
        combined = [alpha_combinations, betaL_block];  
        scanning_library = [scanning_library; combined];                 % append to the final scanning library
    end
end

% Step 6: Keep only unique rows
scanning_library_unique = unique(scanning_library, 'rows');

% Step 7: Save to .mat file
save(fullfile(parent_path, 'scanning_library.mat'), 'scanning_library'); % final scanning library 
                                                                         % total number of combination: 2197 + 2197 x 20 x 4 = 177957 rows
                                                                         % final dimension: 177957 rows, 7 columns  