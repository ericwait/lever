% AddHull.m - Attempt to add or split cell hull into specified number of
% pieces.

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

function AddHull(num)
global Figures CellHulls

[hullID trackID] = UI.GetClosestCell(1);
clickCoord = UI.GetClickedCellPoint();

if ( ~Hulls.CheckHullsContainsPoint(clickCoord, CellHulls(hullID)) )
    trackID = [];
end

if(~isempty(trackID) && (num > 1))
    % Try to split the existing hull    
    
    [bErr newTracks] = Editor.ReplayableEditAction(@Editor.SplitCell, hullID, num);
    if ( bErr )
        return;
    end
    
    if ( isempty(newTracks) )
        msgbox(['Unable to split ' num2str(trackID) ' any further in this frame'],'Unable to Split','help','modal');
        return;
    end
    
    Error.LogAction('Split cell',trackID,[trackID newTracks]);
    
elseif ( isempty(trackID) && (num == 1) )
    % Try to run local segmentation and find a hull we missed or place a
    % point-hull at least
    [bErr newTrack] = Editor.ReplayableEditAction(@Editor.AddNewCell, clickCoord, Figures.time);
    if ( bErr )
        return;
    end
    
    Error.LogAction('Added cell',newTrack);
else
    return;
end

UI.DrawTree(Figures.tree.familyID);
UI.DrawCells();
end
