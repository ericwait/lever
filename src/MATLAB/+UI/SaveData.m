% SaveData.m - This will save the current state back to the opened dataset

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

function SaveData(orginal)

global CONSTANTS Figures

settings = Load.ReadSettings();
%let the user know that this might take a while
if(isfield(Figures,'tree') && isfield(Figures.tree,'handle'))
    set(Figures.tree.handle,'Pointer','watch');
    set(Figures.cells.handle,'Pointer','watch');
end

if isfield(CONSTANTS,'matFullFile') && ~isempty(CONSTANTS.matFullFile)
    Helper.SaveLEVerState([CONSTANTS.matFullFile]);
else
    if(orginal)
        Helper.SaveLEVerState(fullfile(settings.matFilePath, [Metadata.GetDatasetName() '_LEVer.mat']));
    else
        Helper.SaveLEVerState(fullfile(settings.matFilePath, [Metadata.GetDatasetName() '_LEVer_edits.mat']));
    end
end

Editor.History('Saved');

%let the user know that the drawing is done
if(isfield(Figures,'tree') && isfield(Figures.tree,'handle'))
    set(Figures.tree.handle,'Pointer','arrow');
    set(Figures.cells.handle,'Pointer','arrow');
end
end
