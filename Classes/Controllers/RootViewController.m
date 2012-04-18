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


@property (nonatomic, retain) NSString *cachedLocationFilePath;

@end


@implementation RootViewController

@synthesize stationNavController;
@synthesize infoButton;
@synthesize chartScrollView;
@synthesize searchBar;
@synthesize location;
@synthesize sdTide;
@synthesize currentCalendar;
@synthesize viewControllers;
@synthesize chartViewControllers;
@synthesize scrollView;
@synthesize waitReason;
@synthesize transitioning;
@synthesize tideStation;
@synthesize cachedLocationFilePath;


- (void)dealloc {
	[infoButton release];
	[chartScrollView release];
	[currentCalendar release];
	[viewControllers release];
	[chartViewControllers release];
	[scrollView release];
	[waitIndicator release];
	[waitReason release];
	[waitView release];
	[tideStation release];
	[super dealloc];
}

- (void)viewDidLoad {
    NSLog(@"%@", [[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-free" ofType:@"tcd"]);
	NSMutableString *pathBuilder = [[NSMutableString alloc] init];
	[pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-free" ofType:@"tcd"]];
	[pathBuilder appendString:@":"];
	[pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-nonfree" ofType:@"tcd"]];
	setenv("HFILE_PATH",[pathBuilder cStringUsingEncoding:NSUTF8StringEncoding],1);
	[pathBuilder release];
    
    
    NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    self.cachedLocationFilePath = [cachesDir stringByAppendingPathComponent:@"tidestate.plist"];
    
	NSString *lastLocation = [[self lastLocation] retain];
	
	if (lastLocation) {
		[self setLocation:lastLocation];
		self.tideStation = [SDTideFactory tideStationWithName:lastLocation];
		if (self.tideStation.name == nil) {
			NSString *message = [NSString stringWithFormat:@"%@ is no longer a supported location. Please choose another location.",lastLocation];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
			[self setDefaultLocation];
		}
	} else {
		[self setDefaultLocation];
	}
	[lastLocation release];
	self.currentCalendar = [NSCalendar currentCalendar];
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
    
    NSLog(@"%d viewControllers exist",[viewControllers count]);
	self.chartViewControllers = chartControllers;
    [controllers release];
	[chartControllers release];
	
    // a page is the width of the scroll view
    scrollView.pagingEnabled = YES;
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width * appDelegate.daysPref, self.view.frame.size.height);
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = NO;
	scrollView.directionalLockEnabled = YES;
    scrollView.delegate = self;	
    pageControl.numberOfPages = appDelegate.daysPref;
	pageControl.hidden = NO;
	pageControl.defersCurrentPageDisplay = YES;
	
	chartScrollView.pagingEnabled = YES;
	// put 20 back on the height and subtract 20 from width to account for scroll bar at top of landscape 
	chartScrollView.contentSize = CGSizeMake((self.view.frame.size.height) * appDelegate.daysPref, self.view.frame.size.width - 20);
	chartScrollView.showsVerticalScrollIndicator = NO;
	chartScrollView.showsVerticalScrollIndicator = NO;
	chartScrollView.scrollsToTop = NO;
	chartScrollView.directionalLockEnabled = YES;
	chartScrollView.delegate = self;
	chartScrollView.autoresizingMask = UIViewAutoresizingNone;
	
	[self loadScrollViewWithPage:0];
}

- (void)refreshViews {
	NSLog(@"Refresh views called at %@", [NSDate date]);
	
	MainViewController *pageOneController = [viewControllers objectAtIndex:0];
    
	if ([[NSDate date] timeIntervalSinceDate: [[pageOneController sdTide] startTime]] > 86400) {
		[self viewDidAppear:YES];
	} else {
		[pageOneController updatePresentTideInfo];
	}
}

- (void)clearChartData {
    for (UIView *view in chartScrollView.subviews) {
        [view removeFromSuperview];
    }
	for (unsigned i = 0; i < appDelegate.daysPref; i++) {
		[chartViewControllers replaceObjectAtIndex:i withObject:[NSNull null]];
    }
}

-(void)doBackgroundTideCalculation {
    [self startWaitIndicator];
	[NSThread detachNewThreadSelector:@selector(recalculateTides) toTarget:self withObject:nil];
}

- (void)recalculateTides { 
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"Recalculating tides for %d days",appDelegate.daysPref);
    self.sdTide = [self computeTidesForNumberOfDays:appDelegate.daysPref];

    for (unsigned i = 0; i < appDelegate.daysPref; i++) {
		[self loadScrollViewWithPage:i];
	}
    
    [self stopWaitIndicator];
    
    [pool release];
}

-(void)startWaitIndicator {
	UIViewController* currentPageController = [viewControllers objectAtIndex:pageControl.currentPage];
	if ((NSNull*)currentPageController == [NSNull null]) {
		return;
	}
	[self.view insertSubview:waitView aboveSubview:scrollView];
	[waitIndicator startAnimating];
}

-(void)stopWaitIndicator {
	[waitIndicator stopAnimating];
	[waitReason setText:@""];
	if ([waitView superview] != nil) {
		[waitView removeFromSuperview];
	}
}

-(void)updateWaitReason:(id)object
{
	[waitReason setText:(NSString*)object];
}

- (void)loadScrollViewWithPage:(int)page {
    if (page < 0) return;
    if (page >= appDelegate.daysPref) return;
	
    // replace the placeholder if necessary
    MainViewController *controller = [viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null]) {
        controller = [[MainViewController alloc] initWithPageNumber:page];
        controller.rootViewController = self;
        controller.backgroundImage = [UIImage imageNamed:appDelegate.backgroundPref];
        [viewControllers replaceObjectAtIndex:page withObject:controller];
        [controller release];
    }
    
    NSLog(@"Calling setSdTide on %@",controller);
    [controller setSdTide:sdTide];
	
    // add the controller's view to the scroll view
    if (nil == controller.view.superview) {
        CGRect frame = scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [scrollView addSubview:controller.view];
    }
}

-(NSDate *)add:(int)number daysToDate: (NSDate*) date {
	unsigned int unitFlags = NSDayCalendarUnit;
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setDay: number];
	NSDate *result = [currentCalendar dateByAddingComponents:comps toDate:date options:unitFlags];
	[comps release];
	return result;
}


#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (pageControlUsed) {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = sender.frame.size.width;
    int page = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = page;

	if (chartScrollView.superview != nil) {
		[self loadChartScrollViewWithPage:page - 1];
		[self loadChartScrollViewWithPage:page];
		[self loadChartScrollViewWithPage:page + 1];
	}
}


// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)aScrollView {
    pageControlUsed = NO;
	[pageControl updateCurrentPageDisplay];
}

- (IBAction)changePage:(id)sender {
    int page = pageControl.currentPage;

    // update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;

    [scrollView scrollRectToVisible:frame animated:YES];
    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}

#pragma mark ViewToggleControls

- (void)loadChartScrollViewWithPage:(int)page {
    if (page < 0) return;
    if (page >= appDelegate.daysPref) return;
	
    // replace the placeholder if necessary
    ChartViewController *controller = [chartViewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null]) {
        NSLog(@"Initializing new ChartViewController");
		controller = [[ChartViewController alloc] initWithNibName:@"ChartView" bundle:nil tide:[[viewControllers objectAtIndex:page] sdTide]];
        [chartViewControllers replaceObjectAtIndex:page withObject:controller];
        [controller release];
    } else {
		if (controller.sdTide == nil) {
			[controller setSdTide:[[viewControllers objectAtIndex:page] sdTide]];
		}
	}
    
    controller.page = page;
	
    // add the controller's view to the scroll view
    if (nil == controller.view.superview) {
        CGRect frame = chartScrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [chartScrollView addSubview:controller.view];
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
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Tides",@"Currents", nil]];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [segmentedControl addTarget:mapController action:@selector(updateDisplayedStations) forControlEvents:UIControlEventValueChanged];
    
    mapController.tideCurrentSelector = segmentedControl;
    
    UIBarButtonItem *segmentedButtonItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

	mapController.toolbarItems = [NSArray arrayWithObjects:flex,segmentedButtonItem,flex,nil];
	mapController.navController = mapNavigationController;
	mapController.navigationItem.rightBarButtonItem = cancelButton;
    mapNavigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [segmentedControl release];
    [segmentedButtonItem release];
    [flex release];
    [cancelButton release];	
	[self presentModalViewController:mapNavigationController animated:YES];
	
	[mapNavigationController release];
	[mapController release];
	
}

-(void)setLocationFromList
{
	CountryListController *listController = [[CountryListController alloc] initWithNibName:@"CountryListView" bundle:nil];
	listController.title = @"Country";
    listController.rows = [self queryCountries];
	
    stationNavController = [[SelectStationNavigationController alloc] initWithRootViewController:listController];
    self.stationNavController.detailViewDelegate = self;
    
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelAddLocation)];
    
    self.stationNavController.doneButton = doneButton;

    [doneButton release];
    
    self.stationNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:self.stationNavController animated:YES];
	[listController release];
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
    [fr release];
    
    NSMutableArray *countries = [NSMutableArray array];
    for (SDCountry *country in results) {
        [countries addObject:country];
    }
    
    NSSortDescriptor *sortByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    [sortByName release];
    
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
	[super viewDidAppear: animated];
	[self clearChartData];
    [self doBackgroundTideCalculation];
    MainViewController* mainVC = (MainViewController*)[viewControllers objectAtIndex:0];
	[[mainVC currentTideView] becomeFirstResponder];
    
    /* make sure that we show the current time whenever the view is changed or reappears */
    int page = pageControl.currentPage;
    ChartViewController *chartController = (ChartViewController*)[chartViewControllers objectAtIndex:page];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	UIView *mainView = scrollView;
	UIView *chartView = chartScrollView;

    if (sdTide == nil) {
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
    return [SDTideFactory tideForStationName:tideStation.name withInterval:900 forDays:numberOfDays];
}

-(void)showMainView {
	if (chartScrollView == nil) {
		return;
	}
	
	UIView *mainView = scrollView;
	UIView *chartView = chartScrollView;
	
	if ([chartView superview] == nil) {
		return;
	}
    
	int page = pageControl.currentPage;
	CGRect frame = scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
    
	[(MainViewController*)[viewControllers objectAtIndex:page] view].frame = frame;
	[scrollView scrollRectToVisible:frame animated:NO];
	
	[(MainViewController*)[self.viewControllers objectAtIndex:0] updatePresentTideInfo];
	[self replaceSubview:chartView withSubview:mainView transition:kCATransitionFade direction:@"" duration:0.75];
    
	[self.view addSubview:pageControl];
}

-(void)showChartView
{	
	NSLog(@"Setting chart view to use tide from page %d",pageControl.currentPage);
	[self loadChartScrollViewWithPage:pageControl.currentPage];
	
	UIView *mainView = scrollView;
	UIView *chartView = chartScrollView;
	
	if ([mainView superview] == nil) {
		return;
	}
	
	int page = pageControl.currentPage;
	CGRect frame = chartScrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	ChartViewController *viewController = (ChartViewController*)[chartViewControllers objectAtIndex:page];
	viewController.view.frame = frame;
    [viewController showCurrentTime];

	[chartScrollView scrollRectToVisible:frame animated:NO];
	[chartView setNeedsLayout];
    
	[self replaceSubview:mainView withSubview:chartView transition:kCATransitionFade direction:@"" duration:0.75];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	UIView *mainView = scrollView; 
	UIView *chartView = chartScrollView;
	
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
    if(transitioning) {
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
	[plist setObject:location forKey:@"location"];
    
	[self writeApplicationPlist:plist toFile:self.cachedLocationFilePath];
    
	[plist release];
}

-(NSString*)lastLocation {
	NSDictionary *plist = [self applicationPlistFromFile:self.cachedLocationFilePath];
	return (NSString *)[plist objectForKey:@"location"];
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
    [retData release];
    
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
