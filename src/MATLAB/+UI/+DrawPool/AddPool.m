% AddPool(axHandle, poolName, hObj, size)
% 
% Attach a draw pool to the specified axis handle

function AddPool(axHandle, poolName, hObj, size)
    curPools = get(axHandle, 'UserData');
    
    if ( ~isempty(curPools) )
        if ( ~isstruct(curPools) )
            error('Malformed resource pool for this axis handle');
        end
        
        bChkName = strcmpi(poolName, curPools(:,1));
        if ( nnz(bChkName) > 0 )
            error('Specified name is already in the resource pool');
        end
    else
        curPools = struct('pools',{{}}, 'renderOrder',{[]});
    end
    
    newHandles = [];
    for i=1:size
        newHandles(i) = copyobj(hObj, axHandle);
        set(newHandles(i), 'Visible','off', 'HandleVisibility','off');
    end
    
    curPools.pools = [curPools.pools; {poolName} {newHandles} {[0 0]}];
    
    set(axHandle, 'UserData',curPools);
end
