//
//  InteractiveChartView.h
//  ShralpTide2
//
//  Created by Michael Parlee on 11/2/13.
//
//

#import "LabelledChartView.h"

@protocol InteractiveChartViewDelegate <NSObject>

@required
- (void)displayHeight:(CGFloat)height atTime:(NSDate*)time withUnitString:(NSString*)units;
- (void)interactionsEnded;

@end

@interface InteractiveChartView : LabelledChartView <CAAnimationDelegate>

- (void)animateCursorViewToCurrentTime;
- (void)animateFirstTouchAtPoint:(CGPoint)touchPoint;
- (void)showTideForPoint:(CGPoint) point;

@property (nonatomic,weak) IBOutlet id<InteractiveChartViewDelegate> delegate;

@end

