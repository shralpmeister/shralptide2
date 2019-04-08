//
//  CLKTextProvider+MultiColorPatch.h
//  ShralpTide2
//
//  Created by Michael Parlee on 10/6/18.
//
#import <ClockKit/ClockKit.h>

@interface CLKTextProvider (MultiColorPatch)
+ (CLKTextProvider * _Nonnull)textProviderByJoiningTextProviders: (NSArray<CLKTextProvider *> * _Nonnull )textProviders separator:(NSString * _Nullable) separator;
@end
