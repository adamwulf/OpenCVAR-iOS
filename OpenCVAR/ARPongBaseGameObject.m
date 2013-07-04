//
//  ARPongBaseGameOobject.m
//  OpenCVAR
//
//  Created by Joshua Newnham on 03/02/2013.
//  Copyright (c) 2013 We Make Play. All rights reserved.
//

#import "ARPongBaseGameObject.h"

@implementation ARPongBaseGameObject

@synthesize position;
@synthesize rotation;
@synthesize owner; 

- (id)init
{
    self = [super init];
    if (self) {;
        
        self.position = GLKVector3Make(0.0f, 0.0f, 0.0f);
        self.rotation = GLKVector3Make(0.0f, 0.0f, 0.0f);
        
        [self updateModelMatrix];
    }
    return self;
}

-(void) update:(float) elapsedTime{
    if( _ttf > 0 ){
        [super update:elapsedTime];
        [self updateModelMatrix];
    }
}

-(void) updateModelMatrix{
    GLKMatrix4 newModelMatrix = GLKMatrix4MakeTranslation(self.position.x, self.position.y, self.position.z);
    
    // rotation
    newModelMatrix = GLKMatrix4Rotate(newModelMatrix, self.rotation.x, 1.0f, 0.0f, 0.0f);
    newModelMatrix = GLKMatrix4Rotate(newModelMatrix, self.rotation.y, 0.0f, 1.0f, 0.0f);
    newModelMatrix = GLKMatrix4Rotate(newModelMatrix, self.rotation.z, 0.0f, 0.0f, 1.0f);
    
    self.modelMatrix = newModelMatrix;
}

#pragma mark - 
#pragma mark properties 

-(float) left{
    return self.position.x - self.mesh.modelSize.x / 2;
}

-(float) right{
    return self.position.x + self.mesh.modelSize.x / 2;
}

-(float) front{
    return self.position.z + self.mesh.modelSize.z / 2;
}

-(float) back{
    return self.position.z - self.mesh.modelSize.z / 2;
}

@end
