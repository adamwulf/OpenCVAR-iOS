//
//  ARTrackerWrapper.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 15/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARTrackerWrapper.h"
#import "ARCameraIntrinsics.h"

@interface ARTrackerWrapper(){
    ARTracker *tracker;
    
}

@end


@implementation ARTrackerWrapper

- (id)init
{
    self = [super init];
    if (self) {
        tracker = new ARTracker();
        
        cv::Mat instrinsicMat;
        cv::Mat distMat;
        
        [[ARCameraIntrinsics sharedInstance] loadIntrinsicsMatrix:instrinsicMat];
        [[ARCameraIntrinsics sharedInstance] loadDistortionMatrix:distMat];
        
        tracker->initInstrinsic(instrinsicMat, distMat);
    }
    return self;
}

- (void)dealloc
{
    delete tracker;
    
    [super dealloc];
}

#pragma mark - 
#pragma mark properties 

-(DebugMode) getDebugMode{
    return tracker->getDebugMode();
}

-(void) setDebugMode:(DebugMode)debugMode{
    tracker->setDebugMode(debugMode);
}

-(BOOL) isBlurring{
    return tracker->isBlurring();
}

#pragma mark - 
#pragma mark delegate methods

-(void) addTemplate:(int) templateId templateImage:(UIImage*) templateImage{
    cv::Mat templateMat = [ARTrackerWrapper cvMatFromUIImage:templateImage];
    tracker->addTemplate(templateId, templateMat);
}

-(ARTemplate*) getTemplateWithId:(int) templateId{
    return tracker->getTemplateWithId(templateId);
}

- (void)processImage:(cv::Mat&)image{
    //NSLog(@"Processing frame (%dx%d)", image.cols, image.rows);
    
    tracker->processFrame(image);
}

- (cv::Mat&) getProcessedImage{
    return tracker->getWorkInProgressImage();
}

-(NSInteger) getDetectedMarkersCount{
    return tracker->getDetectedMarkersCount();
}

-(ARMarker*) getDetectedMarkerAtIndex:(int) index{
    return tracker->getDetectedMarkerAtIndex(index);
}

#pragma mark - 
#pragma mark util methods (from: http://docs.opencv.org/trunk/doc/tutorials/ios/image_manipulation/image_manipulation.html)

+(cv::Mat) cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

+(cv::Mat) cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

+(UIImage *) UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
