clear;
clc;

tic

video_name = 'data/baby2.mp4';
gaussian_stdev = 2;

%% INITIALS AND COLOR TRANSFORMATION

% video to frame_list(double-precision, [0, 1], YIQ)
[Fs, frame_list] = video_to_frame_list(video_name);
%%%% Fs: 30
%%%% frame_list: (height, width, ch, frame_number)

[height, width, ch, frame_number] = size(frame_list);

% load('frame_list.mat');

fprintf('INITIALS AND COLOR TRANSFORMATION end\n');
toc

%% INITIALS AND COLOR TRANSFOMRATION - RESULTS

% video = VideoReader(video_name);
% frame_1 = readFrame(video);
% 
% frame_1_yiq = zeros(height, width, ch);
% frame_1_yiq(:,:,:) = frame_list(:,:,:,1);

% subplot(1, 2, 1) %%%% frame #1 origianl
% imshow(frame_1)
% subplot(1, 2, 2) %%%% frame #1 YIQ
% imshow(frame_1_yiq)

%% LAPLACIAN PYRAMID

%%% just for frame_index: 1
% image_1 = zeros(height, width, ch);
% image_1(:,:,:) = frame_list(:,:,:,1);

% [image_1_gaussian_1, image_1_residual_0] = get_laplacian_pyramid(gaussian_stdev, image_1);
% [image_1_gaussian_2, image_1_residual_1] = get_laplacian_pyramid(gaussian_stdev, image_1_gaussian_1);

%% LAPLACIAN PYRAMID - RESULTS

% subplot(3, 2, 1)
% imshow(frame_1_yiq)
% subplot(3, 2, 3)
% imshow(imresize(image_1_gaussian_1, 2))
% subplot(3, 2, 5)
% imshow(imresize(image_1_gaussian_2, 4))
% subplot(3, 2, 2)
% imshow(image_1_residual_0)
% subplot(3, 2, 4)
% imshow(imresize(image_1_residual_1, 2))

%% LAPLACIAN PYRAMID - RECONSTRUCT

% image_reconstruct_1 = laplacian_up(image_1_gaussian_2, image_1_residual_1);
% image_reconstruct_0 = laplacian_up(image_1_residual_1, image_1_residual_0);

% subplot(1, 2, 1)
% imshow(frame_1_yiq)
% subplot(1, 2, 2)
% imshow(image_reconstruct_0)

%% LAPLACIAN PYRAMID - CUBE

[gaussian_cube_1, residual_cube_0] = get_cube(gaussian_stdev, frame_list);
[gaussian_cube_2, residual_cube_1] = get_cube(gaussian_stdev, gaussian_cube_1);
[gaussian_cube_3, residual_cube_2] = get_cube(gaussian_stdev, gaussian_cube_2);
[gaussian_cube_4, residual_cube_3] = get_cube(gaussian_stdev, gaussian_cube_3);

fprintf('LAPLACIAN PYRAMID end\n');
toc

%% TEMPORAL FILTERING

[residual_seq_0_f, residual_seq_0_filtered] = check_cube_freq(residual_cube_0);

% plot(residual_seq_0_f, residual_seq_0_filtered);

fprintf('TEMPORAL FILTERING end\n');
toc

%% EXTRACTING THE FREQUENCY BAND OF INTEREST

%%%% _f: filtered
%%%% _s: scaled

% Hd = butterworthBandpassFilter(Fs, 256, 0.83, 1);
Hd = butterworthBandpassFilter(Fs, 256, 0.8, 1);

residual_cube_0_filtered = filter_cube(Hd, residual_cube_0);
residual_cube_1_filtered = filter_cube(Hd, residual_cube_1);
residual_cube_2_filtered = filter_cube(Hd, residual_cube_2);
residual_cube_3_filtered = filter_cube(Hd, residual_cube_3);
gaussian_cube_4_filtered = filter_cube(Hd, gaussian_cube_4);

clear('Hd');

fprintf('EXTRACTING THE FREQUENCY BAND OF INTEREST end\n');
toc

%% IMAGE RECONSTRUCTION

frame_list_reconstructed = zeros(height, width, ch, frame_number);

alpha_0 = 100;
alpha_1 = 100;
alpha_2 = 100;
alpha_3 = 100;
alpha_4 = 100;

image_residual_0_re = zeros(size(residual_cube_0_filtered,1), size(residual_cube_0_filtered,2), ch); % re means reconstructed
image_residual_1_re = zeros(size(residual_cube_1_filtered,1), size(residual_cube_1_filtered,2), ch);
image_residual_2_re = zeros(size(residual_cube_2_filtered,1), size(residual_cube_2_filtered,2), ch);
image_residual_3_re = zeros(size(residual_cube_3_filtered,1), size(residual_cube_3_filtered,2), ch);
image_gaussian_4_re = zeros(size(gaussian_cube_4_filtered,1), size(gaussian_cube_4_filtered,2), ch);

for t = 1: frame_number

    image_residual_0_re(:,:,1) = residual_cube_0_filtered(:,:,1,t);
    image_residual_1_re(:,:,1) = residual_cube_1_filtered(:,:,1,t);
    image_residual_2_re(:,:,1) = residual_cube_2_filtered(:,:,1,t);
    image_residual_3_re(:,:,1) = residual_cube_3_filtered(:,:,1,t);
    image_gaussian_4_re(:,:,1) = gaussian_cube_4_filtered(:,:,1,t);
    
    image_reconstructed_frame = frame_list(:,:,1,t) + alpha_0 * image_residual_0_re + alpha_1 * imresize(image_residual_1_re, 2) + ...
        + alpha_2 * imresize(image_residual_2_re, 4) + alpha_3 * imresize(image_residual_3_re, [height, width]) + alpha_4 * imresize(image_gaussian_4_re, [height, width]);
    
    frame_list_reconstructed(:,:,1,t) = image_reconstructed_frame(:,:,1);
 
end

frame_list_reconstructed(:,:,2:ch,:) = frame_list(:,:,2:ch,:);

fprintf('IMAGE RECONSTRUCTION end\n');
toc

%% IMAGE RECONSTRUCTION - VIDEO

% make_avi(frame_list, 'frame_list');
% fprintf('SAVE frame_list end\n');
% toc

make_avi(frame_list_reconstructed, '_reconstructed');
fprintf('SAVE frame_list_reconstructed end\n');
toc

fprintf('IMAGE RECONSTRUCTION - VIDEO end\n');
toc

%% FUNCTIONS - video_to_frame_list

function [Fs, frame_list] = video_to_frame_list(video_name)

    % Load the video file into Matlab
    video = VideoReader(video_name);

    % extract basic informations of video
    Fs = round(video.FrameRate);
    
    length = video.Duration * video.FrameRate;
    length_round = round(video.Duration * video.FrameRate);
    height = video.Height;
    width = video.Width;
    ch = video.BitsPerPixel / 8;
    
    frame_list = zeros(height, width, ch, length_round);

    % frames -> array
    for frame_index = 1: length_round-1
        video.CurrentTime = frame_index * 1 / video.FrameRate;
        frame = readFrame(video);
                
        % uint8 -> double-precision / to range [0, 1]
        frame = double(frame) / 255;
        
        % RGB to YIQ
        frame = rgb2ntsc(frame);
        
        frame_list(:, :, :, frame_index) = frame(:, :, :);
    end

    % frames -> array: for last frame
    frame_index = length_round;

    video.CurrentTime = length * 1 / video.FrameRate;
    frame = readFrame(video);
    
    % uint8 -> double-precision / to range [0, 1]
    frame = double(frame) / 255;

    % RGB to YIQ
    frame = rgb2ntsc(frame);

    frame_list(:, :, :, frame_index) = frame(:, :, :);
    
end

%% FUNCTIONS - get_laplacian_pyramid

function [image_gaussian, image_residual] = get_laplacian_pyramid(gaussian_stdev, image_original)

    [height, width, ~] = size(image_original);
    
    % Apply Gaussian Filter
    image_blurred = imgaussfilt(image_original, gaussian_stdev);

    % Compute residual
    image_residual = image_original - image_blurred;

    % Subsample
    image_gaussian = image_blurred(1:2:height, 1:2:width, :);

end

%% FUNCTIONS - laplacian_up

function image_reconstruct_1 = laplacian_up(image_gaussian, image_residual)
    
    image_gaussian_up = imresize(image_gaussian, 2); %%%% imresize uses bicubic interpolation.
    image_reconstruct_1 = image_gaussian_up + image_residual;
    
end

%% FUNCTIONS - get_cube

function [gaussian_cube, residual_cube] = get_cube(gaussian_stdev, gaussian_cube_original)

    [height_, width_, ch, frame_number] = size(gaussian_cube_original);
    
    %%%% Initialize its size
    gaussian_cube = zeros(fix((height_+1)/2), fix((width_+1)/2), ch, frame_number);
    residual_cube = zeros(height_, width_, ch, frame_number);

    for i = 1: frame_number
        gaussian_frame = zeros(height_, width_, ch);
        gaussian_frame(:,:,:) = gaussian_cube_original(:,:,:,i);
        
        [image_gaussian, image_residual] = get_laplacian_pyramid(gaussian_stdev, gaussian_frame);
        residual_cube(:,:,:,i) = image_residual;
        gaussian_cube(:,:,:,i) = image_gaussian;
    end
    
end

%% FUNCTIONS - filter_cube

function cube_filtered = filter_cube(Hd, cube)

    [height, width, ch, frame_count] = size(cube);

    cube_filtered = zeros(height, width, ch, frame_count);
    cube_pixel = zeros(frame_count, 1);
    
    Hd_fft = freqz(Hd, frame_count);

    for i = 1: height
        for j = 1: width
            cube_pixel(:,1) = cube(i,j,1,:);
            cube_pixel_fft = fft(cube_pixel);
            cube_pixel_filtered = abs(ifft(cube_pixel_fft .* Hd_fft));
            cube_filtered(i,j,1,:) = cube_pixel_filtered(:, 1);
        end
    end
        
end

%% FUNCTIONS - make_avi

function make_avi(cube, avi_name)

    [height, width, ch, frame_number] = size(cube);

    cube_frame = zeros(height, width, ch);

    v = VideoWriter(avi_name, 'Uncompressed AVI');
    open(v)

    for t = 1: frame_number
        cube(:,:,1,t) = imadjust(cube(:,:,1,t), stretchlim(cube(:,:,1,t)));

        cube_frame(:,:,:) = cube(:,:,:,t);

        % YIQ to RGB
        cube_frame = ntsc2rgb(cube_frame);

        writeVideo(v,cube_frame);
    end
    
    close(v)

end

%% FUNCTIONS - filter_on_residual

function [f, cube_fft] = check_cube_freq(cube)

    [height, width, ~, frame_number] = size(cube);
    
    Fs = 30;

    f = Fs * (0:(fix(frame_number/2)))/frame_number;

    cube_fft = zeros(fix(frame_number/2) + 1, 1);
    cube_pixel = zeros(frame_number, 1);

    for i = 1: height
        for j = 1: width

            cube_pixel(:,1) = cube(i, j, 1, :);
            fftx = fft(cube_pixel);
 
            P2 = abs(fftx/frame_number);
            P1 = P2(1:fix(frame_number/2)+1);
            P1(2:end-1) = 2*P1(2:end-1);

            cube_fft(:,1) = cube_fft(:,1) + P1(:,1);

        end
    end
    
end