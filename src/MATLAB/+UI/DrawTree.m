% DrawTree.m - This will draw the family tree of the given family.

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

function DrawTree(familyID, endTime)

global CellFamilies CellTracks HashedCells Figures CellPhenotypes ResegState

if ( ~exist('endTime','var') )
    endTime = length(HashedCells);
end

if ( ~exist('familyID','var') || isempty(familyID) )
    Families.FindLargestTree();
    return;
end

if ( familyID > length(CellFamilies) )
    Families.FindLargestTree();
    return;
end

%let the user know that this might take a while
set(Figures.tree.handle,'Pointer','watch');
set(Figures.cells.handle,'Pointer','watch');

[localLabels, revLocalLabels] = UI.GetLocalTreeLabels(familyID);

if ( ~isfield(Figures.tree,'axesHandle') || ~Helper.ValidUIHandle(Figures.tree.axesHandle) )
    Figures.tree.axesHandle = axes('Parent', Figures.tree.handle);
    
    set(Figures.tree.axesHandle,...
        'YDir',     'reverse',...
        'YLim',     [-25 endTime],...
        'Position', [.06 .06 .90 .90],...
        'XColor',   'w',...
        'XTick',    [],...
        'Box',      'off',...
        'SortMethod', 'childorder');
end

% Leave current tree up if invalid tree selected
if(isempty(CellFamilies(familyID).tracks))
    indicateInvalidResegTree();
    return;
end

% Only update cell error estimate when tree is redrawn
[nSegmentationEdits, nTrackEdits, nMissingHulls, nHulls] = UI.GetErrorCounts();
errorRate = (nSegmentationEdits+nTrackEdits+nMissingHulls)/nHulls/2;
set(Figures.tree.cellEditsLabel,'String',sprintf('Seg: %d Track: %d Missing: %d Hulls: %d Rate: %.2f%%', nSegmentationEdits, nTrackEdits, nMissingHulls, nHulls, errorRate*100));

if ( ~UI.DrawPool.HasPool(Figures.tree.axesHandle) )
    numTracks = FamilyTracks(CellFamilies, familyID);

    
    hold(Figures.tree.axesHandle, 'on');
    
    hLine = line([0 1], [0 0], 'Parent',Figures.tree.axesHandle);
    UI.DrawPool.AddPool(Figures.tree.axesHandle, 'VertLines', hLine, 2*numTracks);
    UI.DrawPool.AddPool(Figures.tree.axesHandle, 'HorzLines', hLine, numTracks);
    delete(hLine);
    
    hMarker = plot(Figures.tree.axesHandle, 0,0, 'ro');
    UI.DrawPool.AddPool(Figures.tree.axesHandle, 'Markers', hMarker, 2*numTracks);
    delete(hMarker);
    
    hLabel = text(0,0, '', 'Parent',Figures.tree.axesHandle);
    UI.DrawPool.AddPool(Figures.tree.axesHandle, 'Labels', hLabel, numTracks);
    delete(hLabel);
    
    hold(Figures.tree.axesHandle, 'off');
end

Figures.tree.familyID = familyID;

rootTrackID = CellFamilies(familyID).rootTrackID;

figure(Figures.tree.handle);

% ylabel('Time (Frames)');

% title(overAxes, CONSTANTS.datasetName, 'Position',[0 0 1], 'HorizontalAlignment','left', 'Interpreter','none');

hold(Figures.tree.axesHandle, 'on');

% build a map with the heights for each node in the tree rooted at trackID
trackMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
trackHeights = Families.ComputeTrackHeights(rootTrackID);

Figures.tree.trackMap = trackMap;

[sortedTracks bFamHasPheno xBox] = extendedTraverseTree(rootTrackID, trackMap, trackHeights);

xBox = xBox + [-0.5 0.5];

UI.DrawPool.StartDraw(Figures.tree.axesHandle);

% Clear non-pooled draw resources
cla(Figures.tree.axesHandle)
set(Figures.tree.axesHandle, 'XLim', xBox, 'YLim',[-25 endTime]);

for i=1:length(sortedTracks)
    childrenTracks = CellTracks(sortedTracks(i)).childrenTracks;
    if ( ~isempty(childrenTracks) )
        yMitosis = CellTracks(sortedTracks(i)).endTime+1;
        xChildren = [trackMap(childrenTracks(1)).xCenter trackMap(childrenTracks(2)).xCenter];
        drawMitosisEdge(Figures.tree.axesHandle, sortedTracks(i), xChildren, yMitosis);
    end
end

for i=1:length(sortedTracks)
    drawCellEdge(Figures.tree.axesHandle, sortedTracks(i), trackMap(sortedTracks(i)).xCenter);
end


bStructOnly = strcmp('on',get(Figures.tree.menuHandles.structOnlyMenu, 'Checked'));
if ( ~bStructOnly )
    bDrawLabels = strcmp('on',get(Figures.tree.menuHandles.treeColorMenu, 'Checked'));
    for i=1:length(sortedTracks)
        drawCellLabel(Figures.tree.axesHandle, sortedTracks(i), trackMap(sortedTracks(i)).xCenter, bDrawLabels, localLabels(sortedTracks(i)));
    end
end

% if ( Figures.cells.showInterior )
%     debugDrawGraphEdits(familyID, xTracks);
% end

UI.DrawPool.FinishDraw(Figures.tree.axesHandle);

% set(Figures.tree.axesHandle, 'XLim', [xMin-1 xMax+1], 'YLim',[-25 endTime]);
% Figures.tree.axesHandle = overAxes;

if ( CellFamilies(familyID).bLocked )
    set(Figures.tree.menuHandles.lockMenu, 'Checked','on');
    set(Figures.cells.menuHandles.lockMenu, 'Checked','on');
    set(Figures.tree.axesHandle, 'Color',[.75 .75 .75]);
else
    set(Figures.tree.menuHandles.lockMenu, 'Checked','off');
    set(Figures.cells.menuHandles.lockMenu, 'Checked','off');
    set(Figures.tree.axesHandle, 'Color','w');
end

if ( CellFamilies(familyID).bFrozen )
    set(Figures.tree.menuHandles.freezeMenu, 'Checked','on');
    set(Figures.cells.menuHandles.freezeMenu, 'Checked','on');
    
    % Disable the "locking mechanism if tree is already frozen"
    set(Figures.tree.menuHandles.lockMenu, 'Enable','off');
    set(Figures.cells.menuHandles.lockMenu, 'Enable','off');
    
%     frzColor = hsv2rgb([0.6 0.25 1.0]);
    set(Figures.tree.axesHandle, 'Color',[0.75 0.85 1.0]);
else
    set(Figures.tree.menuHandles.freezeMenu, 'Checked','off');
    set(Figures.cells.menuHandles.freezeMenu, 'Checked','off');
    
    set(Figures.tree.menuHandles.lockMenu, 'Enable','on');
    set(Figures.cells.menuHandles.lockMenu, 'Enable','on');
end

indicateInvalidResegTree();

zoom(Figures.tree.handle, 'reset');

phenoHandles = [];
hasPhenos = find(bFamHasPheno);
for i=1:length(hasPhenos)
    if ( hasPhenos(i) == 1 )
        color = [0 0 0];
        sym = 'o';
    else
        color = CellPhenotypes.colors(hasPhenos(i),:);
        sym = 's';
    end
    
    hPheno = plot(-5,-5,sym,'MarkerFaceColor',color,'MarkerEdgeColor','w',...
        'MarkerSize',12);
    
    phenoHandles = [phenoHandles hPheno];
    
    set(hPheno,'DisplayName',CellPhenotypes.descriptions{hasPhenos(i)});
end

pdelta = pixelDelta(Figures.tree.axesHandle);
showResegStatus = get(Figures.cells.menuHandles.resegStatusMenu, 'Checked');
if ( strcmpi(showResegStatus, 'on') )
    trackStruct = values(trackMap);
    boxCell = cellfun(@(x)(x.xSmallBox),trackStruct, 'UniformOutput',0);
    smallBox = vertcat(boxCell{:});
    minSpacing = min(abs(smallBox(:,2)-smallBox(:,1)))/2;
    if ( isempty(minSpacing) )
        minSpacing = 1;
    end

    pdelta = pixelDelta(Figures.tree.axesHandle);
    padLeft = min(minSpacing/3, 4*pdelta);
    for i=1:length(sortedTracks)
        drawResegInfo(sortedTracks(i), trackMap(sortedTracks(i)).xCenter-padLeft);
    end
end

% Draw the "edit" line, and current resegable cirlces,if reseg is running
if ( ~isempty(ResegState) )
    treeXlims = get(Figures.tree.axesHandle,'XLim');
    resegTime = max(ResegState.currentTime-1,1);

    plot(Figures.tree.axesHandle, [treeXlims(1), treeXlims(2)],[resegTime, resegTime], '-b');

    viewLims = [xlim(Figures.cells.axesHandle); ylim(Figures.cells.axesHandle)];

    xStarts = [CellTracks(sortedTracks).startTime];
    xEnds = [CellTracks(sortedTracks).endTime];

    inTracks = sortedTracks((xStarts <= resegTime) & (xEnds >= resegTime));

    [bIgnored bLong] = Segmentation.ResegFromTree.CheckIgnoreTracks(resegTime, inTracks, viewLims);
    resegTracks = inTracks(~(bIgnored|bLong));
    
    indicatorList = [];
    for i=1:length(resegTracks)
        indicatorList = [indicatorList plot(trackMap(resegTracks(i)).xCenter,resegTime, '.b', 'MarkerSize',12)];
    end

    Figures.tree.resegIndicators = indicatorList;
end

hold(Figures.tree.axesHandle, 'off');

UI.UpdateTimeIndicatorLine();

if(isempty(phenoHandles))
    legend(Figures.tree.axesHandle,'hide');
else
    legend(Figures.tree.axesHandle, phenoHandles, 'Location','NorthWest');
end

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
end

function indicateInvalidResegTree()
    global ResegState Figures CellTracks CellFamilies
    if ( isempty(ResegState) )
        return;
    end
    
    badResegColor = [1 0.8 0.8];
    preserveRoots = Families.GetFamilyRoots(CellFamilies(ResegState.primaryTree).rootTrackID);
    validPreserveFam = [CellTracks(preserveRoots).familyID];
    
    if ( any(validPreserveFam == Figures.tree.familyID) )
        return;
    end
    
    % Used to indicate that the current viewing tree is NOT the current reseg tree.
    set(Figures.tree.axesHandle, 'Color',badResegColor);

    xl = xlim(Figures.tree.axesHandle);
    yl = ylim(Figures.tree.axesHandle);
    text(xl(1),yl(1),'Selected tree is not being resegmented!', 'HorizontalAlignment','Left', 'VerticalAlignment','Top', 'Parent',Figures.tree.axesHandle);
end

function drawResegInfo(trackID, xVal)
    global Figures CellTracks CellHulls ResegLinks
    
    hulls = CellTracks(trackID).hulls;
    nzHulls = hulls(hulls ~= 0);
    
    bHasResegLink = any((ResegLinks(:,nzHulls) ~= 0),1);
    if ( nnz(bHasResegLink) == 0 )
        return;
    end
    
    [linkHulls,nextIdx] = find(ResegLinks(:,nzHulls(bHasResegLink)) ~= 0);
    nextHulls = nzHulls(bHasResegLink);
    
    nextTimes = [CellHulls(nextHulls).time];
    linkTimes = [CellHulls(linkHulls).time];
    
    for i=1:length(nextTimes)
        plot(Figures.tree.axesHandle, [xVal xVal], [nextTimes(i) linkTimes(i)], '-r');
    end
end

function hLine = drawMitosisEdge(curAx,trackID, xChildren,yVal)
    global Figures
%     plot(curAx, xChildren,[yVal yVal],'-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
    hLine = UI.DrawPool.GetHandle(curAx, 'HorzLines');
    set(hLine, 'XData',xChildren, 'YData',[yVal yVal],...
               'Color','k', 'UserData',trackID,...
               'uicontextmenu',Figures.tree.contextMenuHandle);
end

function drawCellEdge(curAx, trackID, xVal)
    global CellTracks Figures
    
    yStart = CellTracks(trackID).startTime;
    yEnd = CellTracks(trackID).endTime + 1;
    
    phenotype = Tracks.GetTrackPhenotype(trackID);
    if ( phenotype ~= 1 )
        %draw vertical line to represent edge length
        % plot(curAx, [xVal xVal],[yStart yEnd],...
        %     '-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);

        hLine = UI.DrawPool.GetHandle(curAx, 'VertLines');
        set(hLine, 'XData',[xVal xVal],...
                   'YData',[yStart yEnd],...
                   'Color','k', 'UserData',trackID,...
                   'LineStyle','-',...
                   'uicontextmenu',Figures.tree.contextMenuHandle);
    else
        yPhenos = Tracks.GetTrackPhenoypeTimes(trackID);

        % plot(curAx, [xVal xVal],[yStart yPhenos(end)],...
        %     '-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
        % plot(curAx, [xVal xVal],[yPhenos(end) yEnd],...
        %     '--k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
        hLine = UI.DrawPool.GetHandle(curAx, 'VertLines');
        set(hLine, 'XData',[xVal xVal],...
                   'YData',[yStart yPhenos(end)],...
                   'Color','k', 'UserData',trackID,...
                   'LineStyle','-',...
                   'uicontextmenu',Figures.tree.contextMenuHandle);
        
        hLine = UI.DrawPool.GetHandle(curAx, 'VertLines');
        set(hLine, 'XData',[xVal xVal],...
                   'YData',[yPhenos(end) yEnd],...
                   'Color','k', 'UserData',trackID,...
                   'LineStyle','--',...
                   'uicontextmenu',Figures.tree.contextMenuHandle);
    end
    
    if ( phenotype > 0 )
        yPhenos = Tracks.GetTrackPhenoypeTimes(trackID);
        plot(curAx, xVal*ones(size(yPhenos)),yPhenos,'rx','UserData',trackID);
    end
end

function drawCellLabel(curAx, trackID, xVal, bDrawLabels, label)
    global Figures CellTracks CellPhenotypes
    
    phenotype = Tracks.GetTrackPhenotype(trackID);
    yMin = CellTracks(trackID).startTime;
    
%    [fontSize circleSize] = UI.GetFontShapeSizes(length(num2str(trackID)));
    [fontSize, circleSize] = UI.GetFontShapeSizes(length(label));
    if ( ~bDrawLabels )
        fontSize = 6;
        phenoScale = 1.2;
    else
        phenoScale = 1.5;
    end
    
    % short labels need slightly bigger circles
    bUseShortLabels = strcmp('on',get(Figures.tree.menuHandles.shortLabelsMenu, 'Checked'));
    if bUseShortLabels
        circleSize = circleSize + 5;
    end
    
    textColor = getTextColor(trackID, phenotype, bDrawLabels);
    % Draw text
%     text(xVal,yMin,num2str(trackID),...
%         'Parent',               curAx,...
%         'HorizontalAlignment',  'center',...
%         'FontSize',             fontSize,...
%         'color',                TextColor,...
%         'UserData',             trackID,...
%         'uicontextmenu',        Figures.tree.contextMenuHandle);
    hLabel = UI.DrawPool.GetHandle(curAx, 'Labels');
    set(hLabel, 'String',label,...
                'Position',[xVal, yMin],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize,...
                'FontWeight', 'bold',...
                'color',textColor,...
                'UserData',trackID,...
                'ButtonDownFcn',@(src,evnt)(UI.FigureTreeDown(src,evnt,trackID)),...
                'uicontextmenu',Figures.tree.contextMenuHandle);
    
    % Draw a dead cell marker
    if ( phenotype == 1 )
        hMarker = UI.DrawPool.GetHandle(curAx, 'Markers');
        set(hMarker, 'XData',xVal, 'YData',yMin,...
                     'Marker','o',...
                     'MarkerFaceColor','k',...
                     'MarkerEdgeColor','r',...
                     'MarkerSize',circleSize,...
                     'UserData',trackID,...
                     'ButtonDownFcn',@(src,evnt)(UI.FigureTreeDown(src,evnt,trackID)),...
                     'uicontextmenu',Figures.tree.contextMenuHandle);
        
        UI.DrawPool.SetDrawOrder(Figures.tree.axesHandle, [hMarker hLabel]);
        return;
    end
    
    % Draw a phenotype box
    hPheno = [];
    if ( phenotype > 1 )
        phenoColor = CellPhenotypes.colors(phenotype,:);
        hPheno = UI.DrawPool.GetHandle(curAx, 'Markers');
        set(hPheno, 'XData',xVal, 'YData',yMin,...
                     'Marker','s',...
                     'MarkerFaceColor',phenoColor,...
                     'MarkerEdgeColor','w',...
                     'MarkerSize',phenoScale*circleSize,...
                     'UserData',trackID,...
                     'ButtonDownFcn',@(src,evnt)(UI.FigureTreeDown(src,evnt,trackID)),...
                     'uicontextmenu',Figures.tree.contextMenuHandle);
    end
    
    if ( bDrawLabels )
        hMarker = UI.DrawPool.GetHandle(curAx, 'Markers');
        set(hMarker, 'XData',xVal, 'YData',yMin,...
                     'Marker','o',...
                     'MarkerFaceColor',CellTracks(trackID).color.background,...
                     'MarkerEdgeColor',CellTracks(trackID).color.background,...
                     'MarkerSize',circleSize,...
                     'UserData',trackID,...
                     'ButtonDownFcn',@(src,evnt)(UI.FigureTreeDown(src,evnt,trackID)),...
                     'uicontextmenu',Figures.tree.contextMenuHandle);
        
        
        UI.DrawPool.SetDrawOrder(curAx, [hPheno hMarker hLabel]);
        return;
    end
    
    hMarker = [];
    if ( phenotype == 0 )
        hMarker = UI.DrawPool.GetHandle(curAx, 'Markers');
        set(hMarker, 'XData',xVal, 'YData',yMin,...
                     'Marker','o',...
                     'MarkerFaceColor','w',...
                     'MarkerEdgeColor','k',...
                     'MarkerSize',circleSize,...
                     'UserData',trackID,...
                     'ButtonDownFcn',@(src,evnt)(UI.FigureTreeDown(src,evnt,trackID)),...
                     'uicontextmenu',Figures.tree.contextMenuHandle);
    end
    
    UI.DrawPool.SetDrawOrder(curAx, [hPheno hMarker hLabel]);
end

function textColor = getTextColor(trackID, phenotype, bDrawLabels)
    global CellTracks CellPhenotypes
    
    % Colors for dead cells
    if ( phenotype == 1 )
        textColor = 'r';
        return;
    end
    
    % Colors if track label colors are on
    if ( bDrawLabels )
        textColor = CellTracks(trackID).color.text;
        return;
    end
    
    textColor = 'k';
    % If not drawing labels, but the track has a phenotype
    if ( phenotype > 1 )
        phenoColor = CellPhenotypes.colors(phenotype,:);
        if ( ~isempty(phenoColor) )
            m = rgb2hsv(phenoColor);
            if ( m(1) > 0.5 )
                textColor = 'w';
            end
        end
        return;
    end
end

function [sortedTracks bFamHasPheno] = simpleTraverseTree(trackID, xVal, trackMap, trackHeights)
    global CellTracks CellPhenotypes
    
    bFamHasPheno = false(length(CellPhenotypes.descriptions),1);
    phenoType = Tracks.GetTrackPhenotype(trackID);
    if ( phenoType > 0 )
        bFamHasPheno(phenoType) = true;
    end
    
    if ( isempty(CellTracks(trackID).childrenTracks) )
        startTime = CellTracks(trackID).startTime;
        endTime = CellTracks(trackID).endTime + 1;
        
        sortedTracks = trackID;
        trackMap(trackID) = struct('xCenter',{xVal}, 'xSmallBox',{[xVal-0.5 xVal+0.5]}, 'xBox',{[xVal-0.5 xVal+0.5]}, 'yBox',[startTime endTime]);
        return;
    end
    
    leftChildID = CellTracks(trackID).childrenTracks(1);
    rightChildID = CellTracks(trackID).childrenTracks(2);
    if ( trackHeights(leftChildID) < trackHeights(rightChildID) )
        leftChildID = CellTracks(trackID).childrenTracks(2);
        rightChildID = CellTracks(trackID).childrenTracks(1);
    end
    
    [leftTracks bLeftChildHasPheno] = simpleTraverseTree(leftChildID, xVal, trackMap, trackHeights);
    xRightVal = trackMap(leftChildID).xBox(2) + 0.5;
    
    [rightTracks bRightChildHasPheno] = simpleTraverseTree(rightChildID, xRightVal, trackMap, trackHeights);
    bFamHasPheno = (bFamHasPheno | bLeftChildHasPheno | bRightChildHasPheno);
    
    xCenter = mean([trackMap(leftChildID).xCenter trackMap(rightChildID).xCenter]);
    
    xMin = min(trackMap(leftChildID).xBox(1), trackMap(rightChildID).xBox(1));
    xMax = max(trackMap(leftChildID).xBox(2), trackMap(rightChildID).xBox(2));
    
    xSmallMin = trackMap(leftChildID).xCenter;
    xSmallMax = trackMap(rightChildID).xCenter;
    
    yMin = CellTracks(trackID).startTime;
    yMax = max(trackMap(leftChildID).yBox(2), trackMap(rightChildID).yBox(2));
    
    sortedTracks = [trackID leftTracks rightTracks];
    trackMap(trackID) = struct('xCenter',{xCenter}, 'xSmallBox',{[xSmallMin xSmallMax]}, 'xBox',{[xMin xMax]}, 'yBox',[yMin yMax]);
end

% how far is 1 pixel in normalized units?
function [deltaX deltaY] = pixelDelta(axHandle)

x_lim = xlim(axHandle);
y_lim = ylim(axHandle);

set(axHandle, 'units', 'pixels');
pos = get(axHandle, 'position');

deltaX = x_lim(2) / pos(3);
deltaY = y_lim(2) / pos(4);

set(axHandle, 'units', 'normalized');

end

function numTracks = FamilyTracks(CellFamilies, familyID)
    numTracks = 0;
    family = CellFamilies(familyID);
    
    if isfield(CellFamilies, 'extFamily')
        if isempty(family.extFamily)
            numTracks = length(family.tracks);
        else
            for i=1:length(family.extFamily)
                fid = family.extFamily(i);
                numTracks = numTracks + length(CellFamilies(fid).tracks);
            end
        end
    else
        numTracks = length(family.tracks);
    end
end

function [sortedTracks bFamHasPheno xBox] = extendedTraverseTree(rootTrackID, trackMap, trackHeights)
    global CellFamilies CellTracks
    
    familyID = CellTracks(rootTrackID).familyID;
    family = CellFamilies(familyID);

    % handle the simple cases first
    if isfield(CellFamilies, 'extFamily')
        if isempty(family.extFamily)
            [sortedTracks bFamHasPheno] = simpleTraverseTree(rootTrackID, 0, trackMap, trackHeights);
            xBox = trackMap(rootTrackID).xBox;
            return;
        end
    else
        [sortedTracks bFamHasPheno] = simpleTraverseTree(rootTrackID, 0, trackMap, trackHeights);
        xBox = trackMap(rootTrackID).xBox;
        return;
    end
    
    sortedTracks = [];
    bFamHasPheno = 0;
    offset = 0;
    roots = Families.GetFamilyRoots(rootTrackID);
    
    for i=1:length(roots)
        [tracks hasPheno] = simpleTraverseTree(roots(i), 0, trackMap, trackHeights);
        sortedTracks = [sortedTracks tracks];
        bFamHasPheno = bFamHasPheno | hasPheno;
        
        % find the new offset before we change everything
        root = trackMap(tracks(1));
        newOffset = offset + root.xBox(2) + 1;

        % slide everything over by offset
        for j=1:length(tracks)
            temp = trackMap(tracks(j));
            temp.xCenter   = temp.xCenter + offset;
            temp.xSmallBox = temp.xSmallBox + offset;
            temp.xBox      = temp.xBox + offset;
            trackMap(tracks(j)) = temp;
        end
        
        offset = newOffset;
    end
    
    xBox = [trackMap(roots(1)).xBox(1) trackMap(roots(end)).xBox(2)];
end

function fmax = MaxFluorVal(familyID)
    global CellFamilies CellTracks CellHulls

    famTracks = CellFamilies(familyID).tracks;
    famHulls = [CellTracks(famTracks).hulls];
    famHulls = famHulls(famHulls > 0);
    fvals = [CellHulls(famHulls).fluorVals];
    fvals = reshape(fvals,4,[]);
    fmax = max(fvals,[],2);
end
