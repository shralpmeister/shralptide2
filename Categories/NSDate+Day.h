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
-(NSDate*)startOfDay;

/*
 * Returns a new date representing midnight of the day following the current date.
 */
-(NSDate*)endOfDay;

/*
 * Returns the date components for year month and day of the current date.
 */
-(NSDateComponents*)dayComponents;

@end