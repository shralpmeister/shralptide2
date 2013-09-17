//
//  SDStateProvince.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SDState.h"

@class SDTideStation;

@interface SDStateProvince : SDState

@property (nonatomic, retain) NSSet *tideStations;
@end

@interface SDStateProvince (CoreDataGeneratedAccessors)

- (void)addTideStationsObject:(SDTideStation *)value;
- (void)removeTideStationsObject:(SDTideStation *)value;
- (void)addTideStations:(NSSet *)values;
- (void)removeTideStations:(NSSet *)values;

@end
