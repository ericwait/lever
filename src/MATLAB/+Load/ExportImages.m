
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

function jsonPath = ExportImages(exportDir, inRoot,inFilename)
    [~,imD] = MicroscopeData.Original.ConvertData(inRoot,inFilename, exportDir, false, true, false);
    if ( length(imD) > 1 )
        [~,imName] = fileparts(inFilename);
        exportDir = fullfile(exportDir,imName);
    end
    
    [~,chkIdx] = max(cellfun(@(x)((x.NumberOfFrames)),imD));
    jsonPath = fullfile(exportDir,imD{chkIdx}.DatasetName,[imD{chkIdx}.DatasetName '.json']);
end
