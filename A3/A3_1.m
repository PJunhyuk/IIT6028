clear;
clc;

tic

%% TOY PROBLEM

im = imread('data/toy_problem.png');
[imh, imw, nn] = size(im);
im = im2double(im);

%%%% maps each pixel to a variable number
im2var = zeros(imh, imw);
im2var(1:imh*imw) = 1: imh*imw;

%%%% Initialize
A = sparse(imh*(imw-1) + imw*(imh-1) + 1, imh*imw);
b = zeros(imh*imw, 1);
e = 0;

%%%% Equation(2)
for y = 1:imh
    for x = 1:imw-1
        e = e+1;
        A(e, im2var(y,x+1)) = 1;
        A(e, im2var(y,x)) = -1;
        b(e) = im(y,x+1) - im(y,x);
    end
end
fprintf('Equation(2) end ');
toc

%%%% Equation(3)
for x = 1:imw
    for y = 1:imh-1
        e = e+1;
        A(e, im2var(y+1,x)) = 1;
        A(e, im2var(y,x)) = -1;
        b(e) = im(y+1,x) - im(y,x);
    end
end
fprintf('Equation(3) end ');
toc

%%%% Equation(4)
e = e+1;
A(e, im2var(1,1)) = 1;
b(e) = im(1,1);

%%%% reconstruct image
v = A \ b;
im_reconstructed = reshape(v, [imh, imw]);
imwrite(im_reconstructed, 'data/toy_problem_reconstructed.png');
fprintf('end ');
toc

%%%% check difference of im & im_reconstructed
diff_mean = mean(mean(abs(im-im_reconstructed)));
fprintf('diff_mean: %e ', diff_mean);
toc
