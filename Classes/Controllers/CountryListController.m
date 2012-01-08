//
//  StationListController.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 12/14/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import "CountryListController.h"
#import "StationListController.h"
#import "PickerTableCell.h"
#import "SelectStationNavigationController.h"

@implementation CountryListController

@synthesize rows;

-(void)dealloc
{
    self.rows = nil;
    [super dealloc];
}

-(void)loadView {
    [super loadView];
    self.navigationItem.title = NSLocalizedString(@"Country",nil);
    self.navigationItem.prompt = NSLocalizedString(@"Select a Tide Station",nil);
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = ((SelectStationNavigationController*)self.navigationController).doneButton;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseLabel = @"PickerViewCell";
	
	int row = indexPath.row;
	
	PickerTableCell *cell = (PickerTableCell*)[tableView dequeueReusableCellWithIdentifier:reuseLabel];
	
    if (cell == nil)
    {
        NSArray* nibViews =  [[NSBundle mainBundle] loadNibNamed:@"PickerTableCell" owner:self options:nil];
        cell = [nibViews objectAtIndex: 0];
	}
	
    SDCountry *country = ((SDCountry*)[rows objectAtIndex:row]);
	cell.nameLabel.text = country.name;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	cell.flagView.image = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:country.flag ofType: @"png"]];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.rows count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *countryName = ((SDCountry*)[self.rows objectAtIndex:indexPath.row]).name;
    
    NSManagedObjectContext *context = [(ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"SDCountry" 
											  inManagedObjectContext:context];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", countryName];
    
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity: entityDescription];
	[fr setPredicate:predicate];
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	NSError *error;
	NSArray *results = [context executeFetchRequest:fr error:&error];
	if ([results count] > 0) {
		SDCountry *country = [results objectAtIndex:0];
        if ([country.states count] == 0) {
            StationListController *stationController = [[StationListController alloc] initWithNibName:@"StationListView" bundle:nil];
            
            NSArray *orderedStations = [[country.tideStations objectsPassingTest:
                                                  ^(id obj, BOOL *stop) {
                                                      BOOL result = ![((SDTideStation*)obj).current boolValue];
                                                      return result;
                                                  }] 
                                    sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByName]];
            //stationController.stations = orderedStations;
            [stationController setStations: orderedStations];
            
            [self.navigationController pushViewController:stationController animated:YES];
            [stationController release];
        } else {
            StateListController *stateController = [[StateListController alloc] initWithNibName:@"StateListView" bundle:nil];

            NSArray *orderedStates = [[country.states allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByName]];
            stateController.rows = orderedStates;
            
            if ([country.name isEqualToString:@"Canada"]) {
                stateController.navigationItem.title = NSLocalizedString(@"Province",nil);
            } else if ([country.name isEqualToString:@"United Kingdom"]) {
                stateController.navigationItem.title = @"U.K.";
            } else {
                stateController.navigationItem.title = NSLocalizedString(@"State",nil);
            }
            [self.navigationController pushViewController: stateController animated:YES];
            [stateController release];
        }

	}
	
	[fr release];
}

@end
