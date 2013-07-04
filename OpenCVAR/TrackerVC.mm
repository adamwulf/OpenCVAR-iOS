//
//  ViewController.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 10/12/2012.
//  Copyright (c) 2012 We Make Play. All rights reserved.
//

#import "TrackerVC.h"
#import "OGLMesh.h"
#import "OGLModel.h"
#import "OGLMeshData.h"
#import "ARTrackerWrapper.h"
#import "ARMarker.h"
#import "ARTemplate.h"
#import "ARCameraIntrinsics.h"

using namespace cv;

@interface TrackerVC () {    
    
    ARTrackerWrapper *_tracker;
}

-(void) setupTracker;
-(void) tearDownTracker;

-(NSString*) getCurrentPageDesc;

@end

@implementation TrackerVC

@synthesize currentPage = _currentPage;

- (void)dealloc
{    
    [pageControl release];
    [stateLabel release];
    [stateImage release];
    
    [self tearDownTracker];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTracker];    
    self.currentPage = 0;         
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark properties

-(void) setCurrentPage:(NSInteger)currentPage{
    _currentPage = currentPage;
    
    [_tracker setDebugMode:(DebugMode)_currentPage];
    
    pageControl.currentPage = _currentPage;

    if( _currentPage == 0 ){
        stateLabel.hidden = YES;
        stateImage.hidden = YES;
    } else{
        [stateLabel setText:[self getCurrentPageDesc]];
        stateLabel.hidden = NO;
        stateImage.hidden = NO;
    }
}

-(NSString*) getCurrentPageDesc{
    switch( (DebugMode)_currentPage ){
        case DebugMode_Greyscale:
            return @"Greyscale";
        case DebugMode_Blur:
            return @"Filter noise";
        case DebugMode_Binarization:
            return @"Binarization";
        case DebugMode_Contours:
            return @"Contours";
        case DebugMode_PotentialMarkers:
            return @"Filtered Contours";
        case DebugMode_ProjectedPatterns:
            return @"Warped";
        case DebugMode_DetectedMarkers:
            return @"Detected";
        case DebugMode_None:
            return @"";
    }
    
    return @"";
}

#pragma mark - 
#pragma mark Tracker methods 

-(void) setupTracker{
    _tracker = [[ARTrackerWrapper alloc] init];
    
    // add templates
    [_tracker addTemplate:1 templateImage:[UIImage imageNamed:TEMPLATE_FILE]];
}

-(void) tearDownTracker{
    [_tracker release];
}

#pragma mark - 
#pragma mark override the processing method 

-(cv::Mat&) doProcessImage:(cv::Mat&) image refreshDisplay:(BOOL&) refresh{
    [_tracker processImage:image];
    
    if( [_tracker getDebugMode] == DebugMode_None ){
        // render camera frame to GLTexture
        return image;
    } else{
        cv::Mat& processedImage = [_tracker getProcessedImage];
        
        // render camera frame to GLTexture
        return processedImage;
    }
    
    // update
    [_tracker getDetectedMarkersCount];    
}

#pragma mark -
#pragma mark IBAction callbacks

-(IBAction) onLeftTouched:(id) sender{
    int page = (int)[_tracker getDebugMode];
    page--;
    if( page < 0 ){
        page = DEBUG_STEPS-1;
    }
    
    if( page == DebugMode_Blur && ![_tracker isBlurring]){
        page--;
    }
    
    self.currentPage = page;
}

-(IBAction) onRightTouched:(id) sender{
    int page = (int)[_tracker getDebugMode];
    page++;
    if( page >= DEBUG_STEPS ){
        page = 0;
    }
    
    if( page == DebugMode_Blur && ![_tracker isBlurring]){
        page++;
    }
    
    self.currentPage = page;
}

@end
