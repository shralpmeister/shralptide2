//
//  TideStationAnnotation.m
//  ShralpTidePro
//
//  Created by Michael Parlee on 11/16/09.
//  Copyright 2009 IntelliDOT Corporation. All rights reserved.
//

#import "TideStationAnnotation.h"

@interface TideStationAnnotation()
@property (nonatomic,readwrite) CLLocationCoordinate2D coordinate;
@end


@implementation TideStationAnnotation

-(id)init
{
    if ((self = [super init])) {
        self.title = @"";
        self.subtitle = @"";
    }
    return self;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate
{
	if ( (self = [self init]) != nil ) {
		self.coordinate = aCoordinate;
	}
	return self;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"%@,%@,isPrimary=%d,%f,%f",self.title,self.subtitle,self.primary,self.coordinate.latitude,self.coordinate.longitude];
}

-(BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (other == nil || ![other isKindOfClass: [self class]])
        return NO;
    return [self isEqualToTideStationAnnotation:other];
}

-(BOOL)isEqualToTideStationAnnotation:(TideStationAnnotation*)other
{
    if (self == other)
        return YES;
    if (![self.title isEqualToString:other.title])
        return NO;
    if (![self.subtitle isEqualToString:other.subtitle])
        return NO;
    if (self.coordinate.latitude != other.coordinate.latitude)
        return NO;
    if (self.coordinate.longitude != other.coordinate.longitude)
        return NO;
    if (self.primary != other.primary) 
        return NO;
    return YES;
}

-(NSUInteger)hash
{
    int prime = 31;
    uint64_t result = 1;
    
    result = prime + [self.title hash];
    result = prime * result + [self.subtitle hash];
    result = prime * result + self.coordinate.longitude * 1000;
    result = prime * result + self.coordinate.latitude * 1000;
    result = prime * result + (self.primary?1231:1237);
    
    return result;
}

@end
