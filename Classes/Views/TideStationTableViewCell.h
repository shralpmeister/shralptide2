//
//  TideStationTableViewCell.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/20/10.
//  Copyright 2010 IntelliDOT Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TideStationTableViewCell : UITableViewCell

@property (nonatomic,unsafe_unretained) IBOutlet UILabel *nameLabel;
@property (nonatomic,unsafe_unretained) IBOutlet UILabel *levelLabel;
@property (nonatomic,unsafe_unretained) IBOutlet UILabel *directionLabel;

@end
