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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDisplayedTides) name:kSDAppDelegateRecalculatedTidesNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshDisplayedTides];
    int pageOffset = appDelegate.page * self.view.frame.size.width;
    _bottomViewCell.scrollView.contentOffset = CGPointMake(pageOffset, 0);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshDisplayedTides
{
    NSLog(@"SDLocationManViewController refresh displayed tides called.");
    [self.collectionView reloadData];
}

/**
 * Yikes! This accessor iterates each day's tides and combines them into a single tide object. Could be
 * expensive if it's called often.
 */
- (SDTide*)tide
{
    return [SDTide tideByCombiningTides:_bottomViewCell.tidesForDays];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return appDelegate.tides[section] ? 1 : 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSLog(@"SDLocationMainViewController displaying %d locations", [appDelegate.tides count]);
    return [appDelegate.tides count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString* bottomCellId = @"bottomCell";
    _bottomViewCell = (SDBottomViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:bottomCellId forIndexPath:indexPath];
    SDTide *tide = appDelegate.tides[indexPath.section];
    [_bottomViewCell createPages:tide];
    appDelegate.location = tide.stationName;
    return _bottomViewCell;
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
    }
    self.headerViewController.collectionView.contentOffset = CGPointMake(pushOffset, 0);
}

@end
