% function M = chromatic_adaptation_xyz( from_illum, to_illum, method)
% --------------------------------------------------------------------
%
% (c) Ivo Ihrke 2011
%     Universitaet des Saarlandes / MPI Informatik
%
% computes chromatic adaptation matrix for XYZ space
% chromatic adaptation
%
% input: illuminant names (from, to) and method
%
%        method = 'XYZScaling', 'Bradford', 'vonKries'
%       
%        default 'Bradford'
%
% implementation and choice of default according to 
%
% http://brucelindbloom.com/index.html?Eqn_ChromAdapt.html
%
% the conversion matrices given on this webpage seem to  
% use the 'XYZScaling' method which is mentioned as the
% worst choice.
%
function M = chromatic_adaptation_xyz( from_illum, to_illum, method)


if nargin < 3
    method = 'Bradford';
end

[fX, fY, fZ] = illuminant_xyz( from_illum );

[tX, tY, tZ] = illuminant_xyz( to_illum );


%setup Ma (cone response domain transform) according to <method>

mselected = 0;

if strcmp( method, 'XYZScaling' )
    Ma = eye( 3 );
    mselected = 1;
end

if strcmp( method, 'Bradford' )
    Ma = [ 0.8951000  0.2664000 -0.1614000; -0.7502000  1.7135000 ...
           0.0367000; 0.0389000 -0.0685000  1.0296000 ];
    mselected = 1;
end

if strcmp( method, 'vonKries' )
    Ma = [ 0.4002400  0.7076000 -0.0808100; -0.2263000  1.1653200 ...
           0.0457000; 0.0000000  0.0000000  0.91822000];
    mselected = 1;
end


if ( ~mselected ) 
    fprintf( 2, ['chromatic_adaptation_xyz: unknown transform - ' ...
                 'returning unit matrix'] );
    M = eye( 3 );
else
    %compute transform matrix 

    %rho, gamma, beta
    from_rgb = Ma * [fX; fY; fZ];

    to_rgb = Ma * [tX; tY; tZ];

    M = inv( Ma ) * diag( to_rgb ./ from_rgb ) * Ma;
end

