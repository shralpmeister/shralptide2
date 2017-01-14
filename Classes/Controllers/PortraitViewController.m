//
//  DailySummaryViewController.m
//  ShralpTide2
//
//  Created by Michael Parlee on 7/20/13.
//
//

#import "PortraitViewController.h"

#import "CountryListController.h"
#import "ChartViewController.h"
#import "StationMapController.h"
#import "SDBottomViewController.h"
#import "CountryListController.h"
#import "FavoritesListViewController.h"

#import "UIImage+Mask.h"

#import "BackgroundScene.h"

#import <SpriteKit/SpriteKit.h>


@interface PortraitViewController ()

@property (nonatomic, assign) BOOL pageControlUsed;
@property (nonatomic, strong) CurrentTideViewController *headerViewController;
@property (nonatomic, strong) SDBottomViewController *bottomViewController;
@property (nonatomic, strong) BackgroundScene *backgroundScene;

@end

@implementation PortraitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.automaticallyAdjustsScrollViewInsets = NO;
    for (UIViewController *controller in [self childViewControllers]) {
        if ([controller.restorationIdentifier isEqualToString:@"HeaderViewController"]) {
            self.headerViewController = (CurrentTideViewController*)controller;
        } else if ([controller.restorationIdentifier isEqualToString:@"MainViewController"]) {
            self.bottomViewController = (SDBottomViewController*)controller;
        }
    }
    
    if ([self.view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView*)self.view;
        imageView.image = [UIImage imageNamed:@"background-gradient"];
        imageView.contentMode = UIViewContentModeScaleToFill;
    }
    _listViewButton.imageView.image = [_listViewButton.imageView.image maskImageWithColor: [UIColor colorWithWhite:0.8 alpha:1]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTideData) name:kSDApplicationActivatedNotification object:nil];
    
    appDelegate.supportedOrientations = UIInterfaceOrientationMaskAll | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshTideData
{
    DLog(@"Portrait View Controller got recalc notification. Reloading data");
    [self.bottomViewController createPages:appDelegate.tides[appDelegate.locationPage]];
    [self.headerViewController refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshTideData];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Handle Screen Rotation
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            DLog(@"Device rotated to Landscape Left");
            [self performSegueWithIdentifier:@"landscapeSegue" sender:self];
            break;
        case UIInterfaceOrientationLandscapeRight:
            DLog(@"Device rotated to Landscape Right");
            [self performSegueWithIdentifier:@"landscapeSegue" sender:self];
            break;
        case UIInterfaceOrientationPortrait:
            DLog(@"Device rotated to Portrait");
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            DLog(@"Device rotated to Portrait upsidedown");
            break;
        case UIInterfaceOrientationUnknown:
            DLog(@"Device rotated to unknown position");
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"locationMainViewSegue"]) {
        _bottomViewController = (SDBottomViewController*)segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"landscapeSegue"]) {
        LandscapeViewController *landscapeController = (LandscapeViewController*)segue.destinationViewController;
        landscapeController.bottomViewController = _bottomViewController;
    } else if ([segue.identifier isEqualToString:@"FavoritesListSegue"]) {
        FavoritesListViewController *favoritesController = (FavoritesListViewController*)segue.destinationViewController;
        favoritesController.portraitViewController = self;
    }
}

@end
