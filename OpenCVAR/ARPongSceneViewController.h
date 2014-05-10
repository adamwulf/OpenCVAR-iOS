//
//  ARPongSceneViewController.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 01/02/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <GameKit/GameKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "BaseARViewController.h"
#import "IAppNavigation.h"

typedef enum _modeEnum{
    Mode_Undefined, 
    Mode_SinglePlayer,
    Mode_Multiplayer
} Mode;

@interface ARPongSceneViewController : BaseARViewController <GKPeerPickerControllerDelegate, GKSessionDelegate, UIAlertViewDelegate>{
    
    IBOutlet UIImageView *trackingStatus;
    IBOutlet UILabel *localScoreLbl;
    IBOutlet UILabel *remoteScoreLbl;
    IBOutlet UIButton *singlePlayerBut;
    IBOutlet UIButton *multiPlayerBut;
}

@property (nonatomic, readwrite) Mode mode;

-(IBAction) butSinglePlayerTouched;

-(IBAction) butStartMultiplayerTouched;

@end
