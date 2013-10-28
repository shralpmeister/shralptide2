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

@implementation SDHeaderViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"Header view controller View will appear called");
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [appDelegate.tidesByLocation count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    SDHeaderViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"headerCell" forIndexPath:indexPath];
    SDTide *tide = appDelegate.tidesByLocation.allValues[indexPath.row];
    NSLog(@"Refreshing tide for current time");
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
    return cell;
}

@end
