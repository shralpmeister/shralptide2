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
#import "RootViewController.h"

NSString *kUnitsKey = @"units_preference";
NSString *kDaysKey = @"days_preference";
NSString *kCurrentsKey = @"currents_preference";
NSString *kBackgroundKey = @"background_preference";


@interface ShralpTideAppDelegate ()
- (void)setupByPreferences;
- (void)defaultsChanged:(NSNotification *)notif;
- (NSDictionary*)readSettingsDictionary;
@end

@implementation ShralpTideAppDelegate

@synthesize window;
@synthesize rootViewController;
@synthesize unitsPref, daysPref, showsCurrentsPref, backgroundPref;
@synthesize managedObjectModel, managedObjectContext, persistentStoreCoordinator;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary*)options {
    NSLog(@"applicationDidFinishLaunching");
    
    [self setupByPreferences];
    
    // listen for changes to our preferences
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    [rootViewController createMainViews];
    
	[window addSubview:[rootViewController view]];
	[window makeKeyAndVisible];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[rootViewController refreshViews];
}

#pragma mark -
#pragma mark Read Preferences

- (void)defaultsChanged:(NSNotification *)notif
{
    NSLog(@"Reading preferences and recreating views and tide calculations");
    [self setupByPreferences];
    [rootViewController createMainViews];
    [rootViewController doBackgroundTideCalculation];
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
        NSString *backgroundDefault = nil;
        
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
            else if ([keyValueStr isEqualToString:kBackgroundKey]) {
                backgroundDefault = defaultValue;
            }
        }
        
        // since no default values have been set (i.e. no preferences file created), create it here     
        NSDictionary *appDefaults = @{kUnitsKey: unitsDefault,
                                     kDaysKey: daysDefault,
                                     kCurrentsKey: currentsDefault,
                                     kBackgroundKey: backgroundDefault};
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // we're ready to go, so lastly set the key preference values
    self.unitsPref = [[NSUserDefaults standardUserDefaults] stringForKey:kUnitsKey];
    self.daysPref = [[NSUserDefaults standardUserDefaults] integerForKey:kDaysKey];
    self.showsCurrentsPref = [[NSUserDefaults standardUserDefaults] boolForKey:kCurrentsKey];
    self.backgroundPref = [[NSUserDefaults standardUserDefaults] stringForKey:kBackgroundKey];
    
    NSLog(@"setting daysPref to %d", daysPref);
    NSLog(@"Setting currentsPref to %@", showsCurrentsPref ? @"YES" : @"NO");
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
        [managedObjectContext setUndoManager:nil];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    
    NSString *datastorePath = [[NSBundle mainBundle] pathForResource:@"datastore" ofType:@"sqlite"];
    
    NSString *cachedDatastorePath = [cachesDir stringByAppendingPathComponent:@"datastore.sqlite"];
    
    if (![fm fileExistsAtPath:cachedDatastorePath]) {
        NSError *error;
        if (![fm copyItemAtPath:datastorePath toPath:cachedDatastorePath error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);
        };
    }
    
    NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:cachedDatastorePath] options:nil error:&error]) {
        // Handle the error.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }    
    
    return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? paths[0] : nil;
    return basePath;
}

@end
