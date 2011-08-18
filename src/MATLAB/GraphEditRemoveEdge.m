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

function GraphEditRemoveEdge(time, parentTrackID, trackID)
    global GraphEdits
    
    parentHull = getNearestPrevHull(time-1, parentTrackID);
    nextHull = getNearestNextHull(time, trackID);
    
    if ( parentHull == 0 || nextHull == 0 )
        return;
    end
    
    GraphEdits(parentHull,nextHull) = -1;
end

function hull = getNearestPrevHull(time, trackID)
    global CellTracks
    
    hull = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 || hash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    hull = CellTracks(trackID).hulls(hash);
    if ( hull == 0 )
        hidx = find(CellTracks(trackID).hulls(1:hash),1,'last');
        if ( isempty(hidx) )
            return;
        end
        
        hull = CellTracks(trackID).hulls(hidx);
    end
end

function hull = getNearestNextHull(time, trackID)
	global CellTracks
    
    hull = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 || hash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    hull = CellTracks(trackID).hulls(hash);
    if ( hull == 0 )
        hidx = find(CellTracks(trackID).hulls(hash:end),1,'first');
        if ( isempty(hidx) )
            return;
        end
        
        hull = CellTracks(trackID).hulls(hidx);
    end
end