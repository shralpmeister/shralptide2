//
//  SDState.h
//  ShralpTidePro
//
//  Created by Michael Parlee on 1/30/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SDState : NSManagedObject {
}

@property (nonatomic,retain) NSString *name;
@property (nonatomic,retain) NSString *flag;

@end