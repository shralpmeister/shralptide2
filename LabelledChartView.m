//
//  FlatChartView.m
//  ShralpTide2
//
//  Created by Michael Parlee on 10/19/13.
//
//

#import "LabelledChartView.h"
#import "NSDate+Day.h"
#import "UIImage+Mask.h"

@interface LabelledChartView ()

@property (nonatomic,strong) NSDateFormatter *hourFormatter;

@end

@implementation LabelledChartView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void)commonInit
{
    _labelInset = 0;
    _hourFormatter = [[NSDateFormatter alloc] init];
    _hourFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    self.sunriseIcon = [[UIImage imageNamed:@"sunrise_trnspt"] maskImageWithColor:[UIColor yellowColor]];
    self.sunsetIcon = [[UIImage imageNamed:@"sunset_trnspt"] maskImageWithColor:[UIColor orangeColor]];
    self.moonriseIcon = [[UIImage imageNamed:@"moonrise_trnspt"] maskImageWithColor:[UIColor whiteColor]];
    self.moonsetIcon = [[UIImage imageNamed:@"moonset_trnspt"] maskImageWithColor:[UIColor whiteColor]];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSArray *intervalsForDay = [super.tide intervalsFromDate:[self.datasource day] forHours:self.hoursToPlot];
    NSTimeInterval baseSeconds = [((SDTideInterval*)intervalsForDay[0]).time timeIntervalSince1970];
    
    // draws the sun/moon events
    for (SDTideEvent *event in super.tide.sunAndMoonEvents) {
        UIImage *image = nil;
        if (event.eventType == sunrise) {
            image = self.sunriseIcon;
        } else if (event.eventType == sunset) {
            image = self.sunsetIcon;
        } else if (event.eventType == moonrise) {
            image = self.moonriseIcon;
        } else if (event.eventType == moonset) {
            image = self.moonsetIcon;
        }
        int minute = ([event.eventTime timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
        float x = minute * self.xratio;
        CGSize size = CGSizeMake(15, 15);
        CGRect rect = CGRectMake(x - size.width / 2, _labelInset + 8, size.width, size.height);
        [image drawInRect:rect];
    }
    
    // draws the time labels
    float lastX = 0;
    for (SDTideInterval *tidePoint in intervalsForDay) {
		int minute = ([[tidePoint time] timeIntervalSince1970] - baseSeconds) / SECONDS_PER_MINUTE;
        //NSLog(@"Plotting interval: %@, min since midnight: %d",tidePoint.time, minute);
        if ([tidePoint.time isOnTheHour]) {
            float x = minute * self.xratio;
            if (x == 0 || x - lastX > 40) {
                lastX = x;
                CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
                CGContextSetRGBFillColor(context, 1, 1, 1, 1);
                NSString *hour = [[_hourFormatter stringFromDate:tidePoint.time] stringByReplacingOccurrencesOfString:@" " withString:@""];
                UIFont *font = [UIFont fontWithName:@"Helvetica Neue" size:9];
                [hour drawAtPoint:CGPointMake(x, _labelInset) withAttributes:@{ NSFontAttributeName:font, NSForegroundColorAttributeName: [UIColor whiteColor] }];
            }
        }
	}
}


@end