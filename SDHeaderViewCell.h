//
//  SDHeaderViewCell.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/15/13.
//
//

#import <UIKit/UIKit.h>

@interface SDHeaderViewCell : UICollectionViewCell

@property (nonatomic,weak) IBOutlet UILabel *locationLabel;
@property (nonatomic,weak) IBOutlet UILabel *tideLevelLabel;
@property (nonatomic,weak) IBOutlet UIImageView *directionArrowView;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *topVerticalConstraint;

@end
