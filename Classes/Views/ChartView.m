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
- (void)hideTideDetails;
- (NSDate*)midnight;
- (NSDate*)midnight:(NSDate*)date;

@property (assign) float xratio;
@property (assign) float yratio;
@property (assign) float yoffset;
@end

@implementation ChartView

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
        self.height = 234; // legacy default
        self.hoursToPlot = 24;
    }
    return self;
}

- (BOOL)isOpaque
{
    return YES;
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
    DLog(@"*** Drawing chart!");
    CGFloat chartBottom = self.frame.size.height;
    
	CGContextRef context = UIGraphicsGetCurrentContext();
					  
	_tide = [self.datasource tideDataToChart];
    
    NSArray *intervalsForDay = [_tide intervalsFromDate:[self.datasource day] forHours:self.hoursToPlot];
    if ([intervalsForDay count] == 0) {
        // we're in a bad state. maybe activated on a new day before model has been updated?
        return;
    }
    
    NSTimeInterval baseSeconds = [((SDTideInterval*)intervalsForDay[0]).time timeIntervalSince1970];
    
    NSArray *sunEvents = [_tide sunriseSunsetEvents];
    NSArray *sunPairs = [self pairRiseAndSetEvents:sunEvents riseEventType:sunrise setEventType:sunset];

    NSArray *moonEvents = [_tide moonriseMoonsetEvents];
    NSArray *moonPairs = [self pairRiseAndSetEvents:moonEvents riseEventType:moonrise setEventType:moonset];
	
	// 480 x 320 = 24hrs x amplitude + some margin
	float min = [self findLowestTide:_tide];
	float max = [self findHighestTide:_tide];
	
	float ymin = min - 1;
	float ymax = max + 1;
	self.yratio =  _height / (ymax - ymin);
	self.yoffset = (_height + ymin * self.yratio) + (chartBottom - _height);
	//DLog(@"yoffset = %0.4f", self.yoffset);
	
	float xmin = 0;
	float xmax = MINUTES_PER_HOUR * _hoursToPlot;
	//DLog(@"Frame size is: %0.1f x %0.1f", self.frame.size.width, self.frame.size.height);
    self.xratio = self.frame.size.width / xmax;
	//DLog(@"xratio = %0.4f",self.xratio);
    
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
    
    // draws the tide level curve
    for (SDTideInterval *tidePoint in intervalsForDay) {
		int minute = ([[tidePoint time] timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
        //DLog(@"Plotting interval: %@, min since midnight: %d",tidePoint.time, minute);
		if (minute == 0) {
			CGContextMoveToPoint(context, minute * self.xratio, self.yoffset - [tidePoint height] * self.yratio);
		} else {
			CGContextAddLineToPoint(context, (minute * self.xratio), self.yoffset - ([tidePoint height] * self.yratio));
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
	CGContextMoveToPoint(context, xmin, _yoffset);
	CGContextAddLineToPoint(context, xmax * _xratio, _yoffset);
	CGContextStrokePath(context);

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterFullStyle];
	self.dateLabel.text = [formatter stringFromDate:[self.datasource day]];
    DLog(@"*** Finished drawing chart. xratio=%f", self.xratio);
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
	unsigned unitflags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
	NSDateComponents *components = [gregorian components: unitflags fromDate: date];
	
	return [gregorian dateFromComponents:components];
}	

- (float)findLowestTide:(SDTide *)tide {	
	NSSortDescriptor *ascDescriptor = [[NSSortDescriptor alloc] initWithKey:@"height" ascending:YES];
	NSArray *descriptors = @[ascDescriptor];
	NSArray *ascResult = [[tide allIntervals] sortedArrayUsingDescriptors:descriptors];
	return [(SDTideInterval*)ascResult[0] height];
}

- (float)findHighestTide:(SDTide *)tide {
	NSSortDescriptor *descDescriptor = [[NSSortDescriptor alloc] initWithKey:@"height" ascending:NO];
	NSArray *descriptors = @[descDescriptor];
	NSArray *descResult = [[tide allIntervals] sortedArrayUsingDescriptors:descriptors];
	return [(SDTideInterval*)descResult[0] height];
}

@end
