//
//  SDStateProvince.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//
#import "SDState.h"
#import "SDTideStation.h"
#import <Foundation/Foundation.h>

@interface SDStateProvince : SDState

@property (copy) NSSet *tideStations;
@property (copy,readonly) NSMutableSet *mutableTideStations;

@end

@interface SDStateProvince (CoreDataGeneratedAccessors)

- (void)addTideStationsObject:(SDTideStation *)tideStation;
- (void)removeTideStationsObject:(SDTideStation *)tideStation;

- (void)addTideStations:(NSSet *)tideStations;
- (void)removeTideStations:(NSSet *)tideStations;


@end
