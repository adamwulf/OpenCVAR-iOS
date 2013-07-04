//
//  ARPongBallGameObject.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 03/02/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARPongBallGameObject.h"
#import "OGLMesh.h"

@implementation ARPongBallGameObject

@synthesize velocity;

- (id)init
{
    self = [super init];
    if (self) {
        OGLMesh *modelMesh = [[OGLMesh alloc] initCoords:BALL_MESH_DATA meshDataSize:sizeof(BALL_MESH_DATA) withVertexCount:sizeof(BALL_MESH_DATA) / sizeof(MeshTextureVertex)];
        
        self.mesh = modelMesh;
        
        [modelMesh release];
        
        self.visible = YES;
        
        self.velocity = GLKVector3Make(0, 0, 0);
    }
    return self;
}

-(void) update:(float)elapsedTime{
    if( self.ttf > 0 ){
        
        // apply velocity
        self.position = GLKVector3Add(self.position, GLKVector3MultiplyScalar(self.velocity, elapsedTime));
        
        [super update:elapsedTime];
    }
}

@end
