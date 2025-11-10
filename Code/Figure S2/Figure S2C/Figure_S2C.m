% =======================================================================
% Render four ellipsoid images of step states
% Save to Supplement_Illustration/Supplement_Process as PNG
% =======================================================================

% ===================== User Parameters =====================
parent_path   = '/n/scratch/users/s/suw469/gastruloids_1500_25%_check';
out_dir       = '/home/suw469/codes/Gastruloid_Modeling/Modeling/Check/Visualization/Supplement_Illustration/Supplement_Process';
ensure_dir(out_dir);

NNN           = 15;          % lattice size
r             = 1;           % cell radius
alpha         = 0.80;        % packing
resolution    = 100;         % mesh resolution for ellipsoids
SampleID      = 6;           % OUTPUT6 folder
final_prefix  = 'Aii_0.775_Aoo_0.950_Aio_0.875_BLii_0.000_BLoo_0.135_BLio_0.000_BLoi_0.000_D1_2_dt_0.20';

% 1) Build lattice, define fixed spread 
P_lattice = build_centered_lattice(NNN, r, alpha);
spread    = max(abs(P_lattice), [], 1);  % half-extent along x,y,z
spread    = spread + 2.0;                % add ±2 units on each axis
center    = mean(P_lattice,1);

draw_cells(P_lattice, ones(size(P_lattice,1),1)*-1, ...
    r, resolution, spread, center, 'Image_1_Lattice15x15x15', out_dir);

% 2) MatrixP Initial all grey 
P_init = readmatrix(fullfile(parent_path, sprintf('OUTPUT%d', SampleID), 'WorkSpace_MatrixP_Initial.csv'));
draw_cells(P_init, ones(size(P_init,1),1)*-1, ...
    r, resolution, spread, center, 'Image_2_MatrixP_Initial_allgrey', out_dir);

% 3) MatrixP Initial colored by Gene2 
P_init = readmatrix(fullfile(parent_path, sprintf('OUTPUT%d', SampleID), 'WorkSpace_MatrixP_Initial.csv'));
G_init = readmatrix(fullfile(parent_path, sprintf('OUTPUT%d', SampleID), 'WorkSpace_MatrixG_Initial.csv'));
gene2  = G_init(:,2);
draw_cells(P_init, gene2, ...
    r, resolution, spread, center, 'Image_3_MatrixP_Initial_Gene2', out_dir);

% 4) MatrixP Final colored by Gene2 
P_final = readmatrix(fullfile(parent_path, sprintf('OUTPUT%d', SampleID), [final_prefix '_MatrixP_Final.csv']));
G_final = readmatrix(fullfile(parent_path, sprintf('OUTPUT%d', SampleID), [final_prefix '_MatrixG_Final.csv']));
gene2_f = G_final(:,2);
draw_cells(P_final, gene2_f, ...
    r, resolution, spread, center, 'Image_4_MatrixP_Final_Gene2', out_dir);

disp('All four images saved.');



%% ===================== Helper Functions =====================

function ensure_dir(d)
    if ~exist(d,'dir'), mkdir(d); end
end

function P = build_centered_lattice(NNN, r, alpha)
    center = (NNN+1)/2;
    scale  = 2*r*alpha;
    P = zeros(NNN^3,3);
    idx=1;
    for x=1:NNN
        for y=1:NNN
            for z=1:NNN
                coord = [x-center, y-center, z-center]*scale;
                P(idx,:) = coord;
                idx=idx+1;
            end
        end
    end
end


function draw_cells(position, gene2, r, resolution, spread, center, out_name, out_dir)
    
    f = figure('Visible','off','Position',[50,50,600,600], ...
               'Color','w','Renderer','opengl');
    ax = axes('Parent', f); hold(ax,'on');
    axis(ax,'equal'); axis(ax,'off');

    % fixed cube limits
    xlim(ax,[center(1)-spread(1), center(1)+spread(1)]);
    ylim(ax,[center(2)-spread(2), center(2)+spread(2)]);
    zlim(ax,[center(3)-spread(3), center(3)+spread(3)]);

    for n = 1:size(position,1)
        x          = position(n,1); 
        y          = position(n,2); 
        z          = position(n,3);
        [rx,ry,rz] = ellipsoid(x,y,z, r,r,r, resolution);
        if    gene2(n)==1
            color=[1 0 0];       % red outer
        elseif gene2(n)==0
            color=[0 0 1];       % blue inner
        else
            color=[0.5 0.5 0.5]; % grey default
        end
        surf(ax,rx,ry,rz,'FaceColor',color,'FaceAlpha',1, ...
             'EdgeColor','none','FaceLighting','gouraud');
    end

    % camera & lighting
    view(ax, [-165, -70]);
    camlight(ax,'left'); 
    material(ax,'dull');

    % Save PNG
    out_file = fullfile(out_dir, [out_name '.png']);
    save_figure_png(f, out_file, 600)
    close(f);

end


function save_figure_png(f, out_path, dpi)

    % Ensure target folder exists
    out_dir = fileparts(out_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    
    try
        exportgraphics(f, out_path, 'Resolution', dpi, 'BackgroundColor', 'white');
        fprintf('✅ Successfully saved PNG: %s\n', out_path);
    catch ME
        fprintf('❌ Failed to save PNG: %s\n', out_path);
        fprintf('   Error message: %s\n', ME.message);
    end
end
