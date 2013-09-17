//
//  SDFavoriteLocation.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SDApplicationState;

@interface SDFavoriteLocation : NSManagedObject

@property (nonatomic, retain) NSString * locationName;
@property (nonatomic, retain) SDApplicationState *applicationState;

@end
