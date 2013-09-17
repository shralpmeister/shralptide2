//
//  SDFavoritesControllerViewController.m
//  ShralpTide2
//
//  Created by Michael Parlee on 9/7/13.
//
//

#import "FavoritesControllerViewController.h"
#import "SelectStationNavigationController.h"

@interface FavoritesControllerViewController ()

@property (nonatomic, strong) SelectStationNavigationController *stationNavController;

@end

@implementation FavoritesControllerViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ViewToggleControls

//-(void)setLocationFromMap
//{
//    [self dismissViewControllerAnimated:NO completion:NULL];
//	StationMapController *mapController = [[StationMapController alloc] initWithNibName:@"LocationView"
//																		 forStationType:SDStationTypeTide];
//	mapController.title = NSLocalizedString(@"Choose a Station",nil);
//    mapController.modalViewDelegate = self;
//	
//	// Create the navigation controller and present it modally.
//	SelectStationNavigationController *mapNavigationController = [[SelectStationNavigationController alloc]
//                                                                  initWithRootViewController:mapController];
//	
//	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelAddLocation)];
//    
//    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Tides",@"Currents"]];
//    [segmentedControl addTarget:mapController action:@selector(updateDisplayedStations) forControlEvents:UIControlEventValueChanged];
//    
//    mapController.tideCurrentSelector = segmentedControl;
//    
//    UIBarButtonItem *segmentedButtonItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
//    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
//    
//	mapController.toolbarItems = @[flex,segmentedButtonItem,flex];
//	mapController.navController = mapNavigationController;
//	mapController.navigationItem.rightBarButtonItem = cancelButton;
//    mapNavigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//    
//	[self presentViewController:mapNavigationController animated:YES completion:NULL];
//}
//
//-(void)setLocationFromList
//{
//	CountryListController *listController = [[CountryListController alloc] initWithNibName:@"CountryListView" bundle:nil];
//	listController.title = @"Country";
//    listController.rows = [self queryCountries];
//	
//    self.stationNavController = [[SelectStationNavigationController alloc] initWithRootViewController:listController];
//    self.stationNavController.detailViewDelegate = self;
//    
//	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelAddLocation)];
//    
//    self.stationNavController.doneButton = doneButton;
//    
//    self.stationNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//	[self presentViewController:self.stationNavController animated:YES completion:NULL];
//}
//
//-(NSArray*)queryCountries {
//    NSManagedObjectContext *context = [(ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
//    NSEntityDescription *entityDescription = [NSEntityDescription
//											  entityForName:@"SDCountry"
//											  inManagedObjectContext:context];
//    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
//	[fr setEntity: entityDescription];
//    
//	NSError *error;
//	NSArray *results = [context executeFetchRequest:fr error:&error];
//    
//    NSMutableArray *countries = [NSMutableArray array];
//    for (SDCountry *country in results) {
//        [countries addObject:country];
//    }
//    
//    NSSortDescriptor *sortByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
//    NSArray *sortDescriptors = @[sortByName];
//    
//    return [countries sortedArrayUsingDescriptors:sortDescriptors];
//}
//
//-(void)cancelAddLocation
//{
//	[self dismissViewControllerAnimated:YES completion:NULL];
//    self.stationNavController = nil;
//}


@end
