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

@interface SelectStationNavigationController : UINavigationController {
    UIBarButtonItem *doneButton;
    TideStationAnnotation *selectedStation;
    id<StationDetailViewControllerDelegate> detailViewDelegate;
}

@property (nonatomic,retain) UIBarButtonItem *doneButton;
@property (nonatomic,retain) TideStationAnnotation *selectedStation;
@property (assign) id<StationDetailViewControllerDelegate> detailViewDelegate;

@end
