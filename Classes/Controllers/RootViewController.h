//
//  RootViewController.h
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

#import <CoreLocation/CoreLocation.h>
#import "SDTide.h"
#import "WaitView.h"
#import "SDTideStationData.h"
#import "ChartScrollView.h"
#import "SelectStationNavigationController.h"

@class MainViewController;

@interface RootViewController : UIViewController <UIScrollViewDelegate, StationDetailViewControllerDelegate>
{
}

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet ChartScrollView *chartScrollView;
@property (nonatomic, strong) IBOutlet UILabel *waitReason;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet WaitView *waitView;

- (IBAction)changePage:(id)sender;
- (void)setLocationFromList;
- (void)setLocationFromMap;
- (void)doBackgroundTideCalculation;
- (void)refreshViews;
- (void)createMainViews;

@end
