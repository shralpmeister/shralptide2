//
//  SDTideFactory.mm
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

#include "common.hh"

#import <CoreData/CoreData.h>

#import "SDTideFactory.h"
#import "SDTide.h"
#import "SDTideStationData.h"
#import "NSDate+Day.h"

static NSArray* tideEventsForLocation(const Dstr &name, Interval step, Timestamp start, Timestamp end, Units::PredictionUnits units);
static NSArray* rawEventsForLocation(const Dstr &name, Interval step, Timestamp start, Timestamp end, Units::PredictionUnits units);
static SDTideState cppEventEnumToObjCEventEnum(TideEvent event);
static void setHarmonicsFilePaths();

@interface SDTideFactory()
+(NSDate*)addDays:(int)n toDate:(NSDate*)date;
@end

@implementation SDTideFactory

+(NSDate*)addDays:(int)n toDate:(NSDate*)date
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = n;
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    return [cal dateByAddingComponents: dayComponent toDate: date options: 0];
}


+(SDTide*)todaysTidesForStationName:(NSString*)name withUnits:(SDTideUnitsPref)units
{
    return [SDTideFactory tidesForStationName:name withInterval:900 forDays:1 withUnits:units][0];
}

+(NSArray<SDTide*>*)tidesForStationName:(NSString *)name forDays:(long)days withUnits:(SDTideUnitsPref)units
{
    return [SDTideFactory tidesForStationName:name withInterval:900 forDays:days withUnits:units];
}

+(NSArray<SDTide*>*)tidesForStationName:(NSString*)name withInterval:(long)interval forDays:(long)days withUnits:(SDTideUnitsPref)units
{
    NSDate *now = [NSDate date];
    return [SDTideFactory tidesForStationName:name withInterval:interval forDays:days withUnits:units fromDate:now];
}

+(NSArray<SDTide*>*)tidesForStationName:(NSString *)name withInterval:(long)interval forDays:(long)days withUnits:(SDTideUnitsPref)units fromDate:(NSDate*)date {
    NSMutableArray<SDTide*> *tideCollection = [[NSMutableArray alloc] init];
    
    for (int i=0; i < days; i++) {
        NSDate *day = [self addDays:i toDate: date];
        SDTide* tidy = [SDTideFactory tideForStationName:name withInterval:interval fromDate:[day startOfDay] toDate:[day endOfDay] withUnits: units];
        [tideCollection addObject:tidy];
    }
    
    NSArray<SDTide*> *result = [NSArray arrayWithArray:tideCollection];
    return result;
}

+ (SDTide*)tidesForStationName:(NSString*)name fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate withUnits:(SDTideUnitsPref)units
{
    return [SDTideFactory tideForStationName:name withInterval:900 fromDate:fromDate toDate:toDate withUnits: units];
}

+ (SDTide*)tideForStationName:(NSString*)name withInterval:(long)interval fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate withUnits:(SDTideUnitsPref)unitPref
{
    @synchronized([SDTideFactory class]) {
        srand ((unsigned)time (NULL));
        Global::initCodeset();
        Global::settings.fixUpDeprecatedSettings();
        
        Units::PredictionUnits units = unitPref == METRIC ? Units::meters : Units::feet;
        
        Dstr location ([name UTF8String]);
        
        if (![fromDate isEqualToDate:[fromDate startOfDay]]) {
            fromDate = [[fromDate startOfDay] dateByAddingTimeInterval: [NSDate findNearestInterval:[fromDate timeInMinutesSinceMidnight]] * 60];
        }
        
        Timestamp startTime = (time_t)[fromDate timeIntervalSince1970];
        Timestamp endTime = (time_t)[toDate timeIntervalSince1970] + 1;
        
        NSArray *events = tideEventsForLocation(location, Interval (interval), startTime, endTime, units);
        
        NSArray *intervals = nil;
        if (interval > 0) {
            intervals = rawEventsForLocation(location, Interval (interval), startTime, endTime, units);
        } else {
            intervals = @[];
        }
        
        SDTideEvent *eventZero = nil;
        for (SDTideEvent *event in events) {
            if ([event eventType] == max || [event eventType] == min) {
                eventZero = event;
                break;
            }
        }
        
        SDTide *tide = [[SDTide alloc] init];
        tide.stationName = name;
        tide.startTime = [NSDate dateWithTimeIntervalSince1970:startTime.timet()];
        tide.stopTime = [NSDate dateWithTimeIntervalSince1970:endTime.timet()];
        tide.allIntervals = intervals;
        tide.allEvents = events;
        tide.unitLong = nil;
        tide.unitShort = eventZero.units;
        
        return tide;
    }
}

@end

static NSArray* tideEventsForLocation(const Dstr &name, Interval step, Timestamp start, Timestamp end, Units::PredictionUnits units) 
{
    if (!getenv("HFILE_PATH")) {
        setHarmonicsFilePaths();
    }
    NSMutableArray* tideEvents = [NSMutableArray array];
    const StationRef *sr (Global::stationIndex().getStationRefByName(name));
    if (sr) {
        std::shared_ptr<Station> station (sr->load());
        station->setUnits(units);
        station->step = step;
        
        TideEventsOrganizer organizer = station->tideEventsOrganizer(start,end);
        TideEventsIterator it = organizer.begin();
        while (it != organizer.end()) {
            TideEvent event = it->second;
            SDTideEvent *objcEvent = [[SDTideEvent alloc] init];
            objcEvent.eventTime = [NSDate dateWithTimeIntervalSince1970:event.eventTime.timet()];
            objcEvent.eventType = cppEventEnumToObjCEventEnum(event);
            
            if (!event.isSunMoonEvent()) {
                objcEvent.eventHeight = (float)event.eventLevel.val();
                constString unitsCString = Units::shortName(station->predictUnits());
                objcEvent.units = @(unitsCString);
            }
            
            [tideEvents addObject:objcEvent];
            ++it;
        }
    }
    return tideEvents;
}

static SDTideState cppEventEnumToObjCEventEnum(TideEvent event) {
    switch (event.eventType) {
        case TideEvent::sunset:
            return sunset;
        case TideEvent::sunrise:
            return sunrise;
        case TideEvent::moonrise:
            return moonrise;
        case TideEvent::moonset:
            return moonset;
        case TideEvent::firstquarter:
            return firstquarter;
        case TideEvent::lastquarter:
            return lastquarter;
        case TideEvent::newmoon:
            return newmoon;
        case TideEvent::fullmoon:
            return fullmoon;
        case TideEvent::min:
            return min;
        case TideEvent::max:
            return max;
        case TideEvent::markfall:
            return markfall;
        case TideEvent::markrise:
            return markrise;
        case TideEvent::slackfall:
            return slackfall;
        case TideEvent::slackrise:
            return slackrise;
        default:
            return min;
    }
}

static NSArray* rawEventsForLocation(const Dstr &name, Interval step, Timestamp startTime, Timestamp endTime, Units::PredictionUnits units) {
    if (!getenv("HFILE_PATH")) {
        setHarmonicsFilePaths();
    }
    NSMutableArray *intervals = [NSMutableArray array];
    const StationRef *sr (Global::stationIndex().getStationRefByName(name));
    if (sr) {
        std::shared_ptr<Station> station (sr->load());
        station->setUnits(units);
        station->step = step;
        
        TideEventsOrganizer organizer;
        station->predictRawEvents (startTime, endTime, organizer);
        TideEventsIterator it = organizer.begin();
        while (it != organizer.end()) {
            TideEvent event = it->second;
            SDTideInterval *interval = [[SDTideInterval alloc] init];
            interval.time = [NSDate dateWithTimeIntervalSince1970:event.eventTime.timet()];
            interval.height = (float)event.eventLevel.val();
            constString unitsCString = Units::shortName(station->predictUnits());
            interval.units = @(unitsCString);
            
            [intervals addObject:interval];
            
            ++it;
        }
    }
    return intervals;
}

static void setHarmonicsFilePaths() {
    // Load the tide station data
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.shralpsoftware.ShralpTideFramework"];
    NSMutableString *pathBuilder = [[NSMutableString alloc] init];
    [pathBuilder appendString:[bundle pathForResource:@"harmonics-20040614-wxtide" ofType:@"tcd"]];
    [pathBuilder appendString:@":"];
    [pathBuilder appendString:[bundle pathForResource:@"harmonics-dwf-20081228-free" ofType:@"tcd"]];
    [pathBuilder appendString:@":"];
    [pathBuilder appendString:[bundle pathForResource:@"harmonics-dwf-20081228-nonfree" ofType:@"tcd"]];
    setenv("HFILE_PATH",[pathBuilder cStringUsingEncoding:NSUTF8StringEncoding],1);
}
