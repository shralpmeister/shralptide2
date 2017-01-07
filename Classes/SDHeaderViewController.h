//
//  SDHeaderViewController.h
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/24/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDTide.h"

@class SDLocationMainViewController;

@interface SDHeaderViewController : UIViewController

@property (nonatomic,retain) SDTide *tide;
@property (nonatomic,weak) IBOutlet UILabel *locationLabel;
@property (nonatomic,weak) IBOutlet UILabel *tideLevelLabel;
@property (nonatomic,weak) IBOutlet UIImageView *directionArrowView;

@end
