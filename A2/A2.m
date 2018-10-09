tic

video_name = 'data/baby2.mp4';
gaussian_stdev = 2;

%% INITIALS AND COLOR TRANSFORMATION

% video to frame_list(double-precision, [0, 1], YIQ)
[Fs, frame_list] = video_to_frame_list(video_name);
%%%% Fs: 30
%%%% frame_list: (frame_number, height, width) -> only Y in YIQ space

fprintf('INITIALS AND COLOR TRANSFORMATION end\n');
toc

%% INITIALS AND COLOR TRANSFOMRATION - RESULTS

video = VideoReader(video_name);
frame_1 = readFrame(video);
%%%% frame_1: first frame in video, raw -> (height, width, ch)

frame_1_y = zeros(size(frame_1, 1), size(frame_1, 2), 1);
frame_1_y(:,:,1) = frame_list(1,:,:);

% subplot(1, 2, 1) %%%% frame #1 origianl
% imshow(frame_1)
% subplot(1, 2, 2) %%%% frame #1 only Y
% imshow(frame_1_y)

%% LAPLACIAN PYRAMID

[image_gaussian_1, image_residual_0] = get_laplacian_pyramid(gaussian_stdev, frame_list, 1, 1);
%%%% image_residual_0: (height, width)
%%%% image_gaussain_1: (height/2, width/2)
[image_gaussian_2, image_residual_1] = get_laplacian_pyramid(gaussian_stdev, frame_list, 1, 2);
%%%% image_residual_1: (height/2, width/2)
%%%% image_gaussain_2: (height/4, width/4)

% residual_seq_0 = get_residual_seq(2, frame_list, 1);
% %%% residual_seq_0: (frame_length, height, width, ch)
% residual_seq_1 = get_residual_seq(2, frame_list, 2);

fprintf('LAPLACIAN PYRAMID end\n');
toc

%% LAPLACIAN PYRAMID - RESULTS

% subplot(3, 2, 1)
% imshow(frame_1_y)
% subplot(3, 2, 3)
% imshow(imresize(image_gaussian_1, 2))
% subplot(3, 2, 5)
% imshow(imresize(image_gaussian_2, 4))
% subplot(3, 2, 2)
% imshow(image_residual_0)
% subplot(3, 2, 4)
% imshow(imresize(image_residual_1, 2))

%% LAPLACIAN PYRAMID - RECONSTRUCT

image_reconstruct_1 = laplacian_up(image_gaussian_2, image_residual_1);
image_reconstruct_0 = laplacian_up(image_reconstruct_1, image_residual_0);

% subplot(1, 2, 1)
% imshow(frame_1_y)
% subplot(1, 2, 2)
% imshow(image_reconstruct_0)

%% TEMPORAL FILTERING

% residual_seq_0_filtered = filter_on_residual(residual_seq_0, Fs);

fprintf('TEMPORAL FILTERING end\n');
toc

%% EXTRACTING THE FREQUENCY BAND OF INTEREST

fprintf('EXTRACTING THE FREQUENCY BAND OF INTEREST end\n');
toc

%% IMAGE RECONSTRUCTION

% Hd = butterworthBandpassFilter(Fs, 256, 0.83, 1);
Hd = butterworthBandpassFilter(Fs, 256, 0.83, 1);

image_reconstruct_filtered = zeros(size(frame_list,1), size(frame_list,2), size(frame_list,3));

image_residual_cube_0 = zeros(size(frame_list,1), size(frame_list,2), size(frame_list,3));
for k = 1: size(frame_list, 1)

    [~, image_residual_0] = get_laplacian_pyramid(gaussian_stdev, frame_list, k, 1);
    image_residual_cube_0(k,:,:) = image_residual_0;

end

image_residual_cube_0_filtered = zeros(size(frame_list, 1), size(image_residual_0, 1), size(image_residual_0, 2));

for i = 1: size(frame_list, 2)
    for j = 1: size(frame_list, 3)


        image_residual_0_pixel = image_residual_cube_0(:,i,j);
        image_residual_0_pixel_filtered = filter(Hd, image_residual_0_pixel);
        image_residual_cube_0_filtered(:,i,j) = image_residual_0_pixel_filtered;

    end

end

image_residual_cube_0_filtered_scaled = zeros(size(image_residual_cube_0_filtered));

for t = 1: size(image_residual_cube_0_filtered, 1)

    max_ = max(max(image_residual_cube_0_filtered(t,:,:)));
    min_ = min(min(image_residual_cube_0_filtered(t,:,:)));
    
    a = 1 / (max_ - min_);
    b = min_ / (min_ - max_);
    
    image_residual_cube_0_filtered_scaled(t,:,:) = image_residual_cube_0_filtered(t,:,:) * a + b;
    
end

v = VideoWriter('image_residual_0', 'Archival');
open(v)

image_frame_filtered = zeros(size(image_residual_cube_0_filtered_scaled, 2), size(image_residual_cube_0_filtered_scaled, 3));
image_frame_filtered_video = zeros(size(image_residual_cube_0_filtered_scaled, 2), size(image_residual_cube_0_filtered_scaled, 3));

for t = 1: size(image_residual_cube_0_filtered_scaled, 1)

    image_frame_filtered(:,:) = image_residual_cube_0_filtered_scaled(t,:,:);
    image_frame_filtered_video(:,:) = max(image_frame_filtered(:,:),0);
    writeVideo(v,image_frame_filtered_video);

end

close(v)

% imshow(image_reconstruct_filtered(1,:,:))

fprintf('IMAGE RECONSTRUCTION end\n');
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
    
%     frame_list = zeros(length_round, height, width, ch);
    frame_list = zeros(length_round, height, width);

    % frames -> array
    for frame_index = 1: length_round-1
        video.CurrentTime = frame_index * 1 / video.FrameRate;
        frame = readFrame(video);
        
        % uint8 -> double-precision / to range [0, 1]
        frame = double(frame) / 255;
        
        % RGB to YIQ
        frame = rgb2ntsc(frame);
        
        frame_list(frame_index, :, :, :) = frame(:, :, 1);
    end

    % frames -> array: for last frame
    frame_index = length_round;

    video.CurrentTime = length * 1 / video.FrameRate;
    frame = readFrame(video);

    % uint8 -> double-precision / to range [0, 1]
    frame = double(frame) / 255;

    % RGB to YIQ
    frame = rgb2ntsc(frame);

    frame_list(frame_index, :, :, :) = frame(:, :, 1);
    
end

%% FUNCTIONS - get_laplacian_pyramid

function [image_gaussian, image_residual] = get_laplacian_pyramid(gaussian_stdev, frame_list, frame_index, gaussian_index)

    image_raw = zeros(size(frame_list, 2), size(frame_list, 3));
    image_raw(:, :) = frame_list(frame_index, :, :);
    
    image_original = image_raw;
    %%%% image_original: (height, width)
    
    for i = 1: gaussian_index

        % Apply Gaussian Filter
        image_blurred = imgaussfilt(image_original, gaussian_stdev);
        
        % Compute residual
        image_residual = image_original - image_blurred;
        
        % Subsample
        image_original = image_blurred(1:2:size(image_blurred,1), 1:2:size(image_blurred,2));

    end
    
    image_gaussian = image_original;

end

%% FUNCTIONS - laplacian_up

function image_reconstruct_1 = laplacian_up(image_gaussian, image_residual)
    
    image_gaussian_up = imresize(image_gaussian, 2); %%%% imresize uses bicubic interpolation.
    image_reconstruct_1 = image_gaussian_up + image_residual;
    
end

%% FUNCTIONS - get_residual_seq

function residual_seq = get_residual_seq(gaussian_stdev, frame_list, gaussian_index)
    
    [~, image_residual_0] = get_laplacian_pyramid(gaussian_stdev, frame_list, 1, gaussian_index);

    residual_seq = zeros(size(frame_list, 1), size(image_residual_0, 1), size(image_residual_0, 2), size(image_residual_0, 3));

    for i = 1: size(frame_list, 1)
        
        [~, image_residual] = get_laplacian_pyramid(gaussian_stdev, frame_list, i, gaussian_index);

        residual_seq(i, :, :, :) = image_residual;

    end
    
end

%% FUNCTIONS - filter_on_residual

function residual_seq_filtered = filter_on_residual(residual_seq, Fs)

    L = size(residual_seq, 1);
%     T = 1/Fs;
%     t = (0:L-1) * T;

    residual_seq_filtered = zeros(size(residual_seq, 1) / 2 + 1, size(residual_seq, 2), size(residual_seq, 3), size(residual_seq, 4));
    Hd = butterworthBandpassFilter(Fs, 256, 0.83, 1);

    for i = 1: size(residual_seq, 2)
        for j = 1: size(residual_seq, 3)
            for ch = 1: size(residual_seq, 4)

                x = residual_seq(:, i, j, ch);
                fftx = fft(x);

                P2 = abs(fftx/L);
                P1 = P2(1:L/2+1);
                P1(2:end-1) = 2*P1(2:end-1);

                f = Fs * (0:(L/2))/L;

                P1_filtered = filter(Hd, P1);

%                 plot(f, P1)
%                 hold on
%                 plot(f, P1_filtered)
%                 hold off

                ifftx = ifft(P1_filtered);
                ifftx = real(ifftx/L);

                residual_seq_filtered(:, i, j, ch) = ifftx;

            end
        end
    end
    
end