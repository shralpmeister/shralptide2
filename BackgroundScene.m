//
//  BackgroundScene.m
//  ShralpTide2
//
//  Created by Michael Parlee on 12/28/13.
//
//

#import "BackgroundScene.h"

@implementation BackgroundScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        DLog(@"Background scene initialized");
        /* Setup your scene here */
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"background-gradient"];
        background.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
        
        [self addChild:background];
        
        NSString *bubblesPath = [[NSBundle mainBundle] pathForResource:@"Bubbles" ofType:@"sks"];
        SKEmitterNode *bubblesNode = [NSKeyedUnarchiver unarchiveObjectWithFile:bubblesPath];
        bubblesNode.position = CGPointMake(self.frame.size.width / 2, 0);
        
        const CGFloat HALF_DURATION = 20;
        const CGFloat MIN_ALPHA = 0.1;
        const CGFloat MAX_ALPHA = 0.2;
        const CGFloat ROT_ANGLE = 0.1;
        const CGFloat SCALE_FACTOR = 1.5;
        
        SKSpriteNode *lightRay = [[SKSpriteNode alloc] initWithImageNamed:@"lightray"];
        lightRay.anchorPoint = CGPointMake(0, 1);
        lightRay.position = CGPointMake(0, self.frame.size.height);
        lightRay.alpha = MIN_ALPHA;
        
        SKSpriteNode *lightRay2 = [[SKSpriteNode alloc] initWithImageNamed:@"lightray"];
        lightRay2.anchorPoint = CGPointMake(0, 1);
        lightRay2.position = CGPointMake(-10, self.frame.size.height);
        lightRay2.alpha = MIN_ALPHA;
        lightRay2.scale = 2.3;
        
        SKSpriteNode *lightRay3 = [[SKSpriteNode alloc] initWithImageNamed:@"lightray"];
        lightRay3.anchorPoint = CGPointMake(0, 1);
        lightRay3.position = CGPointMake(20, self.frame.size.height);
        lightRay3.alpha = MIN_ALPHA;
        lightRay3.scale = 1.8;
        
        SKAction *fadeIn = [SKAction fadeAlphaTo:MAX_ALPHA duration:HALF_DURATION];
        SKAction *scale1 = [SKAction scaleBy:SCALE_FACTOR duration:HALF_DURATION];
        SKAction *rot1 = [SKAction rotateByAngle:ROT_ANGLE duration:HALF_DURATION];
        SKAction *group1 = [SKAction group:@[fadeIn,rot1,scale1]];
        
        SKAction *rot2 = [SKAction rotateByAngle:-ROT_ANGLE duration:HALF_DURATION];
        SKAction *scale2 = [SKAction scaleBy:SCALE_FACTOR duration:HALF_DURATION];
        SKAction *fadeOut = [SKAction fadeAlphaTo:MIN_ALPHA duration:HALF_DURATION];
        SKAction *group2 = [SKAction group:@[rot2,scale2,fadeOut]];
        
        SKAction *resetScale = [SKAction scaleTo:1.0 duration:3];
        
        SKAction *sequence = [SKAction sequence:@[group1,group2,resetScale]];
        SKAction *loop = [SKAction repeatActionForever:sequence];
        
        SKAction *wait = [SKAction waitForDuration:7];
        SKAction *resetScale2 = [SKAction scaleTo:2.3 duration:3];
        SKAction *sequence2 = [SKAction sequence:@[wait,sequence,resetScale2]];
        SKAction *loop2 = [SKAction repeatActionForever:sequence2];
        
        SKAction *wait2 = [SKAction waitForDuration:4];
        SKAction *resetScale3 = [SKAction scaleTo:1.8 duration:3];
        SKAction *sequence3 = [SKAction sequence:@[wait2,sequence,resetScale3]];
        SKAction *loop3 = [SKAction repeatActionForever:sequence3];
        
        [lightRay runAction:loop];
        [lightRay2 runAction:loop2];
        [lightRay3 runAction:loop3];
        
        [self addChild:bubblesNode];
        [self addChild:lightRay];
        [self addChild:lightRay2];
        [self addChild:lightRay3];
    }
    return self;
}

@end
