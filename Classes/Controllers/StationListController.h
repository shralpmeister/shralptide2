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
	NSArray *stations;
    NSMutableDictionary *sections;
    NSArray *sectionKeys;
}

@property (readonly) NSArray *stations;
@property (nonatomic,retain) NSMutableDictionary *sections;
@property (nonatomic,retain) NSArray *sectionKeys;

-(void)setStations:(NSArray*)newStations;
-(void)chooseStation:(SDTideStation*) station;

@end
