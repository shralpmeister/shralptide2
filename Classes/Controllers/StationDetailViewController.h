//
//  StationDetailViewController.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 12/9/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TideStationAnnotation.h"
#import "SDTideStation.h"

@protocol StationDetailViewControllerDelegate;

@interface StationDetailViewController : UIViewController <MKMapViewDelegate>
{
	id<StationDetailViewControllerDelegate> modalViewDelegate;
	TideStationAnnotation *tideStationData;
    UIImage *mapImage;
    
    UIView *titleView;
    UIView *buttonView;
    UILabel *titleLabel;
    UIButton *selectButton;
    MKMapView *mapView;
    
    UITableViewCell *locationCell;
    UITableViewCell *primaryCell;
}

@property (nonatomic,retain) TideStationAnnotation *tideStationData;
@property (assign) id<StationDetailViewControllerDelegate> modalViewDelegate;
@property (nonatomic,retain) IBOutlet UIView *titleView;
@property (nonatomic,retain) IBOutlet MKMapView *mapView;
@property (nonatomic,retain) IBOutlet UILabel *titleLabel;
@property (nonatomic,retain) IBOutlet UIView *buttonView;
@property (nonatomic,retain) IBOutlet UIButton *selectButton;
@property (nonatomic, retain) UITableViewCell *locationCell;
@property (nonatomic, retain) UITableViewCell *primaryCell;

-(void)setTideStation:(SDTideStation*)station;

-(IBAction)addTideStation;

@end

@protocol StationDetailViewControllerDelegate

- (void) stationDetailViewController:(StationDetailViewController *)detailViewController 
                      addTideStation:(NSString *)stationName;

@end


