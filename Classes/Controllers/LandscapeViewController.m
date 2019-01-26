//
//  LandscapeViewController.m
//  ShralpTide2
//
//  Created by Michael Parlee on 7/9/13.
//
//
#import "ShralpTide2-Swift.h"
#import "LandscapeViewController.h"
#import "ShralpTideAppDelegate.h"
#import "ChartViewController.h"
#import "SDTideFactory.h"
#import "NSDate+Day.h"
#import <QuartzCore/QuartzCore.h>
#import "ConfigHelper.h"

#define configHelper ((ConfigHelper*)ConfigHelper.sharedInstance)


@interface LandscapeViewController ()

@property (nonatomic,assign) BOOL needsChartRefresh;
@property (nonatomic,assign) BOOL pageControlUsed;
@property (nonatomic,strong) SDTide *tide;
@property (nonatomic,strong) NSDateFormatter *dateFormatter;
@property (nonatomic,strong) NSDateFormatter *timeFormatter;

@end

@implementation LandscapeViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterFullStyle;
    
    self.timeFormatter = [[NSDateFormatter alloc] init];
    self.timeFormatter.timeStyle = NSDateFormatterShortStyle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(iOS 11, *)) {
        self.chartScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    self.heightView.layer.cornerRadius = 5;
    self.heightView.layer.masksToBounds = YES;
    
    _activityView.layer.cornerRadius = 10;
    _activityView.layer.masksToBounds = YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _tide = self.bottomViewController.tide;
    _needsChartRefresh = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Handle Screen Rotation
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // handle pop to root view at start of transition
        [self handleInterfaceOrientation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // add code here if anything needs to happen on completion
    }];
}

- (void)handleInterfaceOrientation {
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) {
        // Portrait
        DLog(@"Device rotated to Landscape Left");
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)createChartViews
{
    [self clearChartViews];
    self.locationLabel.text = [self.tide shortLocationName];
    self.dateLabel.text = [self.dateFormatter stringFromDate:[_tide.startTime dateByAddingTimeInterval:30 * 60 * 60 * appDelegate.page]];
    
    self.chartScrollView.pagingEnabled = YES;
    DLog(@"Frame = %0.1f x %0.1f", self.view.frame.size.width, self.view.frame.size.height);
    self.chartScrollView.contentSize = CGSizeMake((self.view.frame.size.width) * configHelper.daysPref, self.view.frame.size.height);
    self.chartScrollView.showsVerticalScrollIndicator = NO;
    self.chartScrollView.showsVerticalScrollIndicator = NO;
    self.chartScrollView.scrollsToTop = NO;
    self.chartScrollView.directionalLockEnabled = YES;
    self.chartScrollView.delegate = self;
    self.chartScrollView.autoresizingMask = UIViewAutoresizingNone;
    
    self.chartView.frame = CGRectMake(0,0,self.chartScrollView.contentSize.width,self.chartScrollView.frame.size.height);
    self.chartView.datasource = self;
    self.chartView.hoursToPlot = configHelper.daysPref * 24;
    self.chartView.labelInset = [[UIDevice currentDevice].model isEqualToString: @"iPad"] ? 20 : 5;
    self.chartView.height = self.view.bounds.size.height * 3/4;
    self.chartView.delegate = self;
    [self.chartScrollView addSubview:self.chartView];
    self.chartScrollView.contentOffset = CGPointMake(appDelegate.page * self.view.frame.size.width, 0);
}

- (void)clearChartViews
{
    for (UIView* view in (self.chartScrollView).subviews) {
        [view removeFromSuperview];
    }
}

- (void)viewDidLayoutSubviews
{
    if (_needsChartRefresh && self.view.frame.size.width > self.view.frame.size.height) {
        [self createChartViews];
        _needsChartRefresh = NO;
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int page = scrollView.contentOffset.x / self.view.frame.size.width;
    if (scrollView.isDecelerating) {
        appDelegate.page = page;
        self.dateLabel.text = [self.dateFormatter stringFromDate:[_tide.startTime dateByAddingTimeInterval:(6 + (24 * page)) * 60 * 60]];
    }
    
    // when we scroll to a future tide, hide the current tide level.
    [UIView beginAnimations:kCATransition context:nil];
    
    if (self.page == 0) {
        self.heightView.alpha = 1.0;
    } else {
        self.heightView.alpha = 0.0;
    }
    
    [UIView commitAnimations];
}

#pragma mark Interactive Chart View Delegate
- (void)displayHeight:(CGFloat)height atTime:(NSDate*)time withUnitString:(NSString*)units
{
    [UIView beginAnimations:kCATransition context:nil];
    self.heightView.alpha = 1.0;
    self.heightLabel.text = [NSString stringWithFormat:@"%0.2f %@ @ %@", height, units, [self.timeFormatter stringFromDate:time]];
    [UIView commitAnimations];
}

- (void)interactionsEnded
{
    // if we're not on today's graph, hide the current tide level.
    if (self.page != 0) {
        [UIView beginAnimations:kCATransition context:nil];
        self.heightView.alpha = 0.0;
        [UIView commitAnimations];
    }
}

#pragma mark Tide Chart Data source
- (SDTide *)tideDataToChart
{
    return _tide;
}

- (NSDate*)day
{
    return _tide.startTime;
}

- (int)page
{
    CGFloat pageWidth = self.chartScrollView.frame.size.width;
    int page = floor((self.chartScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    return page;
}

@end
