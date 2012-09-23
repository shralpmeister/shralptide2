//
//  StationMapController.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/14/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "SDTideStation.h"
#import "ShralpTideAppDelegate.h"
#import "TideStationAnnotation.h"
#import "StationDetailViewController.h"
#import "SelectStationNavigationController.h"

typedef enum {
	SDStationTypeTide,
	SDStationTypeCurrent
} SDStationType;

@interface StationMapController : UIViewController <CLLocationManagerDelegate,MKMapViewDelegate> {
}

-(id)initWithNibName:(NSString *)nibNameOrNil forStationType:(SDStationType)aStationType;

@property (nonatomic,strong) IBOutlet MKMapView *mapView;
@property (assign,readwrite) SDStationType stationType;
@property (nonatomic,strong) UINavigationController *navController;
@property (unsafe_unretained) id modalViewDelegate;
@property (nonatomic,strong) UISegmentedControl *tideCurrentSelector;

@end
