//
//  ShralpTideAppDelegate.m
//  ShralpTide
//
//  Created by Michael Parlee on 7/23/08.
//  Copyright Michael Parlee 2009. All rights reserved.
/*
   This file is part of ShralpTide.

   ShralpTide is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   ShralpTide is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with ShralpTide.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "ShralpTideAppDelegate.h"
#import "SDTideFactory.h"
#import "ConfigHelper.h"
#import "ShralpTide2-Swift.h"

@interface ShralpTideAppDelegate ()
- (void)defaultsChanged:(NSNotification *)notif;

@property (nonatomic, strong) NSMutableArray *mutableTides;

@property (nonatomic, strong) NSString *cachedLocationFilePath;

@property (nonatomic, strong) NSDictionary<NSString*, NSString*>* countries;

@end

@implementation ShralpTideAppDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.supportedOrientations = UIInterfaceOrientationMaskPortrait;
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary*)options {
    DLog(@"applicationDidFinishLaunchingWithOptions");
    UIApplication.sharedApplication.statusBarStyle = UIStatusBarStyleLightContent;
    [ConfigHelper.sharedInstance setupByPreferences];
    
    // Enables background fetch to update UI at periodic intervals when backgrounded.
    [application setMinimumBackgroundFetchInterval:15*kSDSecondsPerMinute];
    
    // listen for changes to our preferences
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    // Load country data
    self.countries = [self readCountryData];
    
    // Load the tide station data
    NSMutableString *pathBuilder = [[NSMutableString alloc] init];
    if (ConfigHelper.sharedInstance.legacyMode) {
        [pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-20040614-wxtide" ofType:@"tcd"]];
    } else {
        [pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-free" ofType:@"tcd"]];
        [pathBuilder appendString:@":"];
        [pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-nonfree" ofType:@"tcd"]];
    }
	setenv("HFILE_PATH",[pathBuilder cStringUsingEncoding:NSUTF8StringEncoding],1);
    
    [AppStateData.sharedInstance loadSavedState];
    
    [WatchSessionManager.sharedInstance startSession];
    
    [self calculateTides];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return self.supportedOrientations;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    DLog(@"Application finished launching...");
    [self recalculateTidesForNewDay];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    DLog(@"Application entered foreground...");
    [self recalculateTidesForNewDay];
}

- (void)recalculateTidesForNewDay
{
    // when the app comes to foreground we need to refresh the tide (it could have been minutes, hours, days in suspended mode).
    DLog(@"Checking tide freshness...");
    NSDate *startDate = ((SDTide*)self.tides[0]).startTime;
    if ([[NSDate date] timeIntervalSinceDate: startDate] > 86400) {
        DLog(@"It's a new day. Recalculating tides.");
        [self calculateTides];
    } else {
        DLog(@"Tides are fresh as of %@", [NSDateFormatter localizedStringFromDate:startDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterLongStyle]);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSDApplicationActivatedNotification object:self];
}

- (void)calculateTides
{
    _mutableTides = [NSMutableArray new];
    for (SDFavoriteLocation* location in AppStateData.sharedInstance.persistentState.favoriteLocations) {
        SDTide *todaysTide = [SDTideFactory todaysTidesForStationName:location.locationName];
        [_mutableTides addObject:todaysTide];
    }
}

- (NSArray<SDTide*>*)tides
{
    return [NSArray arrayWithArray:_mutableTides];
}

#pragma mark - 
#pragma mark Handle preferences change
- (void)defaultsChanged:(NSNotification *)notif
{
    DLog(@"Reading preferences and recreating views and tide calculations");
    [ConfigHelper.sharedInstance setupByPreferences];
    [self calculateTides];
}

#pragma mark -
#pragma mark Handle Background Fetch
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self recalculateTidesForNewDay];
    completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark -
#pragma mark Misc Util Methods
- (NSDictionary<NSString*, NSString*>*) readCountryData {
    NSMutableDictionary<NSString*, NSString*>* result = [[NSMutableDictionary alloc] init];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"countries" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSArray *json = [NSJSONSerialization JSONObjectWithData:data  options:kNilOptions error:nil];
    for (NSDictionary* jsonObj in json) {
        NSString* key = jsonObj[@"Name"];
        NSString* value = jsonObj[@"Code"];
        result[key] = value;
    }
    return [[NSDictionary alloc] initWithDictionary:result];
}

@end
