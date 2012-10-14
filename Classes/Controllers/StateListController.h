//
//  StateListController.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDStateProvince.h"
#import "SDCountry.h"
#import "ShralpTideAppDelegate.h"


@interface StateListController : UITableViewController

@property (nonatomic,strong) NSArray *rows;

@end
