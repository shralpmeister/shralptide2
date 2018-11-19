//
//  SDFavoritesControllerViewController.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/7/13.
//
//

#import <UIKit/UIKit.h>
#import "SelectStationNavigationController.h"

@class PortraitViewController;

@interface FavoritesListViewController : UITableViewController <StationDetailViewControllerDelegate>

@property (nonatomic,weak) PortraitViewController *portraitViewController;

@end
