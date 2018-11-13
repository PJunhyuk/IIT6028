% function out = apply_color_matrix( I, matrix )
% ----------------------------------------------
% 
% applies a 3x3 color matrix to a 3-channel image I
%
% (c) 2011 Ivo Ihrke
%          Universitaet des Saarlandes 
%          MPI Informatik

function out = apply_color_matrix( I, matrix )

vec = reshape(I,size(I,1)*size(I,2),3);
out_vec = matrix * vec';
out = reshape( out_vec', size(I,1),size(I,2),3 );

