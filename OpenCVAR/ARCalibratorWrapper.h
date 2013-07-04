//
//  ARCalibratorWrapper.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 24/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARCalibrator.h"

@interface ARCalibratorWrapper : NSObject

#pragma mark - 
#pragma mark properties 

#pragma mark - 
#pragma mark methods 

#pragma mark -
#pragma mark processing methods

-(void)processImage:(cv::Mat&)image;

-(cv::Mat&) getProcessedImage;

-(cv::Mat&) getIntrinsicsMatrix;

-(cv::Mat&) getDistortionMatrix;

-(float) calibrateImage:(int) frameWidth frameHeight:(int) frameHeight;

-(NSInteger) getCapturedImageCount;

@end
