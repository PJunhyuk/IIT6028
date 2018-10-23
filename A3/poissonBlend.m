function im_blend = poissonBlend(im_s, mask_s, im_background)

% tic

% im_s = imresize(im_s, 0.5);
% mask_s = imresize(mask_s, 0.5);
% im_background = imresize(im_background, 0.5);

[imh, imw, nn] = size(im_s);

%%%% maps each pixel to a variable number
im2var = zeros(imh, imw);
im2var(1:imh*imw) = 1: imh*imw;

%%%% Initialize
A = sparse(imh*imw, imh*imw);
b = zeros(imh*imw, nn);
e = 0;

%%%% Laplace filter
for y = 1:imh
    for x = 1:imw
        e = e+1;
        if mask_s(y,x) == 1
            A(e, im2var(y,x)) = 4;
            A(e, im2var(y,x-1)) = -1;
            A(e, im2var(y,x+1)) = -1;
            A(e, im2var(y-1,x)) = -1;
            A(e, im2var(y+1,x)) = -1;
            b(e,:) = 4*im_s(y,x,:) - im_s(y,x+1,:) - im_s(y,x-1,:) - im_s(y-1,x,:) - im_s(y+1,x,:);
        else
            A(e, im2var(y,x)) = 1;
            b(e,:) = im_background(y,x,:);
        end
    end
    
    %%%% print logs..
%     if mod(y, 50) == 0
%         fprintf('%d', y);
%         toc
%     end
end

%%%% reconstruct image
v = A \ b;
im_blend = reshape(v, [imh, imw, nn]);

end