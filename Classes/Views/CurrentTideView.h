//
//  CurrentTidesVoiceOver.h
//  ShralpTide
//
//  Created by Michael Parlee on 9/19/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CurrentTideView : UIView {
	IBOutlet UIImageView *directionImgView;
	IBOutlet UILabel *heightLabel;
	IBOutlet UILabel *locationLabel;
	IBOutlet UILabel *date;
}

@end