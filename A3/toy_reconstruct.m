function im_out = toy_reconstruct(toyim)

% tic

% fprintf('DO_TOY START!\n');

[imh, imw, nn] = size(toyim);
toyim = im2double(toyim);

%%%% maps each pixel to a variable number
im2var = zeros(imh, imw);
im2var(1:imh*imw) = 1: imh*imw;

%%%% Initialize
A = sparse(imh*(imw-1) + imw*(imh-1) + 1, imh*imw);
b = zeros(imh*imw, nn);
e = 0;

%%%% Equation(2)
for y = 1:imh
    for x = 1:imw-1
        e = e+1;
        A(e, im2var(y,x+1)) = 1;
        A(e, im2var(y,x)) = -1;
        b(e) = toyim(y,x+1) - toyim(y,x);
    end
end
% fprintf('Equation(2) end ');
% toc

%%%% Equation(3)
for x = 1:imw
    for y = 1:imh-1
        e = e+1;
        A(e, im2var(y+1,x)) = 1;
        A(e, im2var(y,x)) = -1;
        b(e) = toyim(y+1,x) - toyim(y,x);
    end
end
% fprintf('Equation(3) end ');
% toc

%%%% Equation(4)
e = e+1;
A(e, im2var(1,1)) = 1;
b(e) = toyim(1,1);

%%%% reconstruct image
v = A \ b;
im_out = reshape(v, [imh, imw]);
% imwrite(im_out, 'results/toy_problem_reconstructed.png');
% fprintf('DO_TOY END ');
% toc

end