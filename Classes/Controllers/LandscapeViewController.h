//
//  LandscapeViewController.h
//  ShralpTide2
//
//  Created by Michael Parlee on 7/9/13.
//
//

#import <UIKit/UIKit.h>
#import "InteractiveChartView.h"
#import "SDLocationMainViewController.h"
#import "ChartScrollView.h"
#import "SDTideCalculationDelegate.h"

@interface LandscapeViewController : UIViewController <UIScrollViewDelegate, ChartViewDatasource, InteractiveChartViewDelegate, SDTideCalculationDelegate>

@property (nonatomic, weak) IBOutlet ChartScrollView *chartScrollView;
@property (nonatomic, strong) SDLocationMainViewController *locationMainViewController;
@property (nonatomic, weak) IBOutlet InteractiveChartView *chartView;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *heightLabel;
@property (nonatomic, weak) IBOutlet UIView *heightView;
@property (nonatomic, weak) IBOutlet UIView *activityView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

//@property (nonatomic, weak) IBOutlet ChartScrollView *chartScrollView;
//@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;

//- (void)createChartViews;
//- (void)clearChartData;

@end
