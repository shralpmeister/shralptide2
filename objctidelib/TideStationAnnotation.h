//
//  TideStationAnnotation.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/16/09.
//  Copyright 2009 IntelliDOT Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TideStationAnnotation : NSObject <MKAnnotation> {
	NSString *title;
	NSString *subtitle;
	CLLocationCoordinate2D coordinate;
    BOOL primary;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate;
-(BOOL)isEqualToTideStationAnnotation:(TideStationAnnotation*)other;

@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *subtitle;
@property (assign, getter=isPrimary) BOOL primary;

@end
