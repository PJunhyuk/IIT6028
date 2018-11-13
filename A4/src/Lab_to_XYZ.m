%  function XYZ  = Lab_to_XYZ( Lab, illuminant )
%  -------------------------------------------------------
%
% (c) Ivo Ihrke 2011
%     Universitaet des Saarlandes / MPI Informatik
%
% convert from L*a*b* (CIELAB) to XYZ color space 
% using one of the CIE standard illuminants
%
% source:                                                                                                                                                                  
% http://en.wikipedia.org/wiki/Lab_color_space#CIE_XYZ_to_CIE_L.2Aa.2Ab.2A_.28CIELAB.29_and_CIELAB_to_CIE_XYZ_conversions
% 2011-01-06
%
% see also:
%
% illuminant_xyz

function XYZ  = Lab_to_XYZ( Lab, illuminant )

   if nargin < 4
       illuminant = 'D65';
   end
   
   
   [Xn,Yn,Zn] = illuminant_xyz( illuminant );
   
   L = Lab( :, :, 1 );
   a = Lab( :, :, 2 );
   b = Lab( :, :, 3 );

   
   XYZ(:, :, 1 ) = Xn .* finv( 1/116 * ( L + 16 ) + 1/500 * a );
   XYZ(:, :, 2 ) = Yn .* finv( 1/116 * ( L + 16 ) );
   XYZ(:, :, 3 ) = Zn .* finv( 1/116 * ( L + 16 ) - 1/200 * b );



end

function val_out = finv( val )
  val_out = ( val > 6/29 )  .* val.^3 + ...
            ( val <= 6/29 ) .* 3 *( 6/29)^2 .* ( val - 4/29 );
end


