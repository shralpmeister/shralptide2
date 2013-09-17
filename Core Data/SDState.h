//
//  SDState.h
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SDState : NSManagedObject

@property (nonatomic, retain) NSString * flag;
@property (nonatomic, retain) NSString * name;

@end
