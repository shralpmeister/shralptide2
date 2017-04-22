//
//  SDHeaderViewController.m
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/24/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import "CurrentTideViewController.h"
#import "ShralpTideAppDelegate.h"
#import "SDTide.h"
#import "ShralpTide2-Swift.h"

@interface CurrentTideViewController ()

@end

@implementation CurrentTideViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.locationLabel.adjustsFontSizeToFitWidth = YES;
    self.tideLevelLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    DLog(@"SDHeaderViewController refreshing tide for current time, location:%@",
         appDelegate.tides[AppStateData.sharedInstance.locationPage]);
    [self refresh];
}

- (void)refresh
{
    SDTide *tide = appDelegate.tides[AppStateData.sharedInstance.locationPage];
    SDTideStateRiseFall direction = [tide tideDirection];
    NSString *arrow = nil;
    switch (direction) {
        case SDTideStateRising:
            arrow = @"▲";
            break;
        case SDTideStateFalling:
        default:
            arrow = @"▼";
    }
    self.tideLevelLabel.text = [NSString stringWithFormat:@"%0.2f%@%@",
                                [tide nearestDataPointToCurrentTime].y,
                                [tide unitShort],
                                arrow];
    self.locationLabel.text = tide.shortLocationName;
}

@end
