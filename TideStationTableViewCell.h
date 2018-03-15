//
//  TideStationTableViewCell.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/20/10.
//  Copyright 2010 IntelliDOT Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDTide.h"

@interface TideStationTableViewCell : UITableViewCell

@property (nonatomic,weak) SDTide *tide;
@property (nonatomic,weak) IBOutlet UILabel *nameLabel;
@property (nonatomic,weak) IBOutlet UILabel *levelLabel;
@property (nonatomic,weak) IBOutlet UIImageView *directionArrowView;

@end
