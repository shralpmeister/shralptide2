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
#import "ShralpTide2-Swift.h"

@implementation CountryListController

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
	
	NSInteger row = indexPath.row;
	
	PickerTableCell *cell = (PickerTableCell*)[tableView dequeueReusableCellWithIdentifier:reuseLabel];
	
    if (cell == nil)
    {
        NSArray* nibViews =  [[NSBundle mainBundle] loadNibNamed:@"PickerTableCell" owner:self options:nil];
        cell = nibViews[0];
	}
	
    SDCountry *country = ((SDCountry*)self.rows[row]);
	cell.nameLabel.text = country.name;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	cell.flagView.image = [UIImage imageNamed:country.flag];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (self.rows).count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *countryName = ((SDCountry*)(self.rows)[indexPath.row]).name;
    
    NSManagedObjectContext *context = AppStateData.sharedInstance.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"SDCountry" 
											  inManagedObjectContext:context];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", countryName];
    
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	fr.entity = entityDescription;
	fr.predicate = predicate;
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	NSError *error;
	NSArray *results = [context executeFetchRequest:fr error:&error];
	if (results.count > 0) {
		SDCountry *country = results[0];
        if ((country.states).count == 0) {
            StationListController *stationController = [[StationListController alloc] initWithNibName:@"StationListView" bundle:nil];
            
            NSArray *orderedStations = [[country.tideStations objectsPassingTest:
                                                  ^(id obj, BOOL *stop) {
                                                      BOOL result = !(((SDTideStation*)obj).current).boolValue;
                                                      return result;
                                                  }] 
                                    sortedArrayUsingDescriptors:@[sortByName]];
            stationController.stations = orderedStations;
            
            [self.navigationController pushViewController:stationController animated:YES];
        } else {
            StateListController *stateController = [[StateListController alloc] initWithNibName:@"StateListView" bundle:nil];

            NSArray *orderedStates = [(country.states).allObjects sortedArrayUsingDescriptors:@[sortByName]];
            stateController.rows = orderedStates;
            
            if ([country.name isEqualToString:@"Canada"]) {
                stateController.navigationItem.title = NSLocalizedString(@"Province",nil);
            } else if ([country.name isEqualToString:@"United Kingdom"]) {
                stateController.navigationItem.title = @"U.K.";
            } else {
                stateController.navigationItem.title = NSLocalizedString(@"State",nil);
            }
            [self.navigationController pushViewController: stateController animated:YES];
        }

	}
	
}

@end
