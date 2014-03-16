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
#import "SDApplicationState.h"
#import "SDFavoriteLocation.h"
#import "SDTideFactory.h"

/* Preference Keys */
NSString *kUnitsKey = @"units_preference";
NSString *kDaysKey = @"days_preference";
NSString *kCurrentsKey = @"currents_preference";
NSString *kBackgroundKey = @"background_preference";

@interface ShralpTideAppDelegate ()
- (void)setupByPreferences;
- (void)defaultsChanged:(NSNotification *)notif;
- (NSDictionary*)readSettingsDictionary;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) SDApplicationState *persistentState;

@property (nonatomic, strong) NSMutableArray *mutableTides;

@property (nonatomic, strong) NSString *cachedLocationFilePath;

@end

@implementation ShralpTideAppDelegate

@synthesize managedObjectContext, persistentStoreCoordinator, managedObjectModel;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary*)options {
    DLog(@"applicationDidFinishLaunchingWithOptions");
    
    [self setupByPreferences];
    
    // listen for changes to our preferences
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    // Load the tide station data
    DLog(@"%@", [[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-free" ofType:@"tcd"]);
	NSMutableString *pathBuilder = [[NSMutableString alloc] init];
	[pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-free" ofType:@"tcd"]];
	[pathBuilder appendString:@":"];
	[pathBuilder appendString:[[NSBundle mainBundle] pathForResource:@"harmonics-dwf-20081228-nonfree" ofType:@"tcd"]];
	setenv("HFILE_PATH",[pathBuilder cStringUsingEncoding:NSUTF8StringEncoding],1);
    
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"SDApplicationState"
											  inManagedObjectContext:context];
    
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	fr.entity = entityDescription;
    NSError *error;
	NSArray *results = [context executeFetchRequest:fr error:&error];
	if ([results count] == 0) {
        // create a new entity
        [self setDefaultLocation];
    } else {
        // set a reference to the one we already have
        self.persistentState = results[0];
    }
    [self calculateTides];
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
    for (SDFavoriteLocation* location in self.persistentState.favoriteLocations) {
        SDTide *todaysTide = [SDTideFactory todaysTidesForStationName:location.locationName];
        [_mutableTides addObject:todaysTide];
    }
}

- (NSArray*)tides
{
    return [NSArray arrayWithArray:_mutableTides];
}

#pragma mark -
#pragma mark Read Preferences

- (void)defaultsChanged:(NSNotification *)notif
{
    DLog(@"Reading preferences and recreating views and tide calculations");
    [self setupByPreferences];
    [self calculateTides];
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
    
    DLog(@"setting daysPref to %ld", (long)self.daysPref);
    DLog(@"Setting currentsPref to %@", self.showsCurrentsPref ? @"YES" : @"NO");
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
    };
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"shralptide" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
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
    NSString *tideDatastorePath = [[NSBundle mainBundle] pathForResource:@"datastore" ofType:@"sqlite"];
    NSString *cachedTideDatastorePath = [cachesDir stringByAppendingPathComponent:@"datastore.sqlite"];
    
    NSString *libDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString *stateDataStorePath = [libDir stringByAppendingPathComponent:@"appstate.sqlite"];
    
    
    if (![fm fileExistsAtPath:cachedTideDatastorePath]) {
        NSError *error;
        if (![fm copyItemAtPath:tideDatastorePath toPath:cachedTideDatastorePath error:&error]) {
            DLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);
        };
    }
    
    NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration:@"TideDatastore" URL:[NSURL fileURLWithPath:cachedTideDatastorePath] options:nil error:&error]) {
        // Handle the error.
        DLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    if (![persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration:@"StateDatastore" URL:[NSURL fileURLWithPath:stateDataStorePath] options:nil error:&error]) {
        // Handle the error.
        DLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    return persistentStoreCoordinator;
}

- (void)setDefaultLocation {
    // This is what we do when there's no location set.
	NSString *defaultLocation = @"La Jolla (Scripps Institution Wharf), California";
    NSManagedObjectContext *context = self.managedObjectContext;
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"SDApplicationState" inManagedObjectContext:context];
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
    fr.entity = entityDesc;
    
    NSError *error;
    NSArray *fetchResults = [context executeFetchRequest:fr error:&error];
    if (fetchResults) {
        SDApplicationState *appState = nil;
        if ([fetchResults count] == 0) {
            appState = [NSEntityDescription insertNewObjectForEntityForName:entityDesc.name inManagedObjectContext:context];
            appState.selectedLocationIndex = @0;
            SDFavoriteLocation *location = [NSEntityDescription insertNewObjectForEntityForName:@"SDFavoriteLocation" inManagedObjectContext:context];
            location.locationName = defaultLocation;
            appState.favoriteLocations = [NSOrderedSet orderedSetWithObject:location];
            
            if (![context save:&error]) {
                DLog(@"Unable to save change to default location. %@", error);
                return;
            }
            self.persistentState = appState;
        }
    } else {
        DLog(@"Unable to execute fetch for default location due to error: %@", error);
        return;
    }
}

- (void)addFavoriteLocation:(NSString*)locationName
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"SDApplicationState" inManagedObjectContext:context];
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
    fr.entity = entityDesc;
    
    NSError *error;
    NSArray *fetchResults = [context executeFetchRequest:fr error:&error];
    if (fetchResults && [fetchResults count] == 1) {
        SDApplicationState *appState = [fetchResults objectAtIndex:0];
        NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"locationName = %@",locationName];
        NSOrderedSet *results = [appState.favoriteLocations filteredOrderedSetUsingPredicate:namePredicate];
        if ([results count] == 0) {
            SDFavoriteLocation *location = [NSEntityDescription insertNewObjectForEntityForName:@"SDFavoriteLocation" inManagedObjectContext:context];
            location.locationName = locationName;
            NSMutableOrderedSet *locations = [[NSMutableOrderedSet alloc] initWithOrderedSet:appState.favoriteLocations];
            [locations addObject:location];
            appState.favoriteLocations = locations;
        } else {
            DLog(@"Location already present. Skipping.");
            return;
        }
        if (![context save:&error]) {
            DLog(@"Unable to save new favorite location. %@", error);
            return;
        }
        [self calculateTides];
    } else {
        DLog(@"Unable to retrieve applications state. Fetch result = %@",fetchResults);
    }
}

- (void)setSelectedLocation:(NSString*)locationName
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"SDApplicationState" inManagedObjectContext:context];
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
    fr.entity = entityDesc;
    
    NSError *error;
    NSArray *fetchResults = [context executeFetchRequest:fr error:&error];
    if (fetchResults && [fetchResults count] == 1) {
        SDApplicationState *appState = [fetchResults objectAtIndex:0];
        NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"locationName = %@", locationName];
        NSOrderedSet* locationsWithName = [appState.favoriteLocations filteredOrderedSetUsingPredicate:namePredicate];
        if ([locationsWithName count] == 1) {
            SDFavoriteLocation *location = locationsWithName[0];
            appState.selectedLocationIndex = @([appState.favoriteLocations indexOfObject:location]);
            if (![context save:&error]) {
                DLog(@"Unable to save change to selected location. %@",error);
                return;
            }
        }
    } else {
        DLog(@"Unable to retrieve applications state. Fetch result = %@",fetchResults);
    }
}

- (void)removeFavoriteLocation:(NSString *)locationName
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"SDApplicationState" inManagedObjectContext:context];
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
    fr.entity = entityDesc;
    
    NSError *error;
    NSArray *fetchResults = [context executeFetchRequest:fr error:&error];
    if (fetchResults && [fetchResults count] == 1) {
        SDApplicationState *appState = [fetchResults objectAtIndex:0];
        NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"locationName = %@", locationName];
        NSOrderedSet* locationsWithName = [appState.favoriteLocations filteredOrderedSetUsingPredicate:namePredicate];
        if ([locationsWithName count] == 1) {
            SDFavoriteLocation *location = locationsWithName[0];
            SDFavoriteLocation *currentSelection = [appState.favoriteLocations objectAtIndex:[appState.selectedLocationIndex intValue]];
            if ([location isEqual:currentSelection]) {
                appState.selectedLocationIndex = 0;
            }
            [context deleteObject:location];
            appState.selectedLocationIndex = @([appState.favoriteLocations indexOfObject:currentSelection]);
            if (![context save:&error]) {
                DLog(@"Unable to save change to selected location. %@",error);
                return;
            }
        }
        [self calculateTides];
    } else {
        DLog(@"Unable to retrieve applications state. Fetch result = %@",fetchResults);
        return nil;
    }
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

#pragma mark savestate

- (BOOL)writeApplicationPlist:(id)plist toFile:(NSString *)fileName {
    NSString *error;
    NSData *pData = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
    if (!pData) {
        DLog(@"%@", error);
        return NO;
    }
    return ([pData writeToFile:self.cachedLocationFilePath atomically:YES]);
}

- (id)applicationPlistFromFile:(NSString *)fileName {
    NSData *retData;
    NSString *error;
    id retPlist;
    NSPropertyListFormat format;
	
    retData = [[NSData alloc] initWithContentsOfFile:self.cachedLocationFilePath];
    if (!retData) {
        DLog(@"Data file not returned.");
        return nil;
    }
    retPlist = [NSPropertyListSerialization propertyListFromData:retData  mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    if (!retPlist){
        DLog(@"Plist not returned, error: %@", error);
    }
    
    return retPlist;
}

@end
