//
//  ChartViewController.h
//  ShralpTide
//
//  Created by Michael Parlee on 9/22/08.
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
#import "SDTide.h"
#import "SDTideInterval.h"
#import "ChartViewDatasource.h"
#import "ShralpTide2-Swift.h"

@interface ChartViewController : UIViewController <ChartViewDatasource>

@property (NS_NONATOMIC_IOSONLY, readonly, strong) SDTide *tideDataToChart;
@property (nonatomic,strong) SDTide *sdTide;
@property (NS_NONATOMIC_IOSONLY, readonly) int page;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil tide:(SDTide *)aTide;

@end
