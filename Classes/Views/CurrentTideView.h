//
//  CurrentTidesVoiceOver.h
//  ShralpTide
//
//  Created by Michael Parlee on 9/19/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CurrentTideView : UIView

@property (nonatomic, strong) IBOutlet UIImageView *directionImgView;
@property (nonatomic, strong) IBOutlet UILabel *heightLabel;
@property (nonatomic, strong) IBOutlet UILabel *locationLabel;
@property (nonatomic, strong) IBOutlet UILabel *date;

@end
