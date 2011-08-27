//
//  TideStationTableViewCell.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/20/10.
//  Copyright 2010 IntelliDOT Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TideStationTableViewCell : UITableViewCell {
    UILabel *nameLabel;
    UILabel *levelLabel;
    UILabel *directionLabel;
}

@property (nonatomic,assign) IBOutlet UILabel *nameLabel;
@property (nonatomic,assign) IBOutlet UILabel *levelLabel;
@property (nonatomic,assign) IBOutlet UILabel *directionLabel;

@end
