//
//  SDCountry.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//
#import "SDState.h"
#import "SDTideStation.h"
#import "SDStateProvince.h"
#import <Foundation/Foundation.h>


@interface SDCountry : SDState

@property (copy) NSSet *tideStations;
@property (copy,readonly) NSMutableSet *mutableTideStations;

@property (copy) NSSet *states;
@property (copy,readonly) NSMutableSet *mutableStates;

@end

@interface SDCountry (CoreDataGeneratedAccessors)

- (void)addTideStationsObject:(SDTideStation *)tideStation;
- (void)removeTideStationsObject:(SDTideStation *)tideStation;

- (void)addTideStations:(NSSet *)tideStations;
- (void)removeTideStations:(NSSet *)tideStations;

- (void)addStatesObject:(SDStateProvince *)stateProvince;
- (void)removeStatesObject:(SDStateProvince *)stateProvince;

- (void)addStates:(NSSet *)states;
- (void)removeStates:(NSSet *)states;

@end