//
//  StationListController.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDTideStation.h"

@interface StationListController : UITableViewController {
	NSArray *__unsafe_unretained stations;
    NSMutableDictionary *sections;
    NSArray *sectionKeys;
}

@property (unsafe_unretained, readonly) NSArray *stations;
@property (nonatomic,strong) NSMutableDictionary *sections;
@property (nonatomic,strong) NSArray *sectionKeys;

-(void)setStations:(NSArray*)newStations;
-(void)chooseStation:(SDTideStation*) station;

@end
