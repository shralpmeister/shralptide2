//
//  StationMapController.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/14/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import "StationMapController.h"
#import "ShralpTide2-Swift.h"
#import "ConfigHelper.h"

#define configHelper ((ConfigHelper*)ConfigHelper.sharedInstance)

BOOL zoomedToLocal;

@interface StationMapController()
-(void)addTideStationsForRegion:(MKCoordinateRegion)location;
-(void)showNearbyLocations:(CLLocation *)location;
@end

@implementation StationMapController

-(id)initWithNibName:(NSString *)nibNameOrNil forStationType:(SDStationType)aStationType
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nil])) {
		self.stationType = aStationType;
	}
	return self;
}

-(void)updateDisplayedStations
{
    if (self.tideCurrentSelector.selectedSegmentIndex == 0) {
        self.stationType = SDStationTypeTide;
    } else {
        self.stationType = SDStationTypeCurrent;
    }
    DLog(@"updateDisplayedStations called. Switching to %@", self.stationType == SDStationTypeTide ? @"tides." : @"currents.");
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self addTideStationsForRegion: self.mapView.region];
}

-(void)loadView {
    [super loadView];
    self.navigationItem.prompt = NSLocalizedString(@"Select a Tide Station",nil);
}

-(void)viewDidLoad
{
	[super viewDidLoad];
    
    zoomedToLocal = NO;

	[self addTideStationsForRegion: self.mapView.region];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (configHelper.showsCurrentsPref) {
        [self.navigationController setToolbarHidden:NO];
        if (self.stationType == SDStationTypeTide) {
            self.tideCurrentSelector.selectedSegmentIndex = 0;
        } else {
            self.tideCurrentSelector.selectedSegmentIndex = 1;
        }
    } else {
        [self.navigationController setToolbarHidden:YES];
    }
    self.mapView.showsUserLocation = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.mapView.showsUserLocation = NO;
}

-(void)addTideStationsForRegion:(MKCoordinateRegion)region
{
    NSManagedObjectContext *context = AppStateData.sharedInstance.managedObjectContext;
    if (!context) {
        DLog(@"Error occurred starting CoreData managed object context, %@",context);
        return;
    }

    if (region.span.latitudeDelta > 4.0 || region.span.longitudeDelta > 4.0) {
        return;
    }
    
    NSExpression *minLongitude = [NSExpression expressionForConstantValue:@(region.center.longitude - region.span.longitudeDelta)];
	NSExpression *maxLongitude = [NSExpression expressionForConstantValue:@(region.center.longitude + region.span.longitudeDelta)];
	NSExpression *minLatitude = [NSExpression expressionForConstantValue:@(region.center.latitude - region.span.latitudeDelta)];
	NSExpression *maxLatitude = [NSExpression expressionForConstantValue:@(region.center.latitude + region.span.latitudeDelta)];
    
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"SDTideStation" 
											  inManagedObjectContext:context];
    
    NSNumber *currentBoolean = (self.stationType == SDStationTypeTide ? @NO : @YES);
    NSString *locationFilter = @"latitude BETWEEN %@ and longitude BETWEEN %@";
    NSString *currentFilter = @" and current == %@";
    
    NSString *filter = [locationFilter stringByAppendingString:currentFilter];

    DLog(@"applying search filter: %@", filter);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: filter, @[minLatitude, maxLatitude], @[minLongitude, maxLongitude],currentBoolean];
    
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity: entityDescription];
	[fr setPredicate:predicate];
    
	NSError *error;
	NSArray *results = [context executeFetchRequest:fr error:&error];
	DLog(@"%lu results returned",(unsigned long)[results count]);
    
	if (results == nil) {
		NSLog(@"Error fetching stations! %@, %@",error, [error userInfo]);
    } else if ([results count] > 100) {
        NSLog(@"That's too many results... won't plot until lower zoom level.");
	} else {
		for (SDTideStation *result in results) {
            DLog(@"Fetched %@",result.name);
			CLLocationCoordinate2D coordinate;
			coordinate.latitude = [result.latitude doubleValue];
			coordinate.longitude = [result.longitude doubleValue];
			
			TideStationAnnotation *annotation = [[TideStationAnnotation alloc] initWithCoordinate: coordinate];
			annotation.title = result.name;
            annotation.primary = [result.primary boolValue];
			
            if (![[self.mapView annotations] containsObject:annotation]) {
                [self.mapView addAnnotation: annotation];
            }
            
		}
	}
}

-(void)showNearbyLocations:(CLLocation *)location {
	MKCoordinateRegion region;
	region.center = location.coordinate;
	region.span.latitudeDelta = 0.5;
	region.span.longitudeDelta = 0.5;
	[self.mapView setRegion:region animated: NO];
    zoomedToLocal = YES;
}

#pragma mark MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	if ([annotation isKindOfClass:[MKUserLocation class]]) {
		return nil;
	}
	
	MKAnnotationView *view = [aMapView dequeueReusableAnnotationViewWithIdentifier:@"TideStationPinView"];
	if (view == nil) {
		MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"TideStationPinView"];
        TideStationAnnotation *tsAnnotation = (TideStationAnnotation*)annotation;
        pin.pinColor = tsAnnotation.isPrimary ? MKPinAnnotationColorGreen : MKPinAnnotationColorRed;
		[pin setCanShowCallout:YES];
		UIButton *disclosure = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[disclosure addTarget:self action:@selector(chooseStation) forControlEvents:UIControlEventTouchUpInside];
		[pin setRightCalloutAccessoryView:disclosure];
		view = pin;
	} else {
        MKPinAnnotationView *pin = (MKPinAnnotationView*)view;
        TideStationAnnotation *tsAnnotation = (TideStationAnnotation*)annotation;
        pin.pinColor = tsAnnotation.isPrimary ? MKPinAnnotationColorGreen : MKPinAnnotationColorRed;
		[view setAnnotation:annotation];
	}
	return view;
}

- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated 
{
	double latitudeDelta = aMapView.region.span.latitudeDelta;
	double longitudeDelta = aMapView.region.span.longitudeDelta;
    
    if (latitudeDelta > 4 || longitudeDelta > 4) {
        [self.mapView removeAnnotations:[self.mapView annotations]];
        return;
    }
    
    if ([[self.mapView annotations] count] > 0) {
        for (id<MKAnnotation> annotation in [NSArray arrayWithArray:[self.mapView annotations]]) {
            if ([annotation isKindOfClass:[TideStationAnnotation class]]) {
                // if annotation is no longer within our cache radius we'll remove it
                if (annotation.coordinate.latitude > self.mapView.centerCoordinate.latitude + 4.0 ||
                    annotation.coordinate.latitude < self.mapView.centerCoordinate.latitude - 4.0 ||
                    annotation.coordinate.longitude > self.mapView.centerCoordinate.longitude + 4.0 ||
                    annotation.coordinate.longitude < self.mapView.centerCoordinate.longitude - 4.0) {
                    
                    [self.mapView removeAnnotation:annotation];
                    DLog(@"Removed %@", annotation);
                }
            }
        }
    }
    
	if (latitudeDelta <= 4.0 && longitudeDelta <= 4.0) {
        [self addTideStationsForRegion:aMapView.region];
	}
    
    DLog(@"Number of cached annotations: %lu",(unsigned long)[[self.mapView annotations] count]);
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!zoomedToLocal) {
        [self showNearbyLocations:userLocation.location];
    }
}

-(void)chooseStation
{
	NSArray *selectedAnnotations = [self.mapView selectedAnnotations];
	for (id<MKAnnotation> annotation in selectedAnnotations) {
		DLog(@"  - %@", annotation.title);
	}

    StationDetailViewController *detailViewController = [[StationDetailViewController alloc] initWithNibName:@"StationInfoView" bundle:nil];
    detailViewController.modalViewDelegate = self.modalViewDelegate;
	detailViewController.tideStationData = [self.mapView selectedAnnotations][0];
	[self.navigationController pushViewController: detailViewController animated:YES];
}


@end
