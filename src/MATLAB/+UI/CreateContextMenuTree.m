% CreateContextMenuCells.m - creates the context menu for the figure that
% displays the tree data and the subsequent function calls

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

function CreateContextMenuTree()

global Figures

figure(Figures.tree.handle);
Figures.tree.contextMenuHandle = uicontextmenu;

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Remove Mitosis',...
    'CallBack',     @removeMitosis);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Add Mitosis',...
    'CallBack',     @addMitosis);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Change Label',...
    'CallBack',     @changeLabel,...
    'Separator',    'on');

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Add To Extended Family',...
    'CallBack',     @addToExtendedFamily,...
    'Separator',    'on');

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Remove From Extended Family',...
    'CallBack',     @removeFromExtendedFamily);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Show Extended Family',...
    'CallBack',     @showExtendedFamily);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');
end

%% Callback functions
% ChangeLog:
% MW Long ago
function removeMitosis(src,evnt)
global CellTracks Figures
object = get(gco);
if(strcmp(object.Type,'text') || strcmp(object.Marker,'o'))
    %clicked on a node
    curTrack = object.UserData;
    bLocked = Helper.CheckTreeLocked(curTrack);
    
    if(isempty(CellTracks(curTrack).parentTrack))
        msgbox('No Mitosis to Remove','Unable to Remove Mitosis','error');
        return
    end
    
    if ( bLocked )
        resp = questdlg('This edit will affect the structure of tracks on a locked tree, do you wish to continue?', 'Warning: Locked Tree', 'Continue', 'Cancel', 'Cancel');
        if ( strcmpi(resp,'Cancel') )
            return;
        end
    end
    
    choice = object.UserData;
elseif(object.YData(1)==object.YData(2))
    %clicked on a horizontal line
    curTrack = object.UserData;
    bLocked = Helper.CheckTreeLocked(curTrack);
    
    if ( bLocked )
        resp = questdlg('This edit will affect the structure of tracks on a locked tree, do you wish to continue?', 'Warning: Locked Tree', 'Continue', 'Cancel', 'Cancel');
        if ( strcmpi(resp,'Cancel') )
            return;
        end
    end
    
    [localLabels, revLocalLabels] = UI.GetLocalTreeLabels(Figures.tree.familyID);
    leftLocal = UI.TrackToLocal(localLabels, CellTracks(curTrack).childrenTracks(1));
    rightLocal = UI.TrackToLocal(localLabels, CellTracks(curTrack).childrenTracks(2));
    
    choice = questdlg('Which Side to Keep?','Merge With Parent',...
        leftLocal, rightLocal, 'Cancel','Cancel');
    
    if(strcmpi(choice,'Cancel'))
        return
    end
    
%     choice = str2double(choice);
    choice = UI.LocalToTrack(revLocalLabels, choice);
else
    %clicked on a vertical line
    msgbox('Please Click on a Cell Label or the Horizontal Edge to Remove Mitosis','Unable to Remove Mitosis','warn');
    return
end

oldParent = CellTracks(choice).parentTrack;

bErr = Editor.ReplayableEditAction(@Editor.ContextRemoveFromTree, choice);
if ( bErr )
    return;
end

Error.LogAction(['Removed part or all of ' num2str(choice) ' from tree'],[],choice);

UI.DrawTree(CellTracks(oldParent).familyID);
UI.DrawCells();
end

% ChangeLog:
% EW 6/8/12 rewrite
function addMitosis(src,evnt)
global Figures

trackID = get(gco,'UserData');
time = get(gca,'CurrentPoint');
time = round(time(1,2));

[localLabels, revLocalLabels] = UI.GetLocalTreeLabels(Figures.tree.familyID);

answer = inputdlg({'Enter Time of Mitosis',['Enter new sister cell of ' UI.TrackToLocal(localLabels, trackID)]},...
    'Add Mitosis',1,{num2str(time),''});

if(isempty(answer)),return,end

time = str2double(answer{1});
%siblingTrack = str2double(answer(2));
siblingTrack = UI.LocalToTrack(revLocalLabels, answer{2});

Editor.ContextAddMitosis(trackID,siblingTrack,time, localLabels, revLocalLabels);
end

function changeLabel(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
Editor.ContextChangeLabel(CellTracks(trackID).startTime,trackID);
end

function addToExtendedFamily(src,evnt)
    global Figures
    
    trackID = get(gco,'UserData');
    if(isempty(trackID)),return,end

    Editor.ContextAddToExtendedFamily(trackID);
end

function removeFromExtendedFamily(src,evnt)
    trackID = get(gco,'UserData');
    if(isempty(trackID)),return,end

    Editor.ContextRemoveFromExtendedFamily(trackID);
end

function showExtendedFamily(src,evnt)
    global CellFamilies CellTracks
    
    trackID = get(gco,'UserData');
    if(isempty(trackID)),return,end
    
    familyID = CellTracks(trackID).familyID;
    msgbox({'Extended family:', num2str(CellFamilies(familyID).extFamily)})
end

function properties(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
Editor.ContextProperties(CellTracks(trackID).hulls(1),trackID);
end
