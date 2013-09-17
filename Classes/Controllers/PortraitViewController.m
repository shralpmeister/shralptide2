//
//  DailySummaryViewController.m
//  ShralpTide2
//
//  Created by Michael Parlee on 7/20/13.
//
//

#import "PortraitViewController.h"

#import "MainViewController.h"
#import "CountryListController.h"
#import "SDTideFactory.h"
#import "ChartViewController.h"
#import "ChartView.h"
#import "StationMapController.h"


@interface PortraitViewController ()

@property (nonatomic, assign) BOOL pageControlUsed;

@end

@implementation PortraitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    for (UIViewController *controller in [self childViewControllers]) {
        if ([controller.restorationIdentifier isEqualToString:@"HeaderViewController"]) {
            // do what needs doing
        } else if ([controller.restorationIdentifier isEqualToString:@"MainViewController"]) {
            // do with the main view
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"Portrait view appeared");
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)createMainViews {
//	NSMutableArray *controllers = [[NSMutableArray alloc] init];
////    NSLog(@"Creating views for %d days",appDelegate.daysPref);
////    for (unsigned i = 0; i < appDelegate.daysPref; i++) {
////        [controllers addObject:[NSNull null]];
////    }
////    self.viewControllers = controllers;
//    
//    NSLog(@"%d viewControllers exist",[self.viewControllers count]);
//	
//    // a page is the width of the scroll view
//    self.scrollView.pagingEnabled = YES;
//    self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
////    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width * appDelegate.daysPref, self.view.frame.size.height);
//    self.scrollView.showsHorizontalScrollIndicator = NO;
//    self.scrollView.showsVerticalScrollIndicator = NO;
//    self.scrollView.scrollsToTop = NO;
//	self.scrollView.directionalLockEnabled = YES;
//    self.scrollView.delegate = self;
////    self.pageControl.numberOfPages = appDelegate.daysPref;
////	self.pageControl.hidden = NO;
////	self.pageControl.defersCurrentPageDisplay = YES;
//	
//	[self loadScrollViewWithPage:0];
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


- (IBAction)changePage:(id)sender {
//    int page = self.pageControl.currentPage;
//    
//    // update the scroll view to the appropriate page
//    CGRect frame = self.collectionView.frame;
//    frame.origin.x = frame.size.width * page;
//    frame.origin.y = 0;
//    
//    [self.collectionView scrollRectToVisible:frame animated:YES];
//    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
//    self.pageControlUsed = YES;
}
@end
