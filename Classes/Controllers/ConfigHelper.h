//
//  ConfigHelper.h
//  ShralpTide2
//
//  Created by Michael Parlee on 10/15/16.
//
//

#import <Foundation/Foundation.h>

@interface ConfigHelper : NSObject

@property (nonatomic,strong) NSString * _Nonnull unitsPref;
@property (nonatomic,assign) NSInteger daysPref;
@property (nonatomic,assign) BOOL showsCurrentsPref;
@property (nonatomic,assign) BOOL legacyMode;

- (void)setupByPreferences;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary * _Nonnull readSettingsDictionary;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary * _Nonnull preferencesAsDictionary;

+(nonnull ConfigHelper*)sharedInstance;

@end

