function im_blend = mixedBlend(im_s, mask_s, im_background)

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
            
            b = applyGradient(im_s, im_background, b, x, y, e, 0, 1);
            b = applyGradient(im_s, im_background, b, x, y, e, 0, -1);
            b = applyGradient(im_s, im_background, b, x, y, e, 1, 0);
            b = applyGradient(im_s, im_background, b, x, y, e, -1, 0);
        else
            A(e, im2var(y,x)) = 1;
            b(e, :) = im_background(y,x,:);
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
im_blend(:,:,:) = max(0, im_blend(:,:,:));
im_blend(:,:,:) = min(1, im_blend(:,:,:));

end

function b = applyGradient(im_s, im_background, b, x, y, e, x_, y_)

[~, ~, nn] = size(im_s);

grad_s = zeros(1, nn);
grad_t = zeros(1, nn);

for c = 1:nn
    grad_s(1,c) = im_s(y,x,c) - im_s(y+y_,x+x_,c);
    grad_t(1,c) = im_background(y,x,c) - im_background(y+y_,x+x_,c);
end
if abs(grad_s(1,:)) >= abs(grad_t(1,:))
    b(e, :) = b(e, :) + grad_s(1, :);
else
    b(e, :) = b(e, :) + grad_t(1, :);
end

end