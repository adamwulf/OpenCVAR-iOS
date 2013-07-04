//
//  ARCallibrator.cpp
//  OpenCVAR
//
//  Created by Joshua Newnham on 24/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#include "ARCalibrator.h"

ARCalibrator::ARCalibrator(int threshold, cv::Size checkboardSize, bool showCorners){
    setThreshold(threshold);
    setCheckerboardSize(checkboardSize);
    setShowCorners(showCorners);
}

ARCalibrator::~ARCalibrator(){
    
}

void ARCalibrator::reset(){
    _calibrationCount = 0;
}

int ARCalibrator::processFrame(cv::Mat& frame){
    // the points on the chessboard
    std::vector<cv::Point2f> imageCorners;
    
    int success = 0;
    
    // Get the chessboard corners
    bool found = cv::findChessboardCorners(frame, _checkerboardSize, imageCorners);
    
    if( found ){
        cv::Mat grey;
        // Get subpixel accuracy on those corners
        cv::cvtColor( frame, grey, CV_BGR2GRAY );
        // Get subpixel accuracy on the corners
        cv::cornerSubPix(grey, imageCorners,
                         cv::Size(5,5),
                         cv::Size(-1,-1),
                         cv::TermCriteria(cv::TermCriteria::MAX_ITER +
                                          cv::TermCriteria::EPS,
                                          30,		// max number of iterations
                                          0.1));     // min accuracy
        
        // If we have a good board, add it to our data
        if (imageCorners.size() == _checkerboardSize.area()) {
			// Add image and scene points from one view
            addPoints(imageCorners, _objectCorners);
            success = 1;
        }
        
    }
    
    if( _showCorners ){
        cv::drawChessboardCorners(frame, _checkerboardSize, imageCorners, found);
    }
    
    _calibrationCount += success;
    
    return _calibrationCount;
}

void ARCalibrator::addPoints(const std::vector<cv::Point2f>& imageCorners, const std::vector<cv::Point3f>& objectCorners) {
	// 2D image points from one view
	_imagePoints.push_back(imageCorners);
	// corresponding 3D scene points
	_objectPoints.push_back(objectCorners);
}

// Calibrate the camera
// returns the re-projection error
double ARCalibrator::calibrate(cv::Size imageSize)
{
	//Output rotations and translations
    std::vector<cv::Mat> rvecs, tvecs;
    
	// start calibration
	double res = cv::calibrateCamera(
                    _objectPoints, // the 3D points
		            _imagePoints,  // the image points
					imageSize,    // image size
					_intrinsicsMatrix, // output camera matrix
					_distortionMatrix,   // output distortion matrix
					rvecs, tvecs, // Rs, Ts
                    0);        // set options
    //					,CV_CALIB_USE_INTRINSIC_GUESS);
    
    printf("Start - Camera Matrix: (%d %d)\n", imageSize.width, imageSize.height);
    for( int r=0; r<_intrinsicsMatrix.rows; r++ ){
        for( int c=0; c<_intrinsicsMatrix.cols; c++ ){
            printf("%f\t", _intrinsicsMatrix.at<double>(r,c));
        }
        printf("\n");
    }
    printf("End - Camera Matrix:\n");
    
    printf("Start - Distortion Matrix: (%d %d)\n", imageSize.width, imageSize.height);
    for( int r=0; r<_distortionMatrix.rows; r++ ){
        for( int c=0; c<_distortionMatrix.cols; c++ ){
            printf("%f\t", _distortionMatrix.at<double>(r,c));
        }
        printf("\n");
    }
    printf("End - Distortion Matrix:\n");
    
    return res;
    
}
