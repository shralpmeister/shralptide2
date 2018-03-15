//
//  TideStationTableViewCell.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/20/10.
//  Copyright 2010 IntelliDOT Corporation. All rights reserved.
//

#import "TideStationTableViewCell.h"

// This hack is to center the Cell Content inside the tableview.
// As of iOS 11 I noticed the content appeared to be going off the right
// side of the screen. I couldn't resolve it with any of the storyboard
// settings.
// TODO: Remove this if you noticed the cell content is indented too far
// on the right side.
const int LEFT_INSET = 0;
const int RIGHT_INSET = 20;

@implementation TideStationTableViewCell

- (void)setFrame:(CGRect)frame {
    frame.origin.x += LEFT_INSET;
    frame.size.width -= LEFT_INSET + RIGHT_INSET;
    [super setFrame:frame];
}

@end
