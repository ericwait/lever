function newPreserveTracks = FixupSingleFrame(t, preserveTracks, tEnd, viewLims)
    global CellTracks HashedCells
    
    newPreserveTracks = preserveTracks;
    
    bInTracks = Helper.CheckInTracks(t, preserveTracks);
    if ( nnz(bInTracks) == 0 )
        return;
    end
    
    inPreserveTracks = preserveTracks(bInTracks);
    
    % Disconnect all tracks (t-1) -> t.
    [droppedTracks oldEdges] = chopTracks(t, inPreserveTracks);
    bIgnoreEdges = Segmentation.ResegFromTree.CheckIgnoreTracks(t, inPreserveTracks, viewLims);
    
    % This attempts to keep track of what we think we've correctly resegmented
    clearEdgeResegInfo(oldEdges(~bIgnoreEdges,:));
    
    % Find best (t-1) -> t assignment (adding/splitting hulls)
    newEdges = Segmentation.ResegFromTree.FindFrameReseg(t, oldEdges, bIgnoreEdges);
    
    allEdges = zeros(size(oldEdges));
    % Find and fixup conflicts from "ignoring" edges
    allEdges(bIgnoreEdges,:) = fixupConflictingEdges(t, bIgnoreEdges, newEdges, oldEdges, droppedTracks);
    allEdges(~bIgnoreEdges,:) = newEdges;
    
    bExtendEdges = (oldEdges(:,2) == 0);
    
    % Update tracking costs and dijkstra internal state
    updateHulls = [HashedCells{t-1}.hullID];
    tHulls = [HashedCells{t}.hullID];
    
    Tracker.UpdateTrackingCosts(t-1, updateHulls, tHulls);
    
    Segmentation.ResegFromTree.UpdateDijkstraGraph(t-1);
    Segmentation.ResegFromTree.UpdateDijkstraGraph(t);
    
    % Avoid reassignment on tracks that don't exist after current frame.
    % Ignore edges that didn't have a future before for reassignment
    bReassign = false(size(allEdges,1),1);
    bChkReassign = ~bExtendEdges;
    checkTracks = droppedTracks(bChkReassign);
    
    % Use Dijkstra or just manually find best t -> (t+1) assignment, and
    % move hulls in frame t into the appropriate dropped tracks
    bLeaf = arrayfun(@(x)(isempty(CellTracks(x).childrenTracks)), checkTracks);
    bPastEnd = arrayfun(@(x)(t+1 > CellTracks(x).endTime), checkTracks);
    bReassign(bChkReassign) = (~bLeaf | ~bPastEnd);
    
    reassignEdges = allEdges(bReassign,:);
    if ( (t < tEnd) && ~isempty(reassignEdges) )
        allEdges(bReassign,:) = Segmentation.ResegFromTree.ReassignNextFrame(t, droppedTracks(bReassign), reassignEdges);
    end
    
    extendEdges = allEdges(bExtendEdges,:);
    if ( any(bExtendEdges) )
        extendLeavesForward(extendEdges, droppedTracks)
    end
    
    % Do appropriate linking up of tracks from (t-1) -> t as found above
    newPreserveTracks = Segmentation.ResegFromTree.LinkupEdges(allEdges, preserveTracks);
    
    % This attempts to keep track of what we think we've correctly resegmented
    setEdgeResegInfo([newEdges; extendEdges]);
    
    if ( t < length(HashedCells) )
        Tracker.UpdateTrackingCosts(t, tHulls, [HashedCells{t+1}.hullID]);
    end
end

function [droppedTracks edges] = chopTracks(t, tracks)
    global CellTracks;
    
    droppedTracks = zeros(1,length(tracks));
    
    edges = zeros(length(tracks),2);
    % Find edges (hull-to-hull) that span t
    for i=1:length(tracks)
        chkEdge = Segmentation.ResegFromTree.GetTrackInEdge(t, tracks(i));
        edges(i,:) = chkEdge;
    end
    
    choppedTracks = [];
    % Drop tracks at frame t
    for i=1:length(tracks)
        choppedTracks = union(choppedTracks, Families.RemoveFromTreePrune(tracks(i), t));
    end
    
    % Associate edges with droppedTracks
    startHulls = arrayfun(@(x)(x.hulls(1)), CellTracks(choppedTracks));
    [bDropped srtIdx] = ismember(edges(:,2), startHulls);
    
%     if ( ~all(bDropped) )
%         error(['Not all preserve tracks were chopped ' num2str(t)]);
%     end
    
    droppedTracks(bDropped) = choppedTracks(srtIdx(bDropped));
end

function setEdgeResegInfo(edges)
    global CellTracks ResegLinks
    
    bValidEdges = all(edges ~= 0, 2);
    validEdges = edges(bValidEdges,:);
    
    trackIDs = Hulls.GetTrackID(validEdges(:,1));
    familyIDs = [CellTracks(trackIDs).familyID];
    
    for i=1:size(validEdges,1)
        ResegLinks(validEdges(i,1),validEdges(i,2)) = familyIDs(i);
    end
end

function clearEdgeResegInfo(edges)
    global ResegLinks
    
    nzNextHulls = edges((edges(:,2) ~= 0),2);
    ResegLinks(:,nzNextHulls) = 0;
end

function fixedEdges = fixupConflictingEdges(t, bIgnored, newEdges, oldEdges, droppedTracks)
    global CellTracks
    
    ignoredEdges = oldEdges(bIgnored,:);
    oldLookup = find(~bIgnored);
    
    [bNeedsFix conflictIdx] = ismember(ignoredEdges(:,2), newEdges(:,2));
    bNeedsFix = (bNeedsFix & (ignoredEdges(:,2) ~= 0));
    
    % Current mitosis events should be preserved anyway so only worry about next frame mitoses
    bValidDropped = (droppedTracks ~= 0);
    bMitNext = false(length(droppedTracks),1);
    bMitNext(bValidDropped) = (arrayfun(@(x)((~isempty(x.childrenTracks)) && (x.endTime == t)), CellTracks(droppedTracks(bValidDropped))));
    
    fixedEdges = ignoredEdges;
    
    fixIdx = find(bNeedsFix);
    conflictIdx = conflictIdx(bNeedsFix);
    for i=1:length(fixIdx)
        fixedEdges(fixIdx,2) = 0;
        % Swap mitosis events if we're going to take a mitosis from an
        % ignored track and there's nowhere else for original mitosis
        if ( bMitNext(oldLookup(conflictIdx(i))) && (~any(newEdges(:,2) == oldEdges(oldLookup(conflictIdx(i)),2))) )
            fixedEdges(fixIdx,2) = oldEdges(oldLookup(conflictIdx(i)),2);
        end
    end
end

function extendLeavesForward(extendEdges, droppedTracks)
    for i=1:size(extendEdges,1)
        pushHull = extendEdges(i,2);
        if ( pushHull == 0 )
            continue;
        end

        % Don't do anything if the push hull is on a dropped track
        pushTrack = Hulls.GetTrackID(pushHull);
        if ( any(droppedTracks == pushTrack) )
            continue;
        end

        % Tear hull off of its track and make a new one for it.
        Tracks.RemoveHullFromTrack(pushHull);
        Families.NewCellFamily(pushHull);
    end
end
