//
//  ARSceneViewController.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 27/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARSceneViewController.h"
#import "OGLMesh.h"
#import "OGLModel.h"
#import "OGLARModel.h"
#import "OGLMeshData.h"
#import "ARTrackerWrapper.h"
#import "ARMarker.h"
#import "ARTemplate.h"
#import "ARCameraIntrinsics.h"

static GLKMatrix4 cvMatToGLKMatrix( cv::Mat& mat ){
    GLKMatrix4 m = GLKMatrix4Make(
                                  mat.at<float>(0,0), mat.at<float>(0,1), mat.at<float>(0,2), mat.at<float>(0,3),
                                  mat.at<float>(1,0), mat.at<float>(1,1), mat.at<float>(1,2), mat.at<float>(1,3),
                                  mat.at<float>(2,0), mat.at<float>(2,1), mat.at<float>(2,2), mat.at<float>(2,3),
                                  mat.at<float>(3,0), mat.at<float>(3,1), mat.at<float>(3,2), mat.at<float>(3,3));
    
    return m;
}

#define MODEL_TTL 2  // time to live once the marker has been lost
#define AR_ID_PLATFORM  200

@interface ARSceneViewController () {
    
    ARTrackerWrapper *_tracker;
}

-(void) setupTracker;
-(void) tearDownTracker;

-(void) setupProjectionMatrix; 

@end

@implementation ARSceneViewController

- (void)dealloc
{
    [trackingStatus release];
    
    [self tearDownTracker];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTracker];
    [self setupProjectionMatrix];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Tracker methods

-(void) setupTracker{
    _tracker = [[ARTrackerWrapper alloc] init];
    
    // add templates
    [_tracker addTemplate:AR_ID_PLATFORM templateImage:[UIImage imageNamed:TEMPLATE_FILE]];    
}

-(void) tearDownTracker{
    [_tracker release];
}

#pragma mark - 
#pragma mark gl methods 

-(void) setupProjectionMatrix{
    cv::Mat projectionMat;
    
    [[ARCameraIntrinsics sharedInstance] loadProjectionMatrix:projectionMat near:0.01f far:100.0f];
    _projectionMatrix = cvMatToGLKMatrix(projectionMat);
}

-(void) initGLEntities{
    [super initGLEntities];
    
    GLKTextureInfo *modelTex = [self loadTextureInfo:@"tree_tex" withExtenstion:@"png"];
    [self.glTextures setObject:modelTex forKey:@"modeltex"];
    
    OGLMesh *modelMesh = [[OGLMesh alloc] initCoords:TREE_MESH_DATA meshDataSize:sizeof(TREE_MESH_DATA) withVertexCount:sizeof(TREE_MESH_DATA) / sizeof(MeshTextureVertex)];
    
    OGLARModel *arModel = [[OGLARModel alloc] init];
    arModel.effect = self.baseEffect;
    arModel.mesh = modelMesh;
    arModel.arId = AR_ID_PLATFORM;
    arModel.textureId = modelTex.name;
    [self.glEntities addObject:arModel];
    
    [modelMesh release];
    [arModel release];
    
}

#pragma mark -
#pragma mark override the processing method

-(cv::Mat&) doProcessImage:(cv::Mat&) image refreshDisplay:(BOOL&) refresh{
    [_tracker processImage:image];    
    
    // update
    int foundMarkersCount = [_tracker getDetectedMarkersCount];
    
    trackingStatus.highlighted = foundMarkersCount > 0; 
    
    for( size_t i=0;  i<foundMarkersCount; i++ ){
        ARMarker *marker = [_tracker getDetectedMarkerAtIndex:i];
        
        // find associated model
        for( size_t j=0; j<self.glEntities.count; j++ ){
            OGLModel *model = [self.glEntities objectAtIndex:j];
            
            if( [model isKindOfClass:[OGLARModel class]] ){
                OGLARModel *arModel = (OGLARModel*)model;
                
                _viewMatrix = cvMatToGLKMatrix(marker->getModelMatrix());                
                
                // rotate based on models orientation
                if( marker->orientation == 1 ){ // 90
                    _viewMatrix = GLKMatrix4Rotate(_viewMatrix, M_PI_2, 0.0f, 1.0f, 0.0f);
                } else if( marker->orientation == 2 ){ // 180
                    _viewMatrix = GLKMatrix4Rotate(_viewMatrix, M_PI, 0.0f, 1.0f, 0.0f);
                } else if( marker->orientation == 3 ){ // 270 (or -90)
                    _viewMatrix = GLKMatrix4Rotate(_viewMatrix, M_PI_2, 0.0f, -1.0f, 0.0f);
                }
                
                [arModel setTtf:MODEL_TTL];
            }
        }
    }
    
    return image;
}

@end
