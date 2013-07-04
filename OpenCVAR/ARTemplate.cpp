//
//  ARTemplate.cpp
//  OpenCVAR
//
//  Created by Joshua Newnham on 20/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#include "ARTemplate.h"
#include "opencv2/features2d/features2d.hpp"

ARTemplate::ARTemplate(int templateId, cv::Mat &srcMat, cv::Size size, int binaryThreshold ){
    id = templateId;
    
    // convert to grey
    cv::cvtColor(srcMat, srcMat, CV_BGRA2GRAY);
    
    // threshold
    cv::threshold(srcMat, srcMat, binaryThreshold, 255, cv::THRESH_BINARY_INV);
    
    // resize
    cv::resize(srcMat, srcMat, size);
    
    // create rotation matrix
    cv::Point2f centre(srcMat.cols/2.0F, srcMat.rows/2.0F);
    cv::Mat rotMat = cv::getRotationMatrix2D(centre, 90.0f, 1.0f);
	
	// add 4 clones to our vector
	for(int i=0;i<4;i++) {
        templates.push_back(srcMat.clone());
	}
	
	// rotate each subsequent one by 90 deg from the previous
	for(int i=1;i<4;i++) {
        cv::warpAffine(templates[i-1], templates[i], rotMat, templates[i-1].size());
	}    
}

ARTemplate::~ARTemplate(){
    
}

int ARTemplate::match(cv::Mat &mat, float threshold){
    
    double previousBestMax = -1;
    int bestMatchIndex = -1;
    
    for( int i=0; i<4; i++ ){
        cv::Mat result;
        cv::matchTemplate(mat, templates[i], result, CV_TM_CCORR_NORMED);
        double min,max;
        cv::minMaxIdx(result, &min, &max);
        
        if( max > threshold && max > previousBestMax ){
            bestMatchIndex = i;
            previousBestMax = max;
        }
    }
    
    return bestMatchIndex; 
}