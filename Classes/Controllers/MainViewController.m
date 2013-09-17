//
//  MainViewController.m
//  ShralpTide
//
//  Created by Michael Parlee on 7/23/08.
//  Copyright Michael Parlee 2009. All rights reserved.
/*
   This file is part of ShralpTide.

   ShralpTide is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   ShralpTide is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with ShralpTide.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "MainViewController.h"
#import "SDTideFactory.h"
#import "SDTide.h"
#import "SDTideEvent.h"
#import "ShralpTideAppDelegate.h"
#include <mach/mach_time.h>

#define appDelegate ((ShralpTideAppDelegate*)[[UIApplication sharedApplication] delegate])

bool isTall();

double MachTimeToSecs(uint64_t time);

@interface MainViewController ()
- (int)currentTimeInMinutes:(NSDate *)time;
- (NSDate*)today;
- (UIImage*)createImageFromMaskImageNamed:(NSString*)imageName withColor:(UIColor*)color;

@property (nonatomic,strong) NSArray *table;
@property (assign) int pageNumber;
@property (nonatomic,strong) UIImage *backgroundImage;
@end

@implementation MainViewController

@synthesize sdTide;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		// Custom initialization
	}
	return self;
}

// Load the view nib and initialize the pageNumber ivar.
- (id)initWithPageNumber:(int)page {
    if ((self = [self initWithNibName:(isTall() ? @"MainViewTall" :  @"MainView") bundle:nil])) {
        self.pageNumber = page;
    }
    return self;
}

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
 */
- (void)viewDidLoad {
    NSString *imagePref = appDelegate.backgroundPref;
    self.bgImageView.image = [UIImage imageNamed: isTall() ? [NSString stringWithFormat:@"%@-568h", imagePref] : imagePref];
    
    if (isTall()) {
        NSDictionary *sunsetColorMap = @{
        @"woody" : [UIColor colorWithRed:0.431 green:0.318 blue:0.090 alpha:1.0],
        @"morning_glass" : [UIColor colorWithRed:0.059 green:0.122 blue:0.098 alpha:1.0],
        @"june_gloom" : [UIColor colorWithRed:0.263 green:0.263 blue:0.263 alpha:1.0],
        @"fall_gold" : [UIColor colorWithRed:0.549 green:0.384 blue:0.149 alpha:1.0]
        };
        self.sunriseImage.image = [self createImageFromMaskImageNamed:@"sunset_trnspt" withColor: [UIColor whiteColor]];
        self.sunsetImage.image = [self createImageFromMaskImageNamed:@"sunset_trnspt" withColor:sunsetColorMap[imagePref]];
        self.moonriseImage.image = [self createImageFromMaskImageNamed:@"moonset_trnspt" withColor:[UIColor whiteColor]];
        self.moonsetImage.image = [self createImageFromMaskImageNamed:@"moonset_trnspt" withColor:sunsetColorMap[imagePref]];
    }
    
	NSMutableArray *tempTable = [[NSMutableArray alloc] init];

	[tempTable addObject: @[self.time1, self.heightLabel1, self.state1, self.bullet1]];
	[tempTable addObject: @[self.time2, self.heightLabel2, self.state2, self.bullet2]];
	[tempTable addObject: @[self.time3, self.heightLabel3, self.state3, self.bullet3]];
	[tempTable addObject: @[self.time4, self.heightLabel4, self.state4, self.bullet4]];
	
	self.table = tempTable;
	
	[self refresh];
 }

- (UIImage*)createImageFromMaskImageNamed:(NSString*)imageName withColor:(UIColor*)color
{
    UIImage *image = [UIImage imageNamed:imageName];
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect imageRect = CGRectMake(0,0, image.size.width, image.size.height);
    
    // Flip image orientation
    CGContextTranslateCTM(context, 0.0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // Drawing code
    CGContextSetBlendMode(context, kCGBlendModeCopy);
	CGContextClipToMask(context, imageRect, [image CGImage]);
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, imageRect);
    
    UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return maskedImage;
}

- (void)setSdTide: (SDTide*)newTide {
	sdTide = newTide;
	[self refresh];
}

-(void)refresh {
	[self clearTable];
    
	if (self.sdTide == nil) {
        self.presentHeightLabel.text = @"";
        self.date.text = @"";
        self.tideStateImage.hidden = YES;
        self.locationLabel.text = @"";
        return;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterFullStyle;
    self.date.text = [formatter stringFromDate:self.today];
    self.tideStateImage.hidden = NO;
	
	self.locationLabel.text = [sdTide shortLocationName];
    
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    SDTideEvent *sunriseEvent = (SDTideEvent*)[sdTide sunriseSunsetEventsForDay:self.today][@"sunrise"];
    SDTideEvent *sunsetEvent = (SDTideEvent*)[sdTide sunriseSunsetEventsForDay:self.today][@"sunset"];    self.sunriseLabel.text = [formatter stringFromDate:sunriseEvent.eventTime];
    self.sunsetLabel.text = [formatter stringFromDate:sunsetEvent.eventTime];
    
    
    SDTideEvent *moonriseEvent = (SDTideEvent*)[sdTide moonriseMoonsetEventsForDay:self.today][@"moonrise"];
    if (moonriseEvent != nil) {
        self.moonriseLabel.text = [formatter stringFromDate:moonriseEvent.eventTime];
        self.moonriseImage.hidden = NO;
        self.moonriseLabel.hidden = NO;
    } else {
        self.moonriseImage.hidden = YES;
        self.moonriseLabel.hidden = YES;
    }
    SDTideEvent *moonsetEvent = (SDTideEvent*)[sdTide moonriseMoonsetEventsForDay:self.today][@"moonset"];
    if (moonsetEvent != nil) {
        self.moonsetLabel.text = [formatter stringFromDate:moonriseEvent.eventTime];
        self.moonsetImage.hidden = NO;
        self.moonsetLabel.hidden = NO;
    } else {
        self.moonsetImage.hidden = YES;
        self.moonsetLabel.hidden = YES;
    }
    self.moonsetLabel.text = [formatter stringFromDate:moonsetEvent.eventTime];
	
	int minutesSinceMidnight = [self currentTimeInMinutes:self.today];
	if (minutesSinceMidnight > 0) {
		[self updatePresentTideInfo];
	} else {
		[self.presentHeightLabel setText:@""];
	}
    
	if ([[sdTide eventsForDay:[self today]] count] > 4) {
		// there shouldn't be more than 4 tide events in a day -- 2 high, 2 low
		self.correctionLabel.text = @"Too many events predicted";
		return;
	}
	 
	int index = 0;
	for (SDTideEvent *event in [sdTide eventsForDay: [self today]]) {
		[self.table [index][0] setText: [event eventTimeNativeFormat]];
		[self.table [index][1] setText: [NSString stringWithFormat:@"%0.2f %@",[event eventHeight], [sdTide unitShort]]];
		[self.table [index][2] setText: [event eventTypeDescription]];
		NSLog(@"%@, %@, %@", [event eventTime], [NSString stringWithFormat:@"%0.2f %@",[event eventHeight], [sdTide unitShort]], [event eventTypeDescription]);
		++index;
	}
}

-(void)updatePresentTideInfo {
    if (sdTide == nil) {
        return;
    }
	int minutesSinceMidnight = [self currentTimeInMinutes:self.today];
	
	[self.presentHeightLabel setText:[NSString stringWithFormat:@"%0.2f %@",
							[sdTide nearestDataPointForTime: minutesSinceMidnight].y,
							[sdTide unitShort]]];
	SDTideStateRiseFall direction = [sdTide tideDirectionForTime:minutesSinceMidnight];
	NSString *imageName = nil;
	switch (direction) {
		case SDTideStateRising:
			imageName = @"Increasing";
			break;
		case SDTideStateFalling:
        default:
            imageName = @"Decreasing";
	}
	if (imageName != nil) {
		NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName 
															  ofType:@"png"];
		[self.tideStateImage setImage:[UIImage imageWithContentsOfFile:imagePath]];
		[self.tideStateImage setAccessibilityLabel:[imageName isEqualToString:@"Increasing"] ? @"rising" : @"falling"];
	} else {
		[self.tideStateImage setImage:nil];
	}
	
	NSNumber *nextEventIndex = [sdTide nextEventIndex];
	int index = 0;
	for (SDTideEvent *event in [sdTide eventsForDay:[self today]]) {
        if (index < 4) {
            if (nextEventIndex != nil && index == [nextEventIndex intValue]) {
                [self.table[index][3] setHidden:NO];
            } else {
                [self.table[index][3] setHidden:YES];
            }
        } else {
            [self clearTable];
            [self.correctionLabel setText:@"Too many events predicted"];
        }
		++index;
	}
}

-(void)clearTable {
	[self.correctionLabel setText:@""];
	for (NSArray *row in self.table) {
		[row[0] setText: @""];
		[row[1] setText: @""];
		[row[2] setText: @""];
		[row[3] setHidden:YES];
	}
}

-(NSDate*)today
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay: self.pageNumber];
    
    NSDate* today = [calendar dateByAddingComponents:components toDate:[sdTide startTime] options:0];
    
    return today;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return NO;
}

-(IBAction)chooseNearbyTideStation:(id)sender {
//    [self.rootViewController setLocationFromMap];
}

- (IBAction)chooseTideStation:(id)sender {
//	[self.rootViewController setLocationFromList];
}

-(IBAction)calculateOneYear:(id)sender
{
    uint64_t startTime = mach_absolute_time();
    SDTide *yearsWorth = [SDTideFactory tideForStationName:self.sdTide.stationName withInterval:0 forDays:365];
    uint64_t endTime = mach_absolute_time();
    NSLog(@"One years worth of events took %0.5f seconds",MachTimeToSecs(endTime - startTime));
//    for (SDTideEvent *event in yearsWorth.allEvents) {
//        NSLog(@"Event: %@", event);
//    }
}

#pragma mark UtilMethods
// This should be moved for better re-use... my obj-c/cocoa is lacking though... now in ChartView as well.

- (int)currentTimeInMinutes:(NSDate*)time {
	// The following shows the current time on the tide chart.  Need to make sure that it only shows on 
	// the current day!
	NSDate *datestamp = [NSDate date];
	
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	unsigned unitflags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *components = [gregorian components: unitflags fromDate: datestamp];
	
	NSDate *midnight = [gregorian dateFromComponents:components];
	
	if ([midnight compare:time] == NSOrderedSame) {
		return ([datestamp timeIntervalSince1970] - [midnight timeIntervalSince1970]) / 60;
	} else {
		return -1;
	}
}
@end

double MachTimeToSecs(uint64_t time) {
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / 1e9;
}

bool isTall() {
    CGSize result = [[UIScreen mainScreen] bounds].size;
       
    if (result.height == 568) {
        return true;
    } else {
        return false;
    }
}