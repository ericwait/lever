
function hObj = GetHandle(axHandle, poolName)
    curPools = get(axHandle,'UserData');
    
    if ( isempty(curPools) )
        error('Uninitialized resource pool for this axis handle');
    end
    
    poolIdx = find(strcmpi(poolName, curPools.pools(:,1)));
    if ( isempty(poolIdx) )
        error('No matching resource pool found');
    end
    
    curUsed = curPools.pools{poolIdx,3}(1);
    maxUsed = curPools.pools{poolIdx,3}(2);
    
    if ( curUsed + 1 > length(curPools.pools{poolIdx,2}) )
        curPools.pools{poolIdx,2} = [curPools.pools{poolIdx,2} copyobj(curPools.pools{poolIdx,2}(1),axHandle)];
    end
    
    hObj =  curPools.pools{poolIdx,2}(curUsed+1);

    curPools.pools{poolIdx,3}(1) = curUsed + 1;
    if ( curUsed + 1 > maxUsed )
%         set(hObj, 'Visible','on');
        curPools.pools{poolIdx,3}(2) = curUsed + 1;
    end
    
    set(axHandle, 'UserData',curPools);
end
