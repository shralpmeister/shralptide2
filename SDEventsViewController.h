//
//  SDEventsViewController.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/23/13.
//
//

#import <UIKit/UIKit.h>
#import "SDTide.h"
#import "ChartView.h"

@interface SDEventsViewController : UIViewController <UITableViewDataSource,ChartViewDatasource>

@property (nonatomic,weak) IBOutlet UILabel *dateLabel;
@property (nonatomic,strong) IBOutlet ChartView *chartView;
@property (nonatomic,weak) IBOutlet UIScrollView *chartScrollView;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *bottomVerticalConstraint;
@property (nonatomic,strong) SDTide *tide;

@end
