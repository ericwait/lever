% SegAndTrack.m - Spawns segmentation and tracking routines to identify and
% track cells in a sequence of microscope images.

% ChangeLog
% EW - rewrite
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

function errStatus = SegAndTrack()
    global CONSTANTS

    % Modified 
    errStatus = 1;
    
    if (exist('LEVerSettings.mat','file')~=0)
            load('LEVerSettings.mat');
    else
        settings.matFilePath = '.\';
    end

    [settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
        [CONSTANTS.datasetName '_LEVer.mat']);

    if(~FilterIndex)
        return;
    end

    % 
    save('LEVerSettings.mat','settings');
    Load.AddConstant('matFullFile',[settings.matFilePath settings.matFile],1);
    
    numProcessors = getenv('Number_of_processors');
    numProcessors = str2double(numProcessors);
    if(isempty(numProcessors) || isnan(numProcessors) || numProcessors < 4)
        numProcessors = 4;
    end
    
    % TODO: Rewrite for more extensible segmentation/tracking interface:
    % Check for <celltype>Seg.exe, if it exists it is assumed to be a
    % full-movie segmentation which handles threading internally
    % (see e.g. HematoSeg.exe)
    
    errStatus = '';
    switch CONSTANTS.cellType
        case 'Hemato'
            tic;
            Segmentation.HematoSegmentation();
            tSeg = toc;
            tic;
            Tracker.HematoTracker();
            tTrack = toc;
            errStatus = 0;
            
        case 'Adult'
            [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(...
                CONSTANTS.rootImageFolder(1:end-1), CONSTANTS.datasetName,...
                CONSTANTS.imageAlpha, CONSTANTS.imageSignificantDigits, numProcessors);
            
        case 'Embryonic'
            [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(...
                CONSTANTS.rootImageFolder(1:end-1), CONSTANTS.datasetName,...
                CONSTANTS.imageAlpha, CONSTANTS.imageSignificantDigits, numProcessors);
            
        case 'Wehi'
            [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(...
                CONSTANTS.rootImageFolder(1:end-1), CONSTANTS.datasetName,...
                CONSTANTS.imageAlpha, CONSTANTS.imageSignificantDigits, numProcessors);
            
        otherwise
            errStatus = '';
            return
    end
    
    
    
    if ( ~isempty(errStatus) )
        errFilename = [CONSTANTS.datasetName '_segtrack_err.log'];
        fid = fopen(errFilename, 'wt');
        fprintf(fid, '%s', errStatus);
        fclose(fid);
        
        return
    end
    
    UI.InitializeFigures();
    
    UI.SaveData(1);
    
    % Adds the special origin action, to indicate that this is initial
    % segmentation data from which edit actions are built.
    Editor.ReplayableEditAction(@Editor.OriginAction, 1);
    
    Error.LogAction('Segmentation time - Tracking time',tSeg,tTrack);
end
