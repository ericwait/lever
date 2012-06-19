% ClearTrack.m - Function clears out all data for a deleted track.

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

function ClearTrack(trackID)
    global CellTracks CellFamilies
    
    CellFamilies(CellTracks(trackID).familyID).tracks = setdiff(CellFamilies(CellTracks(trackID).familyID).tracks,trackID);
    Families.UpdateFamilyTimes(CellTracks(trackID).familyID);
    
    
    % Get all field names dynamically and clear them
    strFieldNames = fieldnames(CellTracks);
    for i=1:length(strFieldNames)
        CellTracks(trackID).(strFieldNames{i}) = [];
    end
end