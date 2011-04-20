#include "tracker.h"

	
int gnumPts;

int ReadSegmentationData(char* filename, int* numTotalPts, SDetection*** rgDetect, int** detectLengths, int** detectLengthSum)
{
	int numFrames;
	int numPts;

	int* lengthPtr;
	int* lengthSumPtr;
	SDetection* dataPtr;
	SDetection** arrayIdxPtr;
	int nDCH;
	double dDCH;
	FILE* fp;

	fp = fopen(filename, "r");
	if ( !fp )
		return -1;

	fscanf(fp, "%d %d\n\n", &numFrames, &numPts);

	dataPtr = new SDetection[numPts];
	arrayIdxPtr = new SDetection*[numFrames];
	lengthPtr = new int[numFrames];
	lengthSumPtr = new int[numFrames];

	int frameOffset = 0;
	for ( int t=0; t < numFrames; ++t )
	{
		int frameDetections;
		fscanf(fp, "%d\n", &frameDetections);

		lengthPtr[t] = frameDetections;
		if ( t > 0 )
			lengthSumPtr[t] = lengthSumPtr[t-1] + lengthPtr[t-1];
		else
			lengthSumPtr[t] = 0;

		arrayIdxPtr[t] = dataPtr + frameOffset;

		for ( int ptItr = 0; ptItr < frameDetections; ++ptItr )
		{
			SDetection* curPt = &arrayIdxPtr[t][ptItr];
			fscanf(fp, "%d %d %d %d:", &(curPt->X), &(curPt->Y),&(curPt->nPixels),&(curPt->nConnectedHulls));

			for ( int pixItr = 0; pixItr < curPt->nConnectedHulls; ++pixItr )
			{
				fscanf(fp, " %d,%lf", &(nDCH),&(dDCH));
				nDCH--; //Make 0 offset
				curPt->DarkConnectedHulls.push_back(nDCH);
				curPt->DarkConnectedCost.push_back(dDCH);
			}

			fscanf(fp,"\n");
		}

		frameOffset += frameDetections;
	}

	fclose(fp);

	(*numTotalPts) = numPts;
	(*rgDetect) = arrayIdxPtr;
	(*detectLengths) = lengthPtr;
	(*detectLengthSum) = lengthSumPtr;

	return numFrames;
}


void DeleteDetections()
{
	delete[] rgDetect[0];
	delete[] rgDetect;

	delete[] rgDetectLengths;
	delete[] rgDetectLengthSum;
}

int ReadDetectionData(int argc, char* argv[])
{

	int checkResult;

	checkResult = ReadSegmentationData(argv[1], &gnumPts, &rgDetect, &rgDetectLengths, &rgDetectLengthSum);
	if ( checkResult < 0 )
		return -1;

	gNumFrames = checkResult;

	gMaxDetections = 0;
	for ( int t=0; t < gNumFrames; ++t )
		gMaxDetections = std::max<int>(gMaxDetections, rgDetectLengths[t]);



	gConnectOut = new std::map<int,CSourcePath*>[gnumPts];
	gConnectIn = new std::map<int,CSourcePath*>[gnumPts];
	gAssignedConnectIn = new int[gnumPts];
	gAssignedConnectOut = new int[gnumPts];
	gAssignedTrackID = new int[gnumPts];
	for ( int i=0; i < gnumPts; ++i )
	{
		gAssignedConnectIn[i] = -1;
		gAssignedConnectOut[i] = -1;
		gAssignedTrackID[i] = -1;
	}

	return 3;
}