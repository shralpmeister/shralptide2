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
#import "ShralpTideAppDelegate.h"
#import "SDTideStationData.h"
#import "SDTideStation.h"
#import "NSDate+Day.h"

#define appDelegate ((ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate])

static NSArray* tideEventsForLocation(const Dstr &name, Interval step, Timestamp start, Timestamp end, Units::PredictionUnits units);
static NSArray* rawEventsForLocation(const Dstr &name, Interval step, Timestamp start, Timestamp end, Units::PredictionUnits units);
static SDTideState cppEventEnumToObjCEventEnum(TideEvent event);

@implementation SDTideFactory

+(SDTide*)todaysTidesForStationName:(NSString*)name;
{
    return [SDTideFactory tideForStationName:name withInterval:900 forDays:1];
}

+(SDTide*)tideForStationName:(NSString *)name
{
    return [SDTideFactory tideForStationName:name withInterval:900 forDays:appDelegate.daysPref];
}

+(SDTide*)tideForStationName:(NSString*)name withInterval:(int)interval forDays:(int)days
{
    srand (time (NULL));
    Global::initCodeset();
    Global::settings.applyUserDefaults();
    Global::settings.fixUpDeprecatedSettings();
    
    Units::PredictionUnits units = [appDelegate.unitsPref isEqualToString:@"metric"] ? Units::meters : Units::feet;
    
    Timestamp startTime = (time_t)[[[NSDate date] startOfDay] timeIntervalSince1970];
    Timestamp endOfStartDay = (time_t)[[[NSDate date] endOfDay] timeIntervalSince1970];
    Timestamp endTime = endOfStartDay + Interval(1440 * 60 * days);
    
    Dstr location ([name UTF8String]);
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
    
    SDTide *tidy = [[SDTide alloc] init];
    tidy.stationName = name;
    tidy.startTime = [NSDate dateWithTimeIntervalSince1970:startTime.timet()];
    tidy.stopTime = [NSDate dateWithTimeIntervalSince1970:endTime.timet()];
    tidy.intervals = intervals;
    tidy.allEvents = events;
    tidy.unitLong = nil;
    tidy.unitShort = eventZero.units;
    
    return tidy;
}

+(SDTideStationData*)tideStationWithName:(NSString*)name
{
    NSManagedObjectContext *context = [(ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"SDTideStation" 
											  inManagedObjectContext:context];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity: entityDescription];
	[fr setPredicate:predicate];
    
    SDTideStationData *station = nil;
    
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:fr error:&error];
	if ([results count] == 1) {
        SDTideStation *entityObj = results[0];
        station = [[SDTideStationData alloc] init];
        station.name = entityObj.name;
        station.units = entityObj.units;
    }    
    return station;
}

@end

// Separator between tide stations in text client output
// \f is form feed
static constString stationSeparator = "\f";

static NSArray* tideEventsForLocation(const Dstr &name, Interval step, Timestamp start, Timestamp end, Units::PredictionUnits units) 
{
    NSMutableArray* tideEvents = [NSMutableArray array];
    const StationRef *sr (Global::stationIndex().getStationRefByName(name));
    if (sr) {
        std::auto_ptr<Station> station (sr->load());
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
    NSMutableArray *intervals = [NSMutableArray array];
    const StationRef *sr (Global::stationIndex().getStationRefByName(name));
    if (sr) {
        std::auto_ptr<Station> station (sr->load());
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
