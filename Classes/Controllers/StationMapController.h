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
#import "ShralpTide2-Swift.h"
#import "ShralpTideAppDelegate.h"
#import "TideStationAnnotation.h"
#import "StationDetailViewController.h"
#import "SelectStationNavigationController.h"

typedef NS_ENUM(unsigned int, SDStationType) {
	SDStationTypeTide,
	SDStationTypeCurrent
};

@interface StationMapController : UIViewController <CLLocationManagerDelegate,MKMapViewDelegate>

-(instancetype)initWithNibName:(NSString *)nibNameOrNil forStationType:(SDStationType)aStationType;
-(void)updateDisplayedStations;

@property (nonatomic,strong) IBOutlet MKMapView *mapView;
@property (assign,readwrite) SDStationType stationType;
@property (weak) id modalViewDelegate;
@property (nonatomic,strong) UISegmentedControl *tideCurrentSelector;

@end
