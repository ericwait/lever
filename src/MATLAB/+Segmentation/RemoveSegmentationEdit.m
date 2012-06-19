% RemoveSegmentationEdit.m - Remove the user edit listing for a cell that
% has been deleted.

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

function RemoveSegmentationEdit(rmHull)
    global SegmentationEdits
    
    if ( ~isempty(SegmentationEdits) )    
        % Remove the deleted hull from the edited segmentations lists
        SegmentationEdits.newHulls(SegmentationEdits.newHulls == rmHull) = [];
        SegmentationEdits.changedHulls(SegmentationEdits.changedHulls == rmHull) = [];
    else
        SegmentationEdits.newHulls = [];
        SegmentationEdits.changedHulls = [];
    end
    
    UI.UpdateSegmentationEditsMenu();
end

function times = getFrameTimes(hulls)
    global CellHulls
    
    times =[CellHulls(hulls).time];
end