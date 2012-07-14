//
//  SDTideStation.h
//  Shralp	Tide
//
//  Created by Michael Parlee on 11/30/08.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SDTideStation : NSManagedObject {
	NSString *name;
    NSString *state;
	NSNumber *latitude;
	NSNumber *longitude;
	NSNumber *distance;
	NSString *units;
    NSNumber *current;
    NSNumber *primary;
}

@property (strong, readwrite) NSString *name, *state, *units;
@property (strong, readwrite) NSNumber *distance, *latitude, *longitude, *current, *primary;
@end
