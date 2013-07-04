//
//  CalibrationVC.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 24/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "CalibrationVC.h"
#import "OGLMesh.h"
#import "OGLModel.h"
#import "OGLMeshData.h"
#import "ARCalibratorWrapper.h"
#import "ARCameraIntrinsics.h"

#define MIN_FRAMES_FOR_CALIBRATION 5

#define CALIBRATION_RESULT_DISPLAY_TIME 2 // seconds 

using namespace cv;

@interface CalibrationVC (){
    ARCalibratorWrapper *_arCalib;
    
    BOOL _processFrameRequested;
    
    BOOL _calibrateRequested;
    
    CFTimeInterval _calibrationResultDisplayTime; // calibration display count-down time (set when a flagged is processed)
    
    CGPoint frameSize; 
}

-(void) setupCalibrator;
-(void) tearCalibrator;

@end

@implementation CalibrationVC 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [processFrameBut release];
    [calibrateBut release];
    [confirmBut release];
    [statusLbl release];
    [statusBgImg release];
    [infoTf release];
    [infoBgImg release];
    
    [self tearCalibrator];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupCalibrator];
    
    calibrateBut.enabled = NO;
    infoBgImg.hidden = YES;
    confirmBut.hidden = YES; 
    infoTf.hidden = YES;
    
    statusLbl.text = [NSString stringWithFormat:@"%d/%d Frames captured", 0, MIN_FRAMES_FOR_CALIBRATION];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Tracker methods

-(void) setupCalibrator{
    _arCalib = [[ARCalibratorWrapper alloc] init];
}

-(void) tearCalibrator{
    [_arCalib release];
}

#pragma mark -
#pragma mark override the processing method

-(cv::Mat&) doProcessImage:(cv::Mat&) image refreshDisplay:(BOOL&) refresh{
        
    if( _calibrationResultDisplayTime > 0 ){
        _calibrationResultDisplayTime -= self.frameElapsedTime;
        
        if( _calibrationResultDisplayTime <= 0 ){
            _calibrationResultDisplayTime = 0;
            
            processFrameBut.enabled = YES;
            
            if( [_arCalib getCapturedImageCount] >= MIN_FRAMES_FOR_CALIBRATION){
                calibrateBut.enabled = YES; 
            }
        } else{
            refresh = NO;
        }
    }
    
    if( _processFrameRequested ){
        
        [_arCalib processImage:image];
        
        // update status
        statusLbl.text = [NSString stringWithFormat:@"%d/%d Frames captured", [_arCalib getCapturedImageCount], MIN_FRAMES_FOR_CALIBRATION];
        
        _calibrationResultDisplayTime = CALIBRATION_RESULT_DISPLAY_TIME;
        
        _processFrameRequested = NO;
        
    } else if( _calibrateRequested ){
        
        _calibrateRequested = NO;                
        
        statusLbl.text = @"Please wait while calibrating";
        
        // save size
        frameSize = CGPointMake(image.cols, image.rows);
        
        [self performSelectorInBackground:@selector(doCalibration) withObject:nil];                
        
    }
    
    return image;
}

-(void) doCalibration{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [_arCalib calibrateImage:frameSize.x frameHeight:frameSize.y];
    
    [[ARCameraIntrinsics sharedInstance] setIntrinsics:[_arCalib getIntrinsicsMatrix]];
    [[ARCameraIntrinsics sharedInstance] setDistortion:[_arCalib getDistortionMatrix]];
    [[ARCameraIntrinsics sharedInstance] setSize:frameSize.x height:frameSize.y];
    
    [[ARCameraIntrinsics sharedInstance] save];
    
    [pool release];
    
    [self performSelectorOnMainThread:@selector(onCalibrationFinished) withObject:nil waitUntilDone:NO];
    
}

-(void) onCalibrationFinished{
    statusLbl.hidden = YES;
    statusBgImg.hidden = YES;
    processFrameBut.hidden = YES;
    calibrateBut.hidden = YES;
    
    confirmBut.hidden = NO;
    infoTf.hidden = NO;
    infoBgImg.hidden = NO;
}

#pragma mark -
#pragma IBAction methods 

-(IBAction) onProcessFrameButTouched:(id) sender{
    processFrameBut.enabled = NO;
    _processFrameRequested = YES;
    
    calibrateBut.enabled = NO;
    _calibrateRequested = NO;
}

-(IBAction) onCalibrateButTouched:(id) sender{
    processFrameBut.enabled = NO;
    _processFrameRequested = NO;
    
    calibrateBut.enabled = NO;
    _calibrateRequested = YES;
}

-(IBAction) onConfirmButTouched:(id) sender{
    [self stop]; // stop the camera    
    [self.navDelegate navigateBackHome];
}

@end
