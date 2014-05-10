//
//  CalibrationViewController.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 24/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "BaseARViewController.h"
#import "IAppNavigation.h"

@interface CalibrationViewController : BaseARViewController{

    IBOutlet UIButton *processFrameBut;
    IBOutlet UIButton *calibrateBut;
    IBOutlet UIButton *confirmBut;
    
    IBOutlet UILabel *statusLbl;
    IBOutlet UIImageView *statusBgImg;
    
    IBOutlet UITextView *infoTf;
    IBOutlet UIImageView *infoBgImg;
}

-(IBAction) onProcessFrameButTouched:(id) sender;

-(IBAction) onCalibrateButTouched:(id) sender;

-(IBAction) onConfirmButTouched:(id) sender; 

@end
