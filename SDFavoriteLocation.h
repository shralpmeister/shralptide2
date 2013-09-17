//
//  SDFavoriteLocations.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/2/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SDApplicationState;

@interface SDFavoriteLocations : NSManagedObject

@property (nonatomic, retain) NSString * locationName;
@property (nonatomic, retain) SDApplicationState *applicationState;

@end
