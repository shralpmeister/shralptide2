//
//  SDPortraitViewController.m
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/14/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import "SDLocationMainViewController.h"
#import "ShralpTideAppDelegate.h"
#import "SDBottomViewCell.h"

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
	// Do any additional setup after loading the view.
    NSLog(@"Portrait View loaded... yay. Layout = %@",self.collectionViewLayout);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"View will appear... yay!");
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
    static NSString* bottomCellId = @"bottomCell";
    SDBottomViewCell* bottomViewCell = (SDBottomViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:bottomCellId forIndexPath:indexPath];
    NSArray *tideLocations = appDelegate.tidesByLocation.allValues;
    bottomViewCell.tide = tideLocations[indexPath.section];
    [bottomViewCell createPages];
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
    if (scrollView.isDecelerating) {
        // we know we're past halfway... switch backgrounds
    }

    self.headerViewController.collectionView.contentOffset = CGPointMake(pushOffset, 0);
}

@end
