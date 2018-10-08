//
//  CLKTextProvider+MultiColorPatch.h
//  ShralpTide2
//
//  Created by Michael Parlee on 10/6/18.
//
#import <ClockKit/ClockKit.h>

@interface CLKTextProvider (MultiColorPatch)
+ (CLKTextProvider *)textProviderByJoiningTextProviders: (NSArray<CLKTextProvider *> *)textProviders separator:(NSString * _Nullable) separator;
@end
