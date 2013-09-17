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
    cell.tideLevelLabel.text = [NSString stringWithFormat:@"%0.2f %@",
                               [tide nearestDataPointForDate:[NSDate date]].y,
                               [tide unitShort]];
    cell.locationLabel.text = tide.shortLocationName;
    return cell;
}

@end
