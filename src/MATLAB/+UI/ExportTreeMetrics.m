% ExportMetrics.m - Export various cell track metrics for use in external
% analysis.

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

function ExportTreeMetrics(src,evnt)

global CellTracks CellFamilies CONSTANTS Figures

familyID=Figures.tree.familyID;
rootTrackID = CellFamilies(familyID).rootTrackID;

trackHeights = Families.ComputeTrackHeights(rootTrackID);
famTracks = CellFamilies(familyID).tracks;

settings = Load.ReadSettings();

[outFile,outPath,FilterIndex] = uiputfile('*.csv',['Export Metrics for clone #' num2str(rootTrackID)],fullfile(settings.matFilePath,[Metadata.GetDatasetName() '_' num2str(rootTrackID) '_metrics.csv']));
if ( FilterIndex == 0 )
    return;
end

trackSortList = [];
trackMetrics = [];
for i=1:length(famTracks)
    trackEntry = getMetrics(famTracks(i),CellTracks(famTracks(i)));
    
    if ( isempty(trackEntry) )
        continue;
    end
    
    trackSortList = [trackSortList trackHeights(famTracks(i))];
    trackMetrics = [trackMetrics trackEntry];
end

[sortedHeights,srtIdx] = sort(trackSortList,'descend');
trackMetrics = trackMetrics(srtIdx);

data = 'Cell Label,Number of Frames,First Frame,Last Frame,Parent,Child 1,Child 2,Phenotype,Dies on Frame,Mean Speed,Standard Deviation Speed,Min Speed,Max Speed,Mean Area,Standard Deviation Area,Min Area,Max Area\n';
for i=1:length(trackMetrics)
    data = [data num2str(trackMetrics(i).trackID) ',' num2str(trackMetrics(i).timeFrame) ',' num2str(trackMetrics(i).firstFrame) ',' num2str(trackMetrics(i).lastFrame) ',' ];
    if(~isempty(trackMetrics(i).parent))
        data = [data num2str(trackMetrics(i).parent) ','];
    else
        data = [data ','];
    end
    if(~isempty(trackMetrics(i).children))
        data = [data num2str(trackMetrics(i).children(1)) ','];
        if(length(trackMetrics(i).children)>=2)
            data = [data num2str(trackMetrics(i).children(2)) ','];
        else
            data = [data ','];
        end
    else
        data = [data ',,'];
    end
    data = [data trackMetrics(i).phenotype ','];
    if(~isempty(trackMetrics(i).death))
        data = [data num2str(trackMetrics(i).death) ','];
    else
        data = [data ','];
    end
    data = [data num2str(trackMetrics(i).meanSpeed) ',' num2str(trackMetrics(i).standardDeviationSpeed) ','...
        num2str(trackMetrics(i).minSpeed) ',' num2str(trackMetrics(i).maxSpeed) ','...
        num2str(trackMetrics(i).meanArea) ',' num2str(trackMetrics(i).standardDeviationArea) ','...
        num2str(trackMetrics(i).minArea) ',' num2str(trackMetrics(i).maxArea) '\n'];
end

file = fopen(fullfile(outPath,outFile),'w');
if( file < 0)
    warndlg(['The file ' fullfile(outPath,outFile) ' might be opened.  Please close and try again.']);
    return
end

fprintf(file,data);
fclose(file);
end

function trackMetric = getMetrics(trackID,track)
global CellHulls CellPhenotypes

trackMetric = [];
if(length(track.hulls)<3),return,end

trackMetric.trackID = trackID;
trackMetric.timeFrame = length(track.hulls);
trackMetric.firstFrame = track.startTime;
trackMetric.lastFrame = track.endTime;
trackMetric.parent = track.parentTrack;
trackMetric.children = track.childrenTracks;
pheno = Tracks.GetTrackPhenotype(trackID);
if( pheno > 0 )
    % Replace \ with \\ so that fprintf properly outputs latex phenotypes
    trackMetric.phenotype = regexprep(CellPhenotypes.descriptions{pheno},'\\','\\\\');
else
    trackMetric.phenotype = '';
end
trackMetric.death = Tracks.GetTimeOfDeath(trackID);
trackMetric.familyID = track.familyID;

velocities = [];
areas = [];

for i=1:length(track.hulls)-1
    if(~track.hulls(i)),continue,end
    j = i+1;
    if(~track.hulls(j)) %find the next frame where a hull exits
        for k=j:length(track.hulls)
            if(track.hulls(k)),break,end
        end
        if(~track.hulls(k)),break,end %reached the end
        j = k;
    end
    dist = sqrt((CellHulls(track.hulls(j)).centerOfMass(1)-CellHulls(track.hulls(i)).centerOfMass(1))^2 + ...
        (CellHulls(track.hulls(j)).centerOfMass(2)-CellHulls(track.hulls(i)).centerOfMass(2))^2);
    v = dist/(j-i);
    velocities = [velocities v];
    areas = [areas length(CellHulls(track.hulls(i)).indexPixels)];
end
if(track.hulls(length(track.hulls)))
    areas = [areas length(CellHulls(track.hulls(length(track.hulls))).indexPixels)];%i only goes to length -1;
end
trackMetric.meanSpeed = mean(velocities);
trackMetric.minSpeed = min(velocities);
trackMetric.maxSpeed = max(velocities);
trackMetric.standardDeviationSpeed = sqrt(var(velocities));
trackMetric.meanArea = mean(areas);
trackMetric.minArea = min(areas);
trackMetric.maxArea = max(areas);
trackMetric.standardDeviationArea = sqrt(var(areas));
end
