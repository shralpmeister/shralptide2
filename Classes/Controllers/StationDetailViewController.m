//
//  StationDetailViewController.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 12/9/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import "StationDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SelectStationNavigationController.h"


@implementation StationDetailViewController

-(IBAction)addTideStation
{
	DLog(@"StationDetailViewController addTideStation called");
    [self.modalViewDelegate stationDetailViewController:self addTideStation: self.tideStationData.title];
}

-(void)setTideStation:(SDTideStation*) station {
    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake((station.latitude).doubleValue, (station.longitude).doubleValue);
    TideStationAnnotation *tideAnnotation = [[TideStationAnnotation alloc] initWithCoordinate: coordinates];
    self.tideStationData = tideAnnotation;
    self.tideStationData.title = station.name;
    self.tideStationData.primary = (station.primary).boolValue;
}

-(void)loadView 
{
    [super loadView];
    UITableView *tableView = (UITableView*)self.view;
    tableView.tableHeaderView = self.titleView;
    tableView.tableFooterView = self.buttonView;
    
    self.mapView.delegate = self;
    
    self.navigationItem.prompt = NSLocalizedString(@"Select a Tide Station",nil);
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.mapView addAnnotation:self.tideStationData];
    self.mapView.region = MKCoordinateRegionMake(
                                                 CLLocationCoordinate2DMake(self.tideStationData.coordinate.latitude, self.tideStationData.coordinate.longitude), 
                                                 MKCoordinateSpanMake(0.1, 0.1));
    self.mapView.layer.cornerRadius = 5;
    self.mapView.layer.borderWidth = 1.0f;
    [super viewWillAppear:animated];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	DLog(@"Detail view loaded with station, %@", self.tideStationData.title);
    
    // TODO: I don't like munging the titles everyplace they're going to be used.
    self.titleLabel.text = [self.tideStationData.title stringByReplacingOccurrencesOfString:@", " withString:@"\n" options:0 range:NSMakeRange([self.tideStationData.title rangeOfString:@", "].location - 1,3)];
        
    self.locationCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
    double lat = self.tideStationData.coordinate.latitude;
    double lon = self.tideStationData.coordinate.longitude;
    NSString *latDir = lat > 0 ? @"N" : @"S";
    NSString *lonDir = lon > 0 ? @"E" : @"W";
    self.locationCell.detailTextLabel.text = [NSString stringWithFormat:@"%1.3f%@, %1.3f%@",fabs(lat),latDir, fabs(lon), lonDir];
    self.locationCell.textLabel.text = NSLocalizedString(@"Position",nil);
    self.locationCell.userInteractionEnabled = NO;
    
    self.primaryCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
    self.primaryCell.textLabel.text = NSLocalizedString(@"Type",nil);
    if (self.tideStationData.primary) {
        self.primaryCell.detailTextLabel.text = NSLocalizedString(@"Reference Location",nil);
    } else {
        self.primaryCell.detailTextLabel.text = NSLocalizedString(@"Subordinate Location",nil);
    }
    [self.selectButton setTitle:NSLocalizedString(@"Select Station",nil) forState:UIControlStateNormal];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            return self.primaryCell;
        case 1:
            return self.locationCell;
            break;
        default:
            return self.locationCell;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

@end
