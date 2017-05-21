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
#import "ConfigHelper.h"

#define configHelper ((ConfigHelper*)ConfigHelper.sharedInstance)

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
	
	NSInteger row = indexPath.row;
	
	PickerTableCell *cell = (PickerTableCell*)[tableView dequeueReusableCellWithIdentifier:reuseLabel];
	
    if (cell == nil)
    {
        NSArray* nibViews =  [[NSBundle mainBundle] loadNibNamed:@"PickerTableCell" owner:self options:nil];
        cell = nibViews[0];
	}
	
	SDStateProvince* state = (SDStateProvince*)self.rows[row];
    
    cell.nameLabel.text = state.name;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.flagView.image = [UIImage imageNamed:state.flag];
    if (cell.flagView.image == nil) {
        DLog(@"Oops, couldn't find image for %@",state.flag);
    }
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (self.rows).count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *stateName = ((SDStateProvince*)(self.rows)[indexPath.row]).name;
    
    NSManagedObjectContext *context = AppStateData.sharedInstance.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"SDStateProvince" 
											  inManagedObjectContext:context];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", stateName];
    
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	fr.entity = entityDescription;
	fr.predicate = predicate;
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	NSError *error;
	NSArray *results = [context executeFetchRequest:fr error:&error];
	if (results.count > 0) {
		SDStateProvince *state = results[0];
        StationListController *stationController = [[StationListController alloc] initWithNibName:@"StationListView" bundle:nil];
            
        NSArray *orderedStations = [[state.tideStations objectsPassingTest:
                                     ^(id obj, BOOL *stop) {
                                         BOOL result = configHelper.showsCurrentsPref ? YES : !(((SDTideStation*)obj).current).boolValue;
                                         return result;
                                     }] sortedArrayUsingDescriptors:@[sortByName]];
        
        stationController.stations = orderedStations;
        stationController.navigationItem.title = @"Tide Stations";
        
        [self.navigationController pushViewController:stationController animated:YES];
    }
    
}


@end
