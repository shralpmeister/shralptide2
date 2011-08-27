//
//  StationListController.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "StationListController.h"
#import "SelectStationNavigationController.h"
#import "StationDetailViewController.h"

@implementation StationListController

@synthesize stations;
@synthesize sections;
@synthesize sectionKeys;

-(void)loadView {
    [super loadView];
    self.navigationItem.title = NSLocalizedString(@"Tide Stations", nil);
    self.navigationItem.prompt = NSLocalizedString(@"Select a Tide Station",nil);
    
    self.navigationItem.rightBarButtonItem = ((SelectStationNavigationController*)self.navigationController).doneButton;
}

-(void)setStations:(NSArray*)newStations
{
    if (newStations == self.stations) {
        return;
    } else if (newStations == nil) {
        self.stations = nil;
        return;
    }
    
    [newStations retain];
    [stations release];
    stations = newStations;

    sections = [[NSMutableDictionary alloc] init];
    NSMutableSet *sectionKeySet = [[NSMutableSet alloc] init];
    
    if ([stations count] > 20) {
        for (SDTideStation *station in stations) {
            
            NSString *groupKey = [station.name substringToIndex:1];
            [sectionKeySet addObject:groupKey];
            
            if ([sections objectForKey:groupKey] == nil) {
                NSMutableArray *group = [[NSMutableArray alloc] init];
                [group addObject:station];
                [sections setObject:group forKey:groupKey];
                [group release];
            } else {
                NSMutableArray *group = [sections objectForKey:groupKey];
                [group addObject:station];
            }
        }
    }

    self.sectionKeys = [[sectionKeySet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    [sectionKeySet release];
    
    self.navigationItem.rightBarButtonItem = ((SelectStationNavigationController*)self.navigationController).doneButton;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sectionKeys;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.sectionKeys indexOfObject:title];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([sections count] > 0) {
        return [sections count];
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseLabel = @"StationListViewCell";
	
	int row = indexPath.row;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseLabel];
	
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseLabel] autorelease];
	}

    SDTideStation *station = nil;
    if ([sections count] > 0) {
        station = (SDTideStation*)[[sections objectForKey:[sectionKeys objectAtIndex:indexPath.section]] objectAtIndex: row];
    } else {
        station = (SDTideStation*)[stations objectAtIndex:row];
    }
    
    if ([station.current boolValue]) {
        cell.textLabel.textColor = [UIColor redColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    NSArray *nameParts = [station.name componentsSeparatedByString:@", "];
	cell.textLabel.text = [nameParts objectAtIndex:0];
    
    NSMutableString *detailText = [[NSMutableString alloc] init];
    for (int i=1; i < [nameParts count]; i++) {
        if (i > 1) {
            [detailText appendString:@", "];
        }
        [detailText appendString:[nameParts objectAtIndex:i]];
    }
    cell.detailTextLabel.text = detailText;
    [detailText release];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([sections count] > 0) {
        return [[self.sections objectForKey:[sectionKeys objectAtIndex:section]] count];
    }
    return [stations count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([sections count] > 0) {
        return [self.sectionKeys objectAtIndex:section];
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected row %d",indexPath.row);

    if ([sections count] > 0) {
        [self chooseStation:[[sections objectForKey:[sectionKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
    } else {
        [self chooseStation:[stations objectAtIndex:indexPath.row]];
    }
}

-(void)chooseStation:(SDTideStation*) station
{
    
    StationDetailViewController *detailViewController = [[StationDetailViewController alloc] initWithNibName:@"StationInfoView" bundle:nil];
    
    SelectStationNavigationController* navController = (SelectStationNavigationController*)self.navigationController;
    detailViewController.modalViewDelegate = navController.detailViewDelegate;
    
	[detailViewController setTideStation: station];
	[self.navigationController pushViewController: detailViewController animated:YES];
    [detailViewController release];
}


-(void)dealloc
{
	[super dealloc];
	[stations release];
    [sections release];
    [sectionKeys release];
}

@end
