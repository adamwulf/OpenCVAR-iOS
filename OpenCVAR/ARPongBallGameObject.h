//
//  ARPongBallGameObject.h
//  OpenCVAR
//
//  Created by Joshua Newnham on 03/02/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "OGLModel.h"
#import "OGLARModel.h"
#import "OGLMeshData.h"
#import "ARPongBaseGameObject.h"

@interface ARPongBallGameObject : ARPongBaseGameObject

@property (nonatomic, readwrite) GLKVector3 velocity; 

@end
