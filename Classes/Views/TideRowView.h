//
//  TideRowView.h
//  ShralpTide
//
//  Created by Michael Parlee on 9/20/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TideRowView : UIView {
}

@property (nonatomic, strong) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) IBOutlet UILabel *heightLabel;
@property (nonatomic, strong) IBOutlet UILabel *stateLabel;

@end
