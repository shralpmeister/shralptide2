//
//  SDFavoritesControllerViewController.m
//  ShralpTide2
//
//  Created by Michael Parlee on 9/7/13.
//
//

#import "FavoritesListViewController.h"
#import "SelectStationNavigationController.h"
#import "CountryListController.h"
#import "TideStationTableViewCell.h"
#import "SDTide.h"
#import "StationMapController.h"

@interface FavoritesListViewController ()

@property (nonatomic, strong) SelectStationNavigationController *stationNavController;
@property (nonatomic, strong) UIView *sectionHeaderView;
@property (nonatomic, strong) UIView *sectionFooterView;
@property (nonatomic, strong) NSMutableArray *favorites;

@end

@implementation FavoritesListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)shouldAutorotate
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background-gradient"]];
    self.sectionHeaderView = [[NSBundle mainBundle] loadNibNamed:@"FavoritesHeaderView" owner:self options:nil][0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData) name:kSDApplicationActivatedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"Favorites list view will appear.");
    self.favorites = [NSMutableArray arrayWithArray:appDelegate.tides];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)refreshData
{
    DLog(@"Refreshing favorites list");
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSError *error;
    BOOL success = [AppStateData.sharedInstance setSelectedLocationWithLocationName:((SDTide*)self.favorites[indexPath.row]).stationName error: &error];
    if (!success) {
        DLog(@"Unabled to persist selected station: %@",error);
    }
    [self.popoverPresentationController.delegate popoverPresentationControllerDidDismissPopover: self.popoverPresentationController];
    [self dismissViewControllerAnimated:YES completion: nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.sectionHeaderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseLabel = @"CurrentTideCell";
	
	long row = indexPath.row;
	
	TideStationTableViewCell *cell = (TideStationTableViewCell*)[tableView dequeueReusableCellWithIdentifier:reuseLabel];
	
    SDTide *tide = ((SDTide*)self.favorites[row]);
    cell.tide = tide;
	cell.nameLabel.text = tide.shortLocationName;
    SDTideStateRiseFall direction = [tide tideDirection];
    NSString *arrow = nil;
    switch (direction) {
        case SDTideStateRising:
            arrow = @"▲";
            break;
        case SDTideStateFalling:
        default:
            arrow = @"▼";
    }

	cell.levelLabel.text = [NSString stringWithFormat:@"%0.2f%@%@", [tide nearestDataPointToCurrentTime].y, tide.unitShort, arrow];
    cell.directionArrowView.image = [self directionArrowForTide:tide];
    cell.directionArrowView.accessibilityLabel = tide.tideDirection == SDTideStateRising ? @"rising" : @"falling";
	
	return cell;
}

- (UIImage*)directionArrowForTide:(SDTide*)tide
{
    SDTideStateRiseFall direction = [tide tideDirection];
	NSString *imageName = nil;
	switch (direction) {
		case SDTideStateRising:
			imageName = @"increasing";
			break;
		case SDTideStateFalling:
        default:
            imageName = @"decreasing";
	}
    UIImage *image;
	if (imageName != nil) {
		image = [UIImage imageNamed:imageName];
	} else {
		image = nil;
	}
    return image;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (self.favorites).count;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSError *error;
        BOOL success = [AppStateData.sharedInstance removeFavoriteLocationWithLocationName:((SDTide*)self.favorites[indexPath.row]).stationName error: &error];
        if (!success) {
            DLog(@"Unable to remove location from persistent store: %@", error);
        } else {
            [appDelegate calculateTides];
        }
        [self.favorites removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark ViewToggleControls

- (IBAction)selectTideStationFromList:(id)sender
{
    [self performSegueWithIdentifier:@"StationListSegue" sender:self];
}

- (IBAction)selectTideStationFromMap:(id)sender
{
    [self performSegueWithIdentifier:@"StationMapSegue" sender:self];
}

- (void)reloadData
{
    DLog(@"Favorites list reloading data...");
    self.favorites = [NSMutableArray arrayWithArray:appDelegate.tides];
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@[@"StationListSegue",@"StationMapSegue"] containsObject:segue.identifier]) {
        SelectStationNavigationController *stationNavController = (SelectStationNavigationController*)segue.destinationViewController;
        stationNavController.detailViewDelegate = self;
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelAddLocation)];
        
        stationNavController.doneButton = doneButton;
        
        stationNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        
        if ([segue.identifier isEqualToString:@"StationListSegue"]) {
            CountryListController *listController = (CountryListController*)stationNavController.topViewController;
            listController.title = @"Country";
            listController.rows = [self queryCountries];
        } else if ([segue.identifier isEqualToString:@"StationMapSegue"]) {
            StationMapController *mapController = (StationMapController*)stationNavController.topViewController;
            
            mapController.modalViewDelegate = self;
            
            UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Tides",@"Currents"]];
            [segmentedControl addTarget:mapController action:@selector(updateDisplayedStations) forControlEvents:UIControlEventValueChanged];
            
            mapController.tideCurrentSelector = segmentedControl;
            
            UIBarButtonItem *segmentedButtonItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
            UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            mapController.toolbarItems = @[flex,segmentedButtonItem,flex];
            mapController.navigationItem.rightBarButtonItem = doneButton;
            mapController.navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        }
    }
}

-(void)cancelAddLocation
{
    [self dismissViewControllerAnimated:YES completion: NULL];
}

- (void)stationDetailViewController:(StationDetailViewController *)detailViewController
                      addTideStation:(NSString *)stationName
{
    DLog(@"Adding tide station: %@",stationName);
    NSError *error;
    BOOL success = [AppStateData.sharedInstance addFavoriteLocationWithLocationName:stationName error:&error];
    if (!success) {
        DLog(@"Unable to add selected location to persistence store: %@",error);
    } else {
        [appDelegate calculateTides];
    }
    [self reloadData];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(NSArray*)queryCountries {
    NSManagedObjectContext *context = AppStateData.sharedInstance.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"SDCountry"
                                              inManagedObjectContext:context];
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
    fr.entity = entityDescription;
    
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[NSBundle mainBundle] loadNibNamed:@"FavoritesFooterView" owner:self options:nil][0];
}

@end
