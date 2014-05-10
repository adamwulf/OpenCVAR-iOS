//
//  ARTracker.cpp
//  OpenCVAR
//
//  Created by Joshua Newnham on 16/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#include "ARTracker.h"

ARTracker::ARTracker(DebugMode debugMode, int threshold, bool blurring){
    setDebugMode(debugMode);
    setThreshold(threshold);
    setBlurring(blurring);
    
    initPerspectiveTransformTarget();
    initModelPoints();
    
}

ARTracker::~ARTracker(){
    
}

void ARTracker::initPerspectiveTransformTarget(){
    _perspectiveTransformTarget.clear();
    
    // clock wise (top left -> top right -> bottom right -> bottom left)
    _perspectiveTransformTarget.push_back(cv::Point2f(0,0));
    _perspectiveTransformTarget.push_back(cv::Point2f(_perspectiveTransformSize.width,0));
    _perspectiveTransformTarget.push_back(cv::Point2f(_perspectiveTransformSize.width,_perspectiveTransformSize.height));
    _perspectiveTransformTarget.push_back(cv::Point2f(0,_perspectiveTransformSize.height));        
}

void ARTracker::initModelPoints(){
    _modelPoints.clear();
    
    _modelPoints.push_back(cv::Point3f(-1.0f,-1.0f,0));
    _modelPoints.push_back(cv::Point3f(1.0f,-1.0f,0));
    _modelPoints.push_back(cv::Point3f(1.0f,1.0f,0));
    _modelPoints.push_back(cv::Point3f(-1.0f,1.0f,0));
}

void ARTracker::addTemplate(int templateId, cv::Mat templateMat){
    printf( "ARTracker.addTemplate; %d", templateId );
    
    ARTemplate arTemplate = ARTemplate(templateId, templateMat, _perspectiveTransformSize);
    _templates.push_back(arTemplate);
}

ARTemplate* ARTracker::getTemplateWithId(int templateId){
    for( int i=0; i<_templates.size(); i++ ){
        if( _templates[i].getId() == templateId ){
            return &_templates[i];
        }
    }
    
    return NULL;
}

void ARTracker::reset(){
    
}

int ARTracker::processFrame(cv::Mat& frame){
    std::vector<std::vector<cv::Point> > contours;
    std::vector<ARMarker> potentialMarkers;
    
    // flush out previously detected markers
    _detectedMarkers.clear();
    
    doGreyScale(_greyMat, frame);
    
    if( isBlurring() ){
        doBlur(_greyMat, _greyMat);
    }
    
    doThreshold(_binaryMat, _greyMat);
    
    doFindContours(contours, _binaryMat);
    
    doFindPotentialMarkers(potentialMarkers, contours, _binaryMat);
    
    doFindMarkers(_detectedMarkers, potentialMarkers, _binaryMat);
    
    doSubpixelAccuracy(_detectedMarkers, _greyMat);
    
    doEstimatePose(_detectedMarkers);
    
    processDebugRequest(frame, _greyMat, _binaryMat, contours, potentialMarkers, _detectedMarkers);
    
    return (int) _detectedMarkers.size();
    
}

void ARTracker::doGreyScale(cv::Mat& destMat, const cv::Mat& srcMat){
    cv::cvtColor(srcMat, destMat, CV_BGRA2GRAY);
}

void ARTracker::doBlur(cv::Mat& outputMat, cv::Mat& greyMat){
    cv::GaussianBlur( greyMat, outputMat, cv::Size(7, 7), 2, 2 );        
}

void ARTracker::doThreshold(cv::Mat& outputMat, cv::Mat& greyMat){
    cv::threshold(greyMat, outputMat, getThreshold(), 255, cv::THRESH_BINARY_INV);        
}

void ARTracker::doFindContours(std::vector<std::vector<cv::Point> >& contours, cv::Mat& binaryMat){
    cv::Mat clone;
    clone = binaryMat.clone();
    
    std::vector<cv::Vec4i> hierarchy;
    std::vector<std::vector<cv::Point> > allContours;
    
    cv::findContours(clone, allContours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    
    for( size_t i=0; i<allContours.size(); i++ ){
        if( allContours[i].size() > getMinContourPointsAllowed() ){
            contours.push_back(allContours[i]);
        }
    }        
}

void ARTracker::doFindPotentialMarkers(std::vector<ARMarker>& potentialMarkers, std::vector<std::vector<cv::Point> >& contours, cv::Mat& binaryMat){
    
    std::vector<cv::Point> approxCurve;
    float area = 0.0f;
    
    for( size_t i=0; i<contours.size(); i++ ){
        
        cv::approxPolyDP(contours[i], approxCurve, getPolyContourEpsilonRatio()*contours[i].size(), true);
        
        if( approxCurve.size() != 4 ){
            continue;
        }
        
        // make sure the curse is convex
        if( !cv::isContourConvex(approxCurve) ){            
            continue; // ignore
        }
        
        // get the area
        area=fabs( cv::contourArea(approxCurve) );        
        
        // ensure that the area is big enough
        if( area < getMinSqArea() || area > getMaxSqArea() ){
            continue; // ignore
        }
        
        // dicard any contours based on the edge of the image
        if( isContourOnFrameBorder( approxCurve, binaryMat) ){
            continue; 
        }
        
        ARMarker marker;
        for(int i=0;i<4;i++)
        {
            marker.corners.push_back( cv::Point2f( approxCurve[i].x, approxCurve[i].y ) );
        }
        
        // arrange the corners such that the top left is the first and the remaining are CW
        for ( int i = 0; i < 3; ++i ){
            for ( int j = i + 1; j < 4; ++j ){
                if ( marker.corners[ i ].y > marker.corners[ j ].y ){
                    std::swap(marker.corners[ i ],marker.corners[ j ]);
                }
            }
        }
        
        // swap the top corners if the second is greater than the first
        if( marker.corners[ 0 ].x > marker.corners[ 1 ].x ){
            std::swap(marker.corners[ 0 ],marker.corners[ 1 ]);
        }
        
        if( marker.corners[ 2 ].x < marker.corners[ 3 ].x ){
            std::swap(marker.corners[ 2 ],marker.corners[ 3 ]);
        }          
        
        // add to the potentialMarkers vector
        potentialMarkers.push_back(marker);
    }        
}

bool ARTracker::isContourOnFrameBorder(std::vector<cv::Point> &corners, cv::Mat &srcMat){
    
    for( int i=0; i<corners.size(); i++ ){
        if( corners[i].x <= 1 || corners[i].x >= srcMat.cols-1
           || corners[i].y <= 1 || corners[i].y >= srcMat.rows-1 ){
            return true;
        }
    }
    
    return false;
}

void ARTracker::doFindMarkers(std::vector<ARMarker>& detectedMarkers, std::vector<ARMarker>& potentialMarkers, cv::Mat& binaryMat){
    
    cv::Mat homoMatrix;
    cv::Mat warpedMat = cv::Mat(_perspectiveTransformSize.width, _perspectiveTransformSize.height, binaryMat.type());
    
    // Identify the markers
    for (int i=(int)potentialMarkers.size()-1; i>=0; i--)
    {
        ARMarker& marker = potentialMarkers[i];
        
        // finds the transformation that maps our marker onto a flat plane (_perspectiveTarget)
        homoMatrix = cv::getPerspectiveTransform(marker.corners, _perspectiveTransformTarget);        
        
        // now unwrap the image
        cv::warpPerspective(binaryMat, warpedMat,  homoMatrix, _perspectiveTransformSize);
        
        // compare against our templates
        for( size_t j=0; j<_templates.size(); j++ ){
            int orientation = _templates[j].match(warpedMat, TEMPLATE_MATCHING_THRESHOLD);
            
            if( orientation >= 0 ){
                marker.id = _templates[j].getId(); 
                marker.orientation = orientation; 
                detectedMarkers.push_back(marker);                
                
                //printf("-> found marker %d with roation %d\n", marker.id, marker.orientation);
                
                break;
            }
        }                
    }        
}

void ARTracker::doSubpixelAccuracy(std::vector<ARMarker>& detectedMarkers,  cv::Mat& greyMat){
    if( detectedMarkers.size() == 0 ){
        return;
    }
    
    std::vector<cv::Point2f> allCorners;
    for( int i=0; i<detectedMarkers.size(); i++ ){
        ARMarker &marker = detectedMarkers[i];
        for( int j=0; j<4; j++ ){
            allCorners.push_back(marker.corners[j]);
        }
    }
    
    cv::cornerSubPix(greyMat, allCorners, cv::Size(5,5), cv::Size(-1,-1), cv::TermCriteria(CV_TERMCRIT_ITER, 30, 0.1));
    
    for( int i=0; i<detectedMarkers.size(); i++ ){
        ARMarker &marker = detectedMarkers[i];
        for( int j=0; j<4; j++ ){
            marker.corners[j] = allCorners[i*4+j];
        }
    }
}

void ARTracker::doEstimatePose(std::vector<ARMarker>& detectedMarkers){
    for( size_t i=0; i<detectedMarkers.size(); i++ ){
        ARMarker &marker = detectedMarkers.at(i);
        
        cv::Mat Rvec;
        cv::Mat_<float> Tvec;
        cv::Mat raux,taux;
        
        cv::solvePnP(_modelPoints, marker.corners, _intrinsicsMatrix, _distortionMatrix, raux, taux, false, CV_ITERATIVE);
        raux.convertTo(Rvec,CV_32F);
        taux.convertTo(Tvec ,CV_32F);        
        
        cv::Mat_<float> rotMat(3,3);
        cv::Rodrigues(Rvec, rotMat);
        
        cv::Mat modelMatrix;
        cameraMatrixToOpenGL(modelMatrix, rotMat, Tvec);
        
        marker.setModelMatrix(modelMatrix);
    }
    
}

void ARTracker::cameraMatrixToOpenGL(cv::Mat &modelMatrix, const cv::Mat &rotationMatrix, const cv::Mat &translationVector){
    
    modelMatrix = cv::Mat(4,4,CV_32F);
        
    // transpose rotation and flip y and z because open GL views down the -z axis and defines its origin in the bottom left, openCV has its origin in the top left and z is most likely positive
    
    modelMatrix.at<float>(0,0) = -rotationMatrix.at<float>(0,0); 
    modelMatrix.at<float>(0,1) = -rotationMatrix.at<float>(1,0); 
    modelMatrix.at<float>(0,2) = -rotationMatrix.at<float>(2,0);         

    modelMatrix.at<float>(2,0) = -rotationMatrix.at<float>(0,1); 
    modelMatrix.at<float>(2,1) = -rotationMatrix.at<float>(1,1);  
    modelMatrix.at<float>(2,2) = -rotationMatrix.at<float>(2,1);      

    modelMatrix.at<float>(1,0) = rotationMatrix.at<float>(0,2);
    modelMatrix.at<float>(1,1) = rotationMatrix.at<float>(1,2);      
    modelMatrix.at<float>(1,2) = rotationMatrix.at<float>(2,2);      
    
    // invert translation
    modelMatrix.at<float>(3,0)          = -translationVector.at<float>(0,0); // 12
    modelMatrix.at<float>(3,1)          = -translationVector.at<float>(0,1); // 13
    modelMatrix.at<float>(3,2)          = -translationVector.at<float>(0,2); // 14
    
    modelMatrix.at<float>(0,3)          = 0.0f;
    modelMatrix.at<float>(1,3)          = 0.0f;
    modelMatrix.at<float>(2,3)          = 0.0f;
    modelMatrix.at<float>(3,3)          = 1.0f;
}

void ARTracker::processDebugRequest(cv::Mat &frameMat, cv::Mat &greyMat, cv::Mat &binaryMat, std::vector<std::vector<cv::Point> >& contours, std::vector<ARMarker>& potentialMarkers, std::vector<ARMarker>& detectedMarkers){
    
    if( getDebugMode() == DebugMode_Greyscale || getDebugMode() == DebugMode_Blur ){
        cv::cvtColor(greyMat, _wipMat, CV_GRAY2BGRA);
    }
    else if( getDebugMode() == DebugMode_Binarization ){
        cv::cvtColor(binaryMat, _wipMat, CV_GRAY2BGRA);
    }
    else if( getDebugMode() == DebugMode_Contours ){
        cv::cvtColor(binaryMat, _wipMat, CV_GRAY2BGRA);
        cv::drawContours(_wipMat, contours, -1, cv::Scalar(0,0,255), 2);
    }
    else if( getDebugMode() == DebugMode_PotentialMarkers ){
        cv::cvtColor(binaryMat, _wipMat, CV_GRAY2BGRA);
        
        int fontFace = cv::FONT_HERSHEY_SCRIPT_SIMPLEX;
        double fontScale = 0.3f;
        
        for( int i=0; i<potentialMarkers.size(); i++ ){
            for( int j=0; j<4; j++ ){
                int idx = j;
                int nextIdx = (j+1)%4;
                
                cv::line(_wipMat, potentialMarkers[i].corners[idx], potentialMarkers[i].corners[nextIdx], cv::Scalar(0, 250, 250), 2.0f);
                
                cv::Point textOrg = potentialMarkers[i].corners[idx];
                char txt[1];
                sprintf(txt,"%d", idx);
                
                cv::putText(_wipMat, txt, textOrg, fontFace, fontScale, cv::Scalar(0,0,255), 1.2f,1);
            }
        }
    }
    else if( getDebugMode() == DebugMode_ProjectedPatterns ){
        _wipMat = binaryMat.clone();
        _wipMat.setTo(cv::Scalar(0));
        
        cv::Mat homoMatrix;
        cv::Mat warpedMat = cv::Mat(_perspectiveTransformSize.width, _perspectiveTransformSize.height, binaryMat.type());
        
        cv::Mat warpedResizedMat;
        
        for( int i=0; i<potentialMarkers.size(); i++ ){
            ARMarker& marker = potentialMarkers[i];
            
            // finds the transformation that maps our marker onto a flat plane (_perspectiveTarget)
            homoMatrix = cv::getPerspectiveTransform(marker.corners, _perspectiveTransformTarget);
            
            // now unwrap the image
            cv::warpPerspective(binaryMat, warpedMat,  homoMatrix, _perspectiveTransformSize);
            
            float warpedResizedMatWidthAndHeight = MIN(MIN(marker.sizeFromTopLeft().width, marker.sizeFromTopLeft().height), _perspectiveTransformSize.width);
            
            cv::resize(warpedMat, warpedResizedMat, cv::Size(warpedResizedMatWidthAndHeight,warpedResizedMatWidthAndHeight));
            
            cv::Rect roi = cv::Rect(marker.corners[0].x + (marker.sizeFromTopLeft().width - warpedResizedMat.cols)/2, // left,
                                    marker.corners[0].y + (marker.sizeFromTopLeft().height - warpedResizedMat.rows)/2, // top
                                    warpedResizedMat.cols, // right
                                    warpedResizedMat.rows // bottom
                                    );
            warpedResizedMat.copyTo(_wipMat.colRange(roi.x, roi.x + roi.width)
                                    .rowRange(roi.y, roi.y + roi.height));
        }
        
        cv::cvtColor(_wipMat, _wipMat, CV_GRAY2BGRA);        
    }
    else if( getDebugMode() == DebugMode_DetectedMarkers ){
        cv::cvtColor(binaryMat, _wipMat, CV_GRAY2BGRA);
        
        // identify detected markers by a green outline and label otherwise red
        int fontFace = cv::FONT_HERSHEY_SCRIPT_SIMPLEX;
        double fontScale = 0.3f;
        
        for( int i=0; i<detectedMarkers.size(); i++ ){
            cv::Point textOrg = potentialMarkers[i].corners[0];
            char txt[1];
            sprintf(txt,"%d", detectedMarkers[i].id);
            
            cv::putText(_wipMat, txt, textOrg, fontFace, fontScale, cv::Scalar(0,0,255), 1.2f,1);
            
            for( int j=0; j<4; j++ ){
                int idx = j;
                int nextIdx = (j+1)%4;
                cv::line(_wipMat, potentialMarkers[i].corners[idx], potentialMarkers[i].corners[nextIdx], cv::Scalar(0, 250, 0), 2.0f);
            }
        }
        
        for( int i=0; i<potentialMarkers.size(); i++ ){
            if( potentialMarkers[i].id == -99 ){
                continue;
            }
            
            for( int j=0; j<4; j++ ){
                int idx = j;
                int nextIdx = (j+1)%4;
                cv::line(_wipMat, potentialMarkers[i].corners[idx], potentialMarkers[i].corners[nextIdx], cv::Scalar(0, 0, 250), 2.0f);
            }
        }
        
    }
}


