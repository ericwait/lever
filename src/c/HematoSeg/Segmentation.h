#ifndef SEGMENTATION_H
#define SEGMENTATION_H

#include <string>

#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
#include "itkImage.h"
#include "itkImageRegionConstIterator.h"
#include "itkImageRegionIterator.h"
#include "itkOtsuThresholdImageFilter.h"
#include "itkScalarImageToHistogramGenerator.h"
#include "itkOtsuThresholdCalculator.h"
#include "itkBinaryThresholdImageFilter.h"
#include "itkBinaryBallStructuringElement.h"
#include "itkBinaryErodeImageFilter.h"
#include "itkBinaryDilateImageFilter.h"
#include "itkBinaryFillholeImageFilter.h"
#include "itkGrayscaleDilateImageFilter.h"
#include "itkGrayscaleErodeImageFilter.h"
#include "itkSubtractImageFilter.h"
#include "itkBinaryNotImageFilter.h"
#include "itkAndImageFilter.h"
#include "itkConnectedComponentImageFilter.h"
#include "itkLabelGeometryImageFilter.h"

//qhull includes
extern "C"{
#define qh_QHimport
#include "qhull_a.h"
};

#define DIMENSIONS (2)

struct segData {
	std::string imageFile;
	std::string outFile;
	std::string semFile;
	float imageAlpha;
	int minSize;
	float eccentricity;
};

typedef unsigned char CharPixelType;
typedef unsigned short ShortPixelType;
typedef unsigned int UintPixelType;

typedef itk::Image<CharPixelType, DIMENSIONS> CharImageType;
typedef itk::Image<ShortPixelType, DIMENSIONS> ShortImageType;
typedef itk::Image<UintPixelType, DIMENSIONS> UintImageType;

typedef itk::ImageFileReader<ShortImageType> ShortImageFileReaderType;
typedef itk::ImageFileReader<CharImageType> CharImageFileReaderType;
typedef itk::ImageFileWriter<ShortImageType> ShortImageFileWriterType;
typedef itk::ImageFileWriter<CharImageType> CharImageFileWriterType;

typedef itk::ImageRegionConstIterator<CharImageType> ConstIteratorType;
typedef itk::ImageRegionIterator<CharImageType> IteratorType;
typedef itk::Statistics::ScalarImageToHistogramGenerator<CharImageType> ScalarImageToHistogramGeneratorType;
typedef itk::OtsuThresholdCalculator<ScalarImageToHistogramGeneratorType::HistogramType> OtsuThresholdCalculatorType;
typedef itk::BinaryThresholdImageFilter<CharImageType, CharImageType> ThresholdFilterType;
typedef itk::BinaryBallStructuringElement<CharPixelType,DIMENSIONS> StructuringElementType;
typedef itk::BinaryErodeImageFilter<CharImageType,CharImageType,StructuringElementType > ErodeFilterType;
typedef itk::BinaryDilateImageFilter<CharImageType,CharImageType,StructuringElementType > DilateFilterType;
typedef itk::BinaryFillholeImageFilter<CharImageType> BinaryFillholeImageFilterType;
typedef itk::GrayscaleDilateImageFilter<CharImageType,CharImageType,StructuringElementType > GrayscaleDilateFilterType;
typedef itk::GrayscaleErodeImageFilter<CharImageType,CharImageType,StructuringElementType > GrayscaleErodeFilterType;
typedef itk::SubtractImageFilter<CharImageType,CharImageType,CharImageType> SubtractImageFilterType;
typedef itk::BinaryNotImageFilter<CharImageType> BinaryNotImageFilterType;
typedef itk::AndImageFilter<CharImageType, CharImageType, CharImageType> AndImageFilterType;
typedef itk::ConnectedComponentImageFilter<CharImageType,ShortImageType> ConnectedComponentFilterType;
typedef itk::LabelGeometryImageFilter<ShortImageType,ShortImageType> LabelGeometryImageFilterType;

struct coordinate{
	float x;
	float y;
};

struct Hull 
{
	float centerOfMass[DIMENSIONS];
	std::vector<CharImageType::IndexType> pixels;
};

DWORD WINAPI segmentation(LPVOID lpParam);

#endif