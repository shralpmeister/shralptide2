//
//  SDBottomViewCell.m
//  ShralpTide2
//
//  Created by Michael Parlee on 9/21/13.
//
//
#import "SDTide.h"
#import "SDBottomViewController.h"
#import "SDTideEventCell.h"
#import "SDTideEvent.h"
#import "SDEventsViewController.h"
#import "ShralpTideAppDelegate.h"
#import "SDTideFactory.h"
#import "NSDate+Day.h"

@interface SDBottomViewController () {
    dispatch_queue_t calculationQueue;
}

@property (nonatomic,strong) NSArray *tidesForDays;
@property (nonatomic,strong) NSArray *viewControllers;

@end

@implementation SDBottomViewController

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        calculationQueue  = dispatch_queue_create("TideCalcQueue", NULL);
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

/** 
 * Overridden so that we ensure the scrollview window is positioned after
 * screen rotation has completed.
 */
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self scrollToActivePage];
}

- (void)createPages:(SDTide*)tide
{
    // skip if we're still on the same day.
    if ([tide isEqualToTide:_tidesForDays[0]]) {
        DLog(@"We're still on the same day. Skipping refresh.");
        [self scrollToActivePage];
        return;
    }
    
    _activityView.layer.cornerRadius = 10;
    _activityView.layer.masksToBounds = YES;
    _activityView.hidden = NO;
    
    _activityIndicator.hidden = NO;
    [_activityIndicator startAnimating];
    
    if (_tidesForDays == nil) {
        self.tidesForDays = @[tide];
    }

    dispatch_async(calculationQueue, ^(void) {
        NSArray *tides = [SDTideFactory tidesForStationName:tide.stationName];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self displayTides:tides];
            [_activityIndicator stopAnimating];
            _activityView.hidden = YES;
            _scrollView.hidden = NO;
        });
    });
    
}

/**
 * Called when the full set of tides has been calculated across the configured number of days. This
 * method needs to update the display with view controllers to display the tide events for each day.
 */
- (void)displayTides:(NSArray*)tides
{
    [self clearScrollView];
    
    _tidesForDays = tides;
    long numPages = [_tidesForDays count];
    DLog(@"SDBottomViewCell creating %ld days of tide events",numPages);
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width * numPages, self.view.frame.size.height);
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    int xOrigin = 0;
    for (int i=0; i < numPages; i++) {
        SDEventsViewController* pageController = [storyboard instantiateViewControllerWithIdentifier:@"eventsViewController"];
        if (numPages > 1 && i == 0) {
            pageController.tide = [SDTide tideByCombiningTides:@[_tidesForDays[0], _tidesForDays[1]]];
        } else {
            pageController.tide = _tidesForDays[i];
        }
        pageController.view.frame = CGRectMake(xOrigin,0,self.view.frame.size.width,self.view.frame.size.height);
        [self.scrollView addSubview:pageController.view];
        controllers[i] = pageController;
        xOrigin += self.view.frame.size.width;
    }
    _viewControllers = [NSArray arrayWithArray:controllers];
    
    self.pageIndicator.numberOfPages = numPages;
}

-(void)scrollToActivePage
{
    // Scroll to the last page index. Intended to ensure that the portrait view page is in sync with the landscape view page. It kind of messes up scrolling between locations though in that each location's visible day always matches the last location's.
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    CGFloat height = UIScreen.mainScreen.bounds.size.height;
    if (width > height) {
        CGFloat temp = width;
        width = height;
        height = temp;
    }
    DLog(@"Scrolling to day %d, by width %f, height %f. content.x requested at %f", appDelegate.page, width, height, appDelegate.page * width);
    [self.scrollView scrollRectToVisible:CGRectMake(appDelegate.page * width,0,width,height) animated:NO];
    self.pageIndicator.currentPage = appDelegate.page;
}

- (void)clearScrollView
{
    for (UIView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }
}

/**
 * Yikes! This accessor iterates each day's tides and combines them into a single tide object. Could be
 * expensive if it's called often.
 */
- (SDTide*)tide
{
    return [SDTide tideByCombiningTides:self.tidesForDays];
}

#pragma mark UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    DLog(@"Did scroll to day %d, showing from %f, to width %f.", appDelegate.page, self.scrollView.bounds.origin.x, self.scrollView.bounds.size.width);
    int page = scrollView.contentOffset.x / self.view.frame.size.width;
    if (scrollView.isDecelerating) {
        appDelegate.page = page;
        self.pageIndicator.currentPage = page;
    }
}

@end
