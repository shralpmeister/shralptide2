//
//  SDBottomViewCell.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/21/13.
//
//

#import <UIKit/UIKit.h>
#import "SDTide.h"
#import "SDTideCalculationDelegate.h"

@interface SDBottomViewCell : UICollectionViewCell <UIScrollViewDelegate>

@property (nonatomic,readonly) NSArray* tidesForDays;
@property (nonatomic,strong) IBOutlet UIScrollView* scrollView;
@property (nonatomic,weak) id<SDTideCalculationDelegate> tideCalculationDelegate;

- (void)createPages:(SDTide*)tide;

@end
