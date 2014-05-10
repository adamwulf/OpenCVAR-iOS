//
//  ARCameraIntrinsicsModel.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 27/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARCameraIntrinsics.h"

@interface ARCameraIntrinsics(){
    
}

-(NSInteger) retainCount;

@end

@implementation ARCameraIntrinsics

@synthesize focalX = _fx;
@synthesize focalY = _fy;
@synthesize centreX = _cx;
@synthesize centreY = _cy;

@synthesize k1 = _k1;
@synthesize k2 = _k2;
@synthesize p1 = _p1;
@synthesize p2 = _p2;
@synthesize k3 = _k3;

@synthesize width = _width;
@synthesize height = _height;

static ARCameraIntrinsics *instance = NULL;

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

+(ARCameraIntrinsics*) sharedInstance{
    if( instance == NULL ){
        @synchronized(self) {
            instance = [[self alloc] init];
            [instance load];
        }
    }
    return instance;
}

-(NSInteger) retainCount{
    return NSUIntegerMax;
}

- (void)dealloc
{
    [super dealloc];
}

-(oneway void) release{
    /* ignore as the shared instance should not be deallocated */
}

-(id) retain{
    return self;
}

#pragma mark - 
#pragma mark properties/getters/setters 

-(void) setIntrinsics:(float) focalX focalY:(float) focalY centreX:(float) centreX centreY:(float) centreY{    
    _fx = focalX;
    _fy = focalY;
    _cx = centreX;
    _cy = centreY;
}

-(void) setIntrinsics:(cv::Mat&) intrinsicsMat{
    [self setIntrinsics:intrinsicsMat.at<double>(0,0) focalY:intrinsicsMat.at<double>(1,1)
                centreX:intrinsicsMat.at<double>(0,2) centreY:intrinsicsMat.at<double>(1,2)];
}

-(void) setDistortion:(float) k1 k2:(float) k2 p1:(float) p1 p2:(float) p2 k3:(float) k3{
    _k1 = k1;
    _k2 = k2;
    _p1 = p1;
    _p2 = p2;
    _k3 = k3;
}

-(void) setDistortion:(cv::Mat&) distortionMat{
    [self setDistortion:distortionMat.at<double>(0,0) k2:distortionMat.at<double>(0,1) p1:distortionMat.at<double>(0,2)
                     p2:distortionMat.at<double>(0,3) k3:distortionMat.at<double>(0,4)];
}

-(void) setSize:(int) width height:(int) height{
    _width = width;
    _height = height; 
}

#pragma mark - 
#pragma mark utils methods 

-(BOOL) loadIntrinsicsMatrix:(cv::Mat&) intrinsicsMat{
    //  fx  0   cx
    //  0   fy  cy
    //  0   0   1
    
    intrinsicsMat = cv::Mat(3, 3, CV_32F);
    intrinsicsMat.at<float>(0,0) = _fx;  intrinsicsMat.at<float>(0,1) = 0;    intrinsicsMat.at<float>(0,2) = _cx;
    intrinsicsMat.at<float>(1,0) = 0;    intrinsicsMat.at<float>(1,1) = _fy;  intrinsicsMat.at<float>(1,2) = _cy;
    intrinsicsMat.at<float>(2,0) = 0;    intrinsicsMat.at<float>(2,1) = 0;    intrinsicsMat.at<float>(2,2) = 1;
    
    return YES;
}

-(BOOL) loadIntrinsicsMatrix:(cv::Mat&) intrinsicsMat frameWidth:(int) width frameHeight:(int) height{
    //  fx  0   cx
    //  0   fy  cy
    //  0   0   1
    
    float horzScale = (float)width / (float)_width;
    float vertScale = (float)height / (float)_height;
    
    intrinsicsMat = cv::Mat(3, 3, CV_32F);
    intrinsicsMat.at<float>(0,0) = _fx * horzScale;  intrinsicsMat.at<float>(0,1) = 0;    intrinsicsMat.at<float>(0,2) = _cx * horzScale;
    intrinsicsMat.at<float>(1,0) = 0;    intrinsicsMat.at<float>(1,1) = _fy * vertScale;  intrinsicsMat.at<float>(1,2) = _cy * vertScale;
    intrinsicsMat.at<float>(2,0) = 0;    intrinsicsMat.at<float>(2,1) = 0;    intrinsicsMat.at<float>(2,2) = 1;
    
    return YES; 
}

-(BOOL) loadDistortionMatrix:(cv::Mat&) distortionMat{
    distortionMat = cv::Mat(4, 1, CV_32F);
    distortionMat.at<float>(0,0) = _k1;
    distortionMat.at<float>(1,0) = _k2;
    distortionMat.at<float>(2,0) = _p1;
    distortionMat.at<float>(3,0) = _p2;
    
    return YES; 
}

-(BOOL) loadProjectionMatrix:(cv::Mat&) projectionMat near:(float) near far:(float) far{
    projectionMat = cv::Mat(4,4,CV_32F);
    
    projectionMat.at<float>(0,0) = -2.0 * _fx / (float)_width;
	projectionMat.at<float>(0,1) = 0.0;
	projectionMat.at<float>(0,2) = 0.0;
	projectionMat.at<float>(0,3) = 0.0;
    
	projectionMat.at<float>(1,0) = 0.0;
    projectionMat.at<float>(1,1) = 2.0 * _fy / (float)_height;
    projectionMat.at<float>(1,2) = 0.0;
	projectionMat.at<float>(1,3) = 0.0;
	
	projectionMat.at<float>(2,0) = 2.0 * ( _cx / (float)_width) - 1.0;
	projectionMat.at<float>(2,1) = 2.0 * ( _cy / (float)_height ) - 1.0;
	projectionMat.at<float>(2,2) = -( far+near ) / ( far - near );
	projectionMat.at<float>(2,3) = -1.0;
    
	projectionMat.at<float>(3,0) = 0.0;
	projectionMat.at<float>(3,1) = 0.0;
	projectionMat.at<float>(3,2) = -2.0 * far * near / ( far - near );
	projectionMat.at<float>(3,3) = 0.0;
    
    return YES; 
}

#pragma mark -
#pragma mark persistent

-(void) save{
    NSString *camData = [[NSBundle mainBundle] pathForResource:@"calibration" ofType:@"dat"];
    
    NSMutableString *data = [NSMutableString string];
    
    [data appendFormat:@"fx=%f\n", _fx];
    [data appendFormat:@"cx=%f\n", _cx];
    [data appendFormat:@"fy=%f\n", _fy];
    [data appendFormat:@"cy=%f\n", _cy];
    [data appendFormat:@"k1=%f\n", _k1];
    [data appendFormat:@"k2=%f\n", _k2];
    [data appendFormat:@"k3=%f\n", _k3];
    [data appendFormat:@"p1=%f\n", _p1];
    [data appendFormat:@"p2=%f\n", _p2];
    [data appendFormat:@"width=%d\n", _width];
    [data appendFormat:@"height=%d\n", _height];
    
    [data writeToFile:camData atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"Saving Camera Calibration Data:\n%@", data);
}

-(void) load{
    NSString *camData = [[NSBundle mainBundle] pathForResource:@"calibration" ofType:@"dat"];
    NSData *fData = [NSData dataWithContentsOfFile:camData];
    
    if( fData ){
        
        NSString* string = [[[NSString alloc] initWithBytes:[fData bytes]
                                                     length:[fData length]
                                                   encoding:NSUTF8StringEncoding] autorelease];
        
        NSLog(@"Loading Camera Calibration Data:\n%@", string);
        
        //split the string around newline characters to create an array
        NSString* lineDelimiter = @"\n";
        NSArray* lines = [string componentsSeparatedByString:lineDelimiter];
        
        NSString *keyValueDelimiter = @"=";
        for( NSString *line in lines ){
            if( line ){
                NSArray *pair = [line componentsSeparatedByString:keyValueDelimiter];
                if( pair == nil || [pair count] != 2 ){
                    continue;
                }
                
                NSString *key = (NSString*)[pair objectAtIndex:0];
                NSString *value = (NSString*)[pair objectAtIndex:1];
                
                if( key != nil || value != nil ){
                    if( [key isEqualToString:@"fx"] ){
                        _fx=[value floatValue];
                    } else if( [key isEqualToString:@"cx"] ){
                        _cx=[value floatValue];
                    } else if( [key isEqualToString:@"fy"] ){
                        _fy=[value floatValue];
                    } else if( [key isEqualToString:@"cy"] ){
                        _cy=[value floatValue];
                    } else if( [key isEqualToString:@"k1"] ){
                        _k1=[value floatValue];
                    } else if( [key isEqualToString:@"k2"] ){
                        _k2=[value floatValue];
                    } else if( [key isEqualToString:@"k3"] ){
                        _k3=[value floatValue];
                    } else if( [key isEqualToString:@"p1"] ){
                        _p1=[value floatValue];
                    } else if( [key isEqualToString:@"p2"] ){
                        _p2=[value floatValue];
                    } else if( [key isEqualToString:@"width"] ){
                        _width=[value intValue];
                    } else if( [key isEqualToString:@"height"] ){
                        _height=[value intValue];
                    }
                }
            }
        }
    }    
}

@end
