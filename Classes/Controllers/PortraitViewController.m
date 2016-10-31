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
#import "SDLocationMainViewController.h"
#import "CountryListController.h"
#import "FavoritesListViewController.h"

#import "UIImage+Mask.h"

#import "BackgroundScene.h"

#import <SpriteKit/SpriteKit.h>


@interface PortraitViewController ()

@property (nonatomic, assign) BOOL pageControlUsed;
@property (nonatomic, strong) SDHeaderViewController *headerViewController;
@property (nonatomic, strong) SDLocationMainViewController *locationMainViewController;
@property (nonatomic, strong) BackgroundScene *backgroundScene;
@property (nonatomic, assign) BOOL bannerIsVisible;

@end

@implementation PortraitViewController

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
    
    self.bannerIsVisible = NO;
    
    SKView *view = (SKView*)self.view;
    
    _backgroundScene = [BackgroundScene sceneWithSize:view.frame.size];
    _backgroundScene.name = @"Background Scene";
    _backgroundScene.scaleMode = SKSceneScaleModeAspectFill;
        
    self.automaticallyAdjustsScrollViewInsets = NO;
    for (UIViewController *controller in [self childViewControllers]) {
        if ([controller.restorationIdentifier isEqualToString:@"HeaderViewController"]) {
            self.headerViewController = (SDHeaderViewController*)controller;
        } else if ([controller.restorationIdentifier isEqualToString:@"MainViewController"]) {
            self.locationMainViewController = (SDLocationMainViewController*)controller;
        }
        self.locationMainViewController.headerViewController = self.headerViewController;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTideData) name:kSDApplicationActivatedNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshTideData
{
    DLog(@"Portrait View Controller got recalc notification. Reloading data");
    [self.headerViewController.collectionView reloadData];
    [self.locationMainViewController.collectionView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _listViewButton.imageView.image = [_listViewButton.imageView.image maskImageWithColor: [UIColor colorWithWhite:0.8 alpha:1]];
    
    SKView *backgroundView = (SKView*)self.view;
    if (backgroundView.isPaused) {
        backgroundView.paused = NO;
    } else {
        [backgroundView presentScene:_backgroundScene];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    SKView *backgroundView = (SKView*)self.view;
    backgroundView.paused = YES;
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

- (IBAction)changePage:(id)sender {
//    int page = self.pageControl.currentPage;
//    
//    // update the scroll view to the appropriate page
//    CGRect frame = self.collectionView.frame;
//    frame.origin.x = frame.size.width * page;
//    frame.origin.y = 0;
//    
//    [self.collectionView scrollRectToVisible:frame animated:YES];
//    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
//    self.pageControlUsed = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"locationMainViewSegue"]) {
        _locationMainViewController = (SDLocationMainViewController*)segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"landscapeSegue"]) {
        LandscapeViewController *landscapeController = (LandscapeViewController*)segue.destinationViewController;
        landscapeController.locationMainViewController = _locationMainViewController;
        _locationMainViewController.tideCalculationDelegate = landscapeController;
    } else if ([segue.identifier isEqualToString:@"FavoritesListSegue"]) {
        FavoritesListViewController *favoritesController = (FavoritesListViewController*)segue.destinationViewController;
        favoritesController.portraitViewController = self;
    }
}

@end
