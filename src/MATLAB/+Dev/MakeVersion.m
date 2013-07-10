

function verInfo = MakeVersion(bTransientUpdate)

    funcString = {
        '%% versionInfo = VersionInfo()'
        '%% Return the version info structure'
        '%%'
        '%% Note: This file is autogenerated by build script DO NOT MODIFY!!'
        ''
        'function versionInfo = VersionInfo()'
        '	versionInfo = struct(...'
        '       ''majorVersion'',{%d},...'
        '       ''minorVersion'',{%d},...'
        '       ''branchName'',{''%s''},...'
        '       ''buildNumber'',{''%s''},...'
        '       ''buildMachine'',{''%s''});'
        '	end'};
    
    if ( ~exist('bTransientUpdate', 'var') )
        bTransientUpdate = 0;
    end
    
    verInfo = struct(...
                'majorVersion',{0},...
                'minorVersion',{0},...
                'branchName',{'UNKNOWN'},...
                'buildNumber',{'UNKNOWN'},...
                'buildMachine',{'UNKNOWN'});
	
	
	fallbackFile = 'version.txt';
	
	bFoundGit = Dev.SetupGit();
    if ( ~bFoundGit )
        fprintf('WARNING: Could not find git directory, falling back to %s\n', fallbackFile);
    end
    
    [verTag branchName] = gitVersionAndBranch(bFoundGit, fallbackFile);
    
    % Get version info from git tag
    if ( ~isempty(verTag) )
        verTag = strtrim(verTag);
        numTok = regexp(verTag, '[Vv]([0-9]+)[.]([0-9]+).*', 'tokens', 'once');
        if ( length(numTok) >= 2 )
            verInfo.majorVersion = str2double(numTok{1});
            verInfo.minorVersion = str2double(numTok{2});
            
            verInfo.minorVersion = verInfo.minorVersion + 1;
        end
    end
    
    % Try to get a branch name
    [status,branchName] = system('git rev-parse --abbrev-ref HEAD');
    if ( ~isempty(branchName) )
        verInfo.branchName = strtrim(branchName);
    end
    
    % Get a timestamp build-number
    c = clock();
    verInfo.buildNumber = sprintf('%d.%02d.%02d.%02d', c(1), c(2), c(3), c(4));
    
    % Get machine ID
    [status,buildMachine] = system('hostname');
    if ( status ~= 0 )
        fprintf('WARNING: There was an error retrieving hostname:\n %s\n', buildMachine);
    else
        verInfo.buildMachine = strtrim(buildMachine);
    end
    
    if ( ~bTransientUpdate )
        if ( ~bFoundGit )
            error('Unable to use git to build version string for build.');
        end
        
        % Concatenate the template function lines into one giant string
        templateString = [];
        for i=1:length(funcString)
            templateString = [templateString funcString{i} '\n'];
        end

        % Now insert all our arguments into the template and write to a file.
        fid = fopen('+Helper\VersionInfo.m', 'wt');
        if ( fid <= 0 )
            error('Unable to open +Helper\VersionInfo.m for writing');
        end

        fprintf(fid, templateString, verInfo.majorVersion, verInfo.minorVersion, verInfo.branchName, verInfo.buildNumber, verInfo.buildMachine);

        fclose(fid);
        
        % Update fallback file if we used git to retrieve version info.
        fid = fopen(fallbackFile, 'wt');
        if ( fid < 0 )
            return;
        end

        fprintf(fid, '%s\n', verTag);
        fprintf(fid, '%s\n', branchName);

        fclose(fid);
    end
end

function [verTag branchName] = gitVersionAndBranch(bUseGit, fallbackFile)
    verTag = '';
    branchName = '';
    
    if ( bUseGit )
        [verStatus,verTag] = system('git describe --tags --match v[0-9]*.[0-9]* --abbrev=0');
        [branchStatus,branchName] = system('git rev-parse --abbrev-ref HEAD');
        
        if ( verStatus ~= 0 )
            fprintf('WARNING: There was an error retrieving tag from git:\n %s\n', verTag);
            verTag = '';
        end
        
        if ( branchStatus ~= 0 )
            fprintf('WARNING: There was an error retrieving branch name from git:\n %s\n', branchName);
            branchName = '';
        end
        
        return;
    end
    
    if ( ~exist(fallbackFile, 'file') )
        fprintf('ERROR: There is no fallback version.txt file!\n');
        return;
    end
    
    fid = fopen(fallbackFile, 'rt');
    
    if ( fid < 0 )
        return;
    end
    
    verTag = fgetl(fid);
    branchName = fgetl(fid);
    
    fclose(fid);
end
