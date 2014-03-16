//
//  CurrentTidesVoiceOver.m
//  ShralpTide
//
//  Created by Michael Parlee on 9/19/09.
//  Copyright 2009 Michael Parlee. All rights reserved.
//

#import "CurrentTideView.h"


@implementation CurrentTideView

- (BOOL)isAccessibilityElement
{
	return YES;
}

- (NSString *)accessibilityLabel
{
	NSString *locationText = self.locationLabel.text;
	NSString *heightText = self.heightLabel.text;
	NSString *directionText = self.directionImgView.accessibilityLabel;
	
	if (nil == self.directionImgView.image) {
		return [NSString stringWithFormat:@"%@, %@", locationText, self.date.text];
	} else {
		return [NSString stringWithFormat:@"%@, %@, tide level is currently %@ and %@", locationText, self.date.text, heightText, directionText];
	}
}

- (UIAccessibilityTraits)accessibilityTraits
{
	return UIAccessibilityTraitStaticText;
}

- (NSString *)accessibilityHint
{
	return @"Current tide conditions for selected location.";
}

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)dealloc
{
    DLog(@"Whoa, %@, was dealloc'd",self);
}

@end
