% trackIDs = TrackAddedHulls(newHulls, COM)
% Track user split or added hulls.

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

function trackIDs = TrackAddedHulls(newHulls, COM)
    global CellHulls HashedCells GraphEdits
    
    trackIDs = Hulls.GetTrackID(newHulls);
    t = CellHulls(newHulls(1)).time;
    
    % Add new hulls to edited segmentations lists
    Segmentation.AddSegmentationEdit(newHulls, newHulls);
    
    [costMatrix, extendHulls, affectedHulls] = Tracker.TrackThroughSplit(t, newHulls, COM);
    
    [extendHulls, affectedHulls] = Tracker.GetCostClique(extendHulls, affectedHulls);
    [costMatrix bFrom bTo] = Tracker.GetCostSubmatrix(extendHulls, affectedHulls);
    extendHulls = extendHulls(bFrom);
    affectedHulls = affectedHulls(bTo);
    
    % Ignore local graph-edits to avoid reassigning them, this is necessary
    % because ProcessNewborns will not be run immediately after this call.
    bKeepFrom = ~any(GraphEdits(extendHulls,affectedHulls) > 0,2);
    bKeepTo = ~any(GraphEdits(extendHulls,affectedHulls) > 0,1);
    
    extendHulls = extendHulls(bKeepFrom);
    affectedHulls = affectedHulls(bKeepTo);
    costMatrix = costMatrix(bKeepFrom,bKeepTo);
    
    if ( isempty(costMatrix) )
        return;
    end
    
    changedHulls = Tracker.ReassignTracks(costMatrix, extendHulls, affectedHulls, newHulls, newHulls);
    
    if ( t+1 <= length(HashedCells) )
        nextHulls = [HashedCells{t+1}.hullID];
        Tracker.UpdateTrackingCosts(t, changedHulls, nextHulls);
    end
    
    % All changed hulls get added (this may include track changes)
    Segmentation.AddSegmentationEdit([],changedHulls);
    
    trackIDs = [HashedCells{t}(ismember([HashedCells{t}.hullID],newHulls)).trackID];
end
