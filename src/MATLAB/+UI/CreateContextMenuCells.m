% CreateContextMenuCells.m - creates the context menu for the figure that
% displays the image data and the subsequent function calls

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

function CreateContextMenuCells()

global Figures

figure(Figures.cells.handle);
Figures.cells.contextMenuHandle = uicontextmenu;

Figures.cells.removeMenu = uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove Mitosis',...
    'CallBack',     @removeMitosis,...
    'Visible',      'off');

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Add Mitosis',...
    'CallBack',     @addMitosis);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Change Label',...
    'CallBack',     @changeLabel,...
    'Separator',    'on');

addHull = uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Change Number of Cells',...
    'Separator',    'on');

uimenu(addHull,...
    'Label',        'Number of Cells');

uimenu(addHull,...
    'Label',        '1',...
    'CallBack',     @addHull1);

uimenu(addHull,...
    'Label',        '2',...
    'CallBack',     @addHull2);

uimenu(addHull,...
    'Label',        '3',...
    'CallBack',     @addHull3);

uimenu(addHull,...
    'Label',        '4',...
    'CallBack',     @addHull4);

uimenu(addHull,...
    'Label',        'Other',...
    'Separator',    'on',...
    'CallBack',     @addHullOther);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove Cell (this frame)',...
    'CallBack',     @removeHull);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Delete Track',...
    'CallBack',     @removeTrackPrevious);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove From Tree',...
    'CallBack',     @removeFromTree);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');

UI.CreatePhenotypeMenu();
end

%% Callback functions

function removeMitosis(src,evnt)
%%%not used

end

% ChangeLog:
% EW 6/8/12 rewritten
function addMitosis(src,evnt)
global Figures

[hullID siblingTrack] = UI.GetClosestCell(0);
if(isempty(siblingTrack)),return,end

answer = inputdlg({['Add ' num2str(siblingTrack) ' as a sibling to:']},...
    'Add Mitosis',1,{''});

if(isempty(answer)),return,end

trackID = str2double(answer(1));
time = Figures.time;

Editor.ContextAddMitosis(trackID,siblingTrack,time);
end

function changeLabel(src,evnt)
global Figures

[hullID trackID] = UI.GetClosestCell(0);
if(isempty(trackID)),return,end

Editor.ContextChangeLabel(Figures.time,trackID);
end

function addHull1(src,evnt)
Segmentation.AddHull(1);
end

function addHull2(src,evnt)
Segmentation.AddHull(2);
end

function addHull3(src,evnt)
Segmentation.AddHull(3);
end

function addHull4(src,evnt)
Segmentation.AddHull(4);
end

function addHullOther(src,evnt)
num = inputdlg('Enter Number of Cells Present','Add Hulls',1,{'1'});
if(isempty(num)),return,end;
num = str2double(num(1));
Segmentation.AddHull(num);
end

function removeHull(src,evnt)
global Figures CellFamilies

[hullID trackID] = UI.GetClosestCell(0);
if(isempty(trackID)),return,end

try
    Segmentation.RemoveSegmentationEdit(hullID);
    Hulls.RemoveHull(hullID);
    Editor.History('Push');
catch errorMessage
    Error.ErrorHandling(['RemoveHull(' num2str(hullID) ') -- ' errorMessage.message],errorMessage.stack);
    return
end

Error.LogAction(['Removed hull from track ' num2str(trackID)],hullID);

%if the whole family disapears with this change, pick a diffrent family to
%display
if(isempty(CellFamilies(Figures.tree.familyID).tracks))
    for i=1:length(CellFamilies)
        if(~isempty(CellFamilies(i).tracks))
            Figures.tree.familyID = i;
            break
        end
    end
    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
    msgbox(['By removing this cell, the complete tree is no more. Displaying clone rooted at ' num2str(CellFamilies(i).rootTrackID) ' instead'],'Displaying Tree','help');
    return
end

UI.DrawTree(Figures.tree.familyID);
UI.DrawCells();
end

function removeTrackPrevious(src,evnt)
    global Figures CellFamilies

    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID)),return,end
    
    try
        Tracks.RemoveTrackHulls(trackID);
        
        Editor.History('Push');
    catch errorMessage
        Error.ErrorHandling(['RemoveTrackHulls(' num2str(trackID) ') -- ' errorMessage.message],errorMessage.stack);
        return
    end
    Error.LogAction(['Removed all hulls from track ' num2str(trackID)],[],[]);
    
    %if the whole family disapears with this change, pick a diffrent family to
    %display
    if(isempty(CellFamilies(Figures.tree.familyID).tracks))
        for i=1:length(CellFamilies)
            if(~isempty(CellFamilies(i).tracks))
                Figures.tree.familyID = i;
                break
            end
        end
        UI.DrawTree(Figures.tree.familyID);
        UI.DrawCells();
        return
    end

    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end

function removeFromTree(src,evnt)
global Figures

[hullID trackID] = UI.GetClosestCell(0);
if(isempty(trackID)),return,end

Editor.ContextRemoveFromTree(trackID,Figures.time);
end

function properties(src,evnt)
[hullID trackID] = UI.GetClosestCell(0);
if(isempty(trackID)),return,end

Editor.ContextProperties(hullID,trackID);
end
