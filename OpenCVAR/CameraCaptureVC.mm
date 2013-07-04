//
//  CameraCaptureVC.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 30/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "CameraCaptureVC.h"

@interface CameraCaptureVC ()

@end

@implementation CameraCaptureVC

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
#pragma mark override the processing method


-(cv::Mat&) doProcessImage:(cv::Mat&) image refreshDisplay:(BOOL&) refresh{
    
    refresh = YES;
    
    // process image
    
    
    return image;
}

@end
