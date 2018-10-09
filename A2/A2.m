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

%%%% _f: filtered
%%%% _s: scaled

Hd = butterworthBandpassFilter(Fs, 256, 0.83, 1);

[gaussian_cube_1, residual_cube_0] = get_cube(gaussian_stdev, frame_list, 1);
[gaussian_cube_2, residual_cube_1] = get_cube(gaussian_stdev, frame_list, 2);

residual_0_cube_f_s = get_cube_f_s(Hd, residual_cube_0);
fprintf('residual_0_cube_f_s end\n');
toc

residual_1_cube_f_s = get_cube_f_s(Hd, residual_cube_1);
fprintf('residual_1_cube_f_s end\n');
toc

gaussian_2_cube_f_s = get_cube_f_s(Hd, gaussian_cube_2);
fprintf('gaussian_2_cube_f_s end\n');
toc

image_reconstruct_f_s = zeros(size(frame_list));

for t = 1: size(frame_list, 1)
    
    image_residual_0_f_s = zeros(size(residual_0_cube_f_s,2), size(residual_0_cube_f_s,3));
    image_residual_0_f_s(:,:) = residual_0_cube_f_s(t,:,:);
    
    image_residual_1_f_s = zeros(size(residual_1_cube_f_s,2), size(residual_1_cube_f_s,3));
    image_residual_1_f_s(:,:) = residual_1_cube_f_s(t,:,:);

    image_gaussian_2_f_s = zeros(size(gaussian_2_cube_f_s,2), size(gaussian_2_cube_f_s,3));
    image_gaussian_2_f_s(:,:) = gaussian_2_cube_f_s(t,:,:);
    
    image_reconstruct_1_f_s = laplacian_up(image_gaussian_2_f_s, image_residual_1_f_s);
    image_reconstruct_0_f_s = laplacian_up(image_reconstruct_1_f_s, image_residual_0_f_s);
    
    image_reconstruct_f_s(t,:,:) = image_reconstruct_0_f_s(:,:);

end

fprintf('IMAGE RECONSTRUCTION end\n');
toc

%% IMAGE RECONSTRUCTION - VIDEO

make_avi(image_reconstruct_f_s, 'image_reconstruct_f_s');

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

%% FUNCTIONS - get_cube

function [gaussian_cube, residual_cube] = get_cube(gaussian_stdev, frame_list, gaussian_index)
    
    %%%% Initialize its size
    [image_gaussian_0, image_residual_0] = get_laplacian_pyramid(gaussian_stdev, frame_list, 1, gaussian_index);
    residual_cube = zeros(size(frame_list, 1), size(image_residual_0, 1), size(image_residual_0, 2));
    gaussian_cube = zeros(size(frame_list, 1), size(image_gaussian_0, 1), size(image_gaussian_0, 2));

    for i = 1: size(frame_list, 1)
        [image_gaussian, image_residual] = get_laplacian_pyramid(gaussian_stdev, frame_list, i, gaussian_index);
        residual_cube(i,:,:) = image_residual;
        gaussian_cube(i,:,:) = image_gaussian;
    end
    
end

%% FUNCTIONS - get_cube_f_s

function cube_f_s = get_cube_f_s(Hd, cube)

    cube_f = zeros(size(cube,1), size(cube,2), size(cube,3));

    for i = 1: size(cube, 2)
        for j = 1: size(cube, 3)
            cube_pixel = cube(:,i,j);
            cube_pixel_f = filter(Hd, cube_pixel);
            cube_f(:,i,j) = cube_pixel_f;
        end
    end

    cube_f_s = zeros(size(cube_f));

    for t = 1: size(cube_f, 1)
        max_ = max(max(cube_f(t,:,:)));
        min_ = min(min(cube_f(t,:,:)));

        a = 1 / (max_ - min_);
        b = min_ / (min_ - max_);

        cube_f_s(t,:,:) = cube_f(t,:,:) * a + b;
    end
end

%% FUNCTIONS - make_avi

function make_avi(cube, avi_name)

    cube_s = zeros(size(cube));
    cube_s_frame = zeros(size(cube, 2), size(cube, 3));
    
    v = VideoWriter(avi_name, 'Uncompressed AVI');
    open(v)
    
    for t = 1: size(cube, 1)
        
        max_ = max(max(cube(t,:,:)));
        min_ = min(min(cube(t,:,:)));
        a = 1 / (max_ - min_);
        b = min_ / (min_ - max_);

        cube_s(t,:,:) = cube(t,:,:) * a + b;
        cube_s_frame(:,:) = cube_s(t,:,:);

        cube_s_frame(:,:) = max(cube_s_frame(:,:),0);
        cube_s_frame(:,:) = min(cube_s_frame(:,:),1);
        writeVideo(v,cube_s_frame);

    end
    
    close(v)

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