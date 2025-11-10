%% Step 1: Define input and output path
input_path       = '/n/data1/hms/sysbio/hormoz/users/suxuan/gastruloids_1500_25%_check';
OUTPUTS          = 6:10;  % Output groups to iterate over (OUTPUT6..OUTPUT10)
output_path      = '/n/data1/hms/sysbio/hormoz/users/suxuan/Materials/Codes/Virtual_Experiment/Experiment 4/Shuffle_Initial_Status/Initial_Status';
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

% (Optional) Plotting and geometry settings
cell_radius      = 1;                     
num_face         = 100;   
FIG_HEIGHT       = 500;
FIG_WIDTH        = 500;
fig_visibility   = 'on'; 
global_half_span = 12;

 
%% Step 2: Copy MatrixP and shuffle MatrixG to break two-layer initial status
for n = OUTPUTS

    % Step 2.1: Prepare I/O paths for this OUTPUT
    output_folder = fullfile(output_path, ['OUTPUT', num2str(n)]);
    if ~exist(output_folder, 'dir') 
        mkdir(output_folder); 
    end
    input_path_n = fullfile(input_path, sprintf('OUTPUT%d', n));
    input_file_P = fullfile(input_path_n, 'WorkSpace_MatrixP_Initial.csv');
    input_file_G = fullfile(input_path_n, 'WorkSpace_MatrixG_Initial.csv');

    % Step 2.2: Load the initial status of MatrixP and MatrixG
    MatrixP_initial = readmatrix(input_file_P);   
    MatrixG_initial = readmatrix(input_file_G); 

    % Step 2.3: Shuffle MatrixG by permuting its rows
    MatrixG_shuffled = MatrixG_initial(randperm(size(MatrixG_initial, 1)), :);

    % Step 2.4 (optional): Visualize before and after shuffle (uses col 2 as gene_2) for comparison 
    % Before shuffle
    draw_cell_structure(MatrixP_initial, MatrixG_initial(:, 2), [0, 0, 0], ...
                        global_half_span, cell_radius, num_face, ...
                        fig_visibility, FIG_HEIGHT, FIG_WIDTH);
    % After shuffle
    draw_cell_structure(MatrixP_initial, MatrixG_shuffled(:, 2), [0, 0, 0], ...
                        global_half_span, cell_radius, num_face, ...
                        fig_visibility, FIG_HEIGHT, FIG_WIDTH);

    % Step 2.5: Save outputs
    output_file_P   = fullfile(output_folder, 'WorkSpace_MatrixP_Initial.csv');
    writematrix(MatrixP_initial, output_file_P);
    output_file_G   = fullfile(output_folder, 'WorkSpace_MatrixG_Shuffled.csv');
    writematrix(MatrixG_shuffled, output_file_G);
end


%% (Optional) Helper function
function cell_figure = draw_cell_structure(position, gene_2, center, ...
                                           global_half_span, cell_radius, num_face, ...
                                           fig_visibility, FIG_HEIGHT, FIG_WIDTH)
% DRAW_CELL_STRUCTURE  
% Draw a 3D visualization of a multicellular structure.
%
% Inputs
%   position         : N×3 positions (x,y,z)
%   gene_2           : N×1 (0=inner, 1=outer)
%   center           : 1×3 geometric centroid of the position [x, y, z]
%   global_half_span : half-size of the bounding box for fixed scale (scalar)
%   cell_radius      : radius of each cell sphere (scalar)
%   num_face         : number of grid divisions for sphere smoothness (scalar)
%   fig_visibility   : 'on' or 'off', whether to show the figure window
%   FIG_HEIGHT       : figure height in pixels (scalar)
%   FIG_WIDTH        : figure width in pixels (scalar)
%
% Output
%   cell_figure      : figure handle to the created cell structure object

    % Step 1: Create figure and axes
    cell_figure = figure('Visible', fig_visibility, ...
                         'Position', [50, 50, FIG_HEIGHT, FIG_WIDTH], ...
                         'Color', 'w');                                       
    ax = axes('Parent', cell_figure);
    hold(ax, 'on'); 
    axis(ax, 'equal');       % Keep equal aspect ratio in all dimensions
    axis(ax, 'off');         % Hide axis ticks and frame for clean look
 
    % Step 2: Define fixed 3D view limits
    xlim(ax, [center(1) - global_half_span, center(1) + global_half_span]);
    ylim(ax, [center(2) - global_half_span, center(2) + global_half_span]);
    zlim(ax, [center(3) - global_half_span, center(3) + global_half_span]);

    % Step 3: Draw each cell as a colored sphere
    % Loop over all positions and render cells with colors based on cell type (gene_2 = 0 or 1)
    for n = 1:size(position, 1)
        [x, y, z] = ellipsoid(position(n,1), position(n,2), position(n,3), ...
                              cell_radius,   cell_radius,   cell_radius, ...
                              num_face);
        % Assign color
        if gene_2(n) == 1
            color = [1 0 0]; % Red  → outer cell
        else
            color = [0 0 1]; % Blue → inner cell
        end
        % Draw cell surface with smooth shading and no mesh edges
        surf(ax, x, y, z, ...
             'FaceColor', color, ...
             'EdgeColor', 'none', ...
             'FaceLighting', 'gouraud');
    end

    % Step 4: Configure lighting and camera view
    view(ax, [-165, -70]);   % Set azimuth and elevation angles
    camlight(ax, 'left');    % Add light from the left of camera
    material(ax, 'dull');    % Use soft, diffuse reflection (no bright glare)
end