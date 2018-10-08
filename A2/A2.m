tic

video_name = 'data/baby2.mp4';

%% INITIALS AND COLOR TRANSFORMATION

% video to frame_list(double-precision, [0, 1], YIQ)
frame_list = video_to_frame_list(video_name);

fprintf('INITIALS AND COLOR TRANSFORMATION end');

toc

%% LAPLACIAN PYRAMID

[image_gaussian_1, image_residual_1] = get_gaussian_pyramid(2, frame_list, 1, 1);
[image_gaussian_2, image_residual_2] = get_gaussian_pyramid(2, frame_list, 1, 2);
[image_gaussian_3, image_residual_3] = get_gaussian_pyramid(2, frame_list, 1, 3);
[image_gaussian_4, image_residual_4] = get_gaussian_pyramid(2, frame_list, 1, 4);
[image_gaussian_5, image_residual_5] = get_gaussian_pyramid(2, frame_list, 1, 5);
[image_gaussian_6, image_residual_6] = get_gaussian_pyramid(2, frame_list, 1, 6);
[image_gaussian_7, image_residual_7] = get_gaussian_pyramid(2, frame_list, 1, 7);

fprintf('LAPLACIAN PYRAMID end');

toc

%% TEMPORAL FILTERING

Hd = butterworthBandpassFilter(30, 256, 0.83, 1);

fprintf('TEMPORAL FILTERING end');

toc

%% FUNCTIONS - video_to_frame_list

function frame_list = video_to_frame_list(video_name)

    % Load the video file into Matlab
    video = VideoReader(video_name);

    % extract basic informations of video
    length = video.Duration * video.FrameRate;
    length_round = round(video.Duration * video.FrameRate);
    height = video.Height;
    width = video.Width;
    ch = video.BitsPerPixel / 8;
    
    frame_list = zeros(length_round, height, width, ch);

    % frames -> array
    for frame_index = 1: length_round-1
        video.CurrentTime = frame_index * 1 / video.FrameRate;
        frame = readFrame(video);
        
        % uint8 -> double-precision / to range [0, 1]
        frame = double(frame) / 255;
        
        % RGB to YIQ
        frame = rgb2ntsc(frame);
        
        frame_list(frame_index, :, :, :) = frame;
    end

    % frames -> array: for last frame
    frame_index = length_round;

    video.CurrentTime = length * 1 / video.FrameRate;
    frame = readFrame(video);

    % uint8 -> double-precision / to range [0, 1]
    frame = double(frame) / 255;

    % RGB to YIQ
    frame = rgb2ntsc(frame);

    frame_list(frame_index, :, :, :) = frame;
    
end

%% FUNCTIONS - get_gaussian_pyramid

function [image_gaussian, image_residual] = get_gaussian_pyramid(gaussian_stdev, frame_list, frame_index, gaussian_index)
    image_raw_4d = frame_list(frame_index, :, :, :);
    image_raw = reshape(image_raw_4d, size(image_raw_4d, 2), size(image_raw_4d, 3), size(image_raw_4d, 4));
    
    image_original = image_raw;
    
    for i = 1: gaussian_index

        % Apply Gaussian Filter
        image_blurred = imgaussfilt(image_original, gaussian_stdev);
        
        % Compute residual
        image_residual = image_original - image_blurred;
        
        % Subsample
        image_original = image_blurred(1:2:size(image_blurred,1), 1:2:size(image_blurred,2), :);

    end
    
    image_gaussian = image_original;

end
