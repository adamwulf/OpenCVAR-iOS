//
//  ARUtils.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 27/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#ifndef OpenCVAR_ARUtils_h
#define OpenCVAR_ARUtils_h

static float calcDistance( cv::Point2f v1, cv::Point2f v2 ){
    float x = v1.x - v2.x;
    float y = v1.y - v2.y;
    return sqrtf(x * x + y * y);
}

static float calcMagnitude( cv::Point2f v ){
    return sqrtf(v.x * v.x + v.y * v.y);
}

static float calcAngleBetween2Points( cv::Point2f v, cv::Point2f u ){
    return cosf((v.x * u.x + v.y * u.y) / (calcMagnitude(v) * calcMagnitude(u)));
}

static float calcAngleBetween3Points( cv::Point2f pt1, cv::Point2f pt2, cv::Point2f pt0 ) {
    float dx1 = pt1.x - pt0.x;
    float dy1 = pt1.y - pt0.y;
    float dx2 = pt2.x - pt0.x;
    float dy2 = pt2.y - pt0.y;
    
    return (dx1*dx2 + dy1*dy2)/sqrtf((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

static float convertDeg2Rad( float d ){
    return d * (M_PI/180.0f);
}

static float convertRad2Deg( float r ){
    return r * (180.0f/M_PI);
}


#endif
