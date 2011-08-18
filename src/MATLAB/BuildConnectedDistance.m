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

function BuildConnectedDistance(updateCells, bUpdateIncoming, bShowProgress)
    global CellHulls ConnectedDist
    
    if ( ~exist('bUpdateIncoming', 'var') )
        bUpdateIncoming = 0;
    end
    
    if ( ~exist('bShowProgress', 'var') )
        bShowProgress = 0;
    end
    
    if ( isempty(ConnectedDist) )
        ConnectedDist = cell(1,max(updateCells));
    end
    
    for i=1:length(updateCells)
        if (bShowProgress)
            Progressbar((i-1)/length(updateCells));
        end
        
        ConnectedDist{updateCells(i)} = [];
        t = CellHulls(updateCells(i)).time;
        
        UpdateDistances(updateCells(i), t, t+1);
        UpdateDistances(updateCells(i), t, t+2);
        
        if ( bUpdateIncoming )
            UpdateDistances(updateCells(i), t, t-1);
            UpdateDistances(updateCells(i), t, t-2);
        end
    end
    
    if ( bShowProgress )
        Progressbar(1);
    end
end

function UpdateDistances(updateCell, t, tNext)
    global CellHulls HashedCells CONSTANTS
    
    if ( tNext < 1 || tNext > length(HashedCells) )
        return;
    end
    
    tDist = abs(tNext-t);
    
    nextCells = [HashedCells{tNext}.hullID];
    
    comDistSq = sum((ones(length(nextCells),1)*CellHulls(updateCell).centerOfMass - vertcat(CellHulls(nextCells).centerOfMass)).^2, 2);
    
    nextCells = nextCells(comDistSq <= ((tDist*CONSTANTS.dMaxCenterOfMass)^2));

    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(updateCell).indexPixels);
    for i=1:length(nextCells)
        [rNext cNext] = ind2sub(CONSTANTS.imageSize, CellHulls(nextCells(i)).indexPixels);

        isect = intersect(CellHulls(updateCell).indexPixels, CellHulls(nextCells(i)).indexPixels);
        if ( ~isempty(isect) )
            isectDist = 1 - (length(isect) / min(length(CellHulls(updateCell).indexPixels), length(CellHulls(nextCells(i)).indexPixels)));
            SetDistance(updateCell, nextCells(i), isectDist, tNext-t);
%             SetDistance(updateCell, nextCells(i), 0, tNext-t);
            continue;
        end
        
%         [X,Y] = ndgrid(1:length(r), 1:length(rNext));
%         ccDistSq = ((r(X)-rNext(Y)).^2 + (c(X)-cNext(Y)).^2);
%         ccMinDistSq = min(ccDistSq(:));

        ccMinDistSq = Inf;
        for k=1:length(r)
            ccDistSq = (rNext-r(k)).^2 + (cNext-c(k)).^2;
            ccRowMin = min(ccDistSq);
            if ( ccRowMin < ccMinDistSq )
                ccMinDistSq = ccRowMin;
            end
            
            if ( ccRowMin < 1 )
                break;
            end
        end
        
        if ( abs(tNext-t) == 1 )
            ccMaxDist = CONSTANTS.dMaxConnectComponent;
        else
            ccMaxDist = 1.5*CONSTANTS.dMaxConnectComponent;
        end
        
        if ( ccMinDistSq > (ccMaxDist^2) )
            continue;
        end
        
        SetDistance(updateCell, nextCells(i), sqrt(ccMinDistSq), tNext-t);
    end
end

function SetDistance(updateCell, nextCell, dist, updateDir)
    global ConnectedDist
    
    if ( updateDir > 0 )
        ConnectedDist{updateCell} = [ConnectedDist{updateCell}; nextCell dist];
    else
        chgIdx = [];
        if ( ~isempty(ConnectedDist{nextCell}) )
            chgIdx = find(ConnectedDist{nextCell}(:,1) == updateCell, 1, 'first');
        end
        
        if ( isempty(chgIdx) )
            ConnectedDist{nextCell} = [ConnectedDist{nextCell}; updateCell dist];
        else
            ConnectedDist{nextCell}(chgIdx,:) = [updateCell dist];
        end
    end
end

