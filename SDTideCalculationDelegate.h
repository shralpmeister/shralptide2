//
//  SDTideCalculationDelegate.h
//  ShralpTide2
//
//  Created by Michael Parlee on 12/1/13.
//
//

#import <Foundation/Foundation.h>

@protocol SDTideCalculationDelegate <NSObject>

@required
- (void)tideCalculationsCompleted:(NSArray*)tides;

@end
