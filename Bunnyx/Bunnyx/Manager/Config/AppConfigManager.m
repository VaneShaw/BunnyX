//
//  AppConfigManager.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "AppConfigManager.h"
#import "NetworkManager.h"
#import "APIResponseModel.h"
#import "BunnyxMacros.h"

@interface AppConfigManager ()

@property (nonatomic, strong) AppConfigModel *currentConfig;
@property (nonatomic, assign) BOOL isConfigLoaded;
@property (nonatomic, strong) NSDate *lastUpdateTime;
@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation AppConfigManager

#pragma mark - 单例

+ (instancetype)sharedManager {
    static AppConfigManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppConfigManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupManager];
    }
    return self;
}

- (void)setupManager {
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [self loadCachedConfig];
}

#pragma mark - 配置获取

- (void)getAppConfigWithSuccess:(AppConfigSuccessBlock)success
                        failure:(AppConfigFailureBlock)failure {
    [self getAppConfigWithForceRefresh:NO success:success failure:failure];
}

- (void)getAppConfigWithForceRefresh:(BOOL)forceRefresh
                              success:(AppConfigSuccessBlock)success
                              failure:(AppConfigFailureBlock)failure {
    
    // 如果不强制刷新且已有缓存，直接返回缓存
    if (!forceRefresh && self.currentConfig && [self shouldUseCachedConfig]) {
        BUNNYX_LOG(@"使用缓存的配置");
        if (success) {
            success(self.currentConfig);
        }
        return;
    }
    
    // 构建请求URL
    NSString *url = BUNNYX_API_SERVER_GET_APP_CONFIG;
    
    BUNNYX_LOG(@"请求应用配置: %@", url);
    
    // 发送GET请求
    [[NetworkManager sharedManager] GET:url
                             parameters:nil
                                success:^(id responseObject) {
        [self handleConfigResponse:responseObject success:success failure:failure];
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"获取应用配置失败: %@", error.localizedDescription);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)handleConfigResponse:(id)responseObject
                     success:(AppConfigSuccessBlock)success
                     failure:(AppConfigFailureBlock)failure {
    
    // 解析响应
    APIResponseModel *response = [APIResponseModel modelWithDictionary:responseObject];
    
    if (!response) {
        NSError *error = [NSError errorWithDomain:@"AppConfigManager" 
                                             code:-1 
                                         userInfo:@{NSLocalizedDescriptionKey: @"响应数据解析失败"}];
        if (failure) {
            failure(error);
        }
        return;
    }
    
    // 检查响应是否成功
    if (![response isSuccess]) {
        NSError *error = [NSError errorWithDomain:@"AppConfigManager" 
                                             code:response.code 
                                         userInfo:@{NSLocalizedDescriptionKey: [response errorMessage]}];
        if (failure) {
            failure(error);
        }
        return;
    }
    
    // 解析配置数据
    NSDictionary *configData = [response dataDictionary];
    if (!configData || configData.count == 0) {
        NSError *error = [NSError errorWithDomain:@"AppConfigManager" 
                                             code:-2 
                                         userInfo:@{NSLocalizedDescriptionKey: @"配置数据为空"}];
        if (failure) {
            failure(error);
        }
        return;
    }
    
    // 创建配置模型
    AppConfigModel *configModel = [AppConfigModel modelWithDictionary:configData];
    if (!configModel) {
        NSError *error = [NSError errorWithDomain:@"AppConfigManager" 
                                             code:-3 
                                         userInfo:@{NSLocalizedDescriptionKey: @"配置模型创建失败"}];
        if (failure) {
            failure(error);
        }
        return;
    }
    
    // 验证配置数据
    if (![configModel isValid]) {
        NSArray *errors = [configModel validationErrors];
        BUNNYX_ERROR(@"配置数据验证失败: %@", errors);
        NSError *error = [NSError errorWithDomain:@"AppConfigManager" 
                                             code:-4 
                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"配置数据验证失败: %@", [errors componentsJoinedByString:@", "]]}];
        if (failure) {
            failure(error);
        }
        return;
    }
    
    // 保存配置
    [self saveConfig:configModel];
    
    BUNNYX_LOG(@"应用配置获取成功: %@", [configModel configDescription]);
    
    if (success) {
        success(configModel);
    }
}

#pragma mark - 配置管理

- (void)clearConfigCache {
    [self.userDefaults removeObjectForKey:@"AppConfig"];
    [self.userDefaults removeObjectForKey:@"AppConfigUpdateTime"];
    [self.userDefaults synchronize];
    
    self.currentConfig = nil;
    self.isConfigLoaded = NO;
    self.lastUpdateTime = nil;
    
    BUNNYX_LOG(@"配置缓存已清除");
}

- (BOOL)shouldUpdateConfig {
    if (!self.currentConfig || !self.lastUpdateTime) {
        return YES;
    }
    
    // 检查缓存时间
    NSTimeInterval timeSinceLastUpdate = [[NSDate date] timeIntervalSinceDate:self.lastUpdateTime];
    NSTimeInterval cacheTime = self.currentConfig.cacheTime > 0 ? self.currentConfig.cacheTime : BUNNYX_CACHE_DURATION_MEDIUM;
    
    return timeSinceLastUpdate > cacheTime;
}

- (AppConfigModel *)getCachedConfig {
    return self.currentConfig;
}

- (BOOL)shouldUseCachedConfig {
    return self.currentConfig && !self.shouldUpdateConfig;
}

#pragma mark - 配置信息获取

- (NSDictionary *)getVersionInfo {
    if (!self.currentConfig) {
        return @{};
    }
    
    return @{
        @"appVersion": BUNNYX_SAFE_STRING(self.currentConfig.appVersion),
        @"latestVersion": BUNNYX_SAFE_STRING(self.currentConfig.latestVersion),
        @"minVersion": BUNNYX_SAFE_STRING(self.currentConfig.minVersion),
        @"needUpdate": @([self.currentConfig needUpdate]),
        @"forceUpdate": @([self.currentConfig isForceUpdate]),
        @"updateDescription": BUNNYX_SAFE_STRING(self.currentConfig.updateDescription),
        @"downloadUrl": BUNNYX_SAFE_STRING(self.currentConfig.downloadUrl)
    };
}

- (NSDictionary *)getCustomerServiceInfo {
    if (!self.currentConfig) {
        return @{};
    }
    
    return @{
        @"phone": BUNNYX_SAFE_STRING(self.currentConfig.customerServicePhone),
        @"email": BUNNYX_SAFE_STRING(self.currentConfig.customerServiceEmail),
        @"website": BUNNYX_SAFE_STRING(self.currentConfig.officialWebsite)
    };
}

- (NSDictionary *)getLinkInfo {
    if (!self.currentConfig) {
        return @{};
    }
    
    return @{
        @"privacyPolicy": BUNNYX_SAFE_STRING(self.currentConfig.privacyPolicyUrl),
        @"userAgreement": BUNNYX_SAFE_STRING(self.currentConfig.userAgreementUrl),
        @"aboutUs": BUNNYX_SAFE_STRING(self.currentConfig.aboutUsUrl),
        @"helpCenter": BUNNYX_SAFE_STRING(self.currentConfig.helpCenterUrl),
        @"feedback": BUNNYX_SAFE_STRING(self.currentConfig.feedbackUrl)
    };
}

- (NSDictionary *)getShareInfo {
    if (!self.currentConfig) {
        return @{};
    }
    
    return @{
        @"url": BUNNYX_SAFE_STRING(self.currentConfig.shareUrl),
        @"title": BUNNYX_SAFE_STRING(self.currentConfig.shareTitle),
        @"description": BUNNYX_SAFE_STRING(self.currentConfig.shareDescription),
        @"image": BUNNYX_SAFE_STRING(self.currentConfig.shareImage)
    };
}

- (NSDictionary *)getDebugInfo {
    if (!self.currentConfig) {
        return @{};
    }
    
    return @{
        @"debugMode": @(self.currentConfig.debugMode),
        @"logEnabled": @(self.currentConfig.logEnabled),
        @"logLevel": @(self.currentConfig.logLevel),
        @"cacheTime": @(self.currentConfig.cacheTime)
    };
}

#pragma mark - 私有方法

- (void)loadCachedConfig {
    NSData *configData = [self.userDefaults objectForKey:@"AppConfig"];
    if (configData) {
        NSDictionary *configDict = [NSKeyedUnarchiver unarchiveObjectWithData:configData];
        if (configDict) {
            self.currentConfig = [AppConfigModel modelWithDictionary:configDict];
            self.isConfigLoaded = YES;
        }
    }
    
    NSDate *updateTime = [self.userDefaults objectForKey:@"AppConfigUpdateTime"];
    if (updateTime) {
        self.lastUpdateTime = updateTime;
    }
}

- (void)saveConfig:(AppConfigModel *)config {
    self.currentConfig = config;
    self.isConfigLoaded = YES;
    self.lastUpdateTime = [NSDate date];
    
    // 保存到本地
    NSDictionary *configDict = [config toDictionary];
    NSData *configData = [NSKeyedArchiver archivedDataWithRootObject:configDict];
    [self.userDefaults setObject:configData forKey:@"AppConfig"];
    [self.userDefaults setObject:self.lastUpdateTime forKey:@"AppConfigUpdateTime"];
    [self.userDefaults synchronize];
    
    BUNNYX_LOG(@"配置已保存到本地");
}

@end
