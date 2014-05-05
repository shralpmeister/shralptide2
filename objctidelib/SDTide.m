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

- (CGPoint)nearestDataPointForTime:(NSInteger) minutesFromMidnight {
	NSInteger nearestX = [NSDate findNearestInterval:minutesFromMidnight];
	float nearestY = [self findTideForTime:nearestX];
	return CGPointMake((float)nearestX, nearestY);
}

- (SDTideStateRiseFall)tideDirection
{
    NSInteger time = [self currentTimeInMinutes];
	return [self tideDirectionForTime:time];
}

- (SDTideStateRiseFall)tideDirectionForTime:(NSInteger) time {
	if ([self findTideForTime:[NSDate findNearestInterval:time]] > [self findTideForTime:[NSDate findPreviousInterval: time]]) {
		return SDTideStateRising;
	} else if ([self findTideForTime:[NSDate findNearestInterval:time]] < [self findTideForTime:[NSDate findPreviousInterval: time]]) {
		return SDTideStateFalling;
	} else {
		return SDTideStateUnknown;
	}
}

-(float)findTideForTime:(NSInteger) time {
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

-(NSArray*)sunriseSunsetEvents
{
    NSPredicate *sunEvents = [NSPredicate predicateWithFormat:@"eventType == %d OR eventType == %d", sunrise, sunset];
    return [self.allEvents filteredArrayUsingPredicate:sunEvents];
}

-(NSArray*)moonriseMoonsetEvents
{
    NSPredicate *sunEvents = [NSPredicate predicateWithFormat:@"eventType == %d OR eventType == %d", moonrise, moonset];
    return [self.allEvents filteredArrayUsingPredicate:sunEvents];
}

-(NSArray*)sunAndMoonEvents
{
    NSPredicate *events = [NSPredicate predicateWithFormat:@"eventType in %@", @[@(moonrise), @(moonset), @(sunrise), @(sunset)]];
    return [self.allEvents filteredArrayUsingPredicate:events];
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

- (NSArray*)intervalsFromDate:(NSDate*)fromDate forHours:(NSInteger)hours
{
    NSInteger nearestFromInterval = [NSDate findNearestInterval:[fromDate timeInMinutesSinceMidnight]];
    NSDate *fromIntervalDate = [[fromDate startOfDay] dateByAddingTimeInterval:nearestFromInterval * 60];
    NSDate *toDate = [fromIntervalDate dateByAddingTimeInterval:hours * 60 * 60];
    NSPredicate *timeRange = [NSPredicate predicateWithFormat:@"time BETWEEN %@",@[ fromIntervalDate, toDate]];
    return [self.intervals filteredArrayUsingPredicate:timeRange];
}

+ (SDTide*)tideByCombiningTides:(NSArray*)tides
{
    if (tides == nil) {
        NSException* myException = [NSException
                                    exceptionWithName:@"InvalidArgumentException"
                                    reason:@"Tides array cannot be nil."
                                    userInfo:nil];
        @throw myException;
    }
    
    SDTide *combinedTide = [[SDTide alloc] init];
    SDTide *firstTide = (SDTide*)[tides firstObject];
    SDTide *lastTide = (SDTide*)[tides lastObject];
    combinedTide.stationName = firstTide.stationName;
    combinedTide.startTime = firstTide.startTime;
    combinedTide.stopTime = lastTide.stopTime;
    combinedTide.unitLong = firstTide.unitLong;
    combinedTide.unitShort = firstTide.unitShort;
    NSSet *allEventsSet = [NSSet set];
    NSSet *intervalsSet = [NSSet set];
    NSTimeInterval lastIntervalTime = 0;
    for (SDTide* tide in tides) {
        SDTideInterval *nextInterval = (SDTideInterval*)[tide.intervals firstObject];
        NSTimeInterval nextIntervalTime = [nextInterval.time timeIntervalSince1970];
        if (![tide.stationName isEqualToString:combinedTide.stationName] || (lastIntervalTime > 0 && !(nextIntervalTime - lastIntervalTime == 0))) {
            NSException* myException = [NSException
                                        exceptionWithName:@"InvalidArgumentException"
                                        reason:@"Tides must be consecutive and for the same location."
                                        userInfo:nil];
            @throw myException;
        }
        allEventsSet = [allEventsSet setByAddingObjectsFromArray:tide.allEvents];
        intervalsSet = [intervalsSet setByAddingObjectsFromArray:tide.intervals];
        lastIntervalTime = [((SDTideInterval*)[tide.intervals lastObject]).time timeIntervalSince1970];
    }
    
    NSSortDescriptor *eventTimeDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"eventTime" ascending:YES];
    combinedTide.allEvents = [[allEventsSet allObjects] sortedArrayUsingDescriptors:@[eventTimeDescriptor]];
    
    NSSortDescriptor *intervalTimeDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES];
    combinedTide.intervals = [[intervalsSet allObjects] sortedArrayUsingDescriptors:@[intervalTimeDescriptor]];

    return combinedTide;
}

- (NSString*)description
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    return [NSString stringWithFormat:@"Location: %@, startDate: %@, no.events: %lu, no.intervals:%lu", _stationName,
            [formatter stringFromDate:_startTime], (unsigned long)[self.events count], (unsigned long
)[self.intervals count]];
}

#pragma mark PrivateMethods

- (NSInteger)currentTimeInMinutes
{
    return [[NSDate date] timeInMinutesSinceMidnight];
}

-(void)dealloc
{
	DLog(@"Deallocating SDTide %@",self);
}

@end
