//
//  ConfigHelper.h
//  ShralpTide2
//
//  Created by Michael Parlee on 10/15/16.
//
//

#import <Foundation/Foundation.h>

@interface ConfigHelper : NSObject

@property (nonatomic,strong) NSString *unitsPref;
@property (nonatomic,assign) NSInteger daysPref;
@property (nonatomic,assign) BOOL showsCurrentsPref;

- (void)setupByPreferences;
- (NSDictionary*)readSettingsDictionary;
- (NSDictionary*)preferencesAsDictionary;

+(id)sharedInstance;

@end

