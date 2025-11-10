%% =================== SETTINGS ===================
file_path = '/Users/linda0122/Desktop/Materials/Tables/OUTPUT6_10_asymmetry_cluster_weighted_summary_confirm_101425_combined_ranked_D1_2_4.csv';
out_dir        = '/Users/linda0122/Desktop/Materials/Figures/Figure 4/Figure 4A';
if ~exist(out_dir,'dir'), mkdir(out_dir); end

% Size and layout
BAR_H      = 1600;    % figure height
BAND_W     = 70;      % thickness of color bar
FIG_W      = 260;     % total figure width (bar + labels)
NX         = 2000;    % samples along bar
label_font = 20;      % font size for numbers

% Ranges
alpha_min_val = 0.65;  alpha_max_val = 0.95;
beta_cap      = 0.15;
LOSS_MAX      = 0.05;

%% Read CSV to get asymmetry range
T = readtable(file_path, 'PreserveVariableNames', true);
names_lower = lower(string(T.Properties.VariableNames));
asym_col = find(names_lower == "asymmetry_avg", 1);
asym_min_val = min(T{:, asym_col});
asym_max_val = max(T{:, asym_col});

%% Helper for figure + axis
make_fig_ax = @(name) deal( ...
    figure('Visible','off','Units','pixels','Position',[100 100 FIG_W BAR_H], ...
           'Color','w','Renderer','opengl','InvertHardcopy','off','Name',name), ...
    axes('Units','normalized','Position',[0.35 0.08 0.25 0.84]) );

%% === 1) ALPHA (black → green) ===
t = linspace(0,1,NX).';
img = zeros(NX, BAND_W, 3);
img(:,:,2) = repmat(t, 1, BAND_W);

[f, ax] = make_fig_ax('alpha');
image(ax, [0 1], [alpha_min_val alpha_max_val], img);
set(ax,'YDir','normal','XTick',[],'Box','on','LineWidth',1,'YColor','k','XColor','k');
ylim(ax,[alpha_min_val alpha_max_val]);
yt = alpha_min_val:0.1:alpha_max_val;  % Generate ticks automatically at 0.1 spacing
yticks(ax, yt);
yticklabels(ax, arrayfun(@(v) sprintf('%.2f', v), yt, 'UniformOutput', false));
set(ax,'FontSize',label_font,'FontWeight','normal');

try exportgraphics(f, fullfile(out_dir,'Colorbar_alpha.svg'), ...
        'ContentType','vector','BackgroundColor','white');
catch, print(f, fullfile(out_dir,'Colorbar_alpha'),'-dsvg','-opengl'); end
close(f);

%% === 2) BETA (blue → black → red) ===
v = linspace(-beta_cap,+beta_cap,NX).';
R = double(v>0).*min(v./beta_cap,1);
G = zeros(NX,1);
B = double(v<0).*min(-v./beta_cap,1);
img = zeros(NX,BAND_W,3);
img(:,:,1)=repmat(R,1,BAND_W); img(:,:,2)=repmat(G,1,BAND_W); img(:,:,3)=repmat(B,1,BAND_W);

[f, ax] = make_fig_ax('beta');
image(ax,[0 1],[-beta_cap +beta_cap],img);
set(ax,'YDir','normal','XTick',[],'Box','on','LineWidth',1,'YColor','k','XColor','k');
ylim(ax,[-beta_cap +beta_cap]);
yticks(ax,[-beta_cap 0 +beta_cap]);
yticklabels(ax,{sprintf('%.2f',-beta_cap),'0',sprintf('%.2f',+beta_cap)});
set(ax,'FontSize',label_font);

try exportgraphics(f, fullfile(out_dir,'Colorbar_beta.svg'), ...
        'ContentType','vector','BackgroundColor','white');
catch, print(f, fullfile(out_dir,'Colorbar_beta'),'-dsvg','-opengl'); end
close(f);

%% === 3) ASYMMETRY (white → orange) ===
t = linspace(0,1,NX).';
R=ones(NX,1); G=1-0.5*t; B=1-1.0*t;
img=zeros(NX,BAND_W,3);
img(:,:,1)=repmat(R,1,BAND_W); img(:,:,2)=repmat(G,1,BAND_W); img(:,:,3)=repmat(B,1,BAND_W);

[f, ax] = make_fig_ax('asym');
image(ax,[0 1],[asym_min_val asym_max_val],img);
set(ax,'YDir','normal','XTick',[],'Box','on','LineWidth',1,'YColor','k','XColor','k');
ylim(ax,[asym_min_val asym_max_val]);
yt = asym_min_val:1:asym_max_val;  % Generate ticks automatically at 1 spacing
yticks(ax, yt);
yticklabels(ax, arrayfun(@(v) sprintf('%.4g', v), yt, 'UniformOutput', false));
set(ax,'FontSize',label_font);

try exportgraphics(f, fullfile(out_dir,'Colorbar_asymmetry.svg'), ...
        'ContentType','vector','BackgroundColor','white');
catch, print(f, fullfile(out_dir,'Colorbar_asymmetry'),'-dsvg','-opengl'); end
close(f);

%% === 4) LOSS (orange → white, saturates at 0.1) ===
x=linspace(0,1,NX).';
w=min(x./LOSS_MAX,1);
R=ones(NX,1); G=0.5*(1-w)+1.0*w; B=0.0*(1-w)+1.0*w;
img=zeros(NX,BAND_W,3);
img(:,:,1)=repmat(R,1,BAND_W); img(:,:,2)=repmat(G,1,BAND_W); img(:,:,3)=repmat(B,1,BAND_W);

[f, ax] = make_fig_ax('loss');
image(ax,[0 1],[0 1],img);
set(ax,'YDir','normal','XTick',[],'Box','on','LineWidth',1,'YColor','k','XColor','k');
ylim(ax,[0 1]); 
yt_ = 0:0.25:1;
yt  = unique([yt_ LOSS_MAX]);
yticks(ax, yt);
yticklabels(ax, arrayfun(@(v) sprintf('%.2f', v), yt, 'UniformOutput', false));
set(ax,'FontSize',label_font);

try exportgraphics(f, fullfile(out_dir,'Colorbar_loss.svg'), ...
        'ContentType','vector','BackgroundColor','white');
catch, print(f, fullfile(out_dir,'Colorbar_loss'),'-dsvg','-opengl'); end
close(f);

fprintf('Saved vertical SVG colorbars (with black axes) to: %s\n', out_dir);

%% === Legend-style swatches for D ===
%% === D (binary) vertical colorbar (self-contained) ===
COLOR_D2 = [0.00, 0.60, 0.60];  % teal
COLOR_D4 = [0.55, 0.00, 0.80];  % purple
if ~exist('label_font','var'), label_font = 12; end
if ~exist('out_dir','var') || isempty(out_dir), out_dir = pwd; end
NX = 200; BAND_W = 40;     % resolution and bar width (adjust if you like)

imgD = zeros(NX, BAND_W, 3);
halfN = floor(NX/2);

% Lower half → D=2 (teal)
imgD(1:halfN, :, 1) = COLOR_D2(1);
imgD(1:halfN, :, 2) = COLOR_D2(2);
imgD(1:halfN, :, 3) = COLOR_D2(3);

% Upper half → D=4 (purple)
imgD(halfN+1:NX, :, 1) = COLOR_D4(1);
imgD(halfN+1:NX, :, 2) = COLOR_D4(2);
imgD(halfN+1:NX, :, 3) = COLOR_D4(3);

[fD, axD] = make_fig_ax('D');   % or: fD = figure('Color','w'); axD = axes('Parent',fD);
image(axD, [0 1], [0 1], imgD);
set(axD, 'XTick', [], 'YTick', [], 'XColor', 'none', 'YColor', 'none');
image(axD, [0 1], [0 1], imgD);
set(axD, 'YDir','normal', 'Box','on', 'LineWidth',1);
set(axD, 'XTick', [], 'YTick', [], 'XColor', 'none', 'YColor', 'none');
ylim(axD, [0 1]);
set(axD, 'FontSize', label_font);

try
    exportgraphics(fD, fullfile(out_dir,'Colorbar_D.svg'), ...
        'ContentType','vector','BackgroundColor','white');
catch
    print(fD, fullfile(out_dir,'Colorbar_D'), '-dsvg', '-opengl');
end
close(fD);
fprintf('Saved Colorbar_D.svg to: %s\n', out_dir);
