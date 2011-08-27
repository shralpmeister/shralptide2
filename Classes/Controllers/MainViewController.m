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

@interface MainViewController ()
- (int)currentTimeInMinutes:(SDTide *)tide;
-(NSDate*)today;
@end

@implementation MainViewController

@synthesize sdTide;
@synthesize currentTideView;
@synthesize rootViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		// Custom initialization
	}
	return self;
}

// Load the view nib and initialize the pageNumber ivar.
- (id)initWithPageNumber:(int)page {
    if ((self = [self initWithNibName:@"MainView" bundle:nil])) {
        pageNumber = page;
    }
    return self;
}

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
 */
- (void)viewDidLoad {
	NSMutableArray *tempTable = [[NSMutableArray alloc] init];
	[tempTable addObject: [NSArray arrayWithObjects: time1, heightLabel1, state1, bullet1, nil]];
	[tempTable addObject: [NSArray arrayWithObjects: time2, heightLabel2, state2, bullet2, nil]];
	[tempTable addObject: [NSArray arrayWithObjects: time3, heightLabel3, state3, bullet3, nil]];
	[tempTable addObject: [NSArray arrayWithObjects: time4, heightLabel4, state4, bullet4, nil]];
	
	table = [tempTable retain];
	[tempTable release];
	
	[self refresh];
 }

- (void)setSdTide: (SDTide*)newTide {
	[newTide retain];
	if (sdTide != nil) {
		[sdTide release];
	}
	sdTide = newTide;
	[self refresh];
}

-(void)refresh {
	[self clearTable];
    
	if (sdTide == nil) {
        [presentHeightLabel setText:@""];
        [date setText:@""];
        [tideStateImage setHidden:YES];
    } else {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterFullStyle];
        [date setText: [formatter stringFromDate:[self today]]];
        [formatter release];
        [tideStateImage setHidden:NO];
    }
	
	[locationLabel setText:[sdTide shortLocationName]];
	
	int minutesSinceMidnight = [self currentTimeInMinutes:sdTide];
	if (minutesSinceMidnight > 0) {
		[self updatePresentTideInfo];
	} else {
		[presentHeightLabel setText:@""];
	}
    
	if ([[sdTide eventsForDay:[self today]] count] > 4) {
		// there shouldn't be more than 4 tide events in a day -- 2 high, 2 low
		[correctionLabel setText:@"Too many events predicted"];
		return;
	}
	 
	int index = 0;
	for (SDTideEvent *event in [sdTide eventsForDay: [self today]]) {
		[[[table objectAtIndex:index] objectAtIndex:0] setText: [event eventTimeNativeFormat]];
		[[[table objectAtIndex:index] objectAtIndex:1] setText: [NSString stringWithFormat:@"%0.2f %@",[event eventHeight], [sdTide unitShort]]];
		[[[table objectAtIndex:index] objectAtIndex:2] setText: [event eventTypeDescription]];
		NSLog(@"%@, %@, %@", [event eventTime], [NSString stringWithFormat:@"%0.2f %@",[event eventHeight], [sdTide unitShort]], [event eventTypeDescription]);
		++index;
	}
}

-(void)updatePresentTideInfo {
    if (sdTide == nil) {
        return;
    }
	int minutesSinceMidnight = [self currentTimeInMinutes:sdTide];
	
	[presentHeightLabel setText:[NSString stringWithFormat:@"%0.2f %@",
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
		[tideStateImage setImage:[UIImage imageWithContentsOfFile:imagePath]];
		[tideStateImage setAccessibilityLabel:[imageName isEqualToString:@"Increasing"] ? @"rising" : @"falling"];
	} else {
		[tideStateImage setImage:nil];
	}
	
	NSNumber *nextEventIndex = [sdTide nextEventIndex];
	int index = 0;
	for (SDTideEvent *event in [sdTide eventsForDay:[self today]]) {
        if (index < 4) {
            if (nextEventIndex != nil && index == [nextEventIndex intValue]) {
                [[[table objectAtIndex:index] objectAtIndex:3] setHidden:NO];
            } else {
                [[[table objectAtIndex:index] objectAtIndex:3] setHidden:YES];
            }
        } else {
            [self clearTable];
            [correctionLabel setText:@"Too many events predicted"];
        }
		++index;
	}
}

-(void)clearTable {
	[correctionLabel setText:@""];
	for (NSArray *row in table) {
		[[row objectAtIndex:0] setText: @""];
		[[row objectAtIndex:1] setText: @""];
		[[row objectAtIndex:2] setText: @""];
		[[row objectAtIndex:3] setHidden:YES];
	}
}

-(NSDate*)today
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay: pageNumber];
    
    NSDate* today = [calendar dateByAddingComponents:components toDate:[sdTide startTime] options:0];
    
    [components release];
    return today;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return NO;
}

-(IBAction)chooseNearbyTideStation:(id)sender {
    [self.rootViewController setLocationFromMap];
}

- (IBAction)chooseTideStation:(id)sender {
	[self.rootViewController setLocationFromList];
}

-(IBAction)followHyperlink:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://devocean.com.au"]];
}

#pragma mark UtilMethods
// This should be moved for better re-use... my obj-c/cocoa is lacking though... now in ChartView as well.

- (int)currentTimeInMinutes:(SDTide *)tide {
	// The following shows the current time on the tide chart.  Need to make sure that it only shows on 
	// the current day!
	NSDate *datestamp = [NSDate date];
	
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	unsigned unitflags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *components = [gregorian components: unitflags fromDate: datestamp];
	
	NSDate *midnight = [gregorian dateFromComponents:components];
	
	if ([midnight compare:[self today]] == NSOrderedSame) {
		return ([datestamp timeIntervalSince1970] - [midnight timeIntervalSince1970]) / 60;
	} else {
		return -1;
	}
}

- (void)dealloc {
	[table release];
	[sdTide release];
	[super dealloc];
}

@end
