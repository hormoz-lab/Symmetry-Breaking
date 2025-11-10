%% Step 1: USER SETTINGS
% Input and output files
input_path   = '/Users/linda0122/Desktop/Movie S2';
output_video = fullfile(input_path, '/Movie_S2.avi'); 
fps          = 30;   % frames per second


%% Step 2: Find and sort PNG files
png_files = dir(fullfile(input_path, '*.png'));
png_names = {png_files.name};
fprintf('Found %d PNG frames.\n', numel(png_names));
frames = zeros(1, numel(png_names));
for i = 1:numel(png_names)
    tok       = regexp(png_names(i), ...
                       'T_(\d+)', 'tokens', 'once');       % Extract frame numbers from filenames
    frames(i) = str2double(tok{1});
end
[~, idx]  = sort(frames);                                  % Sort filenames by extracted frame index
png_names = png_names(idx);


%% Step 3: Extract size information from the first frame 
first_frame_path = fullfile(input_path, png_names{1});
first_frame      = imread(first_frame_path);
if size(first_frame,3) == 4
    first_frame = first_frame(:,:,1:3);                  % Convert to RGB if RGBA
end
first_frame                  = im2uint8(first_frame);    % Ensure uint8 format for VideoWriter
[height, width, num_channel] = size(first_frame);
fprintf('Frame size = %d x %d x %d\n', height, width, num_channel);


%% Step 4: Generate video 
video_writer           = VideoWriter(output_video, 'Motion JPEG AVI');
video_writer.FrameRate = fps;
open(video_writer);
fprintf('Writing video: %s\n', output_video);

% Loop through all sorted PNG frames
for i = 1:numel(png_names)
    png_path = fullfile(input_path, png_names{i});
    png      = imread(png_path);
    if size(png, 3) == 4
        png = png(:,:,1:3);                              % Convert to RGB if RGBA
    end
    png = im2uint8(png);                                 % Ensure uint8 format for VideoWriter
    writeVideo(video_writer, png);

    if mod(i,20)==0 || i==numel(png_files)               % Print progress every 20 frames and at the end
        fprintf('  processed %d / %d frames\n', i, numel(png_files));
    end
end

close(video_writer);
fprintf('\n✅ DONE! Video saved at:\n%s\n', output_video);


%% Step 5: Website to convert avi to mp4
% 'https://www.freeconvert.com/video-converter'