//
//  SDTide.m
//  xtidelib
//
//  Created by Michael Parlee on 7/16/08.
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

#import "SDTide.h"
#import "SDTideInterval.h"
#import "SDTideEvent.h"
#import "NSDate+Day.h"

@interface SDTide(PrivateMethods)
- (int)findPreviousInterval:(int) minutesFromMidnight;
- (int)findNearestInterval:(int) minutesFromMidnight;
- (int)currentTimeInMinutes;
@end

@implementation SDTide

-(id)initWithTideStation:(NSString *)station StartDate: (NSDate*)start EndDate:(NSDate*)end Events:(NSArray*)events andIntervals:(NSArray*)tideIntervals
{
    if (self = [super init]) {
        NSAssert(start != nil, @"Start date must not be nil");
        NSAssert(end != nil, @"End date must not be nil");
        
        self.startTime = start;
        self.stopTime = end;
        self.intervals = tideIntervals;
        self.allEvents = events;
        self.stationName = station;
    }
    return self;
}

-(NSString*)shortLocationName {
	NSArray *parts = [self.stationName componentsSeparatedByString:@","];
	return parts[0];
}

-(CGPoint)nearestDataPointToCurrentTime
{
    return [self nearestDataPointForTime:[self currentTimeInMinutes]];
}

- (CGPoint)nearestDataPointForTime:(int) minutesFromMidnight {
	int nearestX = [self findNearestInterval:minutesFromMidnight];
	float nearestY = [self findTideForTime:nearestX];
	return CGPointMake((float)nearestX, nearestY);
}

- (SDTideStateRiseFall)tideDirectionForTime:(int) time {
	if ([self findTideForTime:[self findNearestInterval:time]] > [self findTideForTime:[self findPreviousInterval: time]]) {
		return SDTideStateRising;
	} else if ([self findTideForTime:[self findNearestInterval:time]] < [self findTideForTime:[self findPreviousInterval: time]]) {
		return SDTideStateFalling;
	} else {
		return SDTideStateUnknown;
	}
}

-(float)findTideForTime:(int) time {
	float height = 0.0;
	int basetime = 0;
	for (SDTideInterval *tidePoint in [self intervals]) {
		int minutesSinceMidnight = 0;
		if (basetime == 0) {
			basetime = (int)[[tidePoint time] timeIntervalSince1970];
		}
		minutesSinceMidnight = (int)([[tidePoint time] timeIntervalSince1970] - basetime) / 60;
		if (minutesSinceMidnight == time) {
			height = tidePoint.height;
            self.unitShort = tidePoint.units;
			return height;
		}
	}
	return height;
}

-(NSNumber*)nextEventIndex
{
	int count = 0;
	for (SDTideEvent *event in [self events]) {
		if ([[NSDate date] timeIntervalSince1970] < [[event eventTime] timeIntervalSince1970]) {
            self.unitShort = event.units;
			return @(count);
		}
		++count;
	}
	return nil;
}

-(NSArray*)events 
{
    NSPredicate *tideEventsOnly = [NSPredicate predicateWithFormat:@"(eventType == %d OR eventType == %d)", max, min];
    return [self.allEvents filteredArrayUsingPredicate:tideEventsOnly];
}

-(NSDictionary*)sunriseSunsetEventsForDay:(NSDate*)date
{
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    NSPredicate *sunEvents = [NSPredicate predicateWithFormat:@"(eventType == %d OR eventType == %d) AND eventTime BETWEEN %@", sunrise, sunset, @[[date startOfDay], [date endOfDay]]];
    NSArray* events = [self.allEvents filteredArrayUsingPredicate:sunEvents];
    for (SDTideEvent* event in events) {
        if (event.eventType == sunrise) {
            result[@"sunrise"] = event;
        } else {
            result[@"sunset"] = event;
        }
    }
    return [NSDictionary dictionaryWithDictionary:result];
}

-(NSDictionary*)moonriseMoonsetEventsForDay:(NSDate*)date
{
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    NSPredicate *sunEvents = [NSPredicate predicateWithFormat:@"(eventType == %d OR eventType == %d) AND eventTime BETWEEN %@", moonrise, moonset, @[[date startOfDay], [date endOfDay]]];
    NSArray* events = [self.allEvents filteredArrayUsingPredicate:sunEvents];
    for (SDTideEvent* event in events) {
        if (event.eventType == moonrise) {
            result[@"moonrise"] = event;
        } else {
            result[@"moonset"] = event;
        }
    }
    return [NSDictionary dictionaryWithDictionary:result];
}

-(NSArray*)eventsForDay:(NSDate*)date
{
    NSPredicate *daysEventsOnly = [NSPredicate predicateWithFormat:@"eventTime BETWEEN %@",@[[date startOfDay], [date endOfDay]]];
    return [[self events] filteredArrayUsingPredicate:daysEventsOnly];
}

-(NSArray*)intervalsForDay:(NSDate*)date
{
    NSPredicate *daysIntervalsOnly = [NSPredicate predicateWithFormat:@"time BETWEEN %@",@[[date startOfDay], [date endOfDay]]];
    return [self.intervals filteredArrayUsingPredicate:daysIntervalsOnly];
}

#pragma mark PrivateMethods

-(int)findPreviousInterval:(int) minutesFromMidnight {
	return [self findNearestInterval:minutesFromMidnight] - 15;
}

-(int)findNearestInterval:(int) minutesFromMidnight {
	int numIntervals = floor(minutesFromMidnight / 15);
	int remainder = minutesFromMidnight % 15;
	if (remainder >= 8) {
		++numIntervals;
	}
	return numIntervals * 15;
}

- (int)currentTimeInMinutes
{
	// The following shows the current time on the tide chart.  Need to make sure that it only shows on
	// the current day!
	NSDate *datestamp = [NSDate date];
	
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	unsigned unitflags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *components = [gregorian components: unitflags fromDate: datestamp];
	
	NSDate *midnight = [gregorian dateFromComponents:components];
	
    return ([datestamp timeIntervalSince1970] - [midnight timeIntervalSince1970]) / 60;
}

-(void)dealloc
{
	NSLog(@"Deallocating SDTide %@",self);
}

@end
