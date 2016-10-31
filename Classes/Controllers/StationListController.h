//
//  StationListController.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShralpTide2-Swift.h"

@interface StationListController : UITableViewController

@property (nonatomic,strong) NSArray *stations;
@property (nonatomic,strong) NSMutableDictionary *sections;
@property (nonatomic,strong) NSArray *sectionKeys;

-(void)setStations:(NSArray*)newStations;
-(void)chooseStation:(SDTideStation*) station;

@end
