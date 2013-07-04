//
//  ARCalibratorWrapper.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 24/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARCalibratorWrapper.h"

@interface ARCalibratorWrapper(){
    ARCalibrator *arCalibrator;
}

@end

@implementation ARCalibratorWrapper

- (id)init
{
    self = [super init];
    if (self) {
        arCalibrator = new ARCalibrator();
    }
    return self;
}

- (void)dealloc
{
    delete arCalibrator;
    
    [super dealloc];
}

- (void)processImage:(cv::Mat&)image{
    arCalibrator->processFrame(image);
}

-(float) calibrateImage:(int) frameWidth frameHeight:(int) frameHeight{
    return (float)arCalibrator->calibrate(cv::Size(frameWidth,frameHeight));
}

-(cv::Mat&) getProcessedImage{
    return arCalibrator->getWorkInProgressImage(); 
}

-(cv::Mat&) getIntrinsicsMatrix{
    return arCalibrator->getIntrinsicsMatrix();
}

-(cv::Mat&) getDistortionMatrix{
    return arCalibrator->getDistortionMatrix();
}

-(NSInteger) getCapturedImageCount{
    return arCalibrator->getCalibrationCount();
}

@end
