%% INITIALS
fprintf('INITIALS\n');

% load the image
img = imread('./data/banana_slug.tiff');

% check bits-per-integer, width, and height
img_bits = class(img);
[img_height, img_width] = size(img);
fprintf('img_bits: %s\n', img_bits);
fprintf('img_height: %d\n', img_height);
fprintf('img_width: %d\n', img_width);

imwrite(img, 'img_1.png');

% convert the image into a double-precision array
img = double(img);

%% LINEARIZATION
fprintf('LINEARIZATION\n');

% mapping
img = (img - 2047) / (15000 - 2047);
img = max(0, img);
img = min(1, img);

imwrite(img, 'img_2.png');

%% IDENTIFYING THE CORRECT BAYER PATTERN

% create three sub-images of im as shown in figure below
img1 = img(1:2:end, 1:2:end);
img2 = img(1:2:end, 2:2:end);
img3 = img(2:2:end, 1:2:end);
img4 = img(2:2:end, 2:2:end);

% combine the above images into an RGB image, such that im1 is the red,
% im2 is the green, and im3 is the blue channel

img_grbg = cat(3, img2, img1, img3); % grbg
img_rggb = cat(3, img1, img2, img4); % rggb % best
img_bggr = cat(3, img4, img2, img1); % bggr
img_gbrg = cat(3, img3, img1, img2); % gbrg

imwrite(img_grbg, 'img_grbg.png');
imwrite(img_rggb, 'img_rggb.png');
imwrite(img_bggr, 'img_bggr.png');
imwrite(img_gbrg, 'img_gbrg.png');

diff_12 = sum(sum(abs(img1 - img2)));
diff_13 = sum(sum(abs(img1 - img3)));
diff_14 = sum(sum(abs(img1 - img4)));
diff_23 = sum(sum(abs(img2 - img3)));
diff_24 = sum(sum(abs(img2 - img4)));
diff_34 = sum(sum(abs(img3 - img4)));

img_rgb = img_rggb;

% intermediate
% figure; imshow(min(1, img_rgb * 5));

%% WHITE BALANCING

img_wb = white_balancing_grey(img_rgb);
imwrite(img_wb, 'img_wb_gray.png');

img_wb = white_balancing_white(img_rgb);
imwrite(img_wb, 'img_wb_white.png');

%% DEMOSAICING

% for grey word assumption
img_wb_demosaic_r = interp2(img_wb(:,:,1));
img_wb_demosaic_g = interp2(img_wb(:,:,2));
img_wb_demosaic_b = interp2(img_wb(:,:,3));

img_wb_demosaic = cat(3, img_wb_demosaic_r, img_wb_demosaic_g, img_wb_demosaic_b);

imwrite(img_wb_demosaic, 'img_wb_demosaic.png');

%% BRIGHTNESS ADJUSTMENT AND GAMMA CORRECTION

img_wb_demosaic_gray = rgb2gray(img_wb_demosaic);

if img_wb_demosaic_gray < 0.0031308
    img_wb_demosaic_gc = 12.92 * img_wb_demosaic;
else
    img_wb_demosaic_gc = (1+0.055) * power(img_wb_demosaic, 1/2.4) - 0.055;
end

imwrite(img_wb_demosaic_gc, 'img_wb_demosaic_gc.png');

%% COMPRESSION

imwrite(img_wb_demosaic_gc, 'img_wb_demosaic_gc.jpeg', 'quality', 95);
imwrite(img_wb_demosaic_gc, 'img_wb_demosaic_gc_50.jpeg', 'quality', 50);
imwrite(img_wb_demosaic_gc, 'img_wb_demosaic_gc_30.jpeg', 'quality', 30);
imwrite(img_wb_demosaic_gc, 'img_wb_demosaic_gc_20.jpeg', 'quality', 20);
imwrite(img_wb_demosaic_gc, 'img_wb_demosaic_gc_15.jpeg', 'quality', 15);
imwrite(img_wb_demosaic_gc, 'img_wb_demosaic_gc_10.jpeg', 'quality', 10);
imwrite(img_wb_demosaic_gc, 'img_wb_demosaic_gc_5.jpeg', 'quality', 5);

%% WHITE BALANCING FUNCTIONS

% for grey word assumption
function img_wb = white_balancing_grey(img_rgb)
    r_ = mean(mean(img_rgb(:, :, 1)));
    g_ = mean(mean(img_rgb(:, :, 2)));
    b_ = mean(mean(img_rgb(:, :, 3)));
    img_wb = cat(3, img_rgb(:,:,1) * g_ / r_, img_rgb(:,:,2), img_rgb(:,:,3) * g_ / b_);
end

% for white world assumption
function img_wb = white_balancing_white(img_rgb)
    r_ = max(max(img_rgb(:, :, 1)));
    g_ = max(max(img_rgb(:, :, 2)));
    b_ = max(max(img_rgb(:, :, 3)));
    img_wb = cat(3, img_rgb(:,:,1) * g_ / r_, img_rgb(:,:,2), img_rgb(:,:,3) * g_ / b_);
end
