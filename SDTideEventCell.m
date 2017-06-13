//
//  SDTideEventCell.m
//  ShralpTide2
//
//  Created by Michael Parlee on 9/21/13.
//
//

#import "SDTideEventCell.h"

@implementation SDTideEventCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.timeLabel.adjustsFontSizeToFitWidth = YES;
        self.heightLabel.adjustsFontSizeToFitWidth = YES;
        self.typeLabel.adjustsFontSizeToFitWidth = YES;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
