//
//  MainViewController.h
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

#import "SDTide.h"
#import "RootViewController.h"

@interface MainViewController : UIViewController

-(void)refresh;
-(void)setSdTide:(SDTide*)newTide;
-(void)clearTable;
-(void)updatePresentTideInfo;

- (id)initWithPageNumber:(int)page;
-(IBAction)chooseTideStation:(id)sender;
-(IBAction)calculateOneYear:(id)sender;

@property (unsafe_unretained, readonly) SDTide *sdTide;
@property (nonatomic,strong) RootViewController *rootViewController;

@property (nonatomic,strong) IBOutlet UIImageView *bgImageView;
@property (nonatomic,strong) IBOutlet UILabel *locationLabel;
@property (nonatomic,strong) IBOutlet UILabel *presentHeightLabel;
@property (nonatomic,strong) IBOutlet UIImageView *tideStateImage;
@property (nonatomic,strong) IBOutlet UIImageView *sunriseImage;
@property (nonatomic,strong) IBOutlet UIImageView *sunsetImage;
@property (nonatomic,strong) IBOutlet UIImageView *moonriseImage;
@property (nonatomic,strong) IBOutlet UIImageView *moonsetImage;
@property (nonatomic,strong) IBOutlet UILabel *sunriseLabel;
@property (nonatomic,strong) IBOutlet UILabel *sunsetLabel;
@property (nonatomic,strong) IBOutlet UILabel *moonriseLabel;
@property (nonatomic,strong) IBOutlet UILabel *moonsetLabel;
@property (nonatomic,strong) IBOutlet UILabel *date;
@property (nonatomic,strong) IBOutlet UILabel *time1;
@property (nonatomic,strong) IBOutlet UILabel *time2;
@property (nonatomic,strong) IBOutlet UILabel *time3;
@property (nonatomic,strong) IBOutlet UILabel *time4;
@property (nonatomic,strong) IBOutlet UILabel *heightLabel1;
@property (nonatomic,strong) IBOutlet UILabel *heightLabel2;
@property (nonatomic,strong) IBOutlet UILabel *heightLabel3;
@property (nonatomic,strong) IBOutlet UILabel *heightLabel4;
@property (nonatomic,strong) IBOutlet UILabel *state1;
@property (nonatomic,strong) IBOutlet UILabel *state2;
@property (nonatomic,strong) IBOutlet UILabel *state3;
@property (nonatomic,strong) IBOutlet UILabel *state4;
@property (nonatomic,strong) IBOutlet UIImageView *bullet1;
@property (nonatomic,strong) IBOutlet UIImageView *bullet2;
@property (nonatomic,strong) IBOutlet UIImageView *bullet3;
@property (nonatomic,strong) IBOutlet UIImageView *bullet4;
@property (nonatomic,strong) IBOutlet UILabel *correctionLabel;
@property (nonatomic,strong) IBOutlet UIView *currentTideView;

@end
