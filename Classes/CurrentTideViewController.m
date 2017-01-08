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

@interface SDHeaderViewController ()

@end

@implementation SDHeaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.locationLabel.adjustsFontSizeToFitWidth = YES;
    self.tideLevelLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    DLog(@"SDHeaderViewController refreshing tide for current time, location:%@",[self.tide shortLocationName]);
    self.tide = appDelegate.tides[appDelegate.locationPage];
    self.tideLevelLabel.text = [NSString stringWithFormat:@"%0.2f %@",
                                [self.tide nearestDataPointToCurrentTime].y,
                                [self.tide unitShort]];
    self.locationLabel.text = self.tide.shortLocationName;
    
    SDTideStateRiseFall direction = [self.tide tideDirection];
    NSString *imageName = nil;
    switch (direction) {
        case SDTideStateRising:
            imageName = @"increasing";
            break;
        case SDTideStateFalling:
        default:
            imageName = @"decreasing";
    }
    if (imageName != nil) {
        self.directionArrowView.image = [UIImage imageNamed:imageName];
        self.directionArrowView.accessibilityLabel = [imageName isEqualToString:@"increasing"] ? @"rising" : @"falling";
    } else {
        self.directionArrowView.image = nil;
    }
}

@end
