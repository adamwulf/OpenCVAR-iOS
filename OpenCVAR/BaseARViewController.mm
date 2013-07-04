//
//  BaseARViewController.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 24/01/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "BaseARViewController.h"
#import "OGLMesh.h"
#import "OGLModel.h"
#import "OGLMeshData.h"
#import "ARTrackerWrapper.h"
#import "ARMarker.h"
#import "ARTemplate.h"
#import "ARCameraIntrinsics.h"

@interface BaseARViewController (){
    
    // frames per second variables
    CFTimeInterval _lastFrameProcessedTimestamp;
    //CFTimeInterval _frameElapsedTime;
    CFTimeInterval _lastFrameRateTimestamp;
    //NSInteger _fps;
    NSInteger _workingFps;
    
}

-(void) setupVideoCamera;
-(void) tearDownVideoCamera;

-(void) drawCameraStream;
-(void) drawModels;

-(cv::Mat&) doProcessImage:(cv::Mat&) image refreshDisplay:(BOOL&) refresh;

-(void) updateFrameRate; 

@end

@implementation BaseARViewController

@synthesize navDelegate;
@synthesize context;
@synthesize baseEffect;
@synthesize videoCamera;
@synthesize backdropModel;
@synthesize glEntities;
@synthesize glTextures;
@synthesize fps = _fps;
@synthesize frameElapsedTime = _frameElapsedTime; 

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
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self setupGL];
    [self setupVideoCamera];
}

-(void) viewDidDisappear:(BOOL)animated{
    [self tearDownVideoCamera];
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

-(void) stop{
    [self tearDownVideoCamera];
}

-(CFTimeInterval) getElapsedTime{
    return _frameElapsedTime;
}

#pragma mark -
#pragma mark OpenGL

- (void)setupGL
{
    self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    view.enableSetNeedsDisplay = NO;
    
    [EAGLContext setCurrentContext:self.context];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.useConstantColor = YES;
    self.baseEffect.constantColor = GLKVector4Make(1.f, 1.f, 1.f, 1.f);
    
    // set some gl state flags
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    
    glBindVertexArrayOES(0);
    
    _projectionMatrix = GLKMatrix4Identity;
    _viewMatrix = GLKMatrix4Identity;
    
    [self initGLBackdrop];
    [self initGLEntities];
}

-(void) initGLBackdrop{
    
    // create a backdrop plane as the first entities
    OGLMesh *bgMesh = [[OGLMesh alloc] initCoords:BACKGROUND_MESH_DATA meshDataSize:sizeof(BACKGROUND_MESH_DATA) withVertexCount:sizeof(BACKGROUND_MESH_DATA) / sizeof(MeshTextureVertex)];
    
    OGLModel *bgModel = [[OGLModel alloc] init];
    bgModel.effect = self.baseEffect;
    bgModel.mesh = bgMesh;
    
    self.backdropModel = bgModel;
    
    [bgMesh release];
    [bgModel release];
}

-(void) initGLEntities{
    self.glEntities = [NSMutableArray array];
    self.glTextures = [NSMutableDictionary dictionary];
    
    
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    self.baseEffect = nil;
    self.glEntities = nil;
    self.glTextures = nil;
    
    if( self.backdropModel.textureId ){
        GLuint textureId = self.backdropModel.textureId;
        glDeleteTextures(1, &textureId);
    }
    self.backdropModel = nil;
}

-(GLKTextureInfo*) loadTextureInfo:(NSString*) file withExtenstion:(NSString*) fileExtension{
    return [self loadTextureInfo:file withExtenstion:fileExtension withRepeatMode:GL_REPEAT];
}

-(GLKTextureInfo*) loadTextureInfo:(NSString*) file withExtenstion:(NSString*) fileExtension withRepeatMode:(GLfloat) mode{
    
    NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:fileExtension];
    NSError *error = nil;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                        forKey:GLKTextureLoaderOriginBottomLeft];
    
    GLKTextureInfo *tex = [GLKTextureLoader textureWithContentsOfFile:path
                                                              options:options error:&error];
    
    NSLog(@"Texture loaded %@ with alpha state %d (%d)", file, tex.alphaState, tex.name );
    
    if( error != nil ){
        NSLog(@"texture error %@", [error localizedDescription] );
    }
    
    glBindTexture(GL_TEXTURE_2D, tex.name);
    
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
    
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mode );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mode );
    
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return tex;
}

#pragma mark -
#pragma VideoCamera

-(void) setupVideoCamera{
    self.videoCamera = [[CvVideoCamera alloc] init];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.delegate = self;
    self.videoCamera.defaultFPS = 20;
    self.videoCamera.grayscaleMode = NO;
    
    [self.videoCamera start];
}

-(void) tearDownVideoCamera{
    if( self.videoCamera ){
        [self.videoCamera stop];
        self.videoCamera = nil;
    }
}

#pragma mark -
#pragma mark GLKView and GLKViewController delegate methods

- (void)update
{
    for( size_t i=0; i<self.glEntities.count; i++ ){
        OGLModel *model = (OGLModel*)[self.glEntities objectAtIndex:i];
        [model update:self.timeSinceLastUpdate];
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self drawCameraStream];
    
    [self drawModels];
}

-(void) drawCameraStream{
    if( !self.backdropModel.textureId ){
        return;
    }
    
    glUseProgram(0);
    
    glDisable(GL_DEPTH_TEST);
    
    [self.backdropModel draw:GLKMatrix4Identity viewMatrix:GLKMatrix4Identity];
    
    glEnable(GL_DEPTH_TEST);
}

-(void) drawModels{
    for( size_t i=0; i<self.glEntities.count; i++ ){
        OGLModel *model = (OGLModel*)[self.glEntities objectAtIndex:i];
        [model draw:_projectionMatrix viewMatrix:_viewMatrix];
    }
}

#pragma mark -
#pragma mark CvVideoCameraDelegate

- (void)processImage:(cv::Mat&)image{
    
    dispatch_sync( dispatch_get_main_queue(),
                  ^{
                      [self updateFrameRate];
                      
                      BOOL refresh = YES;
                      cv::Mat& imageToRender = [self doProcessImage:image refreshDisplay:refresh];
                      
                      if( refresh ){
                          [self renderCameraFrame:imageToRender.data frameWidth:imageToRender.cols frameHeight:imageToRender.rows];
                          
                          // game loop (update->render)
                          GLKView *view = (GLKView *)self.view;
                          [view display];
                      }
                      
                  });
}

-(void) updateFrameRate{
    CFTimeInterval time = CFAbsoluteTimeGetCurrent();
    _frameElapsedTime = time - _lastFrameProcessedTimestamp;
    _lastFrameProcessedTimestamp = time;
    
    // calc an approx. frames per second
    _workingFps++;
    if( time - _lastFrameRateTimestamp >= 1.0f ){
        _lastFrameRateTimestamp = time;        
        _fps = _workingFps;
        _workingFps = 0;
    }
}

-(cv::Mat&) doProcessImage:(cv::Mat&) image refreshDisplay:(BOOL&) refresh{
    refresh = YES;
    
    return image;
}


-(void) renderCameraFrame:(uchar*) frameData frameWidth:(size_t) width frameHeight:(size_t) height{
    if (!frameData)
    {
        NSLog(@"No video texture cache");
        return;
    }
    
    GLuint textureId = self.backdropModel.textureId;
    
    if( !textureId ){
        // create texture for video frame
        glGenTextures(1, &textureId);
        
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        // required for non-power-of-two textures
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // Using BGRA extension to pull in video frame data directly
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, frameData);
    } else{
        // update video frame
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_BGRA, GL_UNSIGNED_BYTE, frameData);
    }
    
    self.backdropModel.textureId = textureId;
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

#pragma mark -
#pragma mark IBAction methods

-(IBAction) onHomeTouched:(id) sender{
    [self stop]; // stop the camera  
    [self.navDelegate navigateBackHome];
}

@end
