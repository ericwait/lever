function [localLabels, revLocalLabels] = GetLocalTreeLabels(familyID)
    global CellFamilies CellTracks Figures

    % This is a map of trackID -> short label
    localLabels = containers.Map('KeyType', 'double', 'ValueType', 'any');
    
    % This is a map that's the reverse of localLabels, i.e. short label -> trackID
    revLocalLabels = containers.Map('KeyType', 'char', 'ValueType', 'double');
    
    rootTrackID = CellFamilies(familyID).rootTrackID;
    roots = Families.GetFamilyRoots(rootTrackID);
    
    trackHeights = Families.ComputeTrackHeights(rootTrackID);
    
    % if 'Show Short Labels' is unchecked, just return the label itself
    bUseLongLabels = strcmp('off',get(Figures.tree.menuHandles.shortLabelsMenu, 'Checked'));

    visitIdx = 1;
    travQueue = roots;
    while ( ~isempty(travQueue) )
        curTrackID = travQueue(1);
        travQueue = travQueue(2:end);
        
        childTracks = CellTracks(curTrackID).childrenTracks;
        
        if ( ~isempty(childTracks) )
            childHeights(1) = trackHeights(childTracks(1));
            childHeights(2) = trackHeights(childTracks(2));
            
            [srtHeight travOrder] = sort(childHeights, 'descend');
            
            travQueue = [travQueue childTracks(travOrder)];
        end
        
        if ( bUseLongLabels || ismember(curTrackID, roots) )
            localLabels(curTrackID) = num2str(curTrackID);
            revLocalLabels(num2str(curTrackID)) = curTrackID;
        else
            alphaLabel = AlphaLocal(visitIdx);
            localLabels(curTrackID) = alphaLabel;
            revLocalLabels(alphaLabel) = curTrackID;
            visitIdx = visitIdx + 1;
        end
    end
end

% Convert the index to a letter -- A..Z, AA, AB..ZZ, AAA..ZZZ, ...
function res = AlphaLocal(label)
    res = '';
    while 1
        label = label - 1;
        digit = mod(label, 26);
        c = char(digit + 'A');
        res = [c res];
        label = floor(label/26);
        if label == 0
            break
        end
    end
end
