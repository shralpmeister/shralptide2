//
//  SelectStationNavigationController.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 8/11/10.
//  Copyright 2010 IntelliDOT Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TideStationAnnotation.h"
#import "StationDetailViewController.h"

@interface SelectStationNavigationController : UINavigationController

@property (nonatomic,strong) UIBarButtonItem *doneButton;
@property (nonatomic,strong) TideStationAnnotation *selectedStation;
@property (unsafe_unretained) id<StationDetailViewControllerDelegate> detailViewDelegate;

@end
