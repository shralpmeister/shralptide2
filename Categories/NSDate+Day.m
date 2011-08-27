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
	unsigned int unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self]; 
//	NSDateComponents *dayComps = [[[NSDateComponents alloc] init] autorelease];
//	[dayComps setYear: [comps year]];
//	[dayComps setMonth: [comps month]];
//	[dayComps setDay: [comps day]];
    
    return comps;
}

@end
