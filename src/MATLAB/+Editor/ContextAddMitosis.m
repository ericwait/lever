% ContextAddMitosis(trackID, siblingTrack, time)

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


% ChangeLog:
% EW 6/8/12 created
function ContextAddMitosis(trackID, siblingTrack, time, localLabels, revLocalLabels)
global CellTracks CellFamilies Figures

trackIDLocal = UI.TrackToLocal(localLabels, trackID);
siblingTrackLocal = UI.TrackToLocal(localLabels, siblingTrack);

if(siblingTrack>length(CellTracks) || isempty(CellTracks(siblingTrack).hulls))
    msgbox([siblingTrackLocal ' is not a valid cell'],'Not a valid cell','error');
    return
end
if(CellTracks(siblingTrack).endTime<time || siblingTrack==trackID)
    msgbox([siblingTrackLocal ' is not a valid sister cell'],'Not a valid sister cell','error');
    return
end
if(CellTracks(trackID).startTime>time)
    msgbox([trackIDLocal ' starts after ' siblingTrackLocal],'Not a valid daughter cell','error');
    return
end
if(~isempty(Tracks.GetTimeOfDeath(siblingTrack)) && Tracks.GetTimeOfDeath(siblingTrack)<=time)
    msgbox(['Cannot attach a cell to cell ' siblingTrackLocal ' beacuse it is dead at this time'],'Dead Cell','help');
    return
end
if(~isempty(Tracks.GetTimeOfDeath(trackID)) && Tracks.GetTimeOfDeath(trackID)<=time)
    msgbox(['Cannot attach a cell to cell ' trackIDLocal ' beacuse it is dead at this time'],'Dead Cell','help');
    return
end

leftChildTrack = [];

% if both tracks are starting on this frame see who the parent should be
% and then merge the track with the parent
if(CellTracks(trackID).startTime==time)
    bValid = false;
    while(~bValid)
        answer = inputdlg({'Enter parent of these daughter cells '},'Parent',1,{''});
        if(isempty(answer)),return,end
        parentTrackLocal = answer{1};
        parentTrack = UI.LocalToTrack(revLocalLabels, parentTrackLocal);
        
        if(isnan(parentTrack) || CellTracks(parentTrack).startTime>=time || isempty(CellTracks(parentTrack).hulls) ||...
                (~isempty(Tracks.GetTimeOfDeath(parentTrack)) && Tracks.GetTimeOfDeath(parentTrack)<=time))
            choice = questdlg([parentTrackLocal ' is an invalid parent for these cells, please choose another'],...
                'Not a valid parent','Enter a different parent','Cancel','Cancel');
            if ( strcmpi(choice,'Cancel') )
                return
            end
        else
            bValid = true;
        end
    end
    
    leftChildTrack = trackID;
    trackID = parentTrack;
end

bOverrideLock = false;

[bParentLock bChildrenLock bCanAdd] = Families.CheckLockedAddMitosis(trackID, leftChildTrack, siblingTrack, time);
bAffectsLocked = [bParentLock bChildrenLock];
if ( ~bCanAdd )
    lockedTracks = [trackID siblingTrack leftChildTrack];
    lockedTracks = lockedTracks(bAffectsLocked);
    
    lockedList = unique(lockedTracks);
    lockedListLocal = '';
    for i=1:length(lockedList)
        lockedListLocal = [lockedListLocal ' ' UI.TrackToLocal(lockedList(i))];
    end

    resp = questdlg(['This edit may add or remove multiple unintended mitosis events from the locked tree(s): ' lockedListLocal '. Do you wish to continue?'], 'Warning: Breaking Locked Tree', 'Continue', 'Cancel', 'Cancel');
    if ( strcmpi(resp,'Cancel') )
        return;
    end

    bOverrideLock = true;
end

% if ( ~bOverrideLock && any([bParentLock bChildrenLock]) )
%     resp = questdlg(['This edit will affect locked tree: ' num2str(lockedList) '. Do you wish to continue?'], 'Warning: Editing Locked Tree', 'Continue', 'Cancel', 'Cancel');
%     if ( strcmpi(resp,'Cancel') )
%         return;
%     end
% end

if ( ~bOverrideLock && any(bAffectsLocked) )
    bErr = Editor.ReplayableEditAction(@Editor.LockedAddMitosisAction, trackID,leftChildTrack,siblingTrack,time);
else
    bErr = Editor.ReplayableEditAction(@Editor.AddMitosisAction, trackID,leftChildTrack,siblingTrack,time);
end
if ( bErr )
    return;
end

Error.LogAction(['Added ' num2str(siblingTrack) ' as sibling to ' num2str(trackID) ' at time t=' num2str(time)]);

Figures.tree.familyID = CellTracks(trackID).familyID;
UI.DrawTree(Figures.tree.familyID);
UI.DrawCells();
end

