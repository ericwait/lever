
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

function [errStatus,tSeg,tTrack] = SegAndTrackDataset(numProcessors, segArgs)
    global CONSTANTS CellHulls HashedCells ConnectedDist
    
    errStatus = sprintf('Unknown Error\n');
    tSeg = 0;
    tTrack = 0;

    %% Segmentation
    tic
    
    if ( Metadata.GetNumberOfFrames() < 1 )
        return;
    end

    numProcessors = min(numProcessors, Metadata.GetNumberOfFrames());
    bytesPerIm = prod(Metadata.GetDimensions()) * Metadata.GetNumberOfChannels() * 8;
    m = memory;
    maxWorkers = min(numProcessors,floor(m.MaxPossibleArrayBytes / bytesPerIm));

    % Remove trailing \ or / from rootFolder
    if ( (CONSTANTS.rootImageFolder(end) == '\') || (CONSTANTS.rootImageFolder(end) == '/') )
        CONSTANTS.rootImageFolder = CONSTANTS.rootImageFolder(1:end-1);
    end

    fprintf('Segmenting (using %s processors)...\n',num2str(maxWorkers));

    if(~isempty(dir('.\segmentationData')))        
        removeOldFiles('segmentationData', 'err_*.log');
        removeOldFiles('segmentationData', 'objs_*.mat');
        removeOldFiles('segmentationData', 'done_*.txt');
    end
    
    if ( isempty(Metadata.GetDimensions()) )
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Images dimensions are empty\n',cltime(4),cltime(5),cltime(6));
        
        return;
    end
    
    if ( ~exist('.\segmentationData','dir'))
        mkdir('segmentationData');
    end
    
    metadataFile = fullfile(CONSTANTS.rootImageFolder, [Metadata.GetDatasetName() '.json']);
    primaryChannel = CONSTANTS.primaryChannel;
    cellType = CONSTANTS.cellType;
    
    if ( isdeployed() )
        %% compliled version
        % Must use separately compiled segmentor algorithm in compiled LEVer
        % because parallel processing toolkit is unsupported
        for procID=1:maxWorkers
            segCmd = makeSegCommand(procID,maxWorkers,primaryChannel,metadataFile,cellType,segArgs);
            system(['start ' segCmd ' && exit']);
        end
    else
        %% single threaded version
%         for procID=1:maxWorkers
%             Segmentor(procID,maxWorkers,primaryChannel,metadataFile,cellType,segArgs{:});
%         end

        %% spmd version
        poolObj = gcp('nocreate');
        if (~isempty(poolObj))
            oldWorkers = poolObj.NumWorkers;
            if (oldWorkers~=maxWorkers)
                delete(poolObj);
                parpool(maxWorkers);
            end
        else
            oldWorkers = 0;
            parpool(maxWorkers);
        end

        spmd
            Segmentor(labindex,numlabs,primaryChannel,metadataFile,cellType,segArgs{:});
        end

        if (oldWorkers~=0 && oldWorkers~=maxWorkers)
            delete(gcp);
            if (oldWorkers>0)
                parpool(oldWorkers);
            end
        end
    end
    
    %% collate output
    bSegFileExists = false(1,maxWorkers);
    bSemFileExists = false(1,maxWorkers);
    bErrFileExists = false(1,maxWorkers);
    
    bProcFinish = false(1,maxWorkers);
    while ( ~all(bProcFinish) )
        pause(3);
        
        for procID=1:maxWorkers
            errFile = ['.\segmentationData\err_' num2str(procID) '.log'];
            segFile = ['.\segmentationData\objs_' num2str(procID) '.mat'];
            semFile = ['.\segmentationData\done_' num2str(procID) '.txt'];
            
            bErrFileExists(procID) = ~isempty(dir(errFile));
            bSegFileExists(procID) = ~isempty(dir(segFile));
            bSemFileExists(procID) = ~isempty(dir(semFile));
        end
        
        bProcFinish = bErrFileExists | (bSegFileExists & bSemFileExists);
    end
    
    if ( ~all(bSegFileExists) )
        errStatus = '';
        tSeg = toc;
        
        % Collect segmentation error logs into one place
        for procID=1:length(bSegFileExists)
            if ( bSegFileExists(procID) )
                continue;
            end
            
            errStatus = sprintf( '----------------------------------\n');
            objerr = fopen(fullfile('.','segmentationData',['err_' num2str(procID) '.log']));
            logline = fgetl(objerr);
            while ( ischar(logline) )
                errStatus = [errStatus sprintf('%s\n', logline)];
                logline = fgetl(objerr);
            end
            fclose(objerr);
        end
        
        return;
    end

    try
        cellSegments = [];
        for procID=1:maxWorkers
            segFile = ['.\segmentationData\objs_' num2str(procID) '.mat'];
            
            tstLoad = whos('-file', segFile);
            
            load(segFile);
            
            cellSegments = [cellSegments hulls];
        end
    catch excp
        
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Problem loading segmentation\n',cltime(4),cltime(5),cltime(6));
        errStatus = [errStatus Error.PrintException(excp)];
        tSeg = toc;
        return;
    end
    
    if ( isempty(cellSegments) )
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - No segmentations found\n',cltime(4),cltime(5),cltime(6));
        tSeg = toc;
        return;
    end

    % Sort segmentations and fluorescent data so that they are time ordered
    segtimes = [cellSegments.time];
    [~,srtIdx] = sort(segtimes);
    CellHulls = Helper.MakeInitStruct(Helper.GetCellHullTemplate(), cellSegments(srtIdx));
    
    %% Build hashed cell list
    HashedCells = cell(1,Metadata.GetNumberOfFrames());
    for t=1:Metadata.GetNumberOfFrames()
        HashedCells{t} = struct('hullID',{}, 'trackID',{});
    end
    
    for i=1:length(CellHulls)
        HashedCells{CellHulls(i).time} = [HashedCells{CellHulls(i).time} struct('hullID',{i}, 'trackID',{0})];
    end
    
    %% Create connected component distances for tracker
    fprintf('Building Connected Component Distances... ');
    ConnectedDist = [];
    Tracker.BuildConnectedDistance(1:length(CellHulls), 0, 1);

    fprintf(1,'\nDone\n');
    tSeg = toc;

    %% Tracking
    tic
    fprintf(1,'Tracking...');
    
    [hullTracks,gConnect] = trackerMex(CellHulls, ConnectedDist, Metadata.GetNumberOfFrames(), CONSTANTS.dMaxCenterOfMass, CONSTANTS.dMaxConnectComponentTracker);
    
    fprintf('Done\n');
    tTrack = toc;

    %% Import into LEVer's data sturcture
    fprintf('Finalizing Data...');
    try
        Tracker.BuildTrackingData(hullTracks, gConnect);
    catch excp
        
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Problem building LEVER structures\n',cltime(4),cltime(5),cltime(6));
        errStatus = [errStatus Error.PrintException(excp)];
        
        return;
    end
    fprintf('Done\n');
    
    errStatus = '';
end

function segCmd = makeSegCommand(procID, numProc, primaryChannel, metadataFile, cellType, segArg)
    segCmd = 'Segmentor';
    segCmd = [segCmd ' "' num2str(procID) '"'];
    segCmd = [segCmd ' "' num2str(numProc) '"'];
    segCmd = [segCmd ' "' num2str(primaryChannel) '"'];
    segCmd = [segCmd ' "' metadataFile '"'];
    segCmd = [segCmd ' "' cellType '"'];
    
    for i=1:length(segArg)
        segCmd = [segCmd ' "' num2str(segArg{i}) '"'];
    end
end

function removeOldFiles(rootDir, filePattern)
    flist = dir(fullfile(rootDir,filePattern));
    for i=1:length(flist)
        if ( flist(i).isdir )
            continue;
        end
        
        delete(fullfile(rootDir,flist(i).name));
    end
end
