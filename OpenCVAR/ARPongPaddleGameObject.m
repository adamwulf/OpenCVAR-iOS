//
//  ARPongPaddleGameObject.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 01/02/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARPongPaddleGameObject.h"
#import "OGLMesh.h"

@interface ARPongPaddleGameObject(){
    
}

-(void) applyConstraints; 

@end

@implementation ARPongPaddleGameObject

- (id)init
{
    self = [super init];
    if (self) {
        OGLMesh *modelMesh = [[OGLMesh alloc] initCoords:PADDLE_MESH_DATA meshDataSize:sizeof(PADDLE_MESH_DATA) withVertexCount:sizeof(PADDLE_MESH_DATA) / sizeof(MeshTextureVertex)];
        
        self.mesh = modelMesh;
        
        [modelMesh release];

        self.visible = YES; 
    }
    return self;
}

-(void) update:(float) elapsedTime{
    if( _ttf > 0 ){
        
        [self applyConstraints];                
        
        [super update:elapsedTime];
    }
}

-(void) applyConstraints{
   
}

@end
