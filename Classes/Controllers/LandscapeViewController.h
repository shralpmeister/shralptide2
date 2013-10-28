//
//  LandscapeViewController.h
//  ShralpTide2
//
//  Created by Michael Parlee on 7/9/13.
//
//

#import <UIKit/UIKit.h>
#import "FlatChartView.h"
#import "SDLocationMainViewController.h"

@interface LandscapeViewController : UIViewController <UIScrollViewDelegate, ChartViewDatasource>

@property (nonatomic, weak) IBOutlet UIScrollView *chartScrollView;
@property (nonatomic, strong) SDLocationMainViewController *locationMainViewController;
@property (nonatomic, weak) IBOutlet FlatChartView *chartView;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *heightLabel;

//@property (nonatomic, weak) IBOutlet ChartScrollView *chartScrollView;
//@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;

//- (void)createChartViews;
//- (void)clearChartData;

@end
