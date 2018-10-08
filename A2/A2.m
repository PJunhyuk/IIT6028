tic

video_name = 'data/baby2.mp4';

%% INITIALS AND COLOR TRANSFORMATION

% video to frame_list(double-precision, [0, 1], YIQ)
[Fs, frame_list] = video_to_frame_list(video_name);

fprintf('INITIALS AND COLOR TRANSFORMATION end\n');

toc

%% LAPLACIAN PYRAMID

[image_gaussian_1, image_residual_0] = get_laplacian_pyramid(2, frame_list, 1, 1);
[image_gaussian_2, image_residual_1] = get_laplacian_pyramid(2, frame_list, 1, 2);
[image_gaussian_3, image_residual_2] = get_laplacian_pyramid(2, frame_list, 1, 3);
[image_gaussian_4, image_residual_3] = get_laplacian_pyramid(2, frame_list, 1, 4);

residual_seq_0 = get_residual_seq(2, frame_list, 1);
%%% residual_seq_0: (frame_length, height, width, ch)
residual_seq_1 = get_residual_seq(2, frame_list, 2);
residual_seq_2 = get_residual_seq(2, frame_list, 3);
residual_seq_3 = get_residual_seq(2, frame_list, 4);

fprintf('LAPLACIAN PYRAMID end\n');

toc

%% TEMPORAL FILTERING

residual_seq_0_filtered = filter_on_residual(residual_seq_0, Fs);

fprintf('TEMPORAL FILTERING end\n');

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

%% FUNCTIONS - get_laplacian_pyramid

function [image_gaussian, image_residual] = get_laplacian_pyramid(gaussian_stdev, frame_list, frame_index, gaussian_index)

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

    for i = 1: size(residual_seq, 2)
        for j = 1: size(residual_seq, 3)
            for ch = 1: size(residual_seq, 4)

                x = residual_seq(:, i, j, ch);
                fftx = fft(x);

                P2 = abs(fftx/L);
                P1 = P2(1:L/2+1);
                P1(2:end-1) = 2*P1(2:end-1);

                f = Fs * (0:(L/2))/L;

                Hd = butterworthBandpassFilter(Fs, 256, 0.83, 1);

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