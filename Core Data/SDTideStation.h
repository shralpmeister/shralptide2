//
//  SDTideStation.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SDTideStation : NSManagedObject

@property (nonatomic, retain) NSNumber * primary;
@property (nonatomic, retain) NSNumber * current;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * units;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * state;

@end
