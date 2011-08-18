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

function bInHull = CHullContainsPoint(pt, hulls)
    bInHull = false(length(hulls),1);
    
    for i=1:length(hulls)
        
        if ( size(hulls(i).points,1) <= 1 )
            continue;
        end
        
%         cvpts = hulls(i).points;
%         hullvec = diff(cvpts);
%         
%         outnrm = [-hullvec(:,2) hullvec(:,1)];
%         %outnrm = outnrm ./ sqrt(sum(outnrm.^2,2));
%         
%         ptvec = cvpts(1:end-1,:) - ones(size(outnrm,1),1)*pt;
%         %ptvec = ptvec ./ sqrt(sum(ptvec.^2,2));
%         
%         chkIn = sign(sum(outnrm .* ptvec,2));
%         
%         bInHull(i) = all(chkIn >= 0);

        bInHull(i) = inpolygon(pt(1), pt(2), hulls(i).points(:,1), hulls(i).points(:,2));
    end
end