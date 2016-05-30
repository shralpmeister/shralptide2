//
//  InteractiveChartView.m
//  ShralpTide2
//
//  Created by Michael Parlee on 11/2/13.
//
//

#import "InteractiveChartView.h"

#define CURSOR_TOP_GAP 40
#define CURSOR_LABEL_WIDTH 3

@interface InteractiveChartView ()

@property (nonatomic, strong) NSMutableDictionary *times;

@end

@implementation InteractiveChartView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
		self.times = [[NSMutableDictionary alloc] init];
        self.cursorView = [[CursorView alloc] initWithFrame:CGRectMake(0, CURSOR_TOP_GAP, CURSOR_LABEL_WIDTH, self.frame.size.width - CURSOR_TOP_GAP)];
    }
    return self;
}

- (int)currentTimeInMinutes {
	// The following shows the current time on the tide chart.  Need to make sure that it only shows on
	// the current day!
	NSDate *datestamp = [NSDate date];
	NSDate *midnight = [self midnight];
    
	if ([midnight compare:[self.datasource day]] == NSOrderedSame) {
		return ([datestamp timeIntervalSince1970] - [midnight timeIntervalSince1970]) / SECONDS_PER_MINUTE;
	} else {
		return -1;
	}
}

- (int)currentTimeOnChart
{
    return [self currentTimeInMinutes] * self.frame.size.width / MINUTES_PER_HOUR * self.hoursToPlot;
}

-(void)showTideForPoint:(CGPoint) point {
    NSDate *dateTime = [self dateTimeFromMinutes:point.x];
    [self.delegate displayHeight: point.y
                          atTime: dateTime
                  withUnitString: [[self.datasource tideDataToChart] unitShort]];
}

- (NSDate*)dateTimeFromMinutes:(int)minutesSinceMidnight
{
	NSString* key = [NSString stringWithFormat:@"%d",minutesSinceMidnight];
	if ((self.times)[key] != nil) {
		return (self.times)[key];
	} else {
		int hours = minutesSinceMidnight / 60;
		int minutes = minutesSinceMidnight % 60;
		
		NSCalendar *gregorian = [NSCalendar currentCalendar];
		NSDateComponents *components = [[NSDateComponents alloc] init];
		[components setHour:hours];
		[components setMinute:minutes];
		
		NSDate *time = [gregorian dateByAddingComponents:components toDate:[self.datasource day] options:0];
        return time;
	}
}

#pragma mark HandleTouch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    DLog(@"Touches began on chartview!");
    // We only support single touches, so anyObject retrieves just that touch from touches
    UITouch *touch = [touches anyObject];
    
    // Animate the first touch
    CGPoint touchPoint = [touch locationInView:self];
    CGPoint dataPoint = [[self.datasource tideDataToChart] nearestDataPointForTime:[self timeInMinutes:touchPoint.x]];
	CGPoint movePoint = CGPointMake(touchPoint.x, self.frame.size.height / 2 + CURSOR_TOP_GAP);
	
	if (self.cursorView.superview == nil) {
		[self addSubview:self.cursorView];
	}
	
    [self animateFirstTouchAtPoint:movePoint];
	[self showTideForPoint: [[self.datasource tideDataToChart] nearestDataPointForTime: [self timeInMinutes:touchPoint.x]]];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    CGPoint dataPoint = [[self.datasource tideDataToChart] nearestDataPointForTime:[self timeInMinutes:touchPoint.x]];
    CGPoint movePoint = CGPointMake(touchPoint.x, self.frame.size.height / 2 + CURSOR_TOP_GAP);
    self.cursorView.center = movePoint;
    [self showTideForPoint: dataPoint];
}

- (int)timeInMinutes:(CGFloat)xPosition
{
    return (xPosition / self.xratio);
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    DLog(@"Touches ended.");
    self.userInteractionEnabled = NO;
    [self animateCursorViewToCurrentTime];

	// if not the current day hide the cursor and tide details
	if (self.cursorView.center.x <= 0.0) {
		[self.cursorView removeFromSuperview];
	}
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//    DLog(@"Touches cancelled");
    /*
     To impose as little impact on the device as possible, simply set the cursor view's center and transformation to the original values.
     */
    self.cursorView.center = self.center;
    self.cursorView.transform = CGAffineTransformIdentity;
}

- (void)animateFirstTouchAtPoint:(CGPoint)touchPoint {
    
#define MOVE_ANIMATION_DURATION_SECONDS 0.15
    
    NSValue *touchPointValue = [NSValue valueWithCGPoint:touchPoint];
    [UIView beginAnimations:nil context:(__bridge void *)(touchPointValue)];
    [UIView setAnimationDuration:MOVE_ANIMATION_DURATION_SECONDS];
    CGPoint movePoint = CGPointMake(touchPoint.x, self.frame.size.height / 2 + CURSOR_TOP_GAP);
    self.cursorView.center = movePoint;
    [UIView commitAnimations];
}

- (void)animateCursorViewToCurrentTime {
    if (self.cursorView.superview == nil) {
		[self addSubview:self.cursorView];
	}
    
    // Bounces the placard back to the center
	
    CALayer *welcomeLayer = self.cursorView.layer;
    
    // Create a keyframe animation to follow a path back to the center
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    bounceAnimation.removedOnCompletion = NO;
    
    CGFloat animationDuration = 0.5;
	
    // Create the path for the bounces
    CGMutablePathRef thePath = CGPathCreateMutable();
    
    CGFloat midX = [self currentTimeInMinutes] * self.xratio;
    CGPoint dataPoint = [[self.datasource tideDataToChart] nearestDataPointForTime:[self timeInMinutes:midX]];
    CGFloat midY = self.frame.size.height / 2 + CURSOR_TOP_GAP;
    CGFloat originalOffsetX = self.cursorView.center.x - midX;
    CGFloat originalOffsetY = self.cursorView.center.y - midY;
    CGFloat offsetDivider = 10.0;
    
    BOOL stopBouncing = NO;
    
    // Start the path at the cursors's current location
    CGPathMoveToPoint(thePath, NULL, self.cursorView.center.x, self.cursorView.center.y);
    CGPathAddLineToPoint(thePath, NULL, midX, midY);
    
    // Add to the bounce path in decreasing excursions from the center
    while (stopBouncing != YES) {
        CGPathAddLineToPoint(thePath, NULL, midX + originalOffsetX/offsetDivider, midY + originalOffsetY/offsetDivider);
        CGPathAddLineToPoint(thePath, NULL, midX, midY);
		
        offsetDivider += 10;
        animationDuration += 1/offsetDivider;
        if ((fabs(originalOffsetX/offsetDivider) < 6)) {
            stopBouncing = YES;
        }
    }
    
    bounceAnimation.path = thePath;
    bounceAnimation.duration = animationDuration;
	
    
    // Create a basic animation to restore the size of the placard
    CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    transformAnimation.removedOnCompletion = YES;
    transformAnimation.duration = animationDuration;
    transformAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    
    
    // Create an animation group to combine the keyframe and basic animations
    CAAnimationGroup *theGroup = [CAAnimationGroup animation];
    
    // Set self as the delegate to allow for a callback to reenable user interaction
    theGroup.delegate = self;
    theGroup.duration = animationDuration;
    theGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    theGroup.animations = @[bounceAnimation, transformAnimation];
    
    
    // Add the animation group to the layer
    [welcomeLayer addAnimation:theGroup forKey:@"animatePlacardViewToCenter"];
    
    // Set the placard view's center and transformation to the original values in preparation for the end of the animation
    self.cursorView.center = CGPointMake(midX, midY);
    self.cursorView.transform = CGAffineTransformIdentity;
    
    CGPathRelease(thePath);
	
	[self showTideForPoint: [self.datasource.tideDataToChart nearestDataPointForTime:[self timeInMinutes:midX]]];
    [self.delegate interactionsEnded];
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    //Animation delegate method called when the animation's finished:
    // restore the transform and reenable user interaction
    //self.cursorView.transform = CGAffineTransformIdentity;
    self.userInteractionEnabled = YES;
}

@end
