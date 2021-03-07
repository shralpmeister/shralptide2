//
//  NSDate+Day.h
//  ShralpTide2
//
//  Created by Michael Parlee on 4/2/11.
//  Copyright 2011 IntelliDOT Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (NSDate_Day)

/*
 * Returns a new date representing midnight of the day of the current date.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *startOfDay;

/*
 * Returns a new date representing midnight of the day following the current date.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *endOfDay;

/*
 * Returns the date components for year month and day of the current date.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDateComponents *dayComponents;

/*
 * Returns true if the minute is zero. ie. 0800, 0900, 1200, 0000.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isOnTheHour, readonly) BOOL onTheHour;

/*
 * The time in minutes since midnight.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger timeInMinutesSinceMidnight;

+(NSInteger)findPreviousInterval:(NSInteger) minutesFromMidnight;

+(NSInteger)findNearestInterval:(NSInteger) minutesFromMidnight;

@end
