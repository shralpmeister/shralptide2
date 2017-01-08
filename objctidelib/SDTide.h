//
//  SDTide.h
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

#import <CoreGraphics/CoreGraphics.h>
#import "SDTideStationData.h"
#import <Foundation/Foundation.h>
#import "SDTideInterval.h"

typedef NS_ENUM(NSInteger, SDTideStateRiseFall) {
    SDTideStateRising,
    SDTideStateFalling,
    SDTideStateUnknown,
};

@interface SDTide : NSObject

- (id)initWithTideStation:(NSString *)station StartDate: (NSDate*)start EndDate:(NSDate*)end Events:(NSArray*)tideEvents andIntervals:(NSArray*)tideIntervals;
- (NSString*)shortLocationName;
- (float)findTideForTime:(NSInteger) time;
- (SDTideStateRiseFall)tideDirectionForTime:(NSInteger) time;
- (SDTideInterval*)findTideIntervalForTime:(NSInteger) time;
- (CGPoint)nearestDataPointForTime:(NSInteger) minutesFromMidnight;
- (CGPoint)nearestDataPointToCurrentTime;
- (NSNumber*)nextEventIndex;
- (NSArray*)events; // all tide events (only tide events)
- (NSArray*)eventsForDay:(NSDate*)date;
- (NSArray*)intervalsForDay:(NSDate*)date;

- (NSDictionary*)sunriseSunsetEventsForDay:(NSDate*)date;
- (NSDictionary*)moonriseMoonsetEventsForDay:(NSDate*)date;
- (NSArray*)sunriseSunsetEvents;
- (NSArray*)moonriseMoonsetEvents;
- (NSArray*)sunAndMoonEvents;

- (SDTideStateRiseFall)tideDirection;
- (NSInteger)currentTimeInMinutes;
- (NSArray*)intervalsFromDate:(NSDate*)fromDate forHours:(NSInteger)hours;
+ (SDTide*)tideByCombiningTides:(NSArray*)tides;

-(NSNumber*)highestTide;
-(NSNumber*)lowestTide;

- (BOOL)isEqualToTide:(SDTide*)other;

@property (nonatomic,strong) NSDate *startTime;
@property (nonatomic,strong) NSDate *stopTime;
@property (nonatomic,strong) NSArray *allEvents;
@property (nonatomic,strong) NSArray *allIntervals;
@property (nonatomic,copy) NSString *stationName;
@property (nonatomic,copy) NSString *unitLong;
@property (nonatomic,copy) NSString *unitShort;
@end
