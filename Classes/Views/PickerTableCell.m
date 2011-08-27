//
//  PickerTableCell.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 8/5/10.
//  Copyright 2010 IntelliDOT Corporation. All rights reserved.
//

#import "PickerTableCell.h"


@implementation PickerTableCell

@synthesize flagView, nameLabel;

-(void)dealloc
{
    [flagView release];
    [nameLabel release];
    [super dealloc];
}
@end
