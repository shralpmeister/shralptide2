//
//  UIImage+Mask.m
//  ShralpTide2
//
//  Created by Michael Parlee on 10/19/13.
//
//

#import "UIImage+Mask.h"

@implementation UIImage (Mask)

- (UIImage*)maskImageWithColor:(UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect imageRect = CGRectMake(0,0, self.size.width, self.size.height);
    
    // Flip image orientation
    CGContextTranslateCTM(context, 0.0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // Drawing code
    CGContextSetBlendMode(context, kCGBlendModeCopy);
	CGContextClipToMask(context, imageRect, [self CGImage]);
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, imageRect);
    
    UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return maskedImage;
}

@end
