//
//  LandscapeViewController.h
//  ShralpTide2
//
//  Created by Michael Parlee on 7/9/13.
//
//

#import <UIKit/UIKit.h>
#import "ChartScrollView.h"

@interface LandscapeViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet ChartScrollView *chartScrollView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;

- (void)createChartViews;
- (void)clearChartData;

@end
