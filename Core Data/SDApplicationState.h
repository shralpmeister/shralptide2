//
//  SDApplicationState.h
//  ShralpTide2
//
//  Created by Michael Parlee on 3/30/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SDFavoriteLocation;

@interface SDApplicationState : NSManagedObject

@property (nonatomic, retain) NSOrderedSet *favoriteLocations;
@property (nonatomic, retain) SDFavoriteLocation *selectedLocation;
@end

@interface SDApplicationState (CoreDataGeneratedAccessors)

- (void)insertObject:(SDFavoriteLocation *)value inFavoriteLocationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFavoriteLocationsAtIndex:(NSUInteger)idx;
- (void)insertFavoriteLocations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFavoriteLocationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFavoriteLocationsAtIndex:(NSUInteger)idx withObject:(SDFavoriteLocation *)value;
- (void)replaceFavoriteLocationsAtIndexes:(NSIndexSet *)indexes withFavoriteLocations:(NSArray *)values;
- (void)addFavoriteLocationsObject:(SDFavoriteLocation *)value;
- (void)removeFavoriteLocationsObject:(SDFavoriteLocation *)value;
- (void)addFavoriteLocations:(NSOrderedSet *)values;
- (void)removeFavoriteLocations:(NSOrderedSet *)values;
@end
