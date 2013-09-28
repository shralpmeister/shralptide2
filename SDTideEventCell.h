//
//  SDTideEventCell.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/21/13.
//
//

#import <UIKit/UIKit.h>

@interface SDTideEventCell : UITableViewCell

@property (nonatomic,weak) IBOutlet UILabel* timeLabel;
@property (nonatomic,weak) IBOutlet UILabel* heightLabel;
@property (nonatomic,weak) IBOutlet UILabel* typeLabel;

@end
