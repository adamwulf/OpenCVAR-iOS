//
//  ARCameraIntrinsicsModel.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 27/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARCameraIntrinsics : NSObject{
    // matrix
    float _fx;
    float _fy;
    float _cx;
    float _cy;
    
    // distoration
    float _k1;
    float _k2;
    float _p1;
    float _p2;
    float _k3;
    
    int _width;
    int _height;
}

+(ARCameraIntrinsics*) sharedInstance;

@property (nonatomic,readwrite) float focalX;
@property (nonatomic,readwrite) float focalY;
@property (nonatomic,readwrite) float centreX;
@property (nonatomic,readwrite) float centreY;

@property (nonatomic,readwrite) float k1;
@property (nonatomic,readwrite) float k2;
@property (nonatomic,readwrite) float p1;
@property (nonatomic,readwrite) float p2;
@property (nonatomic,readwrite) float k3;

@property (nonatomic,readwrite) int width;
@property (nonatomic,readwrite) int height;

-(void) setIntrinsics:(float) focalX focalY:(float) focalY centreX:(float) centreX centreY:(float) centreY;

-(void) setIntrinsics:(cv::Mat&) intrinsicsMat;

-(void) setDistortion:(float) k1 k2:(float) k2 p1:(float) p1 p2:(float) p2 k3:(float) k3;

-(void) setDistortion:(cv::Mat&) distortionMat;

-(void) setSize:(int) width height:(int) height; 

-(void) save;

-(void) load;

-(BOOL) loadIntrinsicsMatrix:(cv::Mat&) intrinsicsMat;

-(BOOL) loadIntrinsicsMatrix:(cv::Mat&) intrinsicsMat frameWidth:(int) width frameHeight:(int) height;

-(BOOL) loadDistortionMatrix:(cv::Mat&) distortionMat;

-(BOOL) loadProjectionMatrix:(cv::Mat&) projectionMat near:(float) near far:(float) far;

@end
