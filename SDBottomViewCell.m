//
//  SDBottomViewCell.m
//  ShralpTide2
//
//  Created by Michael Parlee on 9/21/13.
//
//
#import "SDTide.h"
#import "SDBottomViewCell.h"
#import "SDTideEventCell.h"
#import "SDTideEvent.h"
#import "SDEventsViewController.h"
#import "ShralpTideAppDelegate.h"
#import "SDTideFactory.h"

@interface SDBottomViewCell () {
    dispatch_queue_t calculationQueue;
}

@property (nonatomic,strong) NSArray *tidesForDays;
@property (nonatomic,strong) NSArray *viewControllers;

@end

@implementation SDBottomViewCell

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        calculationQueue  = dispatch_queue_create("TideCalcQueue", NULL);
    }
    return self;
}

- (void)createPages:(SDTide*)tide
{
    [self clearScrollView];
    if (_tidesForDays == nil) {
        self.tidesForDays = @[tide];
    }
    [self displayTides:_tidesForDays];
    
    _activityView.layer.cornerRadius = 10;
    _activityView.layer.masksToBounds = YES;
    _activityView.hidden = NO;
    
    _activityIndicator.hidden = NO;
    [_activityIndicator startAnimating];
    dispatch_async(calculationQueue, ^(void) {
        NSArray *tides = [SDTideFactory tidesForStationName:tide.stationName];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [_tideCalculationDelegate tideCalculationsCompleted:tides];
            [self displayTides:tides];
            [_activityIndicator stopAnimating];
            _activityView.hidden = YES;
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
    int numPages = [_tidesForDays count];
    NSLog(@"SDBottomViewCell creating %d days of tide events",numPages);
    self.scrollView.contentSize = CGSizeMake(self.frame.size.width * numPages, self.frame.size.height);
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
        pageController.view.frame = CGRectMake(xOrigin,0,self.frame.size.width,self.frame.size.height);
        [self.scrollView addSubview:pageController.view];
        controllers[i] = pageController;
        xOrigin += self.frame.size.width;
    }
    _viewControllers = [NSArray arrayWithArray:controllers];
    
    // Scroll to the last page index. Intended to ensure that the portrait view page is in sync with the landscape view page. It kind of messes up scrolling between locations though in that each location's visible day always matches the last location's.
    [self.scrollView scrollRectToVisible:CGRectMake(appDelegate.page * self.frame.size.width,0,self.frame.size.width,self.frame.size.height) animated:NO];
}

- (void)clearScrollView
{
    for (UIView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }
}

#pragma mark UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int page = scrollView.contentOffset.x / self.frame.size.width;
    if (scrollView.isDecelerating) {
        appDelegate.page = page;
    }
}

@end
