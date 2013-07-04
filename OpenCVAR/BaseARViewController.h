//
//  BaseARViewController.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 24/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "IAppNavigation.h"

@class OGLModel;

@interface BaseARViewController : GLKViewController <CvVideoCameraDelegate>{
    
@protected
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _viewMatrix; 
}

@property (nonatomic,assign) id<IAppNavigation> navDelegate;

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *baseEffect;

@property (nonatomic, retain) CvVideoCamera* videoCamera;

@property (strong, nonatomic) OGLModel *backdropModel;
@property (strong, nonatomic) NSMutableArray *glEntities; // <GLModel>
@property (strong, nonatomic) NSMutableDictionary *glTextures; // <GLKTextureInfo>

@property (readonly, nonatomic) NSInteger fps;
@property (readonly, nonatomic) CFTimeInterval frameElapsedTime;

-(void) stop;

-(void) setupGL;
-(void) initGLBackdrop;
-(void) initGLEntities;
-(void) tearDownGL;

-(void) update; 

-(GLKTextureInfo*) loadTextureInfo:(NSString*) file withExtenstion:(NSString*) fileExtension;

-(GLKTextureInfo*) loadTextureInfo:(NSString*) file withExtenstion:(NSString*) fileExtension withRepeatMode:(GLfloat)mode;

-(IBAction) onHomeTouched:(id) sender;

@end
