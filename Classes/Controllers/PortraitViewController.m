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
#import "ShralpTide2-Swift.h"

#import "UIImage+Mask.h"

#import <SpriteKit/SpriteKit.h>


@interface PortraitViewController ()

@property (nonatomic, assign) BOOL pageControlUsed;
@property (nonatomic, strong) CurrentTideViewController *headerViewController;
@property (nonatomic, strong) SDBottomViewController *bottomViewController;

@end

@implementation PortraitViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
    for (UIViewController *controller in self.childViewControllers) {
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
    DLog(@"Portrait View Controller got recalc notification. Reloading data for page %ld", (long)AppStateData.sharedInstance.locationPage);
    [self.bottomViewController createPages:appDelegate.tides[AppStateData.sharedInstance.locationPage]];
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
    [self refreshTideData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Handle Screen Rotation
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Start seque transition at start of rotation
        [self handleInterfaceOrientation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // add code here for any actions that should happen on completion
    }];
}

- (void)handleInterfaceOrientation {
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) {
        // Landscape
        DLog(@"Device rotated to Landscape Left");
        [self performSegueWithIdentifier:@"landscapeSegue" sender:self];
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
