//
//  IAppNavigation.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 26/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IAppNavigation <NSObject>

-(void) navigateBackHome;

-(void) navigateToARCalibrationController;

-(void) navigateToARCameraCaptureController;

-(void) navigateToARTrackerController;

-(void) navigateToARSceneController;

-(void) navigateToARUFOSceneController;

@end
