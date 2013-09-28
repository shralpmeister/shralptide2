//
//  SDEventsViewController.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/23/13.
//
//

#import <UIKit/UIKit.h>
#import "SDTide.h"

@interface SDEventsViewController : UIViewController <UITableViewDataSource>

@property (nonatomic,weak) IBOutlet UILabel *dateLabel;
@property (nonatomic,strong) SDTide *tide;

@end
