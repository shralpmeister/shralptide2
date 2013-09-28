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

@interface SDBottomViewCell ()

@property (nonatomic,strong) NSArray *viewControllers;

@end

@implementation SDBottomViewCell

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // init here
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)createPages
{
    // a page is the width of the scroll view and the height of the content.
    /* self.tide is today's tides... need to calculate yesterday's and tomorrows and make them page 0 and page 2 respectively. */
    int numPages = ((ShralpTideAppDelegate*)appDelegate).daysPref;
    NSLog(@"Creating %d days of tide events",numPages);
    self.scrollView.contentSize = CGSizeMake(self.frame.size.width * numPages, self.frame.size.height);
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    int xOrigin = 0;
    for (int i=0; i < numPages; i++) {
        SDEventsViewController* pageController = [storyboard instantiateViewControllerWithIdentifier:@"eventsViewController"];
        pageController.tide = self.tide;
        pageController.view.frame = CGRectMake(xOrigin,0,self.frame.size.width,self.frame.size.height);
        [self.scrollView addSubview:pageController.view];
        controllers[i] = pageController;
        xOrigin += self.frame.size.width;
    }
    _viewControllers = [NSArray arrayWithArray:controllers];
}


// TODO: Okay, this is important. I was attaching the SDTide models to each view, then refreshing them when
// the data got to be more than 24 hrs old. I think I want to hold the model objects in the app delegate instead.... maybe.
//- (void)refreshViews {
//	NSLog(@"Refresh views called at %@", [NSDate date]);
//
//	MainViewController *pageOneController = self.viewControllers[0];
//
//	if ([[NSDate date] timeIntervalSinceDate: [[pageOneController sdTide] startTime]] > 86400) {
//		[self viewDidAppear:YES];
//	} else {
//		[pageOneController updatePresentTideInfo];
//	}
//}

#pragma mark Scroll View Delegate Methods


@end
