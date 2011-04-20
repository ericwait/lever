#include "tracker.h"

int GetGlobalIdx(int t, int idx)
{
	return rgDetectLengthSum[t] + idx;
}

int GetLocalIdx(int globalIdx)
{
	int t;
	for ( t=1; t < gNumFrames; ++t )
	{
		if ( globalIdx < rgDetectLengthSum[t] )
		{
			break;
		}
	}

	return (globalIdx - rgDetectLengthSum[t-1]);
}

int BuildHistoryPath(CSourcePath* historyPath, CSourcePath* path, int occlLookback)
{
	int pathStartGIdx = GetGlobalIdx(path->frame[0], path->index[0]);

	// Find the assigned in-edge
	int histTrackID = -1;
	int histIdx = gAssignedConnectIn[pathStartGIdx];
	if ( histIdx >=0 )
	{
		CSourcePath* histpath = gConnectIn[pathStartGIdx][histIdx];
		// Single segment agreement requirement
		//if ( histpath->frame.size() > 2+occlLookback && (histpath->frame[2+occlLookback] == path->frame[1]) && (histpath->index[2+occlLookback] == path->index[1]) )
		if ( histpath->frame.size() > 2	)
			histTrackID = histpath->trackletID;
	}

	if ( histTrackID >= 0 )
	{
		tPathList::iterator histIter = gAssignedTracklets[histTrackID].begin();
		while ( histIter != gAssignedTracklets[histTrackID].end() )
		{
			CSourcePath* curPath = *histIter;

			historyPath->PushPoint(curPath->frame[0], curPath->index[0]);
			++histIter;
		}
	}

	for ( int i=0; i < path->frame.size(); ++i )
		historyPath->PushPoint(path->frame[i], path->index[i]);

	return histTrackID;
}

int DepthFirstBestPathSearch(CSourcePath path, int bestGIdx, int t, int tEnd, int occlLookback)
{
	bool bFinishedSearch = true;
	if ( t < tEnd )
	{
		int nextDetections = rgDetectLengths[t];
		for ( int nextPt=0; nextPt < nextDetections; ++nextPt )
		{
			path.PushPoint(t, nextPt);
			double chkCost = GetCost(path.frame, path.index, 0,1);
			path.PopPoint();

			if ( chkCost == dbltype::infinity() )
				continue;

			bFinishedSearch = false;

			path.PushPoint(t, nextPt);
			bestGIdx = DepthFirstBestPathSearch(path, bestGIdx, t+1, tEnd, occlLookback);
			path.PopPoint();
		}
	}

	if ( bFinishedSearch && (path.frame.size() > 1) )
	{
		CSourcePath historyPath;

		int startGIdx = GetGlobalIdx(path.frame[0], path.index[0]);
		int nextGIdx = GetGlobalIdx(path.frame[1], path.index[1]);

		int historyTrackID = BuildHistoryPath(&historyPath, &path, occlLookback);
		int srcPathIdx = historyPath.frame.size() - path.frame.size();

		double newPathCost = GetCost(historyPath.frame, historyPath.index, srcPathIdx,0);
		if ( newPathCost == dbltype::infinity() )
			return bestGIdx;

		path.trackletID = historyTrackID;
		path.cost = newPathCost;

		if ( gConnectOut[startGIdx].count(nextGIdx) == 0 )
		{
			CSourcePath* newPath = new CSourcePath(path);
			gConnectOut[startGIdx].insert(std::pair<int,CSourcePath*>(nextGIdx, newPath));
			gConnectIn[nextGIdx].insert(std::pair<int,CSourcePath*>(startGIdx, newPath));
		}
		else if ( newPathCost < gConnectOut[startGIdx][nextGIdx]->cost )
		{
			*(gConnectOut[startGIdx][nextGIdx]) = path;
		}

		if ( bestGIdx < 0 || newPathCost < gConnectOut[startGIdx][bestGIdx]->cost )
		{
			bestGIdx = nextGIdx;
		}
	}

	return bestGIdx;
}

void BuildBestPaths(std::vector<CSourcePath*>* inEdges, CSourcePath** outEdges, int t, int occlLookback)
{
	if ( t-occlLookback < 0 )
		return;

	int numDetections = rgDetectLengths[t-occlLookback];

	int tEnd = std::min<int>(t+gWindowSize, gNumFrames);

	for ( int srcIdx=0; srcIdx < numDetections; ++srcIdx )
	{
		int startGIdx = GetGlobalIdx(t-occlLookback, srcIdx); 
		if ( occlLookback > 0 && gAssignedConnectOut[startGIdx] > 0 )
			continue;

		CSourcePath srcPath;
		srcPath.PushPoint(t-occlLookback, srcIdx);
		int bestGIdx = DepthFirstBestPathSearch(srcPath, -1, t+1, tEnd, occlLookback);
		if ( bestGIdx >= 0 )
		{
			int locIdx = GetLocalIdx(bestGIdx);
			inEdges[locIdx].push_back(gConnectOut[startGIdx][bestGIdx]);
		}
	}
}