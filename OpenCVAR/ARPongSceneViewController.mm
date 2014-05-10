//
//  ARPongSceneViewController.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 01/02/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARPongSceneViewController.h"
#import "OGLMesh.h"
#import "OGLModel.h"
#import "OGLARModel.h"
#import "OGLMeshData.h"
#import "ARTrackerWrapper.h"
#import "ARMarker.h"
#import "ARTemplate.h"
#import "ARCameraIntrinsics.h"
#import "ARPongPaddleGameObject.h"
#import "ARPongCourtGameObject.h"
#import "ARPongBallGameObject.h"

typedef struct _gameData {
	GLKVector3	paddlePosition;
	GLKVector3	cameraPosition;
    GLKVector3  ballPosition;
    NSInteger   serversScore;
    NSInteger   clientsScore;
} GameData;

typedef enum _roleEnum{
    Role_Server,
    Role_Client
} Role;

typedef enum _networkCommand{
	Cmd_ACK,
	Cmd_CoinToss,
	Cmd_Update,
	Cmd_TrackingUpdate
} NetworkComment;

typedef enum _multiplayerState {
    MultiplayerState_Undefined, 
	MultiplayerState_PeerPicker,
	MultiplayerState_MultplierPlayer,
	MultiplayerState_Cointoss,
	MultiplayerState_Reconnect
} MultiplayerState;

static GLKMatrix4 cvMatToGLKMatrix( cv::Mat& mat ){
    GLKMatrix4 m = GLKMatrix4Make(
                                  mat.at<float>(0,0), mat.at<float>(0,1), mat.at<float>(0,2), mat.at<float>(0,3),
                                  mat.at<float>(1,0), mat.at<float>(1,1), mat.at<float>(1,2), mat.at<float>(1,3),
                                  mat.at<float>(2,0), mat.at<float>(2,1), mat.at<float>(2,2), mat.at<float>(2,3),
                                  mat.at<float>(3,0), mat.at<float>(3,1), mat.at<float>(3,2), mat.at<float>(3,3));
    
    return m;
}


#define MODEL_TTL 2  // time to live once the marker has been lost

#define REBOUND_MULTIPLIER 1.01 // applied to the velocity of the ball when it hits a surface 

#define AR_ID_PLATFORM  200

#define GAMEKIT_SESSION_ID @"opencvar"

#define MAX_GAMEKIT_PACKET_SIZE 1024

@interface ARPongSceneViewController (){
    ARTrackerWrapper *_tracker;
    
    GLKVector3 _cameraPosition;
    
    NSInteger _localScore;
    NSInteger _remoteScore;
    
    NSInteger _packetCount;
    NSInteger _uid; 
}

@property (nonatomic,assign) ARPongPaddleGameObject *pinkPaddle;
@property (nonatomic,assign) ARPongPaddleGameObject *bluePaddle;
@property (nonatomic,assign) ARPongBallGameObject *ball;
@property (nonatomic,assign) ARPongCourtGameObject *court;

@property(nonatomic, strong) GKSession	 *gameSession;
@property(nonatomic, copy) NSString	 *gamePeerId;

@property (nonatomic,readwrite) MultiplayerState gkState;
@property (nonatomic, readwrite) Role role; 

-(void) setupTracker;
-(void) tearDownTracker;

-(void) setupProjectionMatrix;

-(void) startGame;

-(void) launchBall;

-(void) updateScoreBoard;

-(void) gameOver; 

-(void) showPeerPicker;

-(void) invalidateGameSession:(GKSession *)session;

-(void) sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend;

-(void) onGameDataReceived:(GameData*) data;

@end

@implementation ARPongSceneViewController

@synthesize pinkPaddle;
@synthesize bluePaddle;
@synthesize ball;
@synthesize court; 
@synthesize mode;

@synthesize gameSession;
@synthesize gamePeerId;

@synthesize gkState;
@synthesize role; 

- (void)dealloc
{
    [trackingStatus release];
    [localScoreLbl release];
    [remoteScoreLbl release];
    [singlePlayerBut release];
    [multiPlayerBut release];
    
    [self tearDownTracker];
    
    [self invalidateGameSession:self.gameSession];
	self.gameSession = nil;
	self.gamePeerId = nil;
    
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
#pragma mark Session Related Methods

- (void)invalidateGameSession:(GKSession *)session {
	if(session != nil) {
		[session disconnectFromAllPeers];
		session.available = NO;
		[session setDataReceiveHandler: nil withContext: NULL];
		session.delegate = nil;
	}
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

/* Notifies delegate that the connection type is requesting a GKSession object.
 
 You should return a valid GKSession object for use by the picker. If this method is not implemented or returns 'nil', a default GKSession is created on the delegate's behalf.
 */
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type{
    GKSession *session = [[GKSession alloc] initWithSessionID:GAMEKIT_SESSION_ID displayName:nil sessionMode:GKSessionModePeer];
	return [session autorelease]; 
}

/* Notifies delegate that the peer was connected to a GKSession. */
- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session{
    self.gamePeerId = peerID;
	
	self.gameSession = session; // retain
	self.gameSession.delegate = self;
	[self.gameSession setDataReceiveHandler:self withContext:NULL];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
		
	self.gkState = MultiplayerState_Cointoss;
}

/* Notifies delegate that the user cancelled the picker. */
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker{
	picker.delegate = nil;
    [picker autorelease];		
	
	// go back to start mode
	[self gameOver];
}

#pragma mark GKSessionDelegate Methods

// we've gotten a state change in the session
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
	if(self.gkState == MultiplayerState_PeerPicker) {
		return;
	}
	
	if(state == GKPeerStateDisconnected) {
		[self gameOver];
	}
}

#pragma mark - 
#pragma mark sending and receiving data 

/*
 * Getting a data packet. This is the data receive handler method expected by the GKSession.
 * We set ourselves as the receive data handler in the -peerPickerController:didConnectPeer:toSession: method.
 */
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    
	static int lastPacketTime = -1;
	unsigned char *incomingPacket = (unsigned char *)[data bytes];
	int *pIntData = (int *)&incomingPacket[0];
	
	int packetTime = pIntData[0];
	int packetID = pIntData[1];
	if(packetTime < lastPacketTime && packetID != Cmd_CoinToss) {
		return;
	}
    
	lastPacketTime = packetTime;
	switch( packetID ) {
		case Cmd_CoinToss:
        {
            // coin toss to determine roles of the two players
            int coinToss = pIntData[2];
            // if other player's coin is higher than ours then that player is the server
            if(coinToss > _uid) {
                self.role = Role_Client;
            } else{
                self.role = Role_Server;
            }
            
            NSLog(@"Coin_toss packet received %d", coinToss);
            
            [self startGame];
        }
			break;
		case Cmd_Update:
        {
            GameData *data = (GameData*)&incomingPacket[8];
            [self onGameDataReceived:data];
        }
			break;
		case Cmd_TrackingUpdate:
        {
            // TODO: pause the game when on of the players loose tracking 
        }
			break;
		default:
			// error
			break;
	}
}

- (void) sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend {
	// the packet we'll send is resued
	static unsigned char networkPacket[MAX_GAMEKIT_PACKET_SIZE];
	const unsigned int packetHeaderSize = 2 * sizeof(int); // we have two "ints" for our header
	
	if(length < (MAX_GAMEKIT_PACKET_SIZE - packetHeaderSize)) { // our networkPacket buffer size minus the size of the header info
		int *pIntData = (int *)&networkPacket[0];
		// header info
		pIntData[0] = _packetCount++;
		pIntData[1] = packetID;
        
		// copy data in after the header
		memcpy( &networkPacket[packetHeaderSize], data, length );
		
		NSData *packet = [NSData dataWithBytes: networkPacket length: (length+8)];
		if(howtosend == YES) {
			[session sendData:packet toPeers:[NSArray arrayWithObject:gamePeerId] withDataMode:GKSendDataReliable error:nil];
		} else {
			[session sendData:packet toPeers:[NSArray arrayWithObject:gamePeerId] withDataMode:GKSendDataUnreliable error:nil];
		}
	}
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
    
    // load textures
    GLKTextureInfo *blueTex = [self loadTextureInfo:@"blue_tex" withExtenstion:@"png"];
    [self.glTextures setObject:blueTex forKey:@"blue"];
    
    GLKTextureInfo *pinkTex = [self loadTextureInfo:@"pink_tex" withExtenstion:@"png"];
    [self.glTextures setObject:pinkTex forKey:@"pink"];
    
    GLKTextureInfo *yellowTex = [self loadTextureInfo:@"yellow_tex" withExtenstion:@"png"];
    [self.glTextures setObject:yellowTex forKey:@"yellow"];
    
    GLKTextureInfo *courtTex = [self loadTextureInfo:@"court_tex" withExtenstion:@"png"];
    [self.glTextures setObject:courtTex forKey:@"court"];
    
    GLKTextureInfo *courtBordersTex = [self loadTextureInfo:@"borders_tex" withExtenstion:@"png"];
    [self.glTextures setObject:courtBordersTex forKey:@"borders"];
    
    // load models - court
    self.court = [[[ARPongCourtGameObject alloc] init] autorelease];
    self.court.effect = self.baseEffect;
    self.court.arId = AR_ID_PLATFORM;
    self.court.textureId = courtTex.name;
    [self.glEntities addObject:self.court];
    
    OGLMesh *bordersMesh = [[[OGLMesh alloc] initCoords:COURT_BORDERS_MESH_DATA meshDataSize:sizeof(COURT_BORDERS_MESH_DATA) withVertexCount:sizeof(COURT_BORDERS_MESH_DATA) / sizeof(MeshTextureVertex)] autorelease];
    OGLARModel *courtBorders = [[[OGLARModel alloc] init] autorelease];
    courtBorders.effect = self.baseEffect;
    courtBorders.arId = AR_ID_PLATFORM;
    courtBorders.textureId = courtBordersTex.name;
    courtBorders.mesh = bordersMesh;
    [self.glEntities addObject:courtBorders];
    
   
    // load models - ball
    self.ball = [[[ARPongBallGameObject alloc] init] autorelease];
    self.ball.effect = self.baseEffect;
    self.ball.arId = AR_ID_PLATFORM;
    self.ball.textureId = yellowTex.name;
    [self.glEntities addObject:self.ball];
    
    // load models - ball
    self.bluePaddle = [[[ARPongPaddleGameObject alloc] init] autorelease];
    self.bluePaddle.effect = self.baseEffect;
    self.bluePaddle.arId = AR_ID_PLATFORM;
    self.bluePaddle.textureId = blueTex.name;
    self.bluePaddle.position = GLKVector3Make(0.0f, 0.0f, self.court.mesh.modelSize.z / 2 - self.bluePaddle.mesh.modelSize.z * 1.2f);
    [self.bluePaddle updateModelMatrix];
    [self.glEntities addObject:self.bluePaddle];
    
    
    self.pinkPaddle = [[[ARPongPaddleGameObject alloc] init] autorelease];
    self.pinkPaddle.effect = self.baseEffect;
    self.pinkPaddle.arId = AR_ID_PLATFORM;
    self.pinkPaddle.textureId = pinkTex.name;
    self.pinkPaddle.position = GLKVector3Make(0.0f, 0.0f, -self.court.mesh.modelSize.z / 2 + self.bluePaddle.mesh.modelSize.z * 1.2f);
    [self.pinkPaddle updateModelMatrix];
    [self.glEntities addObject:self.pinkPaddle];
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
                
                [arModel setTtf:MODEL_TTL];
                
                
                if( [model isKindOfClass:[ARPongCourtGameObject class]] ){
                    // set the view matrix (centre of our world)
                    _viewMatrix = cvMatToGLKMatrix(marker->getModelMatrix());
                    
                    // rotate based on models orientation
                    if( marker->orientation == 1 ){ // 90
                        _viewMatrix = GLKMatrix4Rotate(_viewMatrix, M_PI_2, 0.0f, 1.0f, 0.0f);
                    } else if( marker->orientation == 2 ){ // 270 (or -90)
                        _viewMatrix = GLKMatrix4Rotate(_viewMatrix, M_PI_2, 0.0f, -1.0f, 0.0f);
                    } else if( marker->orientation == 3 ){ // 180
                        _viewMatrix = GLKMatrix4Rotate(_viewMatrix, M_PI, 0.0f, 1.0f, 0.0f);
                    }
                    
                    // extract the camera position from the view matrix
                    // invert translation
                    _cameraPosition = GLKVector3Make(
                                                     marker->getModelMatrix().at<float>(3,0),
                                                        marker->getModelMatrix().at<float>(3,1),
                                                            marker->getModelMatrix().at<float>(3,2));
                }
            }
        }
    }
    
    return image;
}

#pragma mark - 
#pragma mark update methods 

- (void)update
{
    [super update];
    
    if( self.mode == Mode_Multiplayer && self.gkState == MultiplayerState_Cointoss ){
        [self sendNetworkPacket:self.gameSession packetID:Cmd_CoinToss withData:&_uid ofLength:sizeof(int) reliable:YES];
    }
    
    // boundary check for ball
    if( self.ball.position.z > (self.court.mesh.modelSize.z/2 + self.ball.mesh.modelSize.z) ){
        // bottom
        if( self.bluePaddle.owner == Owner_Local ){
            _remoteScore++;
        } else{
            _localScore++;
        }
        [self updateScoreBoard];
    } else if( self.ball.position.z < -(self.court.mesh.modelSize.z/2 + self.ball.mesh.modelSize.z) ){
        // top
        if( self.bluePaddle.owner == Owner_Local ){
            _localScore++;
        } else{
            _remoteScore++;
        }
        [self updateScoreBoard];        
    }
    
    // hit the sides?
    if( self.ball.position.x - self.ball.mesh.modelSize.x/2 < -self.court.mesh.modelSize.x/2){
        GLKVector3 pos = self.ball.position;
        pos.x = self.court.left +  self.ball.mesh.modelSize.x / 2;
        self.ball.position = pos; 
        // invert the x velocity
        self.ball.velocity = GLKVector3Make(-self.ball.velocity.x, self.ball.velocity.y, self.ball.velocity.z);
        // apply multiplier
        self.ball.velocity = GLKVector3MultiplyScalar(self.ball.velocity, REBOUND_MULTIPLIER);
    } else if( self.ball.position.x + self.ball.mesh.modelSize.x/2 > self.court.mesh.modelSize.x/2){
        GLKVector3 pos = self.ball.position;
        pos.x = self.court.right - self.ball.mesh.modelSize.x / 2;
        self.ball.position = pos;
        // invert the x velocity
        self.ball.velocity = GLKVector3Make(-self.ball.velocity.x, self.ball.velocity.y, self.ball.velocity.z);
        // apply multiplier
        self.ball.velocity = GLKVector3MultiplyScalar(self.ball.velocity, REBOUND_MULTIPLIER);
    }        
    
    // handle user input
    if( self.pinkPaddle.owner == Owner_Local ){
        GLKVector3 pos = self.pinkPaddle.position;
        pos.x = -_cameraPosition.x;
        
        if( pos.x - (self.pinkPaddle.mesh.modelSize.x / 2) < self.court.left ){
            pos.x = self.court.left + self.pinkPaddle.mesh.modelSize.x / 2;
        }
        else if( pos.x + (self.pinkPaddle.mesh.modelSize.x / 2) > self.court.right ){
            pos.x = self.court.right - self.pinkPaddle.mesh.modelSize.x / 2;
        }
        
        self.pinkPaddle.position = pos;
    }
    else if( self.bluePaddle.owner == Owner_Local ){
        GLKVector3 pos = self.bluePaddle.position;
        pos.x = _cameraPosition.x;
        
        if( pos.x - (self.bluePaddle.mesh.modelSize.x / 2) < self.court.left ){
            pos.x = self.court.left + self.bluePaddle.mesh.modelSize.x / 2;
        }
        else if( pos.x + (self.bluePaddle.mesh.modelSize.x / 2) > self.court.right ){
            pos.x = self.court.right - self.bluePaddle.mesh.modelSize.x / 2;
        }
        
        self.bluePaddle.position = pos;
    }
    
    // AI (or sorts) 
    if( self.mode == Mode_SinglePlayer ){
        // update AI
        GLKVector3 pos = self.pinkPaddle.position;
        pos.x = self.ball.position.x;
        
        if( pos.x - (self.pinkPaddle.mesh.modelSize.x / 2) < self.court.left ){
            pos.x = self.court.left + self.pinkPaddle.mesh.modelSize.x / 2;
        }
        else if( pos.x + (self.pinkPaddle.mesh.modelSize.x / 2) > self.court.right ){
            pos.x = self.court.right - self.pinkPaddle.mesh.modelSize.x / 2;
        }
        
        self.pinkPaddle.position = pos;
    }
    
    // hit one of the paddles?
    if( ABS(self.pinkPaddle.position.z - self.ball.position.z) <= (self.pinkPaddle.mesh.modelSize.z + self.ball.mesh.modelSize.z)/2
       && self.ball.velocity.z < 0 ){
        // check left and right
        if( self.ball.left >= self.pinkPaddle.left && self.ball.right <= self.pinkPaddle.right ){
            // invert the x velocity
            self.ball.velocity = GLKVector3Make(-self.ball.velocity.x, self.ball.velocity.y, -self.ball.velocity.z);
            // apply multiplier
            self.ball.velocity = GLKVector3MultiplyScalar(self.ball.velocity, REBOUND_MULTIPLIER);
        }
    } else if( ABS(self.bluePaddle.position.z - self.ball.position.z) <= (self.bluePaddle.mesh.modelSize.z + self.ball.mesh.modelSize.z)/2
       && self.ball.velocity.z > 0){
        // check left and right
        if( self.ball.left >= self.bluePaddle.left && self.ball.right <= self.bluePaddle.right ){
            // invert the x velocity
            self.ball.velocity = GLKVector3Make(-self.ball.velocity.x, self.ball.velocity.y, -self.ball.velocity.z);
            // apply multiplier
            self.ball.velocity = GLKVector3MultiplyScalar(self.ball.velocity, REBOUND_MULTIPLIER);
        }
    }
    
    // sync
    if( self.mode == Mode_Multiplayer && self.gkState == MultiplayerState_MultplierPlayer ){
        if( self.role == Role_Client ){
            GameData gd;
            gd.paddlePosition = self.pinkPaddle.position;
            gd.cameraPosition = _cameraPosition;
            [self sendNetworkPacket:gameSession packetID:Cmd_Update withData:&gd ofLength:sizeof(GameData) reliable:NO];
            
        } else if( self.role == Role_Server ){
            GameData gd;
            gd.paddlePosition = self.bluePaddle.position;
            gd.cameraPosition = _cameraPosition;
            gd.ballPosition = self.ball.position;
            gd.serversScore = _localScore;
            gd.clientsScore = _remoteScore; 
            [self sendNetworkPacket:gameSession packetID:Cmd_Update withData:&gd ofLength:sizeof(GameData) reliable:NO];
        }
    }
}

#pragma mark - 
#pragma mark game methods 

-(void) showPeerPicker {
    _uid = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] hash];
    _packetCount = 0;
    
    singlePlayerBut.hidden = YES;
    multiPlayerBut.hidden = YES;
    
	GKPeerPickerController*		picker;
	
	self.gkState = MultiplayerState_PeerPicker;
    self.mode = Mode_Multiplayer;
	
	picker = [[GKPeerPickerController alloc] init]; // note: picker is released in various picker delegate methods when picker use is done.
	picker.delegate = self;
	[picker show]; // show the Peer Picker
}

-(void) startGame{
    _localScore = _remoteScore = 0;
    
    // single player
    if( self.mode == Mode_SinglePlayer ){
        self.bluePaddle.owner = Owner_Local;
        self.ball.owner = Owner_Local;
        self.pinkPaddle.owner = Owner_AI;
        
        [self launchBall];
    } else{
        if( self.role == Role_Server ){
            self.bluePaddle.owner = Owner_Local;
            self.ball.owner = Owner_Local;
            self.pinkPaddle.owner = Owner_Remote;
            
            [self launchBall];
        } else{
            self.bluePaddle.owner = Owner_Remote;
            self.ball.owner = Owner_Remote;
            self.pinkPaddle.owner = Owner_Local;
        }
        
        self.gkState = MultiplayerState_MultplierPlayer;
    }
    
    singlePlayerBut.hidden = YES;
    multiPlayerBut.hidden = YES;
    
    [self updateScoreBoard];
    
    localScoreLbl.hidden = NO;
    remoteScoreLbl.hidden = NO;
}

-(void) gameOver{
    // invalidate and release game session if one is around.
	if(self.gameSession != nil)	{
		[self invalidateGameSession:self.gameSession];
		self.gameSession = nil;
	}
    
    self.gkState = MultiplayerState_Undefined;
    self.mode = Mode_Undefined;
    
    _localScore = _remoteScore = 0;
    [self updateScoreBoard];
    localScoreLbl.hidden = remoteScoreLbl.hidden = YES;
    
    singlePlayerBut.hidden = multiPlayerBut.hidden = NO;
    
}

-(void) launchBall{
    // place ball in the middle and give initial velocity
    self.ball.position = GLKVector3Make(0,0,0);
    self.ball.velocity = GLKVector3Make( 1.0f, 0.0f, 0.1f );
}

-(void) updateScoreBoard{
    remoteScoreLbl.text = [NSString stringWithFormat:@"%d", _remoteScore];
    localScoreLbl.text = [NSString stringWithFormat:@"%d", _localScore];
}

-(void) onGameDataReceived:(GameData*) data{
    
    NSLog(@"onGameDataReceived");
    
    if( self.role == Role_Server ){
        self.pinkPaddle.position = data->paddlePosition;
    } else{
        self.bluePaddle.position = data->paddlePosition;
        self.ball.position = data->ballPosition;
        _remoteScore = data->serversScore;
        _localScore = data->clientsScore;
        [self updateScoreBoard];
    }
}

#pragma mark -
#pragma mark IBAction callbacks 

-(IBAction) butSinglePlayerTouched{
    self.mode = Mode_SinglePlayer;
    [self startGame];
}

-(IBAction) butStartMultiplayerTouched{
    [self showPeerPicker];
}

@end
