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
#import <Foundation/Foundation.h>
#import "SDTideStationData.h"
#import "SDTideInterval.h"
#import "SDTideEvent.h"

typedef NS_ENUM(NSInteger, SDTideStateRiseFall) {
    SDTideStateRising,
    SDTideStateFalling,
    SDTideStateUnknown,
};

@interface SDTide : NSObject

- (instancetype)initWithTideStation:(NSString *)station StartDate: (NSDate*)start EndDate:(NSDate*)end Events:(NSArray<SDTideEvent *> *)tideEvents andIntervals:(NSArray<SDTideInterval *> *)tideIntervals;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *shortLocationName;
- (float)findTideForTime:(NSInteger) time;
- (SDTideStateRiseFall)tideDirectionForTime:(NSInteger) time;
- (SDTideInterval*)findTideIntervalForTime:(NSInteger) time;
- (CGPoint)nearestDataPointForTime:(NSInteger) minutesFromMidnight;
@property (NS_NONATOMIC_IOSONLY, readonly) CGPoint nearestDataPointToCurrentTime;
@property (readonly) int nextEventIndex;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<SDTideEvent*> *events; // all tide events (only tide events)
- (NSArray<SDTideEvent*>*)eventsForDay:(NSDate*)date;
- (NSArray<SDTideInterval*>*)intervalsForDay:(NSDate*)date;

- (NSDictionary<NSString*, SDTideEvent*>*)sunriseSunsetEventsForDay:(NSDate*)date;
- (NSDictionary<NSString*, SDTideEvent*>*)moonriseMoonsetEventsForDay:(NSDate*)date;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<SDTideEvent*> *sunriseSunsetEvents;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<SDTideEvent*> *moonriseMoonsetEvents;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<SDTideEvent*> *sunAndMoonEvents;

@property (NS_NONATOMIC_IOSONLY, readonly) SDTideStateRiseFall tideDirection;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger currentTimeInMinutes;
- (NSArray<SDTideInterval*>*)intervalsFromDate:(NSDate*)fromDate forHours:(NSInteger)hours;
+ (SDTide*)tideByCombiningTides:(NSArray*)tides;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumber *highestTide;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumber *lowestTide;

- (BOOL)isEqualToTide:(SDTide*)other;

@property (nonatomic,strong) NSDate *startTime;
@property (nonatomic,strong) NSDate *stopTime;
@property (nonatomic,strong) NSArray<SDTideEvent*> *allEvents;
@property (nonatomic,strong) NSArray<SDTideInterval*> *allIntervals;
@property (nonatomic,copy) NSString *stationName;
@property (nonatomic,copy) NSString *unitLong;
@property (nonatomic,copy) NSString *unitShort;
@end
