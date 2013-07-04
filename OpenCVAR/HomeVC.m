//
//  OpenCVARVCViewController.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 25/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "HomeVC.h"

@interface HomeVC ()

@end

@implementation HomeVC

@synthesize navDelegate; 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 
#pragma mark IBAction methods 

-(IBAction) onCalibrateTouched:(id) sender{
    [navDelegate navigateToARCalibrationController];
}

-(IBAction) onCameraCaptureTouched:(id) sender{
    [navDelegate navigateToARCameraCaptureController];
}

-(IBAction) onDetectionTouched:(id) sender{
    [navDelegate navigateToARTrackerController];
}

-(IBAction) onAugmentTouched:(id) sender{
    [navDelegate navigateToARSceneController];
}

-(IBAction) onUFOGameTouched:(id) sender{
    [navDelegate navigateToARUFOSceneController];
}

@end
