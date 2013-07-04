//
//  AppDelegate.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 10/12/2012.
//  Copyright (c) 2012 We Make Play. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IAppNavigation.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, IAppNavigation>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UIViewController *currentController;

@end
