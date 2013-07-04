//
//  ARPongBaseGameOobject.h
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

typedef enum _ownerEnum{
    Owner_Undefined, 
    Owner_Local,
    Owner_Remote,
    Owner_AI
} Owner;

@interface ARPongBaseGameObject : OGLARModel

@property (nonatomic,readwrite) GLKVector3 position;

@property (nonatomic,readwrite) GLKVector3 rotation;

@property (nonatomic,readwrite) Owner owner;

@property (nonatomic,readonly) float left;

@property (nonatomic,readonly) float right;

@property (nonatomic,readonly) float front;

@property (nonatomic,readonly) float back;

/** set the model matrix based on position and rotation **/
-(void) updateModelMatrix;

@end
