% Segmentor.m - Cell image segmentation algorithm.
% Segmentor is to be run as a seperate compiled function for parallel
% processing.  It will process tLength-tStart amount of images.  Call this
% function for the number of processors on the machine.

% mcc -o Segmentor -m Segmentor.m

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

function [objs features levels] = Segmentor(varargin)

objs=[];
features = [];
levels = struct('haloLevel',{}, 'igLevel',{});

supportedCellTypes = Load.GetSupportedCellTypes();
[procArgs segArgs] = setSegArgs(supportedCellTypes, varargin);
if ( isempty(procArgs) )
    return;
end

% Use the supported type structure to find segmentation routine
typeIdx = findSupportedTypeIdx(procArgs.cellType, supportedCellTypes);
funcName = char(supportedCellTypes(typeIdx).segRoutine.func);
funcPath = which(funcName);

if ( ~isempty(funcPath) )
    segFunc = supportedCellTypes(typeIdx).segRoutine.func;
else
    fprintf(['WARNING: Could not find ' funcName '() using default Segmentation.FrameSegmentor() routine\n']);
    segFunc = @Segmentation.FrameSegmentor;
end

segParams = struct2cell(segArgs);

try 
    fprintf(1,'%s\n',argStruct.imagePolder);
    fprintf(1,'%s\n',argStruct.imagePattern);
    
    Load.AddConstant('rootImageFolder', procArgs.imagePolder, 1);
    Load.AddConstant('imageNamePattern', procArgs.imagePattern, 1);
    
    tStart = procArgs.procID;
    tEnd = procArgs.numFrames;
    tStep = procArgs.numProcesses;
    
    numImages = floor(tEnd/tStep);

    for t = tStart:tStep:tEnd
        imFilename = Helper.GetFullImagePath(t);
        if ( ~exist(imFilename,'file') )
            continue;
        end

        fprintf('%d%%...', round(100 * floor(t/tStep) / numImages));

        im = Helper.LoadIntensityImage(imFilename);

        objs = [objs frmObjs];
        features = [features frmFeatures];
        levels = [levels frmLevels];
        [frmObjs frmFeatures frmLevels] = segFunc(im, t, segParams{:});
    end
    
catch excp
    cltime = clock();
    errFilename = ['.\segmentationData\err_' num2str(procArgs.procID) '.log'];
    fid = fopen(errFilename, 'w');
    if ( ~exist('t', 'var') )
        fprintf(fid, '%02d:%02d:%02.1f - Error in segmentor\n',cltime(4),cltime(5),cltime(6));
    else
        fprintf(fid, '%02d:%02d:%02.1f - Error in segmenting frame %d \n',cltime(4),cltime(5),cltime(6), t);
    end
    excpMessage = Error.PrintException(excp);
    fprintf(fid, '%s', excpMessage);
    fclose(fid);
    return;
end

fileName = ['.\segmentationData\objs_' num2str(tStart) '.mat'];
save(fileName,'objs','features','levels');

fSempahore = fopen(['.\segmentationData\done_' num2str(tStart) '.txt'], 'w');
fclose(fSempahore);

fprintf('\tDone\n');
end

function [procArgs segArgs] = setSegArgs(supportedCellTypes, argCell)
    procArgs = struct('procID',{1}, 'numProcesses',{1}, 'numFrames',{0}, 'cellType',{''}, 'imagePath',{''}, 'imagePattern',{''});
    
    procArgFields = fieldnames(procArgs);
    procArgTypes = structfun(@(x)(class(x)), procArgs, 'UniformOutput',0);
    
    segArgs = [];
    
    procID = 1;
    if ( ~isempty(argCell) )
       procID = convertArg(argCell{1}, procArgTypes{1});
    end
    errFilename = ['.\segmentationData\err_' num2str(procArgs.procID) '.log'];
    
    if ( length(argCell) < length(procArgFields) )
        cltime = clock();
        
        fid = fopen(errFilename, 'w');
        fprintf(fid, '%02d:%02d:%02.1f - Problem segmenting frame \n',cltime(4),cltime(5),cltime(6));
        fprintf(fid, '  Too few input arguments expected at least %d: %d missing\n', length(argFields), (length(argFields) - length(argCell)));
        
        printArgs(fid, argCell, procArgFields);

        fclose(fid);
        
        procArgs = [];
        return;
    end
    
    procArgs = makeArgStruct(argCell, procArgFields, procArgTypes);
    
    % Use cell type to figure out what segmentation parameters are
    % available, and what algorithm to use.
    typeIdx = findSupportedTypeIdx(procArgs.cellType, supportedCellTypes);
    
    segArgCell = argCell(length(procArgFields)+1:end);
    segArgFields = {SupportedTypes(typeIdx).segRoutine.params.name};
    segArgTypes = cell(1,length(cellParamFields));
    [segArgTypes{:}] = deal('double');
    
    if ( (length(segArgCell)) ~= length(segArgFields) )
        cltime = clock();
        
        fid = fopen(errFilename, 'w');
        fprintf(fid, '%02d:%02d:%02.1f - Problem segmenting frame \n',cltime(4),cltime(5),cltime(6));
        if ( length(argCell) > length(argFields) )
            fprintf(fid, '  Too many input arguments expected %d: %d extra\n', length(argFields), (length(argCell)-length(argFields)));
        else
            fprintf(fid, '  Too few input arguments expected %d: %d missing\n', length(argFields), (length(argFields) - length(argCell)));
        end
        
        printArgs(fid, argCell, [procArgFields segArgFields]);

        fclose(fid);
        
        procArgs = [];
        return;
    end
    
    segArgs = makeArgStruct(segArgCell, segArgFields, segArgTypes);
end

function typeIdx = findSupportedTypeIdx(cellType, supportedTypes)
    typeIdx = find(strcmpi(cellType, {supportedTypes.name}),1,'first');
    
    % Try default cell type if we don't have current type in supported list.
    if ( isempty(typeIdx) )
        fprintf(['WARNING: Unsupported cell type: ' cellType ' using default "Embryonic" cell type instead\n']);
        
        cellType = 'Embryonic';
        typeIdx = find(strcmpi(cellType, {supportedTypes.name}),1,'first');
    end
end

function argStruct = makeArgStruct(argCell, argFields, argTypes)
    argStruct = struct();
    for i=1:length(argFields);
        argStruct.(argFields{i}) = convertArg(argCell{i}, argTypes{i});
    end
end

function outArg = convertArg(inArg, toType)
    if ( strcmpi(toType,'char') )
        outArg = num2str(inArg);
    elseif ( ischar(inArg) )
        outArg = cast(str2double(inArg), toType);
    else
        outArg = cast(inArg, toType);
    end
end

function printArgs(fid, argCell, argFields)
    for i=1:length(argFields)
        curArg = '[]';
        if ( i <= length(argCell) )
            curArg = num2str(argCell{i});
        end
        
        fprintf(fid, '    %d: %s = %s\n', i, argFields{i}, curArg);
    end
    
    for i=(length(argFields)+1):length(argCell)
        curArg = num2str(argCell{i});
        fprintf(fid, '    %d: [] = %s\n', i, curArg);
    end
end

