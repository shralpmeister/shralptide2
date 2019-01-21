//
//  InteractiveChartViewDelegate.h
//  ShralpTide2
//
//  Created by Michael Parlee on 1/21/19.
//
@protocol InteractiveChartViewDelegate <NSObject>

@required
- (void)displayHeight:(CGFloat)height atTime:(NSDate*)time withUnitString:(NSString*)units;
- (void)interactionsEnded;

@end
