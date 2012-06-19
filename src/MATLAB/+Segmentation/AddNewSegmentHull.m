% AddNewSegmentHull.m - Attempt to add a completely new segmentation near
% the clicked point.

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

function newTrackID = AddNewSegmentHull(clickPt)
    global CONSTANTS Figures

    filename = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' Helper.GetDigitString(Figures.time) '.TIF'];
    img = Helper.LoadIntensityImage(filename);
    
    [newObj newFeat] = Segmentation.PartialImageSegment(img, clickPt, 200, 1.0);

    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0, 'userEdited', 1);
    newFeature = struct('darkRatio',{0}, 'haloRatio',{0}, 'igRatio',{0}, 'darkIntRatio',{0}, 'brightInterior',{1}, 'polyPix',{[]}, 'perimPix',{[]}, 'igPix',{[]}, 'haloPix',{[]});
    
    if ( ~isempty(newObj) )
        newObj = makeNonOverlapping(newObj, Figures.time, clickPt);
    end
    
    if ( isempty(newObj) )
        % Add a point hull since we couldn't find a segmentation containing the click
        newHull.time = Figures.time;
        newHull.points = round(clickPt);
        newHull.centerOfMass =  [clickPt(2) clickPt(1)];
        newHull.indexPixels = sub2ind(size(img), newHull.points(2), newHull.points(1));
        newHull.imagePixels = img(newHull.indexPixels);
        
        newFeature.polyPix = newHull.indexPixels;
    else
        newHull.time = Figures.time;
        newHull.points = newObj.points;
        [r c] = ind2sub(CONSTANTS.imageSize, newObj.indPixels);
        newHull.centerOfMass = mean([r c]);
        newHull.indexPixels = newObj.indPixels;
        newHull.imagePixels = newObj.imPixels;
        
        newFeature = newFeat;
    end
    
    newHullID = Hulls.SetHullEntries(0, newHull, newFeature);
    
    newTrackID = Tracker.TrackAddedHulls(newHullID, newHull.centerOfMass);
end

%TODO: Maybe handle convex hull intersection instead of interior points as
%the current method still allows considerable hull overlap in some cases.
function newobj = makeNonOverlapping(obj, t, clickPt)
    global CONSTANTS CellHulls HashedCells
    
    newobj = [];
    
    ccidxs = vertcat(CellHulls([HashedCells{t}.hullID]).indexPixels);
    pix = obj.indPixels;
    
    bPickPix = ~ismember(pix, ccidxs);
    
    if ( all(bPickPix) )
        newobj = obj;
        return;
    end
    
    bwimg = zeros(CONSTANTS.imageSize);
    bwimg(pix(bPickPix)) = 1;
    
    CC = bwconncomp(bwimg,8);
    if ( CC.NumObjects < 1 )
        newobj = [];
        return;
    end
    
    for i=1:CC.NumObjects
        [r c]=ind2sub(size(bwimg),CC.PixelIdxList{i});
        try
            ch = convhull(r,c);
        catch errmsg
            continue;
        end
        
        if ( inpolygon(clickPt(1), clickPt(2), c(ch), r(ch)) )
            bCCPix = ismember(pix, CC.PixelIdxList{i});
            
            newobj.indPixels = CC.PixelIdxList{i};
            newobj.imPixels = obj.imPixels(bCCPix);
            
            newobj.points = [c(ch) r(ch)];
%             newobj.COM = mean([r c]);
            
            break;
        end
    end
end
