//
//  SDApplicationState.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/2/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SDFavoriteLocations;

@interface SDApplicationState : NSManagedObject

@property (nonatomic, retain) NSOrderedSet *favoriteLocations;
@end

@interface SDApplicationState (CoreDataGeneratedAccessors)

- (void)insertObject:(SDFavoriteLocations *)value inFavoriteLocationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFavoriteLocationsAtIndex:(NSUInteger)idx;
- (void)insertFavoriteLocations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFavoriteLocationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFavoriteLocationsAtIndex:(NSUInteger)idx withObject:(SDFavoriteLocations *)value;
- (void)replaceFavoriteLocationsAtIndexes:(NSIndexSet *)indexes withFavoriteLocations:(NSArray *)values;
- (void)addFavoriteLocationsObject:(SDFavoriteLocations *)value;
- (void)removeFavoriteLocationsObject:(SDFavoriteLocations *)value;
- (void)addFavoriteLocations:(NSOrderedSet *)values;
- (void)removeFavoriteLocations:(NSOrderedSet *)values;
@end
