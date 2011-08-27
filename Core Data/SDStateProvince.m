//
//  SDStateProvince.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "SDStateProvince.h"


@implementation SDStateProvince

@dynamic tideStations;

- (NSMutableSet *)mutableTideStations {
    return [self mutableSetValueForKey:@"tideStations"];
}

@end
