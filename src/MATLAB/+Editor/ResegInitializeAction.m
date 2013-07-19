% historyAction = ResegInitializeAction(preserveFamilies)
% Edit Action:
% 
% Initialize resegmentation state

function historyAction = ResegInitializeAction(preserveFamilies, tStart)
    global ResegState bResegPaused Figures
    
    xlims = get(Figures.tree.axesHandle,'XLim');
    hold(Figures.tree.axesHandle,'on');
    plot(Figures.tree.axesHandle, [xlims(1), xlims(2)],[tStart, tStart], '-b');
    hold(Figures.tree.axesHandle,'off');
    
    bResegPaused = 0;
    ResegState = [];
    ResegState.preserveFamilies = preserveFamilies;
    ResegState.primaryTree = preserveFamilies(1);
    ResegState.currentTime = tStart;
    ResegState.SegEdits = {};
    
    historyAction = '';
end