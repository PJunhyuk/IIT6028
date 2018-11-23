clear;
clc;

tic

%% HDR IMAGING - INITIALS

resize_ratio = 1/60;

% load .TIFF images
img = imresize(imread('./exposure_stack/exposure1.jpg'), resize_ratio);
[height, width, ch] = size(img);
k = 16;
Zmin = 0;
Zmax = 255;
n = Zmax - Zmin + 1;

img_list = zeros(height, width, ch, k);

for i = 1: k
    img_name = join(['exposure', int2str(i), '.jpg']);
    img_path = fullfile('.', 'exposure_stack', img_name);
    img_list(:,:,:,i) = imresize(imread(img_path), resize_ratio);
end

%%%% tiff -> 0-65535
% img_list = floor(img_list/65536 * n);
%%%% jpg -> 0-255

fprintf('HDR IMAGING - INITIALS end\n'); toc

%% HDR IMAGING - LINEARIZE RENDERED IMAGES

Z_r = zeros(height*width, k);
Z_g = zeros(height*width, k);
Z_b = zeros(height*width, k);
for i = 1: height
    for j = 1: width
        Z_r((i-1)*width + j, :) = img_list(i, j, 1, :);
    end
end
for i = 1: height
    for j = 1: width
        Z_g((i-1)*width + j, :) = img_list(i, j, 2, :);
    end
end
for i = 1: height
    for j = 1: width
        Z_b((i-1)*width + j, :) = img_list(i, j, 3, :);
    end
end

B = zeros(k, 1);
for i = 1: k
    B(i) = power(2, i-1) / 2048;
end

w = zeros(n,1);
%%%% weighting schemes - tent
% for z = 1: n/2
%     w(z) = z-Zmin-1;
% end
% for z = n/2+1: n
%     w(z) = Zmax+1-z;
% end
%%%% weighting schemes - uniform
for z = 1: n
    w(z) = n/2;
end

l = 1000;

fprintf('gsolve(Z_r) start\n'); toc
[g_r,lE_r] = gsolve(Z_r,B,l,w);
fprintf('gsolve(Z_r) end\n'); toc
[g_g,lE_g] = gsolve(Z_g,B,l,w);
fprintf('gsolve(Z_g) end\n'); toc
[g_b,lE_b] = gsolve(Z_b,B,l,w);
fprintf('gsolve(Z_b) end\n'); toc

%%%% g-> 256x3 double

% figure
% plot(g_r, 'r')
% hold on
% plot(g_g, 'g')
% hold on
% plot(g_b, 'b')
% title(l)

fprintf('HDR IMAGING - LINEARIZE RENDERED IMAGES end\n');
toc

%% HDR IMAGING - MERGE EXPOSURE STACK INTO HDR IMAGE

resize_ratio = 1/2;

% load .TIFF images
img = imresize(imread('./exposure_stack/exposure1.jpg'), resize_ratio);
[height, width, ch] = size(img);
k = 16;
Zmin = 0;
Zmax = 255;
n = Zmax - Zmin + 1;

img_list = zeros(height, width, ch, k);

for i = 1: k
    img_name = join(['exposure', int2str(i), '.jpg']);
    img_path = fullfile('.', 'exposure_stack', img_name);
    img_list(:,:,:,i) = imresize(imread(img_path), resize_ratio);
end

%%%% tiff -> 0-65535
% img_list = floor(img_list/65536 * n);
%%%% 0-255

%%%% Exponential
img_list_r(:,:,:) = exp( g_r(img_list(:, :, 1, :) + 1)/n );
img_list_g(:,:,:) = exp( g_g(img_list(:, :, 2, :) + 1)/n );
img_list_b(:,:,:) = exp( g_b(img_list(:, :, 3, :) + 1)/n );
%%%% Linear
% img_list_r(:,:,:) = g_r(img_list(:, :, 1, :) + 1);
% img_list_g(:,:,:) = g_g(img_list(:, :, 2, :) + 1);
% img_list_b(:,:,:) = g_b(img_list(:, :, 3, :) + 1);

img_list_new = zeros(height, width, ch, k);
img_list_new(:,:,1,:) = img_list_r;
img_list_new(:,:,2,:) = img_list_g;
img_list_new(:,:,3,:) = img_list_b;

img_list_max = max(max(max(max(img_list_new))));
img_list_min = min(min(min(min(img_list_new))));
img_list_new = img_list_new * 0.998 / (img_list_max-img_list_min) + (0.001*img_list_max - 0.999*img_list_min) / (img_list_max-img_list_min);
img_list_new = floor(img_list_new * 256);

B_img = zeros(height, width, ch, k);
for i = 1: height
    for j = 1: width
        for c = 1: ch
            B_img(i, j, c, :) = B(:, 1);
        end
    end
end

img_hdr_u = sum( w(img_list_new+1) .* img_list_new ./ B_img, 4);
img_hdr_d = sum( w(img_list_new+1), 4);
img_hdr = img_hdr_u ./ img_hdr_d;

img_hdr_max = max(max(max(max(img_hdr))));
img_hdr_min = min(min(min(min(img_hdr))));
img_hdr = img_hdr * 0.998 / (img_hdr_max-img_hdr_min) + (0.001*img_hdr_max - 0.999*img_hdr_min) / (img_hdr_max-img_hdr_min);
% img_hdr = floor(img_hdr * 256);

% hdrwrite(img_hdr, './img_hdr.hdr');
% imshow(img_hdr)

fprintf('HDR IMAGING - MERGE EXPOSURE STACK INTO HDR IMAGE end\n'); toc

%% TONEMAPPING - PHOTOGRAPHIC TONEMAPPING

img_hdr_tm = photo_tonemap(0.15, 0.85, img_hdr);
imshow(img_hdr_tm);
