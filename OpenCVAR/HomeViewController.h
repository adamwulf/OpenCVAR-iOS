//
//  OpenCVARVCViewController.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 25/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "IAppNavigation.h"

@interface HomeViewController : UIViewController

@property (nonatomic,assign) id<IAppNavigation> navDelegate;

-(IBAction) onCalibrateTouched:(id) sender;

-(IBAction) onCameraCaptureTouched:(id) sender; 

-(IBAction) onDetectionTouched:(id) sender;

-(IBAction) onAugmentTouched:(id) sender;

-(IBAction) onUFOGameTouched:(id) sender; 

@end