//
//  SDTideInterval.m
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

#import "SDTideInterval.h"

@implementation SDTideInterval


-(instancetype)initWithTime:(NSDate *)t height:(float)f andUnits:(NSString*)u
{
    if (self = [super init]) {
        self.time = t;
        self.height = f;
        self.units = u;
    }
    return self;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"time=%@, height=%0.2f, units=%@",[self.time descriptionWithLocale:[NSLocale currentLocale]],self.height,self.units];
}

@end
