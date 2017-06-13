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

+(ConfigHelper*)sharedInstance
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
    NSString *pathStr = [NSBundle mainBundle].bundlePath;
    NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
    NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
    
    return [NSDictionary dictionaryWithContentsOfFile:finalPath];
}

- (void)setupByPreferences
{
    NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
    NSString *testValue = [stdDefaults stringForKey:kUnitsKey];
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
        [stdDefaults setInteger:daysDefault.integerValue forKey:kDaysKey];
        [stdDefaults setValue:unitsDefault forKey:kUnitsKey];
        [stdDefaults setBool:currentsDefault.boolValue forKey:kCurrentsKey];
    }
    
    // we're ready to go, so lastly set the key preference values
    self.unitsPref = [stdDefaults stringForKey:kUnitsKey];
    self.daysPref = [stdDefaults integerForKey:kDaysKey];
    self.showsCurrentsPref = [stdDefaults boolForKey:kCurrentsKey];
    
    DLog(@"setting daysPref to %ld", (long)self.daysPref);
    DLog(@"Setting currentsPref to %@", self.showsCurrentsPref ? @"YES" : @"NO");
}

-(NSDictionary*)preferencesAsDictionary {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    dict[kUnitsKey] = self.unitsPref;
    dict[kDaysKey] = @(self.daysPref);
    dict[kCurrentsKey] = @(self.showsCurrentsPref);
    return dict;
}


@end
