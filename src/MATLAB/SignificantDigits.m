%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function digits = SignificantDigits(num)
% SignificantDigits will see how many digits the image file name needs for
% each frame and then will convert num to the appropriate string


global CONSTANTS
digits = '';
switch CONSTANTS.imageSignificantDigits
        case 3
            digits = num2str(num,'%03d');
        case 4
            digits = num2str(num,'%04d');
        case 5
            digits = num2str(num,'%05d');
        case 6
            digits = num2str(num,'%06d');
end
end