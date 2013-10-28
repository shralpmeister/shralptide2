//
//  ChartView.m
//  ShralpTide
//
//  Created by Michael Parlee on 9/22/08.
//  Copyright 2009 Michael Parlee. All rights reserved.
/*
   This file is part of ShralpTide.

   ShralpTide is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   ShralpTide is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with ShralpTide.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "ChartView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+Day.h"

@interface ChartView ()
- (float)findLowestTide:(SDTide *)tide;
- (float)findHighestTide:(SDTide *)tide;
- (void)showTideForPoint:(CGPoint) point;
- (void)hideTideDetails;
- (NSDate*)midnight;
- (NSDate*)midnight:(NSDate*)date;
- (NSString*)timeInNativeFormatFromMinutes:(int)minutesSinceMidnight;
- (NSString*)timeIn24HourFormatFromMinutes:(int)minutesSinceMidnight;

@property (nonatomic, strong) NSMutableDictionary *times;
@property (assign) float xratio;
@end

@implementation ChartView

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		self.times = [[NSMutableDictionary alloc] init];
        self.height = 234; // legacy default
        self.hoursToPlot = 24;
    }
    return self;
}

- (NSDate*)endTime
{
    return [NSDate dateWithTimeIntervalSince1970:[[self.datasource day] timeIntervalSince1970] + (self.hoursToPlot * 60 * 60)];
}

- (NSArray*)pairRiseAndSetEvents:(NSArray*)events riseEventType:(SDTideState)riseType setEventType:(SDTideState)setType
{
    NSMutableArray *pairs = [[NSMutableArray alloc] init];
    NSDate *riseTime = nil;
    NSDate *setTime = nil;
    for (SDTideEvent *event in events) {
        if (event.eventType == riseType) {
            riseTime = event.eventTime;
            if ([event isEqual:[events lastObject]]) {
                setTime = self.endTime;
            }
        }
        if (event.eventType == setType) {
            if ([events indexOfObject:event] == 0) {
                riseTime = [self.datasource day];
            }
            setTime = event.eventTime;
        }
        if (riseTime && setTime) {
            [pairs addObject:@[riseTime,setTime]];
            riseTime = nil;
            setTime = nil;
        }
    }
    return [NSArray arrayWithArray:pairs];
}

-(void)drawRect:(CGRect)rect {

    CGFloat chartBottom = self.frame.size.height;
    
	CGContextRef context = UIGraphicsGetCurrentContext();
					  
	SDTide *tide = [self.datasource tideDataToChart];
    
    NSArray *intervalsForDay = [tide intervalsFromDate:[self.datasource day] forHours:self.hoursToPlot];
    
    NSTimeInterval baseSeconds = [((SDTideInterval*)intervalsForDay[0]).time timeIntervalSince1970];
    
    NSArray *sunEvents = [tide sunriseSunsetEvents];
    NSArray *sunPairs = [self pairRiseAndSetEvents:sunEvents riseEventType:sunrise setEventType:sunset];

    NSArray *moonEvents = [tide moonriseMoonsetEvents];
    NSArray *moonPairs = [self pairRiseAndSetEvents:moonEvents riseEventType:moonrise setEventType:moonset];
	
	// 480 x 320 = 24hrs x amplitude + some margin
	float min = [self findLowestTide:tide];
	float max = [self findHighestTide:tide];
	
	float ymin = min - 1;
	float ymax = max + 1;
	float yratio =  _height / (ymax - ymin);
	float yoffset = (_height + ymin * yratio) + (chartBottom - _height);
	NSLog(@"yoffset = %0.4f", yoffset);
	
	float xmin = 0;
	float xmax = MINUTES_PER_HOUR * _hoursToPlot;
	NSLog(@"Frame size is: %0.1f x %0.1f", self.frame.size.width, self.frame.size.height);
    self.xratio = self.frame.size.width / xmax;
	NSLog(@"xratio = %0.4f",self.xratio);
    
    // show daylight hours as light background
    CGContextSetRGBFillColor(context, 0.04, 0.27, 0.61, 1.0);
    
    for (NSArray *riseSet in sunPairs) {
        int sunriseMinutes = ([riseSet[0] timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
        int sunsetMinutes = ([riseSet[1] timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
        CGContextFillRect(context, CGRectMake(sunriseMinutes * self.xratio, 0, sunsetMinutes * self.xratio - sunriseMinutes * self.xratio, chartBottom));
    }
    
    CGContextSetRGBFillColor(context, 1, 1, 1, 0.2);
    for (NSArray *riseSet in moonPairs) {
        int moonriseMinutes = ([riseSet[0] timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
        int moonsetMinutes = ([riseSet[1] timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
        CGContextFillRect(context, CGRectMake(moonriseMinutes * self.xratio, 0, moonsetMinutes * self.xratio - moonriseMinutes * self.xratio, chartBottom));
    }
//    if (moonriseMinutes < moonsetMinutes) {
//        CGContextFillRect(context, CGRectMake(moonriseMinutes * self.xratio, 0, moonsetMinutes * self.xratio - moonriseMinutes * self.xratio, chartBottom));
//    } else {
//        CGContextFillRect(context, CGRectMake(0, 0, moonsetMinutes * self.xratio, chartBottom));
//        CGContextFillRect(context, CGRectMake(moonriseMinutes * self.xratio, 0, self.frame.size.width, chartBottom));
//    }
    
    // draw indicators in the header for astronomical events
//    float sunriseX = sunriseMinutes * self.xratio - self.sunriseIcon.image.size.width / 2;
//    float sunsetX = sunsetMinutes * self.xratio - self.sunsetIcon.image.size.width / 2;
//    float moonriseX = moonriseMinutes * self.xratio - self.moonriseIcon.image.size.width / 2;
//    float moonsetX = moonsetMinutes * self.xratio - self.moonsetIcon.image.size.width / 2;
//    
//    if (moonsetX >= self.headerView.frame.size.width - self.moonsetIcon.image.size.width) {
//        moonsetX -= self.moonsetIcon.image.size.width;
//    } else if (moonsetX == 0) {
//        moonsetX += 1;
//    }
//    
//    self.sunriseIcon.frame = CGRectMake(sunriseX, self.headerView.frame.size.height - self.sunriseIcon.image.size.height * 1.1, self.sunriseIcon.image.size.width, self.sunriseIcon.image.size.height);
//    self.sunsetIcon.frame = CGRectMake(sunsetX, self.headerView.frame.size.height - self.sunsetIcon.image.size.height * 1.1, self.sunsetIcon.image.size.width, self.sunsetIcon.image.size.height);
//    self.moonriseIcon.frame = CGRectMake(moonriseX, self.headerView.frame.size.height - self.moonriseIcon.image.size.height * 1.1, self.moonriseIcon.image.size.width, self.moonriseIcon.image.size.height);
//    self.moonsetIcon.frame = CGRectMake(moonsetX, self.headerView.frame.size.height - self.moonriseIcon.image.size.height * 1.1, self.moonsetIcon.image.size.width, self.moonsetIcon.image.size.height);
//    
//    [self.headerView addSubview:self.moonriseIcon];
//    [self.headerView addSubview:self.moonsetIcon];
//    [self.headerView addSubview:self.sunriseIcon];
//    [self.headerView addSubview:self.sunsetIcon];
    
    // draws the tide level curve
    for (SDTideInterval *tidePoint in intervalsForDay) {
		int minute = ([[tidePoint time] timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
        NSLog(@"Plotting interval: %@, min since midnight: %d",tidePoint.time, minute);
		if (minute == 0) {
			CGContextMoveToPoint(context, minute * self.xratio, yoffset - [tidePoint height] * yratio);
		} else {
			CGContextAddLineToPoint(context, (minute * self.xratio), yoffset - ([tidePoint height] * yratio));
		}
	}
	
    // closes the path so that it can be filled.
    int lastMinute = ([((SDTideInterval*)[intervalsForDay lastObject]).time timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
	CGContextAddLineToPoint(context, lastMinute*self.xratio, chartBottom);
	CGContextAddLineToPoint(context, 0, chartBottom);
	
    // fill in the tide level curve
	CGContextSetRGBFillColor(context, 0.0, 1.0, 1.0, 0.7);
	CGContextFillPath(context);
    
    // Drawing with a white stroke color
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    
    // draws the zero height line
    CGContextSetLineWidth(context,2.0);
	CGContextMoveToPoint(context, xmin, yoffset);
	CGContextAddLineToPoint(context, xmax * self.xratio, yoffset);
	CGContextStrokePath(context);
			
	self.cursorView.center = CGPointMake([self currentTimeInMinutes] * self.xratio, chartBottom / 2);
	if (self.cursorView.center.x > 0) {
		NSLog(@"min: %0.1f, max: %0.1f",min,max);
		[self addSubview:self.cursorView];
		[self insertSubview:self.cursorView belowSubview: self.headerView];
		[self showTideForPoint:[tide nearestDataPointForTime:floor(self.cursorView.center.x / self.xratio)]];	
	} else {
		[self hideTideDetails];
	}


	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterFullStyle];
	self.dateLabel.text = [formatter stringFromDate:[self.datasource day]];
}

-(void)showTideForPoint:(CGPoint) point {
	self.valueLabel.text = [NSString stringWithFormat:@"%0.2f %@ @ %@",point.y, [[self.datasource tideDataToChart] unitShort], [self timeInNativeFormatFromMinutes: (int)point.x]];
}

-(void)hideTideDetails
{
	self.valueLabel.text = @"";
}
                                           
- (NSDate*)midnight {
    return [self midnight: [NSDate date]];
}

- (NSDate*)midnight: (NSDate*)date {
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	unsigned unitflags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *components = [gregorian components: unitflags fromDate: date];
	
	return [gregorian dateFromComponents:components];
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
    return [self currentTimeInMinutes] * self.frame.size.width / MINUTES_PER_HOUR * _hoursToPlot;
}

- (NSString*)timeInNativeFormatFromMinutes:(int)minutesSinceMidnight {
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
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setTimeStyle:NSDateFormatterShortStyle];
		NSString *timeString = [formatter stringFromDate:time];
		
		(self.times)[key] = timeString;
		return timeString;
	}
}

- (NSString*)timeIn24HourFormatFromMinutes:(int)minutesSinceMidnight {
	int hours = minutesSinceMidnight / 60;
	int minutes = minutesSinceMidnight % 60;
	
	return [NSString stringWithFormat:@"%02d%02d",hours,minutes];
}

- (float)findLowestTide:(SDTide *)tide {	
	NSSortDescriptor *ascDescriptor = [[NSSortDescriptor alloc] initWithKey:@"height" ascending:YES];
	NSArray *descriptors = @[ascDescriptor];
	NSArray *ascResult = [[tide intervals] sortedArrayUsingDescriptors:descriptors];
	return [(SDTideInterval*)ascResult[0] height];
}

- (float)findHighestTide:(SDTide *)tide {
	NSSortDescriptor *descDescriptor = [[NSSortDescriptor alloc] initWithKey:@"height" ascending:NO];
	NSArray *descriptors = @[descDescriptor];
	NSArray *descResult = [[tide intervals] sortedArrayUsingDescriptors:descriptors];
	return [(SDTideInterval*)descResult[0] height];
}

#pragma mark HandleTouch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // We only support single touches, so anyObject retrieves just that touch from touches
    UITouch *touch = [touches anyObject];
    
    // Animate the first touch
    CGPoint touchPoint = [touch locationInView:self];
	CGPoint movePoint = CGPointMake(touchPoint.x, 150);
	
	if (self.cursorView.superview == nil) {
		[self addSubview:self.cursorView];
		[self insertSubview:self.cursorView belowSubview: self.headerView];
	}
	
    [self animateFirstTouchAtPoint:movePoint];
	[self showTideForPoint: [[self.datasource tideDataToChart] nearestDataPointForTime: (touchPoint.x + (self.datasource.page * self.frame.size.width)) / self.xratio]];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
	
    CGPoint location = [touch locationInView:self];
    self.cursorView.center = CGPointMake(location.x, 150);
	[self showTideForPoint: [[self.datasource tideDataToChart] nearestDataPointForTime:(location.x + (self.datasource.page * self.frame.size.width)) / self.xratio]];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.userInteractionEnabled = NO;
    [self animateCursorViewToCurrentTime];
	
	// if not the current day hide the cursor and tide details
	if (self.cursorView.center.x <= 0.0) {
		[self.cursorView removeFromSuperview];
		[self hideTideDetails];
	}
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
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
    self.cursorView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.cursorView.center = [touchPointValue CGPointValue];
    [UIView commitAnimations];
}

- (void)animateCursorViewToCurrentTime {
    
    // Bounces the placard back to the center
	
    CALayer *welcomeLayer = self.cursorView.layer;
    
    // Create a keyframe animation to follow a path back to the center
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    bounceAnimation.removedOnCompletion = NO;
    
    CGFloat animationDuration = 0.5;
	
    
    // Create the path for the bounces
    CGMutablePathRef thePath = CGPathCreateMutable();
    
    CGFloat midX = [self currentTimeInMinutes] * self.xratio;
    CGFloat midY = 160.0;
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
        if ((abs(originalOffsetX/offsetDivider) < 6)) {
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
	
	[self showTideForPoint: [self.datasource.tideDataToChart nearestDataPointForTime:(midX + self.datasource.page * self.frame.size.width) / self.xratio]];
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    //Animation delegate method called when the animation's finished:
    // restore the transform and reenable user interaction
    self.cursorView.transform = CGAffineTransformIdentity;
    self.userInteractionEnabled = YES;
}

@end
