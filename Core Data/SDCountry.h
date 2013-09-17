//
//  SDCountry.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SDState.h"

@class SDStateProvince, SDTideStation;

@interface SDCountry : SDState

@property (nonatomic, retain) NSSet *states;
@property (nonatomic, retain) NSSet *tideStations;
@end

@interface SDCountry (CoreDataGeneratedAccessors)

- (void)addStatesObject:(SDStateProvince *)value;
- (void)removeStatesObject:(SDStateProvince *)value;
- (void)addStates:(NSSet *)values;
- (void)removeStates:(NSSet *)values;

- (void)addTideStationsObject:(SDTideStation *)value;
- (void)removeTideStationsObject:(SDTideStation *)value;
- (void)addTideStations:(NSSet *)values;
- (void)removeTideStations:(NSSet *)values;

@end
