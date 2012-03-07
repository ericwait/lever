% CompileLEVer.m - Script to build LEVer and its dependencies

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic

vstoolroot = getenv('VS100COMNTOOLS');
if ( isempty(vstoolroot) )
    error('Cannot compile MTC and mexMAT without Visual Studio 2010');
end

if ( ~exist('..\..\bin64','dir') )
    mkdir('..\..\bin64');
end

system(['"' fullfile(vstoolroot,'..','..','vc','bin','amd64','vcvars64.bat') '"' ]);

system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build Release "..\c\MTC.sln"']);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build Release "..\c\mexMAT.sln"']);


% clears out mex cache so src/mexMAT.mexw32 can be overwritten
clear mex
system('copy ..\c\x64\Release\mexMAT.dll .\mexMAT.mexw64');
system('copy ..\c\x64\Release\mexMAT.dll ..\..\bin64\mexMAT.mexw64');
system('copy ..\c\MTC\Release\MTC.exe .\');
system('copy ..\c\MTC\Release\MTC.exe ..\..\bin64\');

mcc -m LEVer.m -d ..\..\bin\.
mcc -m Segmentor.m
system('copy Segmentor.exe ..\..\bin64\.');

mcc -m LEVER_SegAndTrackFolders.m
system('copy LEVER_SegAndTrackFolders.exe ..\..\bin64\.');

if(isempty(dir('.\MTC.exe')) || isempty(dir('..\..\bin64\MTC.exe')))
    warndlg('Make sure that MTC.exe is in the same dir as LEVer.exe and LEVer MATLAB src code');
end
toc