//
//  SDBottomViewCell.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/21/13.
//
//

#import <UIKit/UIKit.h>
#import "SDTide.h"

@interface SDBottomViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic,readonly) NSArray* tidesForDays;
@property (nonatomic,strong) IBOutlet UIScrollView* scrollView;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic,strong) IBOutlet UIView *activityView;
@property (nonatomic,strong) IBOutlet UIPageControl *pageIndicator;
@property (readonly) SDTide *tide;

- (void)createPages:(SDTide*)tide;

@end
