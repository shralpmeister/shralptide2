//
//  SDHeaderViewController.m
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/24/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import "SDHeaderViewController.h"
#import "ShralpTideAppDelegate.h"
#import "SDHeaderViewCell.h"
#import "SDTide.h"

@interface SDHeaderViewController ()

@end

@implementation SDHeaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    float headerOffset = appDelegate.locationPage * self.collectionView.frame.size.width * 1.5;
    self.collectionView.contentOffset = CGPointMake(headerOffset,0);
    DLog(@"Header view controller view will appear called. Page = %ld, offset=%f", appDelegate.locationPage, self.collectionView.contentOffset.x);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return appDelegate.tides[section] ? 1 : 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    DLog(@"SDHeaderViewController contains:%lu sections", (unsigned long)[appDelegate.tides count]);
    return [appDelegate.tides count];
}

- (void)refreshCurrentTideStatus:(SDTide*)tide forCell:(SDHeaderViewCell*)cell
{
    DLog(@"SDHeaderViewController refreshing tide for current time, location:%@",[tide shortLocationName]);
    cell.tideLevelLabel.text = [NSString stringWithFormat:@"%0.2f %@",
                                           [tide nearestDataPointToCurrentTime].y,
                                           [tide unitShort]];
    cell.locationLabel.text = tide.shortLocationName;
    
    SDTideStateRiseFall direction = [tide tideDirection];
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
		cell.directionArrowView.image = [UIImage imageNamed:imageName];
		cell.directionArrowView.accessibilityLabel = [imageName isEqualToString:@"increasing"] ? @"rising" : @"falling";
	} else {
		cell.directionArrowView.image = nil;
	}
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    SDHeaderViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"headerCell" forIndexPath:indexPath];
    SDTide *tide = appDelegate.tides[indexPath.section];
    DLog(@"Header cell bounds=%f,%f,%f,%f",cell.bounds.origin.x, cell.bounds.origin.y, cell.bounds.size.width, cell.bounds.size.height);
    DLog(@"Header cell frame=%f,%f,%f,%f",cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
    DLog(@"SDHeaderView Controller returning cell for location: %@, indexPath=%lu",tide.stationName, (long)indexPath.section);
    [self refreshCurrentTideStatus:tide forCell:cell];
    return cell;
}   

@end
