% ResegmentHull.m - Splits hull into k pieces using a gaussian mixture model,
% returns the k split hulls or [] if there are errors.

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

function newHulls  = ResegmentHull(hull, k, bUserEdit)
global CONSTANTS CellHulls

newHulls = [];

if ( ~exist('bUserEdit','var') )
    bUserEdit = 0;
end

% guassian clustering (x,y,...) coordinates of cell interior
rcImageDims = Metadata.GetDimensions('rc');
rcCoords = Utils.IndToCoord(rcImageDims, hull.indexPixels);
xyCoords = Utils.SwapXY_RC(rcCoords);

typeParams = Load.GetCellTypeStructure(CONSTANTS.cellType);
if ( typeParams.splitParams.useGMM )
    gmoptions = statset('Display','off', 'MaxIter',400);
    
    obj = Helper.fitGMM(xyCoords, k, 'Replicates',15, 'Options',gmoptions);
    kIdx = cluster(obj, xyCoords);
else
    kIdx = kmeans(xyCoords, k, 'Replicates',5, 'EmptyAction','drop');
end

if ( any(isnan(kIdx)) )
    return;
end

for i=1:k
    newHullPixels = hull.indexPixels( kIdx==i );
    
    outputHull = Hulls.CreateHull(rcImageDims, newHullPixels, hull.time, bUserEdit);
    newHulls = [newHulls outputHull];
end

% Define an ordering on the hulls selected, COM is unique per component so
% this gives a deterministic ordering to the components
[sortCOM, sortIdx] = sortrows(vertcat(newHulls.centerOfMass));
newHulls = newHulls(sortIdx);

end

