//
//  ConfigHelper.m
//  ShralpTide2
//
//  Created by Michael Parlee on 10/15/16.
//
//

#import "ConfigHelper.h"

/* Preference Keys */
NSString *kUnitsKey = @"units_preference";
NSString *kDaysKey = @"days_preference";
NSString *kCurrentsKey = @"currents_preference";

@implementation ConfigHelper

+(id)sharedInstance
{
    static ConfigHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ConfigHelper alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

-(NSDictionary*)readSettingsDictionary
{
    NSString *pathStr = [[NSBundle mainBundle] bundlePath];
    NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
    NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
    
    return [NSDictionary dictionaryWithContentsOfFile:finalPath];
}

- (void)setupByPreferences
{
    NSString *testValue = [[NSUserDefaults standardUserDefaults] stringForKey:kUnitsKey];
    if (testValue == nil)
    {
        // no default values have been set, create them here based on what's in our Settings bundle info
        //
        NSDictionary *settingsDict = [self readSettingsDictionary];
        NSArray *prefSpecifierArray = settingsDict[@"PreferenceSpecifiers"];
        
        NSString *unitsDefault = nil;
        NSNumber *daysDefault = nil;
        NSNumber *currentsDefault = nil;
        
        for (NSDictionary *prefItem in prefSpecifierArray)
        {
            NSString *keyValueStr = prefItem[@"Key"];
            id defaultValue = prefItem[@"DefaultValue"];
            
            if ([keyValueStr isEqualToString:kUnitsKey])
            {
                unitsDefault = defaultValue;
            }
            else if ([keyValueStr isEqualToString:kDaysKey])
            {
                daysDefault = defaultValue;
            }
            else if ([keyValueStr isEqualToString:kCurrentsKey])
            {
                currentsDefault = defaultValue;
            }
        }
        
        // since no default values have been set (i.e. no preferences file created), create it here
        NSDictionary *appDefaults = @{kUnitsKey: unitsDefault,
                                      kDaysKey: daysDefault,
                                      kCurrentsKey: currentsDefault};
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // we're ready to go, so lastly set the key preference values
    self.unitsPref = [[NSUserDefaults standardUserDefaults] stringForKey:kUnitsKey];
    self.daysPref = [[NSUserDefaults standardUserDefaults] integerForKey:kDaysKey];
    self.showsCurrentsPref = [[NSUserDefaults standardUserDefaults] boolForKey:kCurrentsKey];
    
    DLog(@"setting daysPref to %ld", (long)self.daysPref);
    DLog(@"Setting currentsPref to %@", self.showsCurrentsPref ? @"YES" : @"NO");
}

-(NSDictionary*)preferencesAsDictionary {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:self.unitsPref forKey:kUnitsKey];
    [dict setObject:[NSNumber numberWithLong:self.daysPref] forKey:kDaysKey];
    [dict setObject:[NSNumber numberWithBool:self.showsCurrentsPref] forKey:kCurrentsKey];
    return dict;
}


@end
