//
//  SDTideEvent.m
//  xtidelib
//
//  Created by Michael Parlee on 7/20/08.
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

#import "SDTideEvent.h"

@interface SDTideEvent ()
+(NSArray*)eventTypeDescriptions;
@end

@implementation SDTideEvent

+(NSArray*)eventTypeDescriptions
{
    return @[@"max", @"min", @"slackrise", @"slackfall", @"markrise", @"markfall",@"sunrise", @"sunset", @"moonrise", @"moonset", @"newmoon", @"firstquarter", @"fullmoon",@"lastquarter", @"rawreading"];
}

-(instancetype)initWithTime:(NSDate *)time Event:(SDTideState)state andHeight:(float)height
{
    if (self = [super init]) {
        self.eventTime = time;
        self.eventType = state;
        self.eventHeight = height;
    }
    return self;    
}

-(NSString *)eventTypeDescription
{
    NSString* result;
    switch (self.eventType) {
        case min:
            result = @"Low";
            break;
        case max:
            result = @"High";
            break;
        case slackrise:
            result = @"Slack Rise";
            break;
        case slackfall:
            result = @"Slack Fall";
            break;
        case markrise:
            result = @"Mark Rise";
            break;
        case markfall:
            result = @"Mark Fall";
            break;
        case sunrise:
            result = @"Sunrise";
            break;
        case sunset:
            result = @"Sunset";
            break;
        case moonrise:
            result = @"Moonrise";
            break;
        case moonset:
            result = @"Moonset";
            break;
        case firstquarter:
            result = @"First Quarter";
            break;
        case lastquarter:
            result = @"Last Quarter";
            break;
        case newmoon:
            result = @"New Moon";
            break;
        case fullmoon:
            result = @"Full Moon";
            break;
		default:
			result = @"";
			break;
    }
    return result;
}

-(NSString *)eventTimeNativeFormat {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.timeStyle = NSDateFormatterShortStyle;
	NSString *fTime = [formatter stringFromDate:self.eventTime];
    return fTime;
}

-(NSString *)eventTimeString24HR {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"HH:mm";
    NSString *fTime = [formatter stringFromDate:self.eventTime];
    return fTime;
}
-(NSString *)eventTimeString12HR {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"HH:mm pm";
    NSString *fTime = [formatter stringFromDate:self.eventTime];
	return fTime;	
}

-(NSString*)description {
    if (self.units != nil) {
        return [NSString stringWithFormat:@"%@\t%@: %0.1f%@",[self eventTimeString24HR],[SDTideEvent eventTypeDescriptions][self.eventType],self.eventHeight,self.units];
    } else {
        return [NSString stringWithFormat:@"%@\t%@",[self eventTimeString24HR],[SDTideEvent eventTypeDescriptions][self.eventType]];
    }
}

@end
