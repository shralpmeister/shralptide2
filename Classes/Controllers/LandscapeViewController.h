//
//  LandscapeViewController.h
//  ShralpTide2
//
//  Created by Michael Parlee on 7/9/13.
//
//
#import "ShralpTide2-Swift.h"
#import <UIKit/UIKit.h>
#import "SDBottomViewController.h"
#import "ChartScrollView.h"

@interface LandscapeViewController : UIViewController <UIScrollViewDelegate, UINavigationControllerDelegate, ChartViewDatasource, InteractiveChartViewDelegate>

@property (nonatomic, weak) IBOutlet ChartScrollView *chartScrollView;
@property (nonatomic, strong) SDBottomViewController *bottomViewController;
@property (nonatomic, weak) IBOutlet InteractiveChartView *chartView;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *heightLabel;
@property (nonatomic, weak) IBOutlet UIView *heightView;
@property (nonatomic, weak) IBOutlet UIView *activityView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
