//
//  ARTracker.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 16/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#ifndef __OpenCVAR__ARTracker__
#define __OpenCVAR__ARTracker__

#include "ARMarker.h"
#include "ARConstants.h"
#include "ARUtils.h"
#include "ARTemplate.h"

#define DEBUG_STEPS 8

typedef enum {
    DebugMode_None = 0,
    DebugMode_Greyscale,
    DebugMode_Blur,
    DebugMode_Binarization,
    DebugMode_Contours,    
    DebugMode_PotentialMarkers,
    DebugMode_ProjectedPatterns,
    DebugMode_DetectedMarkers
} DebugMode;

class ARTracker
{
public:
    
    ARTracker(DebugMode debugMode = DebugMode_None, int threshold = BINARY_THRESHOLD, bool blurring = false);
	virtual ~ARTracker();    
    
    void initInstrinsic(cv::Mat& intrinsicsMatrix, cv::Mat& distortionMatrix){
        _intrinsicsMatrix = intrinsicsMatrix.clone();
        _distortionMatrix = distortionMatrix.clone(); 
    }
    
    DebugMode getDebugMode(){
        return _debugMode;
    }
    
    void setDebugMode( DebugMode debugMode ){
        _debugMode = debugMode;
    }
            
    int getThreshold(){
        return _threshold;
    }
    
    void setThreshold(int threshold){
        _threshold = threshold;
    }
    
    bool isBlurring(){
        return _blurring;
    }
    
    void setBlurring(bool blurring){
        _blurring = blurring;
    }
    
    int getMinContourPointsAllowed(){
        return _minContourPointsAllowed;
    }
    
    void setMinContourPointsAllowed(int minContourPointsAllowed){
        _minContourPointsAllowed = minContourPointsAllowed;
    }
    
    float getPolyContourEpsilonRatio(){
        return _polyContourEpsilonRatio;
    }
    
    void setPolyContourEpsilonRatio(float polyContourEpsilonRatio){
        _polyContourEpsilonRatio = polyContourEpsilonRatio;
    }
    
    float getMinSqArea(){
        return _minSqArea;
    }
    
    void setMinSqArea(float minSqArea){
        _minSqArea = minSqArea;
    }
    
    float getMaxSqArea(){
        return _maxSqArea;
    }
    
    void setMaxSqArea(float maxSqArea){
        _maxSqArea = maxSqArea;
    }
    
    cv::Size getPerspectiveTransformSize(){
        return _perspectiveTransformSize;
    }
    
    void setPerspectiveTransformSize(cv::Size perspectiveTransformSize){
        _perspectiveTransformSize = perspectiveTransformSize;
        initPerspectiveTransformTarget(); 
    }
    
    cv::Mat& getWorkInProgressImage(){
        return _wipMat;
    }
    
    /*
     process the frame;
     step 1 - convert to grey scale (convert image from BRGA to Greyscale - from 4 bytes to 1 byte - simplifiers processing i.e. less bytes to process)
     step 2 - (optional) blurr the image to remove noise
     step 3 - threshold image (binarized image)
     step 4 - find the contours
     step 5 - poly contours (simplified contours using Douglas-Peucker algorithm) & filter based on min area 
     step 6 - 
     step 7 - ...
     
     
     pose estimate from bounding box of detected circle
     */
    int processFrame(cv::Mat& frame);
    
    /* called when starting to process frames - will flush out any previous data */
    void reset();
    
    void addTemplate(int templateId, cv::Mat templateMat);
    
    ARTemplate* getTemplateWithId(int templateId);
    
    int getDetectedMarkersCount(){
        return (int) _detectedMarkers.size();
    }
    
    ARMarker* getDetectedMarkerAtIndex(int index){
        if( index < 0 || index >= _detectedMarkers.size() ){
            NULL;
        }
        
        return &_detectedMarkers[index];
    }
    
protected:
    
    void doGreyScale(cv::Mat& outputMat, const cv::Mat& srcMat);
    
    void doBlur(cv::Mat& outputMat, cv::Mat& greyMat);
    
    void doThreshold(cv::Mat& outputMat, cv::Mat& greyMat);
    
    void doFindContours(std::vector<std::vector<cv::Point> >& contours, cv::Mat& binaryMat);
    
    void doFindPotentialMarkers(std::vector<ARMarker>& potentialMarkers, std::vector<std::vector<cv::Point> >& contours, cv::Mat& binaryMat);
    
    void doFindMarkers(std::vector<ARMarker>& detectedMarkers, std::vector<ARMarker>& potentialMarkers, cv::Mat& binaryMat);    
    
    void doSubpixelAccuracy(std::vector<ARMarker>& detectedMarkers,  cv::Mat& greyMat);
    
    void doEstimatePose(std::vector<ARMarker>& detectedMarkers);
    
    void cameraMatrixToOpenGL(cv::Mat &modelMatrix, const cv::Mat &rotationMatrix, const cv::Mat &translationVector);
    
    void initPerspectiveTransformTarget();
    
    void initModelPoints();
    
    bool isContourOnFrameBorder(std::vector<cv::Point> &corners, cv::Mat &srcMat);
    
    void processDebugRequest(cv::Mat &frameMat, cv::Mat &greyMat, cv::Mat &binaryMat, std::vector<std::vector<cv::Point> >& contours, std::vector<ARMarker>& potentialMarkers, std::vector<ARMarker>& detectedMarkers);
    
protected:
    DebugMode _debugMode                    = DebugMode_None;
    
    int _threshold                          = BINARY_THRESHOLD;
    bool _blurring                          = false;
    int _minContourPointsAllowed            = 5;
    float _polyContourEpsilonRatio          = 0.02f;
    float _minSqArea                        = MIN_SQUARE_AREA;
    float _maxSqArea                        = MAX_SQARE_AREA;
    
    cv::Size _perspectiveTransformSize      = cv::Size(TEMPLATE_SIZE,TEMPLATE_SIZE);
    std::vector<cv::Point2f> _perspectiveTransformTarget;
    
    std::vector<cv::Point3f> _modelPoints; // used for pose estimation
    cv::Mat _intrinsicsMatrix;                                  // output Matrices
    cv::Mat _distortionMatrix;
    
    cv::Mat _greyMat;                // step 1 - greyscale the image
    cv::Mat _binaryMat;              // step 3 - threshold image (binarized image)
    cv::Mat _contoursMat;            // step 4 - find the contours
    
    cv::Mat _wipMat;                 // work in progress image - used for debugging 
    
    std::vector<ARTemplate> _templates;
    
    std::vector<ARMarker> _detectedMarkers;
    
};

#endif /* defined(__OpenCVAR__ARTracker__) */
