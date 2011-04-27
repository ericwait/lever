function tStart = PropagateChanges(changedHulls, editedHulls)
    global CellHulls HashedCells
    
    tStart = min([CellHulls(editedHulls).time]);
    tEnd = length(HashedCells)-1;
    
    % Get initial changehulls to update
    trackHulls = [];
    
    for t=tStart:tEnd
        tChangedHulls = intersect([HashedCells{t}.hullID],changedHulls);
        trackHulls = union(trackHulls,tChangedHulls);
        if ( isempty(trackHulls) )
            Progressbar(1);
            return;
        end
        
        Progressbar((t-tStart)/(tEnd-tStart));
        
        checkHulls = [HashedCells{t}.hullID];
        checkTracks = [HashedCells{t}.trackID];
        nextHulls = [HashedCells{t+1}.hullID];

        UpdateTrackingCosts(t, trackHulls, nextHulls);

        [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(checkHulls, nextHulls);
        checkHulls = checkHulls(bOutTracked);
        checkTracks = checkTracks(bOutTracked);
        nextHulls = nextHulls(bInTracked);
        
        % Figure out which hulls are assigned to tracks we allow to split
        bPastEdit = (t >= [CellHulls(editedHulls).time]);
        followTracks = GetTrackID(editedHulls(bPastEdit));
        
        bFollowTracks = ismember(checkTracks, followTracks);
        followTracks = checkTracks(bFollowTracks);
        followHulls = checkHulls(bFollowTracks);
        
        % Stop if none of the original split tracks are still around
        if ( isempty(followTracks) )
            ReassignTracks(t+1, costMatrix, checkHulls, nextHulls, [], 1);
            Progressbar(1);
            return;
        end

        allNewHulls = [];
        splits = findSplits(costMatrix, checkHulls, nextHulls);
        for i=1:length(splits)
            splitHulls = checkHulls(splits{i});
            bFollowSplit = ismember(splitHulls, followHulls);
            if ( ~any(bFollowSplit) )
                continue;
            end

%             if ( ~all(checkTrackLengths(splitHulls(~bFollowSplit),5)) )
%                 continue;
%             end

            newHulls = attemptNextFrameSplit(t, nextHulls(i), splitHulls);
            if ( isempty(newHulls) )
                continue;
            end
            
            allNewHulls = [allNewHulls newHulls];
        end
        
        nextHulls = [HashedCells{t+1}.hullID];
        [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(checkHulls, nextHulls);
        
        extendHulls = checkHulls(bOutTracked);
        affectedHulls = nextHulls(bInTracked);

        trackHulls = ReassignTracks(t+1, costMatrix, extendHulls, affectedHulls, allNewHulls);
    end
    
    Progressbar(1);
end

function [newHulls] = attemptNextFrameSplit(t, hull, desireSplitHulls)
    global HashedCells
    
% TODO: This was the constraint to only split into actually tracked hulls
%     while ( length(desireSplitHulls) > 1 )
        % Try to split
        [newHulls oldCOM] = splitNextFrame(hull, length(desireSplitHulls));
        if ( isempty(newHulls) )
            return;
        end

        TrackThroughSplit(t+1, newHulls, oldCOM);
        
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];
        
        [chkCM bChkHulls bNextHulls] = GetCostSubmatrix(checkHulls, nextHulls);
        checkHulls = checkHulls(bChkHulls);
        nextHulls = nextHulls(bNextHulls);
        
%         trackedSplitHulls = verifySplit(chkCM, checkHulls, nextHulls, newHulls, desireSplitHulls);
%         if ( length(trackedSplitHulls) == length(desireSplitHulls) )
%             break;
%         end
%         
%         revertSplit(t+1, hull, newHulls);
%         desireSplitHulls = trackedSplitHulls;
%         newHulls = [];
%     end
end

function [newHullIDs oldCOM] = splitNextFrame(hullID, k)
    global CellHulls

    newHullIDs = [];
    oldCOM = CellHulls(hullID).centerOfMass;
%     oldTracks = [HashedCells{CellHulls(hull).time}.trackID];

    newHulls = ResegmentHull(CellHulls(hullID), k);
    if ( isempty(newHulls) )
        return;
    end

    % Just arbitrarily assign clone's hull for now
    CellHulls(hullID) = newHulls(1);
    newHullIDs = hullID;

    % Other hulls are just added off the clone
    newFamilyIDs = [];
    for i=2:length(newHulls)
        CellHulls(end+1) = newHulls(i);
        newFamilyIDs = [newFamilyIDs NewCellFamily(length(CellHulls), newHulls(i).time)];
        newHullIDs = [newHullIDs length(CellHulls)];
    end
end

function trackedSplits = verifySplit(costMatrix, extendHulls, nextHulls, newHulls, splitHulls)
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    trackedSplits = [];
    availableNewHulls = newHulls;
    
    bestOutgoing  = bestOutgoing';
    bMatchedCol = false(size(bestIncoming));
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    bMatchedCol(bestOutgoing(bMatched)) = 1;
    matchedIdx = find(bMatched);
    
    for i=1:length(matchedIdx)
        assignHull = nextHulls(bestOutgoing(matchedIdx(i)));
        fromHull = extendHulls(matchedIdx(i));
        
        costMatrix(matchedIdx(i),:) = Inf;
        costMatrix(:,bestOutgoing(matchedIdx(i))) = Inf;
        
        if ( any(availableNewHulls == assignHull) && any(splitHulls == fromHull) )
            trackedSplits = [trackedSplits fromHull];
            availableNewHulls = setdiff(availableNewHulls, assignHull);
        end
    end
    
    [minCost minIdx] = min(costMatrix(:));
    while ( minCost ~= Inf )
        [r c] = ind2sub(size(costMatrix), minIdx);
        assignHull = nextHulls(c);
        fromHull = extendHulls(r);
        
        costMatrix(r,:) = Inf;
        costMatrix(:,c) = Inf;
        
        if ( any(availableNewHulls == assignHull) && any(splitHulls == fromHull) )
            trackedSplits = [trackedSplits fromHull];
            availableNewHulls = setdiff(availableNewHulls, assignHull);
        end
        
        [minCost minIdx] = min(costMatrix(:));
    end
end

function revertSplit(t, hull, newHulls)
    global CONSTANTS CellHulls HashedCells CellTracks CellFamilies Costs ConnectedDist
    
    rmHulls = setdiff(newHulls,hull);
    
    bRmHashIdx = ismember([HashedCells{t}.hullID], rmHulls);
    rmTrackIDs = getTrackID(rmHulls,t);
    rmFamilyIDs = [CellTracks(rmTrackIDs).familyID];
    
    leaveHulls = setdiff(1:length(CellHulls),rmHulls);
    
    % Note: can only do these simple removals because notheing has yet been
    % updated to reference the new cell structure.
    HashedCells{t} = HashedCells{t}(~bRmHashIdx);
    CellTracks = CellTracks(setdiff(1:length(CellTracks),rmTrackIDs));
    CellFamilies = CellFamilies(setdiff(1:length(CellFamilies),rmFamilyIDs));
    Costs = Costs(leaveHulls,leaveHulls);
    ConnectedDist = ConnectedDist(leaveHulls);
    
    BuildConnectedDistance(hull,1);
    
    % Merge cells and remove split cells
    mergedIdxPix = vertcat(CellHulls(newHulls).indexPixels);
    mergedImgPix = vertcat(CellHulls(newHulls).imagePixels);
    
    [mergedIdxPix,srtIdx] = sort(mergedIdxPix);
    mergedImgPix = mergedImgPix(srtIdx);
    
    [r c] = ind2sub(CONSTANTS.imageSize, mergedIdxPix);
    chIdx = convhull(c,r);
    
    CellHulls(hull).indexPixels = mergedIdxPix;
    CellHulls(hull).imagePixels = mergedImgPix;
    CellHulls(hull).centerOfMass = mean([r c]);
    CellHulls(hull).points = [c(chIdx) r(chIdx)];
    
    CellHulls = CellHulls(leaveHulls);
end

function bFullLength = checkTrackLengths(hulls, minlength)
    global CellHulls CellTracks
    
    bFullLength = false(size(hulls));
    
    for i=1:length(hulls)
        t = CellHulls(hulls(i)).time;
        trackID = GetTrackID(hulls(i),t);
        
        hasht = t - CellTracks(trackID).startTime + 1;
        if ( hasht < minlength )
            continue;
        end
        
        hashmin = (t-minlength+1) - CellTracks(trackID).startTime + 1;
        if ( ~all(CellTracks(trackID).hulls(hashmin:hasht) > 0) )
            continue;
        end
        
        bFullLength(i) = 1;
    end
end

function splits = findSplits(costMatrix, checkHulls, nextHulls)
    global ConnectedDist

    [minIn,bestIn] = min(costMatrix,[],1);
    [minOut,bestOut] =  min(costMatrix,[],2);
    
    splits = cell(1,size(costMatrix,2));
    
    bestOut = bestOut';
    for i=1:size(costMatrix,2)
        wants=find(bestOut == i);
        
        if ( length(wants) <= 1 )
            continue;
        end
        
        % Only split using overlapping cells
        bValidWants = true(size(wants));
        for k=1:length(wants)
            if ( isempty(ConnectedDist{checkHulls(wants(k))}) )
                continue;
            end
            
            ccidx = find(ConnectedDist{checkHulls(wants(k))}(:,1) == nextHulls(i));
            if ( isempty(ccidx) || ConnectedDist{checkHulls(wants(k))}(ccidx,2) >= 1.0 )
                bValidWants(k) = 0;
            end
        end
        
        wants = wants(bValidWants);
        
        if ( length(wants) <= 1 )
            continue;
        end
        
        splits{i} = wants;
    end
end
