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

-(void)loadView {
    [super loadView];
    self.navigationItem.title = NSLocalizedString(@"Tide Stations", nil);
    self.navigationItem.prompt = NSLocalizedString(@"Select a Tide Station",nil);
    self.navigationController.navigationBarHidden = NO;
    
    self.navigationItem.rightBarButtonItem = ((SelectStationNavigationController*)self.navigationController).doneButton;
}

-(void)setStations:(NSArray*)newStations
{
    if (newStations == _stations) {
        return;
    } else if (newStations == nil) {
        _stations = nil;
        return;
    }
    
    _stations = newStations;

    self.sections = [[NSMutableDictionary alloc] init];
    NSMutableSet *sectionKeySet = [[NSMutableSet alloc] init];
    
    if ([_stations count] > 20) {
        for (SDTideStation *station in self.stations) {
            
            NSString *groupKey = [station.name substringToIndex:1];
            [sectionKeySet addObject:groupKey];
            
            if (self.sections[groupKey] == nil) {
                NSMutableArray *group = [[NSMutableArray alloc] init];
                [group addObject:station];
                self.sections[groupKey] = group;
            } else {
                NSMutableArray *group = self.sections[groupKey];
                [group addObject:station];
            }
        }
    }

    self.sectionKeys = [[sectionKeySet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    self.navigationItem.rightBarButtonItem = ((SelectStationNavigationController*)self.navigationController).doneButton;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sectionKeys;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.sectionKeys indexOfObject:title];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.sections count] > 0) {
        return [self.sections count];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseLabel];
	}

    SDTideStation *station = nil;
    if ([self.sections count] > 0) {
        station = (SDTideStation*)self.sections[self.sectionKeys[indexPath.section]][row];
    } else {
        station = (SDTideStation*)self.stations[row];
    }
    
    if ([station.current boolValue]) {
        cell.textLabel.textColor = [UIColor redColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    NSArray *nameParts = [station.name componentsSeparatedByString:@", "];
	cell.textLabel.text = nameParts[0];
    
    NSMutableString *detailText = [[NSMutableString alloc] init];
    for (int i=1; i < [nameParts count]; i++) {
        if (i > 1) {
            [detailText appendString:@", "];
        }
        [detailText appendString:nameParts[i]];
    }
    cell.detailTextLabel.text = detailText;
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([self.sections count] > 0) {
        return [self.sections[self.sectionKeys[section]] count];
    }
    return [self.stations count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.sections count] > 0) {
        return self.sectionKeys[section];
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"Selected row %d",indexPath.row);

    if ([self.sections count] > 0) {
        [self chooseStation:self.sections[self.sectionKeys[indexPath.section]][indexPath.row]];
    } else {
        [self chooseStation:self.stations[indexPath.row]];
    }
}

-(void)chooseStation:(SDTideStation*) station
{
    
    StationDetailViewController *detailViewController = [[StationDetailViewController alloc] initWithNibName:@"StationInfoView" bundle:nil];
    
    SelectStationNavigationController* navController = (SelectStationNavigationController*)self.navigationController;
    detailViewController.modalViewDelegate = navController.detailViewDelegate;
    
	[detailViewController setTideStation: station];
	[self.navigationController pushViewController: detailViewController animated:YES];
}



@end
