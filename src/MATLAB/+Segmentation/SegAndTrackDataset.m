function [errStatus tSeg tTrack] = SegAndTrackDataset(rootFolder, datasetName, namePattern, numProcessors, segArgs)
    global CONSTANTS CellHulls HashedCells ConnectedDist
    
    errStatus = sprintf('Unknown Error\n');
    tSeg = 0;
    tTrack = 0;

    %% Segmentation
    tic
    
    % Remove trailing \ or / from rootFolder
    if ( (rootFolder(end) == '\') || (rootFolder(end) == '/') )
        rootFolder = rootFolder(1:end-1);
    end
    
    % Set CONSTANTS.imageSize as soon as possible
    [numChannels numFrames] = Helper.GetImListInfo(CONSTANTS.rootImageFolder, CONSTANTS.imageNamePattern);
    Load.AddConstant('numFrames', numFrames,1);
    Load.AddConstant('numChannels', numChannels,1);
    
    numProcessors = min(numProcessors, numFrames);
    numProcessors = min(numProcessors, 4);
    
    if ( numFrames < 1 )
        return;
    end

    fprintf('Segmenting (using %s processors)...\n',num2str(numProcessors));

    if(~isempty(dir('.\segmentationData')))        
        removeOldFiles('segmentationData', 'err_*.log');
        removeOldFiles('segmentationData', 'objs_*.mat');
        removeOldFiles('segmentationData', 'done_*.txt');
    end
    
    imSet = Helper.LoadIntensityImageSet(1);

    imSizes = zeros(length(imSet),2);
    for i=1:length(imSet)
        imSizes(i,:) = size(imSet{i});
    end

    Load.AddConstant('imageSize', max(imSizes,[],1),1);
    
    if ( ndims(CONSTANTS.imageSize) < 2 || ndims(CONSTANTS.imageSize) > 3 )
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Images are empty or have incorrect dimensions [%s]\n',cltime(4),cltime(5),cltime(6), num2str(CONSTANTS.imageSize));
        
        return;
    end
    
    if ( ~exist('.\segmentationData','dir'))
        mkdir('segmentationData');
    end
    
    if ( isdeployed() )
        for procID=1:numProcessors
            segCmd = makeSegCommand(procID,numProcessors,numChannels,numFrames,CONSTANTS.cellType,rootFolder,namePattern,segArgs);
            system(['start ' segCmd ' && exit']);
        end
    else
%         matlabpool(numProcessors)
%         parfor procID=1:numProcessors
        for procID=1:numProcessors
            Segmentor(procID,numProcessors,numChannels,numFrames,CONSTANTS.cellType,rootFolder,namePattern,segArgs{:});
        end
    end

    bSegFileExists = false(1,numProcessors);
    for procID=1:numProcessors
        errFile = ['.\segmentationData\err_' num2str(procID) '.log'];
        fileName = ['.\segmentationData\objs_' num2str(procID) '.mat'];
        semFile = ['.\segmentationData\done_' num2str(procID) '.txt'];
        semDesc = dir(semFile);
        fileDescriptor = dir(fileName);
        efd = dir(errFile);
        while((isempty(fileDescriptor) || isempty(semDesc)) && isempty(efd))
            pause(3)
            fileDescriptor = dir(fileName);
            efd = dir(errFile);
            semDesc = dir(semFile);
        end
        
        bSegFileExists(procID) = ~isempty(fileDescriptor);
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
        frameOrder = [];
        for procID=1:numProcessors
            fileName = ['.\segmentationData\objs_' num2str(procID) '.mat'];
            
            tstLoad = whos('-file', fileName);
            
            load(fileName);
            
            cellSegments = [cellSegments hulls];
            frameOrder = [frameOrder frameTimes];
        end
    catch excp
        
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Problem loading segmentation\n',cltime(4),cltime(5),cltime(6));
        errStatus = [errStatus Error.PrintException(excp)];
        tSeg = toc;
        return;
    end

    % Sort segmentations and fluorescent data so that they are time ordered
    segtimes = [cellSegments.time];
    [srtSegs srtIdx] = sort(segtimes);
    CellHulls = cellSegments(srtIdx);

    [srtFrames srtIdx] = sort(frameOrder);
    
    fprintf('Building Connected Component Distances... ');
    HashedCells = cell(1,numFrames);
    for t=1:tmax
        HashedCells{t} = struct('hullID',{}, 'trackID',{});
    end
    
    for i=1:length(CellHulls)
        HashedCells{CellHulls(i).time} = [HashedCells{CellHulls(i).time} struct('hullID',{i}, 'trackID',{0})];
    end
    
    ConnectedDist = [];
    Tracker.BuildConnectedDistance(1:length(CellHulls), 0, 1);
    Segmentation.RewriteSegData('segmentationData',datasetName);

    fprintf(1,'\nDone\n');
    tSeg = toc;

    %% Tracking
    tic
    fprintf(1,'Tracking...');
    fnameIn=['.\segmentationData\SegObjs_' datasetName '.txt'];
    fnameOut=['.\segmentationData\Tracked_' datasetName '.txt'];
    
    system(['.\MTC.exe ' num2str(CONSTANTS.dMaxCenterOfMass) ' ' num2str(CONSTANTS.dMaxConnectComponentTracker) ' "' fnameIn '" "' fnameOut '" > out.txt']);
    
    fprintf('Done\n');
    tTrack = toc;

    %% Import into LEVer's data sturcture
    [objTracks gConnect] = Tracker.RereadTrackData('segmentationData', CONSTANTS.datasetName);
    fprintf('Finalizing Data...');
    try
        Tracker.RebuildTrackingData(objTracks, gConnect);
    catch excp
        
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Problem building LEVER structures\n',cltime(4),cltime(5),cltime(6));
        errStatus = [errStatus Error.PrintException(excp)];
        
        return;
    end
    fprintf('Done\n');
    
    errStatus = '';
end

function segCmd = makeSegCommand(procID, numProc, numFrames, cellType, rootFolder, imagePattern, segArg)
    segCmd = 'Segmentor';
    segCmd = [segCmd ' "' num2str(procID) '"'];
    segCmd = [segCmd ' "' num2str(numProc) '"'];
    segCmd = [segCmd ' "' num2str(numFrames) '"'];
    segCmd = [segCmd ' "' cellType '"'];
    segCmd = [segCmd ' "' rootFolder '"'];
    segCmd = [segCmd ' "' imagePattern '"'];
    
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
