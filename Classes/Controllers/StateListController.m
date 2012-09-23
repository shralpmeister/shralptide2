//
//  StateListController.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "StateListController.h"
#import "StationListController.h"
#import "PickerTableCell.h"
#import "SelectStationNavigationController.h"

#define appDelegate ((ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate])

@implementation StateListController

-(void)loadView {
    [super loadView];
    self.navigationItem.prompt = NSLocalizedString(@"Select a Tide Station",nil);
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (!self.rows) {
		self.rows = [[NSMutableArray alloc] init];
	}
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
        cell = nibViews[0];
	}
	
	SDStateProvince* state = (SDStateProvince*)self.rows[row];
    
    cell.nameLabel.text = state.name;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.flagView.image = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:state.flag ofType:@"png"]];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.rows count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *stateName = ((SDStateProvince*)(self.rows)[indexPath.row]).name;
    
    NSManagedObjectContext *context = [(ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"SDStateProvince" 
											  inManagedObjectContext:context];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", stateName];
    
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity: entityDescription];
	[fr setPredicate:predicate];
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	NSError *error;
	NSArray *results = [context executeFetchRequest:fr error:&error];
	if ([results count] > 0) {
		SDStateProvince *state = results[0];
        StationListController *stationController = [[StationListController alloc] initWithNibName:@"StationListView" bundle:nil];
            
        NSArray *orderedStations = [[state.tideStations objectsPassingTest:
                                     ^(id obj, BOOL *stop) {
                                         BOOL result = appDelegate.showsCurrentsPref ? YES : ![((SDTideStation*)obj).current boolValue];
                                         return result;
                                     }] sortedArrayUsingDescriptors:@[sortByName]];
        
        [stationController setStations: orderedStations];
        stationController.navigationItem.title = @"Tide Stations";
        
        [self.navigationController pushViewController:stationController animated:YES];
    }
    
}


@end
