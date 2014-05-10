//
//  AppDelegate.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 10/12/2012.
//  Copyright (c) 2012 We Make Play. All rights reserved.
//

#import "AppDelegate.h"

#import "HomeViewController.h"
#import "CalibrationViewController.h"
#import "CameraCaptureViewController.h"
#import "TrackerViewController.h"
#import "ARSceneViewController.h"
#import "ARPongSceneViewController.h"

@implementation AppDelegate

- (void)dealloc
{
    [_window release];
    self.currentController = nil;
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    
    [self navigateBackHome];    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - 
#pragma navigation methods 

-(void) navigateBackHome{
    
    HomeViewController *nextController = [[[HomeViewController alloc] initWithNibName:@"HomeVC" bundle:nil] autorelease];
    nextController.navDelegate = self; 
    self.window.rootViewController = nextController;
    self.currentController = nextController;
    
    [self.window makeKeyAndVisible];
}

-(void) navigateToARCalibrationController{
    CalibrationViewController *nextController = [[[CalibrationViewController alloc] initWithNibName:@"CalibrationViewController" bundle:nil] autorelease];
    nextController.navDelegate = self;
    self.window.rootViewController = nextController;
    self.currentController = nextController;
}

-(void) navigateToARCameraCaptureController{
    CameraCaptureViewController *nextController = [[[CameraCaptureViewController alloc] initWithNibName:@"CameraCaptureViewController" bundle:nil] autorelease];
    nextController.navDelegate = self;
    self.window.rootViewController = nextController;
    self.currentController = nextController;
}

-(void) navigateToARTrackerController{
    TrackerViewController *nextController = [[[TrackerViewController alloc] initWithNibName:@"TrackerViewController" bundle:nil] autorelease];
    nextController.navDelegate = self;
    self.window.rootViewController = nextController;
    self.currentController = nextController;
}

-(void) navigateToARSceneController{
    ARSceneViewController *nextController = [[[ARSceneViewController alloc] initWithNibName:@"ARSceneViewController" bundle:nil] autorelease];
    nextController.navDelegate = self;
    self.window.rootViewController = nextController;
    self.currentController = nextController;
}

-(void) navigateToARUFOSceneController{
    ARPongSceneViewController *nextController = [[[ARPongSceneViewController alloc] initWithNibName:@"ARPongSceneViewController" bundle:nil] autorelease];
    nextController.navDelegate = self;
    self.window.rootViewController = nextController;
    self.currentController = nextController;
}

@end
