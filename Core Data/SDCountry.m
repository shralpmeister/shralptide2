//
//  SDCountry.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "SDCountry.h"


@implementation SDCountry

@dynamic tideStations;
@dynamic states;

- (NSMutableSet *)mutableTideStations {
    return [self mutableSetValueForKey:@"tideStations"];
}

- (NSMutableSet *)mutableStates {
    return [self mutableSetValueForKey:@"states"];
}
@end
