//
//  LandscapeViewController.m
//  ShralpTide2
//
//  Created by Michael Parlee on 7/9/13.
//
//

#import "LandscapeViewController.h"
#import "ShralpTideAppDelegate.h"
#import "ChartViewController.h"
#import "SDTideFactory.h"
#import "NSDate+Day.h"

#define appDelegate ((ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate])


@interface LandscapeViewController ()

@property (nonatomic,assign) BOOL pageControlUsed;
@property (nonatomic,strong) SDTide *tide;
@property (nonatomic,strong) NSDate *startDate;
@property (nonatomic,strong) NSDateFormatter *dateFormatter;

@end

@implementation LandscapeViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
}

/**
 * I'm going to have to manage the chart view independently of the root view controller.
 * This means that this class will have to handle drawing the individual views, caching one
 * view forward and one view back (if we're going to do that) and refreshing the views as
 * needed.
 *
 * How can we propagate the signal to refresh all of the tide info? Maybe a fire a notification.
 *
 * I think this is potentially a really great refactoring. :) I should also consider moving to 
 * doxygen docs. I think that will be helpful for any future dev waiding into this mess.
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated
{
    _startDate = [[NSDate date] startOfDay];
    NSDate *then = [_startDate dateByAddingTimeInterval:appDelegate.daysPref * 24 * 60 * 60];
    _tide = [SDTideFactory tidesForStationName:self.locationMainViewController.tide.stationName fromDate:_startDate toDate:then];
    [self createChartViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Handle Screen Rotation
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    switch (toInterfaceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"Device rotated to Landscape Left");
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"Device rotated to Landscape Right");
            break;
        case UIDeviceOrientationPortrait:
            NSLog(@"Device rotated to Portrait");
            [self performSegueWithIdentifier:@"portraitSegue" sender:self];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"Device rotated to Portrait upsidedown");
            break;
    }
}

- (void)createChartViews
{
    self.locationLabel.text = [self.tide shortLocationName];
    self.dateLabel.text = [self.dateFormatter stringFromDate:self.startDate];
    
    self.chartScrollView.pagingEnabled = YES;
	// put 20 back on the height and subtract 20 from width to account for scroll bar at top of landscape
    NSLog(@"Frame = %0.1f x %0.1f", self.view.frame.size.width, self.view.frame.size.height);
	self.chartScrollView.contentSize = CGSizeMake((self.view.frame.size.width) * appDelegate.daysPref, self.view.frame.size.height);
	self.chartScrollView.showsVerticalScrollIndicator = NO;
	self.chartScrollView.showsVerticalScrollIndicator = NO;
	self.chartScrollView.scrollsToTop = NO;
	self.chartScrollView.directionalLockEnabled = YES;
	self.chartScrollView.delegate = self;
	self.chartScrollView.autoresizingMask = UIViewAutoresizingNone;
    
    self.chartView.frame = CGRectMake(0,0,self.chartScrollView.contentSize.width,self.chartScrollView.frame.size.height);
    self.chartView.datasource = self;
    self.chartView.hoursToPlot = appDelegate.daysPref * 24;
    self.chartView.labelInset = 20;
    [self.chartScrollView addSubview:self.chartView];
}


//- (void)clearChartData
//{
//    for (UIView *view in self.chartScrollView.subviews) {
//        [view removeFromSuperview];
//    }
//	for (unsigned i = 0; i < appDelegate.daysPref; i++) {
//		self.chartViewControllers[i] = [NSNull null];
//    }
//}

- (void)loadChartScrollViewWithPage:(int)page {
    //    if (page < 0) return;
    //    if (page >= appDelegate.daysPref) return;
    
    // okay we need to put the current page into a shared location.
	
    // replace the placeholder if necessary
    //    ChartViewController *controller = self.chartViewControllers[page];
    //    if ((NSNull *)controller == [NSNull null]) {
    //        NSLog(@"Initializing new ChartViewController");
    //		controller = [[ChartViewController alloc] initWithNibName:@"ChartView" bundle:nil tide:[self.viewControllers[page] sdTide]];
    //        self.chartViewControllers[page] = controller;
    //    } else {
    //		if (controller.sdTide == nil) {
    //			[controller setSdTide:[self.viewControllers[page] sdTide]];
    //		}
    //	}
    
    //    controller.page = page;
    //
    //    // add the controller's view to the scroll view
    //    if (nil == controller.view.superview) {
    //        CGRect frame = self.chartScrollView.frame;
    //        frame.origin.x = frame.size.width * page;
    //        frame.origin.y = 0;
    //        controller.view.frame = frame;
    //        [self.chartScrollView addSubview:controller.view];
    //    }
	
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    static int lastPageIndex;
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = sender.frame.size.width;
    int pageNumber = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if (pageNumber != lastPageIndex) {
        self.dateLabel.text = [self.dateFormatter stringFromDate:[self.startDate dateByAddingTimeInterval:24 * 60 * 60 * pageNumber]];
        lastPageIndex = pageNumber;
    }
}

#pragma mark Tide Chart Data source
-(SDTide *)tideDataToChart
{
    return _tide;
}

-(NSDate*)day
{
    return _startDate;
}

-(int)page
{
    
}

@end
