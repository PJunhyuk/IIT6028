clear;
clc;

tic

% starter script for project 3
DO_TOY = true;
DO_BLEND = false;
DO_MIXED  = false;
DO_COLOR2GRAY = false;

if DO_TOY 
    fprintf('DO_TOY START!\n');
    toyim = im2double(imread('./data/toy_problem.png')); 
    % im_out should be approximately the same as toyim
    im_out = toy_reconstruct(toyim);
    disp(['Error: ' num2str(sqrt(sum(toyim(:)-im_out(:))))])
    fprintf('DO_TOY END! ');
    toc
end

if DO_BLEND
    fprintf('DO_BLEND START!\n');
    im_background = imresize(im2double(imread('./data/hiking.jpg')), 0.5, 'bilinear');
    im_object = imresize(im2double(imread('./data/penguin-chick.jpeg')), 0.5, 'bilinear');

    % get source region mask from the user
    objmask = getMask(im_object);
    % align im_s and mask_s with im_background
    [im_s, mask_s] = alignSource(im_object, objmask, im_background);

    % blend
    im_blend = poissonBlend(im_s, mask_s, im_background);
    figure(3), hold off, imshow(im_blend)
    fprintf('DO_BLEND END! ');
    toc
end

if DO_MIXED
    % read images
    %...
    
    % blend
    im_blend = mixedBlend(im_s, mask_s, im_bg);
    figure(3), hold off, imshow(im_blend);
end

if DO_COLOR2GRAY
    im_rgb = im2double(imread('./data/colorBlindTest35.png'));
    im_gr = color2gray(im_rgb);
    figure(4), hold off, imagesc(im_gr), axis image, colormap gray
end