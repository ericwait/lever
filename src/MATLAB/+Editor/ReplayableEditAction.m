% [bErr varargout] = ReplayableEditAction(actPtr, varargin)
% 
% ReplayableEditAction attempts to execute the edit function pointed to by actPtr
% with the rest of the arguments to the function passed on unmodified. If
% an exception is caught during execution of the function an error is logged
% and the edit is undone.
%
% NOTE: All action function passed in actPtr are expected to return at
% least one argument, historyAction, which upon successful completion of
% the action, determines the appropriate history response (generally
% pushing to the history stack). See ChangeLabelAction for an example of
% this.
% 
% Regardless of success, the action and all arguments are added to the end
% of the replay list.

function [bErr varargout] = ReplayableEditAction(actPtr, varargin)
    global ReplayEditActions
    
    if ( nargout(actPtr) < 1 )
        error('All valid replayable actions must return at least a historyAction argument');
    end
    
    actCtx = getEditContext();
    
    startRandState = Helper.GetRandomState();
    
    newAct = struct('funcName',{func2str(actPtr)}, 'funcPtr',{actPtr}, 'args',{varargin}, 'ret',{{}}, ...
                    'histAct',{''}, 'bErr',{0}, 'randState',{[]}, 'ctx',{actCtx}, 'chkHash',{{}});
	
    if ( isempty(ReplayEditActions) )
        ReplayEditActions = newAct;
    else
        ReplayEditActions = [ReplayEditActions; Helper.MakeInitStruct(ReplayEditActions,newAct)];
    end
    
    % This is silly, but basically lets us push the error message down to
    % the function that actually has fewer outputs than requested.
    numArgs = max(nargout, nargout(actPtr));
    
    varargout = cell(1,max(0,numArgs-1));
    [bErr historyAction varargout{:}] = Editor.SafeExecuteAction(actPtr, varargin{:});
    
    ReplayEditActions(end).bErr = bErr;
    if ( ~bErr )
        % Only bother to save random state if it's changed (rand was used)
        endRandState = Helper.GetRandomState();
        if ( ~isequal(endRandState, startRandState) )
            ReplayEditActions(end).randState = startRandState;
        end
        
        ReplayEditActions(end).ret = varargout;
        if ( ~isempty(historyAction) )
            % Allow history action/arg pairs if necessary
            if ( isstruct(historyAction) )
                Editor.History(historyAction.action, historyAction.arg);
            else
                Editor.History(historyAction);
            end
            
            ReplayEditActions(end).histAct = historyAction;
        end
%         ReplayEditActions(end).chkHash = Dev.GetCoreHashList();
    else
        % Always save on errors, just in case
        ReplayEditActions(end).randState = startRandState;
    end
end

function context = getEditContext()
    global Figures
    
    context = [];
    if ( isempty(Figures) )
        return;
    end
    
    curAx = get(Figures.cells.handle, 'CurrentAxes');
    cellLims = [xlim(curAx);ylim(curAx)];
    curAx = get(Figures.tree.handle, 'CurrentAxes');
    treeLims = [xlim(curAx);ylim(curAx)];
    
    context = struct('time',{Figures.time}, 'family',{Figures.tree.familyID}, 'treeLims',{treeLims}, 'cellLims',{cellLims});
end
