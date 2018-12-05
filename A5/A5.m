clear;
clc;

tic

%% Initials

img_raw = imread('data/chessboard_lightfield.png');

global u v s t c
u = 16;
v = 16;
s = size(img_raw, 1) / u;
t = size(img_raw, 2) / v;
c = 3;

% load('results/focal_stack.mat');
% fprintf('load complete\n'); toc

img_array = zeros(u, v, s, t, c);
img_array = uint8(img_array);
for i = 1:s
    for j = 1:t
        for x = 1:u
            for y = 1:v
                for z = 1:c
                    img_array(x, y, i, j, z) = img_raw(u*(i-1)+x, v*(j-1)+y, z);
                end
            end
        end
    end
end

fprintf('Initials end\n'); toc

%% Sub-aperture views

img_mosaic = zeros(u*s, v*t, c);
img_mosaic = uint8(img_mosaic);
for x = 1:u
    for y = 1:v
        img_mosaic(s*(x-1)+1: s*(x-1)+s, t*(y-1)+1: t*(y-1)+t, :) = img_array(x, y, :, :, :);
    end
end

imwrite(img_mosaic, 'results/img_mosaic.png');
fprintf('Sub-aperture views end\n'); toc

%% Refocusing and focal-stack generation

d = 21; % 0:0.1:2

focal_stack = zeros(s, t, c, d);
focal_stack = uint8(focal_stack);

for d_ = 1:d
%     fprintf('%d/ ', d_);
    focal_stack(:, :, :, d_) = combine_depth(img_array, 0.1*(d_-1));
end

fprintf('Refocusing and focal-stack generation end\n'); toc

img_combined = zeros(s, t, c);
img_combined = uint8(img_combined);

for d_ = 1:d
    img_combined = focal_stack(:, :, :, d_);
    imwrite(img_combined, strcat('results/combined_', num2str((d_-1)*0.1, 2), '.png'));
end

fprintf('Refocusing and focal-stack generation - save end\n'); toc

%% All-focus image and depth from defocus

focal_stack = double(focal_stack);

focal_stack_lum = zeros(s, t, d);
focal_stack_low = zeros(s, t, d);
focal_stack_high = zeros(s, t, d);
focal_stack_sharp = zeros(s, t, d);

stdev_1 = 5;
stdev_2 = 5;

for d_ = 1:d
    img_combined = focal_stack(:, :, :, d_);
    
    % luminance
    img_combined_xyz = rgb2xyz(img_combined, 'ColorSpace', 'srgb');
    img_combined_lum = img_combined_xyz(:, :, 2);
    focal_stack_lum(:,:,d_) = img_combined_lum;

    % low
    img_combined_low = imgaussfilt(img_combined_lum, stdev_1);
    focal_stack_low(:,:,d_) = img_combined_low;

    % high
    img_combined_high = img_combined_lum - img_combined_low;
    focal_stack_high(:,:,d_) = img_combined_high;
    
    % sharpness
    img_combined_sharp = imgaussfilt(img_combined_high .^ 2, stdev_2);
    focal_stack_sharp(:,:,d_) = img_combined_sharp;
end

fprintf('All-focus image and depth from defocus - setting end\n'); toc

img_all_focus = zeros(s, t, c);
img_depth_map = zeros(s, t);

for i = 1:s
    fprintf("%d ", i); toc
    for j = 1:t
        sum_sharp = 0;
        for d_ = 1:7:d
            img_combined = focal_stack(:, :, :, d_);
            sharp_value = focal_stack_sharp(i,j,d_);

%             img_all_focus(i, j, :) = img_all_focus(i, j, :) + img_combined(i, j, :) * sharp_value;
            for z = 1:c
                img_all_focus(i, j, z) = img_all_focus(i, j, z) + img_combined(i, j, z) * sharp_value;
            end
            img_depth_map(i, j) = img_depth_map(i, j) + sharp_value * 0.1*(d_-1);

            sum_sharp = sum_sharp + sharp_value;
        end
        img_all_focus(i, j, :) = img_all_focus(i, j, :) / sum_sharp;
        img_depth_map(i, j) = img_depth_map(i, j) / sum_sharp;
    end
end

img_all_focus = uint8(img_all_focus);
img_depth_map = (1 - img_depth_map / 2);

imwrite(img_all_focus, 'results/img_all_focus.png');
imwrite(img_depth_map, 'results/img_depth_map.png');

fprintf('All-focus image and depth from defocus end\n'); toc


%% functions

function [img_combined] = combine_depth(img_array, d_)

    global u v s t c
    
    img_array = double(img_array);

    img_combined = zeros(s, t, c);
    
    for i = 1:s
        for j = 1:t
            count = 0;
            for x = 1-u/2:u/2
                i_ = i + round(x*d_);
                for y = 1-v/2:v/2
                    j_ = j - round(y*d_);
                    if i_ <= s && i_ >= 1 && j_ <= t && j_ >= 1
                        for z =1:c
                            img_combined(i, j, z) = img_combined(i, j, z) + img_array(x+u/2, y+v/2, i_, j_, z);
                        end
                        count = count + 1;
                    end
                end
            end
            img_combined(i, j, :) = img_combined(i, j, :) / count;
        end
    end
    
    img_combined = uint8(img_combined);

end
