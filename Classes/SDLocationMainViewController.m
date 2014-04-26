//
//  SDPortraitViewController.m
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/14/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import "SDLocationMainViewController.h"
#import "ShralpTideAppDelegate.h"

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

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString* bottomCellId = @"bottomCell";
    
    SDBottomViewCell *bottomViewCell = (SDBottomViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:bottomCellId forIndexPath:indexPath];
    
    CGRect bounds = bottomViewCell.bounds;
    CGRect frame = bottomViewCell.frame;
    if ([UIScreen mainScreen].bounds.size.height != 568) {
        bottomViewCell.bounds = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 275);
        bottomViewCell.frame = CGRectMake(frame.origin.x, 200, frame.size.width, 275);
    } else {
        bottomViewCell.bounds = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 360);
        bottomViewCell.frame = CGRectMake(frame.origin.x, 200, frame.size.width, 360);
    }
    
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
        appDelegate.selectedLocation = [appDelegate.tides[page] valueForKey:@"stationName"];
    }
    self.headerViewController.collectionView.contentOffset = CGPointMake(pushOffset, 0);
}

@end
