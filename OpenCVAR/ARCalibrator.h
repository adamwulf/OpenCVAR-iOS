//
//  ARCallibrator.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 24/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#ifndef __OpenCVAR__ARCallibrator__
#define __OpenCVAR__ARCallibrator__

#include <iostream>
#include "ARConstants.h"

class ARCalibrator
{
public:
    
    ARCalibrator(int threshold = BINARY_THRESHOLD, cv::Size checkboardSize = cv::Size(CHECKER_BOARD_COL, CHECKER_BOARD_ROWS), bool showCorners = true);
	virtual ~ARCalibrator();
    
    int getThreshold(){
        return _threshold;
    }
    
    void setThreshold(int threshold){
        _threshold = threshold;
    }
    
    cv::Size getCheckerboardSize(){
        return _checkerboardSize;
    }
    
    void setCheckerboardSize(cv::Size size){
        _checkerboardSize = size;
        
        _objectCorners.clear();
        // 3D Scene Points:
        // Initialize the chessboard corners
        // in the chessboard reference frame
        // The corners are at 3D location (X,Y,Z)= (i,j,0)
        for (int r=0; r<_checkerboardSize.height; r++) {
            for (int c=0; c<_checkerboardSize.width; c++) {                
                _objectCorners.push_back(cv::Point3f(r, c, 0.0f));
            }
        }
    }
    
    bool isShowingCorners(){
        return _showCorners;
    }
    
    void setShowCorners(bool showCorners){
        _showCorners = showCorners;
    }
    
    int getCalibrationCount(){
        return _calibrationCount;
    }
    
    int getCalibrationNumber(){
        return _calibrationNumber;
    }
    
    void setCalibrationNumber(int calibrationNumber){
        _calibrationNumber = calibrationNumber;
    }
        
    int processFrame(cv::Mat& frame);
    
    double calibrate(cv::Size imageSize);
    
    cv::Mat& getWorkInProgressImage(){
        return _wipMat;
    }
    
    cv::Mat& getIntrinsicsMatrix(){
        return _intrinsicsMatrix;
    }
    
    cv::Mat& getDistortionMatrix(){
        return _distortionMatrix;
    }
    
    /* called when starting to process frames - will flush out any previous data */
    void reset();
            
protected:
    // Add scene points and corresponding image points
    void addPoints(const std::vector<cv::Point2f>& imageCorners, const std::vector<cv::Point3f>& objectCorners);
    
protected:
    
    int _threshold                          = BINARY_THRESHOLD;
    cv::Size _checkerboardSize              = cv::Size(CHECKER_BOARD_COL,CHECKER_BOARD_ROWS);
    bool _showCorners                       = true;
    int _calibrationCount                   = 0;            // how many times we have (successfully) calibrated
    int _calibrationNumber                  = 22;
    std::vector<std::vector<cv::Point3f>> _objectPoints;    // the points in world coordinates
    std::vector<std::vector<cv::Point2f>> _imagePoints;     // the point positions in pixels
    
    std::vector<cv::Point3f> _objectCorners; 
    
    cv::Mat _intrinsicsMatrix;                                  // output Matrices
    cv::Mat _distortionMatrix;
    
    cv::Mat _wipMat;                                        // work in progress image
    
};

#endif /* defined(__OpenCVAR__ARCallibrator__) */
