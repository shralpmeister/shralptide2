//
//  ShralpTideAppDelegate.h
//  ShralpTide
//
//  Created by Michael Parlee on 7/23/08.
//  Copyright Michael Parlee 2009. All rights reserved.
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
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "SDTideStationData.h"
#import <Foundation/Foundation.h>
#import "SDTide.h"

@interface ShralpTideAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong, readonly) NSArray<SDTide*> *tides;
@property (nonatomic, assign) int page;
@property (nonatomic, assign) UIInterfaceOrientationMask supportedOrientations;
@property (nonatomic, readonly) NSDictionary<NSString*, NSString*>* countries;

- (void)calculateTides;

@end

