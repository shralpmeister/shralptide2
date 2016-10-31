//
//  SDPortraitViewController.m
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/14/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import "SDLocationMainViewController.h"
#import "ShralpTideAppDelegate.h"
#import "ShralpTide2-Swift.h"

@interface SDLocationMainViewController ()

@end

@implementation SDLocationMainViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    float locationOffset = appDelegate.locationPage * self.view.frame.size.width;
    self.collectionView.contentOffset = CGPointMake(locationOffset,0);
}

/**
 * Yikes! This accessor iterates each day's tides and combines them into a single tide object. Could be
 * expensive if it's called often.
 */
- (SDTide*)tide
{
    SDBottomViewCell *visibleCell = (SDBottomViewCell*)[self collectionView:self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:appDelegate.locationPage]];
    return [SDTide tideByCombiningTides:visibleCell.tidesForDays];
}

- (void)setTideCalculationDelegate:(id<SDTideCalculationDelegate>)tideCalculationDelegate
{
    SDBottomViewCell *visibleCell = (SDBottomViewCell*)[self collectionView:self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:appDelegate.locationPage]];
    visibleCell.tideCalculationDelegate = tideCalculationDelegate;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return appDelegate.tides[section] ? 1 : 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    DLog(@"SDLocationMainViewController displaying %lu locations", (unsigned long)[appDelegate.tides count]);
    return [appDelegate.tides count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.frame.size.width, self.view.frame.size.height * 2/3);
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    DLog(@"Location main view controller cell for index path: %ld", (long)indexPath.section);
    static NSString* bottomCellId = @"bottomCell";
    
    SDBottomViewCell *bottomViewCell = (SDBottomViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:bottomCellId forIndexPath:indexPath];
    
    SDTide *tide = appDelegate.tides[indexPath.section];
    [bottomViewCell createPages:tide];
    return bottomViewCell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIScrollViewDelegate methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float newOffset = scrollView.contentOffset.x;
    float pushOffset = newOffset * 1.5;
    int page = self.collectionView.contentOffset.x / self.view.frame.size.width;
    if (scrollView.isDecelerating) {
        // we know we're past halfway... take whatever action might be good here.
        appDelegate.locationPage = page;
        NSError *error;
        BOOL success = [AppStateData.sharedInstance setSelectedLocationWithLocationName: [appDelegate.tides[page] valueForKey:@"stationName"] error:&error];
        if (!success) {
            DLog(@"Failed to persist the currenlty selected station.");
        }
    }
    self.headerViewController.collectionView.contentOffset = CGPointMake(pushOffset, 0);
}

@end
