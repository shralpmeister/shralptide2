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
	UIButton *infoButton;
	IBOutlet UIScrollView *scrollView;
    IBOutlet UIPageControl *pageControl;
	IBOutlet WaitView *waitView;
	IBOutlet UILabel *waitReason;
	IBOutlet ChartScrollView *chartScrollView;
	UIActivityIndicatorView *waitIndicator;
    NSMutableArray *viewControllers;
	NSMutableArray *chartViewControllers;
	UISearchBar *searchBar;
	SDTide *sdTide;
	NSString *location;
	NSCalendar *currentCalendar;
	BOOL transitioning;
	BOOL pageControlUsed;
	BOOL acceptLocationUpdates;
	SDTideStationData *tideStation;
    SelectStationNavigationController *stationNavController;
}

@property (nonatomic, strong) UIButton *infoButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) ChartScrollView *chartScrollView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) SDTide* sdTide;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic, strong) NSMutableArray *chartViewControllers;
@property (nonatomic, strong) NSCalendar *currentCalendar;
@property (nonatomic, strong) UILabel *waitReason;
@property (nonatomic, strong) SDTideStationData *tideStation;
@property (nonatomic, strong) SelectStationNavigationController *stationNavController;

@property (readonly, getter=isTransitioning) BOOL transitioning;

- (IBAction)changePage:(id)sender;
- (void)setLocationFromList;
- (void)setLocationFromMap;
- (SDTide*)computeTidesForNumberOfDays:(int)numberOfDays;
- (NSDate *)add:(int)number daysToDate: (NSDate*) date;
- (void)doBackgroundTideCalculation;
- (void)updateWaitReason:(id)object;
- (void)refreshViews;
- (void)createMainViews;

@end
