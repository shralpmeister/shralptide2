//
//  RootViewController.m
//  ShralpTide
//
//  Created by Michael Parlee on 7/23/08.
//  Copyright Michael Parlee 2009. All rights reserved.
/*
   This file is part of ShralpTide.

   ShralpTide is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   ShralpTide is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with ShralpTide.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <QuartzCore/QuartzCore.h>

#import "RootViewController.h"
#import "MainViewController.h"
#import "CountryListController.h"
#import "SDTideFactory.h"
#import "ChartViewController.h"
#import "ChartView.h"
#import "StationMapController.h"

// Shorthand for getting localized strings, used in formats below for readability
#define LocStr(key) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

//crazy core animation stuff
#define kAnimationKey @"transitionViewAnimation"

#define appDelegate ((ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate])

@interface RootViewController ()
-(NSArray*)queryCountries;
- (void)loadScrollViewWithPage:(int)page;
- (void)loadChartScrollViewWithPage:(int)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;
- (void)recalculateTides;
- (void)startWaitIndicator;
- (void)stopWaitIndicator;
- (void)saveState;
- (NSString*)lastLocation;
- (BOOL)writeApplicationPlist:(id)plist toFile:(NSString *)fileName;
- (id)applicationPlistFromFile:(NSString *)fileName;
- (void)replaceSubview:(UIView *)oldView withSubview:(UIView *)newView transition:(NSString *)transition direction:(NSString *)direction duration:(NSTimeInterval)duration;
- (void)setDefaultLocation;
- (SDTide*)computeTidesForNumberOfDays:(int)numberOfDays;

@property (nonatomic, strong) NSString *cachedLocationFilePath;
@property (nonatomic, strong) UIActivityIndicatorView *waitIndicator;
@property (nonatomic, strong) UIButton *infoButton;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) SDTide* sdTide;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic, strong) NSMutableArray *chartViewControllers;
@property (nonatomic, strong) NSCalendar *currentCalendar;
@property (nonatomic, strong) SDTideStationData *tideStation;
@property (nonatomic, strong) SelectStationNavigationController *stationNavController;
@property (assign) BOOL pageControlUsed;
@property (readonly, getter=isTransitioning) BOOL transitioning;

@end


@implementation RootViewController

- (void)viewDidLoad {
    NSLog(@"View did load");
    NSLog(@"%@", [[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-free" ofType:@"tcd"]);
	NSMutableString *pathBuilder = [[NSMutableString alloc] init];
	[pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-free" ofType:@"tcd"]];
	[pathBuilder appendString:@":"];
	[pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-nonfree" ofType:@"tcd"]];
	setenv("HFILE_PATH",[pathBuilder cStringUsingEncoding:NSUTF8StringEncoding],1);
   
    NSString *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    self.cachedLocationFilePath = [cachesDir stringByAppendingPathComponent:@"tidestate.plist"];
    
	NSString *lastLocation = [self lastLocation];
	
	if (lastLocation) {
		[self setLocation:lastLocation];
		self.tideStation = [SDTideFactory tideStationWithName:lastLocation];
		if (self.tideStation.name == nil) {
			NSString *message = [NSString stringWithFormat:@"%@ is no longer a supported location. Please choose another location.",lastLocation];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[self setDefaultLocation];
		}
	} else {
		[self setDefaultLocation];
	}
	self.currentCalendar = [NSCalendar currentCalendar];
    self.waitView.frame = self.view.window.frame;
}

- (void)setDefaultLocation {
	NSString *defaultLocation = @"La Jolla (Scripps Institution Wharf), California";
	[self setLocation:defaultLocation];
	self.tideStation = [SDTideFactory tideStationWithName:defaultLocation];
}

- (void)createMainViews {
	NSMutableArray *controllers = [[NSMutableArray alloc] init];
	NSMutableArray *chartControllers = [[NSMutableArray alloc] init];
    NSLog(@"Creating views for %d days",appDelegate.daysPref);
    for (unsigned i = 0; i < appDelegate.daysPref; i++) {
        [controllers addObject:[NSNull null]];
		[chartControllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    
    NSLog(@"%d viewControllers exist",[self.viewControllers count]);
	self.chartViewControllers = chartControllers;
	
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width * appDelegate.daysPref, self.view.frame.size.height);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
	self.scrollView.directionalLockEnabled = YES;
    self.scrollView.delegate = self;
    self.pageControl.numberOfPages = appDelegate.daysPref;
	self.pageControl.hidden = NO;
	self.pageControl.defersCurrentPageDisplay = YES;
	
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
	
	[self loadScrollViewWithPage:0];
}

- (void)refreshViews {
	NSLog(@"Refresh views called at %@", [NSDate date]);
	
	MainViewController *pageOneController = self.viewControllers[0];
    
	if ([[NSDate date] timeIntervalSinceDate: [[pageOneController sdTide] startTime]] > 86400) {
		[self viewDidAppear:YES];
	} else {
		[pageOneController updatePresentTideInfo];
	}
}

- (void)clearChartData {
    for (UIView *view in self.chartScrollView.subviews) {
        [view removeFromSuperview];
    }
	for (unsigned i = 0; i < appDelegate.daysPref; i++) {
		self.chartViewControllers[i] = [NSNull null];
    }
}

-(void)doBackgroundTideCalculation {
    [self startWaitIndicator];
	[NSThread detachNewThreadSelector:@selector(recalculateTides) toTarget:self withObject:nil];
}

- (void)recalculateTides { 
    @autoreleasepool {
        NSLog(@"Recalculating tides for %d days",appDelegate.daysPref);
        self.sdTide = [self computeTidesForNumberOfDays:appDelegate.daysPref];

        for (unsigned i = 0; i < appDelegate.daysPref; i++) {
            [self loadScrollViewWithPage:i];
        }
        [self stopWaitIndicator];
    }
}

-(void)startWaitIndicator {
	UIViewController* currentPageController = self.viewControllers[self.pageControl.currentPage];
	if ((NSNull*)currentPageController == [NSNull null]) {
		return;
	}
	[self.view insertSubview:self.waitView aboveSubview:self.scrollView];
	[self.waitIndicator startAnimating];
}

-(void)stopWaitIndicator {
	[self.waitIndicator stopAnimating];
	[self.waitReason setText:@""];
	if ([self.waitView superview] != nil) {
		[self.waitView removeFromSuperview];
	}
}

- (void)loadScrollViewWithPage:(int)page {
    if (page < 0) return;
    if (page >= appDelegate.daysPref) return;
	
    // replace the placeholder if necessary
    MainViewController *controller = self.viewControllers[page];
    if ((NSNull *)controller == [NSNull null]) {
        controller = [[MainViewController alloc] initWithPageNumber:page];
        controller.rootViewController = self;
        self.viewControllers[page] = controller;
    }
    
    NSLog(@"Calling setSdTide on %@",controller);
    [controller setSdTide:self.sdTide];
	
    // add the controller's view to the scroll view
    if (nil == controller.view.superview) {
        CGRect frame = self.scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [self.scrollView addSubview:controller.view];
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


// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)aScrollView {
    self.pageControlUsed = NO;
	[self.pageControl updateCurrentPageDisplay];
}

- (IBAction)changePage:(id)sender {
    int page = self.pageControl.currentPage;

    // update the scroll view to the appropriate page
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;

    [self.scrollView scrollRectToVisible:frame animated:YES];
    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    self.pageControlUsed = YES;
}

#pragma mark ViewToggleControls

- (void)loadChartScrollViewWithPage:(int)page {
    if (page < 0) return;
    if (page >= appDelegate.daysPref) return;
	
    // replace the placeholder if necessary
    ChartViewController *controller = self.chartViewControllers[page];
    if ((NSNull *)controller == [NSNull null]) {
        NSLog(@"Initializing new ChartViewController");
		controller = [[ChartViewController alloc] initWithNibName:@"ChartView" bundle:nil tide:[self.viewControllers[page] sdTide]];
        self.chartViewControllers[page] = controller;
    } else {
		if (controller.sdTide == nil) {
			[controller setSdTide:[self.viewControllers[page] sdTide]];
		}
	}
    
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

-(void)setLocationFromMap
{
    [self dismissModalViewControllerAnimated:NO];
	StationMapController *mapController = [[StationMapController alloc] initWithNibName:@"LocationView"
																		 forStationType:SDStationTypeTide];
	mapController.title = NSLocalizedString(@"Choose a Station",nil);
    mapController.modalViewDelegate = self;
	
	// Create the navigation controller and present it modally.
	SelectStationNavigationController *mapNavigationController = [[SelectStationNavigationController alloc]
                                                       initWithRootViewController:mapController];
	
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelAddLocation)];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Tides",@"Currents"]];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [segmentedControl addTarget:mapController action:@selector(updateDisplayedStations) forControlEvents:UIControlEventValueChanged];
    
    mapController.tideCurrentSelector = segmentedControl;
    
    UIBarButtonItem *segmentedButtonItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

	mapController.toolbarItems = @[flex,segmentedButtonItem,flex];
	mapController.navController = mapNavigationController;
	mapController.navigationItem.rightBarButtonItem = cancelButton;
    mapNavigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
	[self presentModalViewController:mapNavigationController animated:YES];
}

-(void)setLocationFromList
{
	CountryListController *listController = [[CountryListController alloc] initWithNibName:@"CountryListView" bundle:nil];
	listController.title = @"Country";
    listController.rows = [self queryCountries];
	
    self.stationNavController = [[SelectStationNavigationController alloc] initWithRootViewController:listController];
    self.stationNavController.detailViewDelegate = self;
    
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelAddLocation)];
    
    self.stationNavController.doneButton = doneButton;
    
    self.stationNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:self.stationNavController animated:YES];
}

-(NSArray*)queryCountries {
    NSManagedObjectContext *context = [(ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"SDCountry" 
											  inManagedObjectContext:context];
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity: entityDescription];
    
	NSError *error;
	NSArray *results = [context executeFetchRequest:fr error:&error];
    
    NSMutableArray *countries = [NSMutableArray array];
    for (SDCountry *country in results) {
        [countries addObject:country];
    }
    
    NSSortDescriptor *sortByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = @[sortByName];
    
    return [countries sortedArrayUsingDescriptors:sortDescriptors];
}

-(void)cancelAddLocation
{
	[self dismissModalViewControllerAnimated:YES];
    self.stationNavController = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"View will appear. Attempting rotation");
    [super viewWillAppear:animated];
    if ([[RootViewController class] respondsToSelector:@selector(attemptRotationToDeviceOrientation)]) {
        [RootViewController attemptRotationToDeviceOrientation];
    }
}

-(void)viewDidAppear:(BOOL)animated 
{
    if (self.currentCalendar == nil) {
        return;
    }
    NSLog(@"View did appear");
	[super viewDidAppear: animated];
	[self clearChartData];
    [self doBackgroundTideCalculation];
    MainViewController* mainVC = (MainViewController*)self.viewControllers[0];
	[[mainVC currentTideView] becomeFirstResponder];
    
    /* make sure that we show the current time whenever the view is changed or reappears */
    int page = self.pageControl.currentPage;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	UIView *mainView = self.scrollView;
	UIView *chartView = self.chartScrollView;
    
    NSLog(@"Should auto rotate called..");

    if (self.sdTide == nil) {
		return NO;
	} else if ([mainView superview] != nil || [chartView superview] != nil) {
		if ([mainView superview] != nil && interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
			return NO;
		}
		return YES;
	} else {
		return NO;
	}
}

#pragma mark UIViewController

- (void)viewDidUnload
{
    NSLog(@"RootController view did unload called.... should this do anything?");
    self.infoButton = nil;
    self.scrollView = nil;
    self.waitReason = nil;
    self.chartScrollView = nil;
}

-(SDTide*)computeTidesForNumberOfDays:(int)numberOfDays
{
    NSLog(@"Computing tides for %d", numberOfDays);
    return [SDTideFactory tideForStationName:self.tideStation.name withInterval:900 forDays:numberOfDays];
}

-(void)showMainView {
	if (self.chartScrollView == nil) {
		return;
	}
	
	UIView *mainView = self.scrollView;
	UIView *chartView = self.chartScrollView;
	
	if ([chartView superview] == nil) {
		return;
	}
    
	int page = self.pageControl.currentPage;
	CGRect frame = self.scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
    
	[(MainViewController*)self.viewControllers[page] view].frame = frame;
	[self.scrollView scrollRectToVisible:frame animated:NO];
	
	[(MainViewController*)(self.viewControllers)[0] updatePresentTideInfo];
	[self replaceSubview:chartView withSubview:mainView transition:kCATransitionFade direction:@"" duration:0.75];
    
	[self.view addSubview:self.pageControl];
}

-(void)showChartView
{	
	NSLog(@"Setting chart view to use tide from page %d",self.pageControl.currentPage);
	[self loadChartScrollViewWithPage:self.pageControl.currentPage];
	
	UIView *mainView = self.scrollView;
	UIView *chartView = self.chartScrollView;
	
	if ([mainView superview] == nil) {
		return;
	}
	
	int page = self.pageControl.currentPage;
	CGRect frame = self.chartScrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	ChartViewController *viewController = (ChartViewController*)self.chartViewControllers[page];
	viewController.view.frame = frame;
    [viewController showCurrentTime];

	[self.chartScrollView scrollRectToVisible:frame animated:NO];
	[chartView setNeedsLayout];
    
	[self replaceSubview:mainView withSubview:chartView transition:kCATransitionFade direction:@"" duration:0.75];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	UIView *mainView = self.scrollView; 
	UIView *chartView = self.chartScrollView;
	
	if ([mainView superview] != nil || [chartView superview] != nil) {
		switch (toInterfaceOrientation) {
			case UIDeviceOrientationLandscapeLeft:
				NSLog(@"Device rotated to Landscape Left");
				[self showChartView];
				break;
			case UIDeviceOrientationLandscapeRight:
				NSLog(@"Device rotated to Landscape Right");
				[self showChartView];
				break;
			case UIDeviceOrientationPortrait:
				NSLog(@"Device rotated to Portrait");
				[self showMainView];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				NSLog(@"Device rotated to Portrait upsidedown");
				[self showMainView];
				break;
		}
	}

}

#pragma mark CrazyCoreAnimationStuff

	// Method to replace a given subview with another using a specified transition type, direction, and duration
- (void)replaceSubview:(UIView *)oldView withSubview:(UIView *)newView transition:(NSString *)transition direction:(NSString *)direction duration:(NSTimeInterval)duration {
    
    // If a transition is in progress, do nothing
    if(self.transitioning) {
        return;
    }
    
    [oldView removeFromSuperview];

    [self.view addSubview:newView];
    
    // Set up the animation
    CATransition *animation = [CATransition animation];
    [animation setDelegate:self];
    
    // Set the type and if appropriate direction of the transition, 
    if (transition == kCATransitionFade) {
        [animation setType:kCATransitionFade];
    } else {
        [animation setType:transition];
        [animation setSubtype:direction];
    }
    
    // Set the duration and timing function of the transtion -- duration is passed in as a parameter, use ease in/ease out as the timing function
    [animation setDuration:duration];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    [[self.view layer] addAnimation:animation forKey:kAnimationKey];
}

#pragma mark savestate
- (void)saveState {
	NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithCapacity:1];
	plist[@"location"] = self.location;
    
	[self writeApplicationPlist:plist toFile:self.cachedLocationFilePath];
    
}

-(NSString*)lastLocation {
	NSDictionary *plist = [self applicationPlistFromFile:self.cachedLocationFilePath];
	return (NSString *)plist[@"location"];
}

- (BOOL)writeApplicationPlist:(id)plist toFile:(NSString *)fileName {
    NSString *error;
    NSData *pData = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
    if (!pData) {
        NSLog(@"%@", error);
        return NO;
    }
    return ([pData writeToFile:self.cachedLocationFilePath atomically:YES]);
}

- (id)applicationPlistFromFile:(NSString *)fileName {
    NSData *retData;
    NSString *error;
    id retPlist;
    NSPropertyListFormat format;
	
    retData = [[NSData alloc] initWithContentsOfFile:self.cachedLocationFilePath];
    if (!retData) {
        NSLog(@"Data file not returned.");
        return nil;
    }
    retPlist = [NSPropertyListSerialization propertyListFromData:retData  mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    if (!retPlist){
        NSLog(@"Plist not returned, error: %@", error);
    }
    
    return retPlist;
}

#pragma mark StationDetailViewController Delegate Methods
-(void)stationDetailViewController:(StationDetailViewController*)detailViewController 
					addTideStation:(NSString*)stationName
{
	NSLog(@"Delegate addTideStation method called with name; %@",stationName);
	// set the tide station and recalculate tides
    self.location = stationName;
    self.tideStation = [SDTideFactory tideStationWithName:stationName];
    [self saveState];
    
	[self dismissModalViewControllerAnimated:YES];
}

	
@end
