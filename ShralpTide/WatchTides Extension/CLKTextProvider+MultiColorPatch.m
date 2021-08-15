//
//  CLKTextProvider+MultiColorPatch.m
//  ShralpyWatch Extension
//
//  Created by Michael Parlee on 10/6/18.
//

#import "CLKTextProvider+MultiColorPatch.h"

@implementation CLKTextProvider (MultiColorPatch)

+ (CLKTextProvider *)textProviderByJoiningTextProviders: (NSArray<CLKTextProvider *> *)textProviders separator:(NSString * _Nullable) separator {
    
    NSString *formatString = @"%@%@";
    
    if (separator.length > 0) {
        formatString = [NSString stringWithFormat:@"%@%@%@", @"%@", separator, @"%@"];
    }
    
    CLKTextProvider *firstItem = textProviders.firstObject;
    
    for (int index = 1; index < textProviders.count; index++) {
        CLKTextProvider *secondItem = [textProviders objectAtIndex: index];
        firstItem = [CLKTextProvider textProviderWithFormat:formatString, firstItem, secondItem];
    }
    
    return firstItem;
}

@end
