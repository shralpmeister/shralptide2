 //
//  SDPortraitViewController.h
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/14/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDHeaderViewController.h"
#import "SDTide.h"
#import "SDBottomViewCell.h"

@interface SDLocationMainViewController : UICollectionViewController <UIScrollViewDelegate>

@property (nonatomic,weak) SDHeaderViewController* headerViewController;
@property (nonatomic,weak) SDBottomViewCell *bottomViewCell;
@property (readonly) SDTide *tide;

@end
