% function [Xo,Yo,Zo] = xyY_to_XYZ( x, y, Y )
% --------------------------------------------------
%
% (c) Ivo Ihrke 2011
%     Universitaet des Saarlandes / MPI Informatik
%
%

function [Xo,Yo,Zo] = xyY_to_XYZ( x, y, Y )

  Xo = Y .* x ./ y;
  Yo = Y;
  Zo = Y .* ( 1 - x - y ) ./ y;
end