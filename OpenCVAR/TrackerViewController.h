//
//  ViewController.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 10/12/2012.
//  Copyright (c) 2012 We Make Play. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "BaseARViewController.h"
#import "IAppNavigation.h"

@interface TrackerViewController : BaseARViewController {
    IBOutlet UILabel *stateLabel;
    IBOutlet UIImageView *stateImage;
    IBOutlet UIPageControl *pageControl;
    
    NSInteger _currentPage;

}

@property (nonatomic,readwrite) NSInteger currentPage;

-(IBAction) onLeftTouched:(id) sender;

-(IBAction) onRightTouched:(id) sender;

@end
