 //
//  SDPortraitViewController.h
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/14/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDTide.h"
#import "SDBottomViewCell.h"
#import "SDTideCalculationDelegate.h"

@interface SDLocationMainViewController : UICollectionViewController <UIScrollViewDelegate>

@property (nonatomic,weak) id<SDTideCalculationDelegate> tideCalculationDelegate;
@property (readonly) SDTide *tide;

@end
