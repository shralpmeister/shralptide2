//
//  SDBottomViewCell.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/21/13.
//
//

#import <UIKit/UIKit.h>
#import "SDTide.h"

@interface SDBottomViewCell : UICollectionViewCell <UIScrollViewDelegate>

@property (nonatomic,weak) SDTide* tide;
@property (nonatomic,strong) IBOutlet UIScrollView* scrollView;

- (void)createPages;

@end
