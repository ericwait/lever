% historyAction = ResegFinishAction()
% Edit Action:
% 
% Finish resegmentation action, (push history)

function [historyAction finishTime finalResegState] = ResegFinishAction()
    global ResegState bResegPaused
    
    resegEdits = ResegState.SegEdits;
    finalResegState = ResegState;
    
    finishTime = ResegState.currentTime;
    
    finalTree = ResegState.primaryTree;
    
    bResegPaused = [];
    ResegState = [];
    
    disp(['Finished Resegmentation: ' num2str(size(resegEdits,1)) ' automatic edits']);
    
    UI.DrawTree(finalTree);
    
    historyAction = '';
end
