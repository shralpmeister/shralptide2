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

#define appDelegate ((ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate])

@interface LandscapeViewController ()

@property (nonatomic,strong) NSMutableArray *chartViewControllers;
@property (assign) BOOL pageControlUsed;

@end

@implementation LandscapeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createChartViews
{
	NSMutableArray *chartControllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < appDelegate.daysPref; i++) {
		[chartControllers addObject:[NSNull null]];
    }
	self.chartViewControllers = chartControllers;
    
    self.chartScrollView.pagingEnabled = YES;
	// put 20 back on the height and subtract 20 from width to account for scroll bar at top of landscape
    NSLog(@"Frame = %0.1f x %0.1f", self.view.frame.size.width, self.view.frame.size.height);
    self.chartScrollView.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
	self.chartScrollView.contentSize = CGSizeMake((self.view.frame.size.height) * appDelegate.daysPref, self.view.frame.size.width - 20);
	self.chartScrollView.showsVerticalScrollIndicator = NO;
	self.chartScrollView.showsVerticalScrollIndicator = NO;
	self.chartScrollView.scrollsToTop = NO;
	self.chartScrollView.directionalLockEnabled = YES;
	self.chartScrollView.delegate = self;
	self.chartScrollView.autoresizingMask = UIViewAutoresizingNone;
}


- (void)clearChartData
{
    for (UIView *view in self.chartScrollView.subviews) {
        [view removeFromSuperview];
    }
	for (unsigned i = 0; i < appDelegate.daysPref; i++) {
		self.chartViewControllers[i] = [NSNull null];
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (self.pageControlUsed) {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = sender.frame.size.width;
    int page = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
    
	if (self.chartScrollView.superview != nil) {
		[self loadChartScrollViewWithPage:page - 1];
		[self loadChartScrollViewWithPage:page];
		[self loadChartScrollViewWithPage:page + 1];
	}
}

- (void)loadChartScrollViewWithPage:(int)page {
    if (page < 0) return;
    if (page >= appDelegate.daysPref) return;
    
    // okay we need to put the current page into a shared location.
	
    // replace the placeholder if necessary
    ChartViewController *controller = self.chartViewControllers[page];
//    if ((NSNull *)controller == [NSNull null]) {
//        NSLog(@"Initializing new ChartViewController");
//		controller = [[ChartViewController alloc] initWithNibName:@"ChartView" bundle:nil tide:[self.viewControllers[page] sdTide]];
//        self.chartViewControllers[page] = controller;
//    } else {
//		if (controller.sdTide == nil) {
//			[controller setSdTide:[self.viewControllers[page] sdTide]];
//		}
//	}
    
    controller.page = page;
	
    // add the controller's view to the scroll view
    if (nil == controller.view.superview) {
        CGRect frame = self.chartScrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [self.chartScrollView addSubview:controller.view];
    }
	
}

@end
