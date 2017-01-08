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
    DLog(@"SDHeaderViewController refreshing tide for current time, location:%@",[self.tide shortLocationName]);
    self.tide = appDelegate.tides[appDelegate.locationPage];
    
    SDTideStateRiseFall direction = [self.tide tideDirection];
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
                                [self.tide nearestDataPointToCurrentTime].y,
                                [self.tide unitShort],
                                arrow];
    self.locationLabel.text = self.tide.shortLocationName;

}

@end
