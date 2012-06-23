% historyAction = ContextSwapLabels(trackA, trackB, time)
% Edit Action:
% 
% Swap tracking for tracks A and B beginning at specified time.

function historyAction = ContextSwapLabels(trackA, trackB, time)
    
    Tracker.GraphEditSetEdge(trackA, trackB, time);
    Tracker.GraphEditSetEdge(trackB, trackA, time);
    
    Tracks.SwapLabels(trackA, trackB, time);
    
    Families.ProcessNewborns();
    
    historyAction = 'Push';
end
