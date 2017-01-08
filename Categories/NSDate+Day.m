//
//  NSDate+Day.m
//  ShralpTide2
//
//  Created by Michael Parlee on 4/2/11.
//  Copyright 2011 IntelliDOT Corporation. All rights reserved.
//

#import "NSDate+Day.h"


@implementation NSDate (NSDate_Day)

-(NSDate*)startOfDay
{
    NSDateComponents *comps = [self dayComponents];
	[comps setHour: 0];
	[comps setMinute: 0];
	[comps setSecond:0];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

-(NSDate*)endOfDay
{
    NSDateComponents *comps = [self dayComponents];
	[comps setHour:24];
	[comps setMinute:00];
	[comps setSecond:00];
    return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

-(NSDateComponents*)dayComponents
{
	unsigned int unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
    return comps;
}

-(BOOL)isOnTheHour
{
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitMinute fromDate:self];
    return comps.minute == 0;
}

- (NSInteger)timeInMinutesSinceMidnight
{
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	unsigned unitflags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
	NSDateComponents *components = [gregorian components: unitflags fromDate: self];
	
	NSDate *midnight = [gregorian dateFromComponents:components];
	
    return ([self timeIntervalSince1970] - [midnight timeIntervalSince1970]) / 60;
}

+(NSInteger)findPreviousInterval:(NSInteger) minutesFromMidnight {
	return [self findNearestInterval:minutesFromMidnight] - 15;
}

+(NSInteger)findNearestInterval:(NSInteger) minutesFromMidnight {
	int numIntervals = floor(minutesFromMidnight / 15);
	int remainder = minutesFromMidnight % 15;
	if (remainder >= 8) {
		++numIntervals;
	}
	return numIntervals * 15;
}

@end
