//
//  FlatChartView.m
//  ShralpTide2
//
//  Created by Michael Parlee on 10/19/13.
//
//

#import "SunMoonChartView.h"
#import "NSDate+Day.h"
#import "UIImage+Mask.h"

@interface SunMoonChartView ()

@property (nonatomic,strong) NSDateFormatter *hourFormatter;
@property (nonatomic,strong) NSDateFormatter *timeFormatter;

@end

@implementation SunMoonChartView

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
    _timeFormatter = [[NSDateFormatter alloc] init];
    [_timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    self.sunriseIcon = [[UIImage imageNamed:@"sunrise_trnspt"] maskImageWithColor:[UIColor yellowColor]];
    self.sunsetIcon = [[UIImage imageNamed:@"sunset_trnspt"] maskImageWithColor:[UIColor orangeColor]];
    self.moonriseIcon = [[UIImage imageNamed:@"moonrise_trnspt"] maskImageWithColor:[UIColor whiteColor]];
    self.moonsetIcon = [[UIImage imageNamed:@"moonset_trnspt"] maskImageWithColor:[UIColor whiteColor]];
    self.showZero = NO;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSArray *intervalsForDay = [super.tide intervalsFromDate:[self.datasource day] forHours:self.hoursToPlot];
    if ([intervalsForDay count] == 0) {
        return;
    }
    NSTimeInterval baseSeconds = [((SDTideInterval*)intervalsForDay[0]).time timeIntervalSince1970];
    
    // draws the sun/moon events
    float lastX = 0;
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
        UIFont *font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        CGFloat imageHeight = _labelInset + font.lineHeight;
        CGRect rect = CGRectMake(x - size.width / 2, imageHeight, size.width, size.height);
        
        // draw the sunmoon times
        CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
        CGContextSetRGBFillColor(context, 1, 1, 1, 1);
        NSString *time = [[_timeFormatter stringFromDate:event.eventTime] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        CGFloat yOffset = 0;
        CGFloat sunHeight = _labelInset;
        CGFloat moonHeight = imageHeight + rect.origin.y;
        if ([@[@"Sunrise", @"Sunset"] containsObject:event.eventTypeDescription]) {
            yOffset = sunHeight;
        } else {
            yOffset = moonHeight;
        }
        CGFloat timeWidth = [time sizeWithAttributes: font.fontDescriptor.fontAttributes].width;
        CGFloat timeCenterX = x - timeWidth / 2;
        if (timeCenterX < 0) {
            timeCenterX = 0;
        } else if (x + (timeWidth / 2) >= self.frame.size.width) {
            timeCenterX = self.frame.size.width - timeWidth - 10;
        }
        [time drawAtPoint:CGPointMake(timeCenterX, yOffset) withAttributes:@{ NSFontAttributeName:font, NSForegroundColorAttributeName: [UIColor whiteColor] }];
        
        [image drawInRect:rect];
    }
}


@end
