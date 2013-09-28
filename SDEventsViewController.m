//
//  SDEventsViewController.m
//  ShralpTide2
//
//  Created by Michael Parlee on 9/23/13.
//
//

#import "SDEventsViewController.h"
#import "SDTideEvent.h"
#import "SDTideEventCell.h"

@interface SDEventsViewController ()

@end

@implementation SDEventsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark Table View Data Source methods

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.tide events] count];
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* reuseId = @"eventCell";
    SDTideEvent *event = (SDTideEvent*)self.tide.events[indexPath.row];
    SDTideEventCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    cell.timeLabel.text = event.eventTimeNativeFormat;
    cell.heightLabel.text = [NSString stringWithFormat:@"%1.2f %@",event.eventHeight,self.tide.unitShort];
    cell.typeLabel.text = event.eventTypeDescription;
    return cell;
}

@end
