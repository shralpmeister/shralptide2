//
//  StationDetailViewController.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 12/9/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TideStationAnnotation.h"

@class SDTideStation;

@protocol StationDetailViewControllerDelegate;

@interface StationDetailViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic,strong) TideStationAnnotation *tideStationData;
@property (unsafe_unretained) id<StationDetailViewControllerDelegate> modalViewDelegate;
@property (nonatomic,strong) IBOutlet UIView *titleView;
@property (nonatomic,strong) IBOutlet MKMapView *mapView;
@property (nonatomic,strong) IBOutlet UILabel *titleLabel;
@property (nonatomic,strong) IBOutlet UIView *buttonView;
@property (nonatomic,strong) IBOutlet UIButton *selectButton;
@property (nonatomic, strong) UITableViewCell *locationCell;
@property (nonatomic, strong) UITableViewCell *primaryCell;

-(void)setTideStation:(SDTideStation*)station;

-(IBAction)addTideStation;

@end

@protocol StationDetailViewControllerDelegate

- (void) stationDetailViewController:(StationDetailViewController *)detailViewController 
                      addTideStation:(NSString *)stationName;

@end


