//
//  HostEnvironmentManager.m
//  Bunnyx
//
//  Created by Assistant on 2025/11/19.
//

#import "HostEnvironmentManager.h"

NSString * const BXHostEnvironmentDidChangeNotification = @"BXHostEnvironmentDidChangeNotification";

static NSString * const kBXHostEnvironmentKey = @"BXHostEnvironmentKey";
static NSString * const kBXHostCustomURLKey = @"BXHostEnvironmentCustomURLKey";
static NSString * const kBXHostProductionURL = @"https://api.bunnyx.com";
static NSString * const kBXHostTestURL = @"https://testappapi.bunnyx.ai";

@interface HostEnvironmentManager ()

@property (nonatomic, assign) BXHostEnvironmentType currentEnvironment;
@property (nonatomic, copy) NSString *customBaseURL;

@end

@implementation HostEnvironmentManager

+ (instancetype)sharedManager {
    static HostEnvironmentManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HostEnvironmentManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger storedEnv = [defaults integerForKey:kBXHostEnvironmentKey];
        
#ifdef DEBUG
        BXHostEnvironmentType defaultEnv = BXHostEnvironmentTypeTest;
#else
        BXHostEnvironmentType defaultEnv = BXHostEnvironmentTypeProduction;
#endif
        if (storedEnv < BXHostEnvironmentTypeProduction || storedEnv > BXHostEnvironmentTypeCustom) {
            storedEnv = defaultEnv;
        }
        _currentEnvironment = (BXHostEnvironmentType)storedEnv;
        NSString *storedCustomURL = [defaults stringForKey:kBXHostCustomURLKey] ?: @"";
        _customBaseURL = [self sanitizedURL:storedCustomURL];
    }
    return self;
}

- (NSString *)currentBaseURL {
    switch (self.currentEnvironment) {
        case BXHostEnvironmentTypeProduction:
            return kBXHostProductionURL;
        case BXHostEnvironmentTypeTest:
            return kBXHostTestURL;
        case BXHostEnvironmentTypeCustom: {
            NSString *customURL = [self sanitizedURL:self.customBaseURL];
            if (customURL.length > 0) {
                return customURL;
            }
            return kBXHostTestURL;
        }
    }
}

- (void)switchToEnvironment:(BXHostEnvironmentType)environment customURL:(NSString * _Nullable)customURL {
    if (environment == BXHostEnvironmentTypeCustom) {
        NSString *sanitized = [self sanitizedURL:customURL];
        if (sanitized.length == 0) {
            NSLog(@"[HostEnvironmentManager] 自定义地址无效，保持原状");
            return;
        }
        self.customBaseURL = sanitized;
        [[NSUserDefaults standardUserDefaults] setObject:sanitized forKey:kBXHostCustomURLKey];
    }
    
    self.currentEnvironment = environment;
    [[NSUserDefaults standardUserDefaults] setInteger:environment forKey:kBXHostEnvironmentKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BXHostEnvironmentDidChangeNotification object:nil];
}

#pragma mark - Helpers

- (NSString *)sanitizedURL:(NSString *)urlString {
    if (!urlString || urlString.length == 0) {
        return @"";
    }
    NSString *trimmed = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return @"";
    }
    if (![trimmed.lowercaseString hasPrefix:@"http://"] && ![trimmed.lowercaseString hasPrefix:@"https://"]) {
        trimmed = [@"https://" stringByAppendingString:trimmed];
    }
    // 去掉结尾的 /
    while ([trimmed hasSuffix:@"/"] && trimmed.length > 8) {
        trimmed = [trimmed substringToIndex:trimmed.length - 1];
    }
    return trimmed;
}

@end

