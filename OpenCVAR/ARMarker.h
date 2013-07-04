//
//  ARMarker.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 16/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#ifndef __OpenCVAR__ARMarker__
#define __OpenCVAR__ARMarker__

#include <iostream>
#include "ARConstants.h"

class ARMarker
{
public:
    ARMarker();
    virtual ~ARMarker();
    
public:
    
    //id of  the marker
    int id;
    
    std::vector<cv::Point2f> corners;
    
    int orientation;
    
    cv::Size size(){
        int maxX = -1, minX = 9999999;
        int maxY = -1, minY = 9999999;
        
        for( int i=0; i<corners.size(); i++ ){
            minX = MIN(corners[i].x, minX);
            maxX = MAX(corners[i].x, maxX);
            minY = MIN(corners[i].y, minY);
            maxY = MAX(corners[i].y, maxY);
        }
        
        return cv::Size(maxX-minX, maxY-minY);
    }
    
    cv::Size sizeFromTopLeft(){
        return cv::Size(corners[1].x-corners[0].x, corners[3].y-corners[0].y);
    }
    
    cv::Mat& getModelMatrix(){
        return _modelMatrix;
    }
    
    void setModelMatrix(cv::Mat &modelMatrix){
        _modelMatrix = modelMatrix.clone(); 
    }
    
protected:
    cv::Mat _modelMatrix;    
};

#endif /* defined(__OpenCVAR__ARMarker__) */
