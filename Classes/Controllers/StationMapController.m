//
//  StationMapController.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/14/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import "StationMapController.h"

#define appDelegate ((ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate])

BOOL zoomedToLocal;

@interface StationMapController()
-(void)addTideStationsForRegion:(MKCoordinateRegion)location;
-(void)showNearbyLocations:(CLLocation *)location;
@end

@implementation StationMapController

@synthesize mapView;
@synthesize stationType;
@synthesize navController;
@synthesize modalViewDelegate;
@synthesize tideCurrentSelector;

-(id)initWithNibName:(NSString *)nibNameOrNil forStationType:(SDStationType)aStationType
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nil])) {
		self.stationType = aStationType;
	}
	return self;
}

-(void)updateDisplayedStations
{
    if (tideCurrentSelector.selectedSegmentIndex == 0) {
        self.stationType = SDStationTypeTide;
    } else {
        self.stationType = SDStationTypeCurrent;
    }
    NSLog(@"updateDisplayedStations called. Switching to %@", self.stationType == SDStationTypeTide ? @"tides." : @"currents.");
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
    if (appDelegate.showsCurrentsPref) {
        [navController setToolbarHidden:NO];
        if (self.stationType == SDStationTypeTide) {
            tideCurrentSelector.selectedSegmentIndex = 0;
        } else {
            tideCurrentSelector.selectedSegmentIndex = 1;
        }
    } else {
        [navController setToolbarHidden:YES];
    }
    mapView.showsUserLocation = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    mapView.showsUserLocation = NO;
}

-(void)addTideStationsForRegion:(MKCoordinateRegion)region
{
	NSManagedObjectContext *context = [appDelegate managedObjectContext];
    if (!context) {
        NSLog(@"Error occurred starting CoreData managed object context, %@",context);
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

    NSLog(@"applying search filter: %@", filter);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: filter, @[minLatitude, maxLatitude], @[minLongitude, maxLongitude],currentBoolean];
    
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity: entityDescription];
	[fr setPredicate:predicate];
    
	NSError *error;
	NSArray *results = [context executeFetchRequest:fr error:&error];
	NSLog(@"%d results returned",[results count]);
    
	if (results == nil) {
		NSLog(@"Error fetching stations! %@, %@",error, [error userInfo]);
    } else if ([results count] > 100) {
        NSLog(@"That's too many results... won't plot until lower zoom level.");
	} else {
		for (SDTideStation *result in results) {
			CLLocationCoordinate2D coordinate;
			coordinate.latitude = [result.latitude doubleValue];
			coordinate.longitude = [result.longitude doubleValue];
			
			TideStationAnnotation *annotation = [[TideStationAnnotation alloc] initWithCoordinate: coordinate];
			annotation.title = result.name;
            annotation.primary = [result.primary boolValue];
			
            if (![[mapView annotations] containsObject:annotation]) {
                [mapView addAnnotation: annotation];
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
        [mapView removeAnnotations:[mapView annotations]];
        return;
    }
    
    if ([[mapView annotations] count] > 0) {
        for (id<MKAnnotation> annotation in [NSArray arrayWithArray:[mapView annotations]]) {
            if ([annotation isKindOfClass:[TideStationAnnotation class]]) {
                // if annotation is no longer within our cache radius we'll remove it
                if (annotation.coordinate.latitude > mapView.centerCoordinate.latitude + 4.0 ||
                    annotation.coordinate.latitude < mapView.centerCoordinate.latitude - 4.0 ||
                    annotation.coordinate.longitude > mapView.centerCoordinate.longitude + 4.0 ||
                    annotation.coordinate.longitude < mapView.centerCoordinate.longitude - 4.0) {
                    
                    [mapView removeAnnotation:annotation];
                    NSLog(@"Removed %@", annotation);
                }
            }
        }
    }
    
	if (latitudeDelta <= 4.0 && longitudeDelta <= 4.0) {
        [self addTideStationsForRegion:aMapView.region];
	}
    
    NSLog(@"Number of cached annotations: %d",[[mapView annotations] count]);
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!zoomedToLocal) {
        [self showNearbyLocations:userLocation.location];
    }
}

-(void)chooseStation
{
	NSLog(@"Yeah, you clicked me alright...");
	NSArray *selectedAnnotations = [mapView selectedAnnotations];
	for (id<MKAnnotation> annotation in selectedAnnotations) {
		NSLog(@"  - %@", annotation.title);
	}

    StationDetailViewController *detailViewController = [[StationDetailViewController alloc] initWithNibName:@"StationInfoView" bundle:nil];
    detailViewController.modalViewDelegate = self.modalViewDelegate;
	detailViewController.tideStationData = [mapView selectedAnnotations][0];
	[navController pushViewController: detailViewController animated:YES];
}


@end
