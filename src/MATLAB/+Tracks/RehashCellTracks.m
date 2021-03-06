% RehashedCellTracks(trackID) 
% will rearange the hulls in the given track so that it will hash correctly.
% It will also zero pad the hulls list appropriately. The hulls are hashed 
% so that the index into the cell array is time of hull subtract start time
% of track.  
% eg hash = time of hull - CellTracks(i).startTime
% CellTracks.endTime and Family.start/end will be updated too, if nessasary

% ChangeLog
% EW 6/6/12  rewrite
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

function RehashCellTracks(trackID)
global CellTracks CellHulls

hulls = CellTracks(trackID).hulls(CellTracks(trackID).hulls > 0);
if (~isempty(hulls))
    [uniqueTimes sortedIndcies] = unique([CellHulls(hulls).time]);
    if (length(uniqueTimes)~=length([CellHulls(hulls).time]))
        hullsString = sprintf('%d, ',CellTracks(trackID).hulls);
        error('More than one hull on a frame on track %d\nHulls: %s',trackID,hullsString);
    end
    
    %Update the times from the sorting
    CellTracks(trackID).startTime = uniqueTimes(1);
    CellTracks(trackID).endTime = uniqueTimes(end);
    
    %Clear out the old list to the size that the zero padded list should be
    CellTracks(trackID).hulls = zeros(1,uniqueTimes(end)-uniqueTimes(1)+1);
    
    %Add the hulls back into the list in the approprite location
    hashedTimes = uniqueTimes - uniqueTimes(1) + 1; %get hashed times of the hull list
    CellTracks(trackID).hulls(hashedTimes) = hulls(sortedIndcies); %place the hulls in sorted order into thier hashed locations
else
    %Clear out hulls and times
    CellTracks(trackID).startTime = [];
    CellTracks(trackID).endTime = [];
    CellTracks(trackID).hulls = [];
end

%Update the family times
Families.UpdateFamilyTimes(CellTracks(trackID).familyID);
end
