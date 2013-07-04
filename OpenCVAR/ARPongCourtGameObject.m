//
//  ARPongCourtGameObject.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 01/02/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARPongCourtGameObject.h"
#import "OGLMesh.h"

@implementation ARPongCourtGameObject

- (id)init
{
    self = [super init];
    if (self) {
        OGLMesh *modelMesh = [[OGLMesh alloc] initCoords:COURT_MESH_DATA meshDataSize:sizeof(COURT_MESH_DATA) withVertexCount:sizeof(COURT_MESH_DATA) / sizeof(MeshTextureVertex)];
        
        self.mesh = modelMesh;
        
        [modelMesh release];
        
        self.visible = YES;
    }
    return self;
}

@end
