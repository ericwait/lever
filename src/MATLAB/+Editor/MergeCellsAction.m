% [historyAction deletedCells replaceCell] = MergeCellsAction(selectedHulls)
% Edit Action:
% 
% Attempt to merge oversegmented cells.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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


function [historyAction deletedCells replaceCell] = MergeCellsAction(selectedHulls, selectedTree)
    global SegmentationEdits
    
    historyAction = '';
    
    [deletedCells replaceCell] = Segmentation.MergeSplitCells(selectedHulls, selectedTree);
    
    if ( isempty(replaceCell) )
        return;
    end

    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    
    UI.UpdateSegmentationEditsMenu();
    
    historyAction = 'Push';
end
