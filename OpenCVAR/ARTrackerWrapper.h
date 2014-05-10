//
//  ARTrackerWrapper.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 15/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTracker.h"

@interface ARTrackerWrapper : NSObject

#pragma mark - 
#pragma mark init methods

-(DebugMode) getDebugMode;

-(void) setDebugMode:(DebugMode)debugMode;

-(BOOL) isBlurring;

-(void) addTemplate:(int) templateId templateImage:(UIImage*) templateImage;

-(ARTemplate*) getTemplateWithId:(int) templateId;

#pragma mark - 
#pragma mark processing methods

-(void)processImage:(cv::Mat&)image;

-(cv::Mat&) getProcessedImage;

-(NSInteger) getDetectedMarkersCount;

-(ARMarker*) getDetectedMarkerAtIndex:(int) index;

#pragma mark - 
#pragma mark util methods

+(cv::Mat)cvMatFromUIImage:(UIImage *)image;

+(cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;

+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;

@end
