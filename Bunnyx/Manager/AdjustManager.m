//
//  AdjustManager.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "AdjustManager.h"
#import <UIKit/UIKit.h>
#import <AdjustSdk/AdjustSdk.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "APIResponseModel.h"

// 本地存储的 Key
static NSString *const KEY_CHANNEL = @"AdjustManager_Channel";
static NSString *const KEY_IDFA = @"AdjustManager_IDFA";
static NSString *const KEY_ADID = @"AdjustManager_Adid";
static NSString *const KEY_HAS_REPORTED_OPEN_EVENT = @"AdjustManager_HasReportedOpenEvent";
static NSString *const KEY_IS_FROM_FB = @"AdjustManager_IsFromFB";

// Adjust App Token
static NSString *const ADJUST_APP_TOKEN = @"szpvszkx0wzk";

// Facebook App ID
static NSString *const FACEBOOK_APP_ID = @"4045339082444096";

// Facebook App Secret（密钥）
static NSString *const FACEBOOK_APP_SECRET = @"614e99e6bc1b2dd4f9b6c0af138370c6";

@interface AdjustManager () <AdjustDelegate>

@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, assign) BOOL isInitComplete;
@property (nonatomic, assign) BOOL hasCompletedIDFA; // idfa 是否已完成（无论是否获取到）
@property (nonatomic, assign) BOOL hasCompletedAdid; // adid 是否已完成（无论是否获取到）
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *idfa;
@property (nonatomic, strong) NSString *adid;
@property (nonatomic, strong) ADJAttribution *currentAttribution;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, copy) AdjustInitCompleteCallback initCompleteCallback;
@property (nonatomic, strong) NSNumber *facebookAttributionCache; // 使用NSNumber以便区分nil和false

@end

@implementation AdjustManager

+ (instancetype)sharedManager {
    static AdjustManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AdjustManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        [self loadCachedData];
    }
    return self;
}

#pragma mark - 初始化

- (void)initializeWithApplication:(UIApplication *)application {
    if (self.isInitialized) {
        BUNNYX_LOG(@"AdjustManager 已初始化，跳过重复初始化");
        return;
    }
    
    // 从本地存储加载数据
    [self loadCachedData];
    
    // 重置完成标志位
    self.hasCompletedIDFA = NO;
    self.hasCompletedAdid = NO;
    self.isInitComplete = NO;
    
    // 初始化 Adjust SDK
    [self initAdjustSdk];
    
    // 初始化 Facebook SDK
    [self initFacebookSdk];
    
    self.isInitialized = YES;
    
    // 开始获取必要的数据
    [self startInitProcess];
    
    BUNNYX_LOG(@"AdjustManager 初始化完成");
}

- (void)initAdjustSdk {
    // 根据构建类型选择环境
    NSString *environment = ADJEnvironmentProduction;
    #ifdef DEBUG
    environment = ADJEnvironmentSandbox;
    #endif
    
    // 创建 Adjust 配置
    ADJConfig *adjustConfig = [[ADJConfig alloc] initWithAppToken:ADJUST_APP_TOKEN
                                                     environment:environment];
    
    // 设置日志级别
    #ifdef DEBUG
    [adjustConfig setLogLevel:ADJLogLevelVerbose];
    #else
    [adjustConfig setLogLevel:ADJLogLevelSuppress];
    #endif
    
    // 设置归因回调
    adjustConfig.delegate = self;
    
    // 初始化 Adjust SDK
    [Adjust initSdk:adjustConfig];
    
    BUNNYX_LOG(@"Adjust SDK 初始化成功，环境: %@", environment);
}

- (void)initFacebookSdk {
    // 初始化 Facebook Audience Network SDK
    [FBAdSettings setLogLevel:FBAdLogLevelNone];
    [FBAdSettings setAdvertiserTrackingEnabled:YES];
    
    BUNNYX_LOG(@"Facebook Audience Network SDK 初始化成功");
}

#pragma mark - AdjustDelegate

- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    self.currentAttribution = attribution;
    
    // 判断是否为Facebook引流
    BOOL isFromFB = [self isFacebookAttribution:attribution];
    self.facebookAttributionCache = @(isFromFB);
    
    // 保存到本地存储（重要：因为 Attribution 回调只在特定时机触发）
    [self saveFacebookAttributionToCache:isFromFB];
    
    // 获取到归因信息后，调用 getChannelByAdjust 接口
    if (attribution) {
        [self requestChannelByAdjust:attribution];
    } else {
        // 如果归因信息为空，也需要检查初始化完成（因为已经尝试获取过）
        [self checkInitComplete];
    }
}

#pragma mark - 初始化流程

- (void)startInitProcess {
    // 延迟获取 IDFA（确保 UI 完全准备好后再请求授权，ATT 弹窗需要在可见界面时显示）
    // 延迟 2 秒，确保启动页或登录页已经完全显示并稳定（避免UI切换时弹窗无法显示）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self getIDFAAsync];
    });
    
    // 延迟获取 adid 和归因信息（Adjust SDK 可能需要一些时间才能准备好）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self getAdidInternal];
        // 尝试获取归因信息（如果回调还没触发）
        [self tryGetAttributionIfNeeded];
        [self checkInitComplete];
    });
    
    // 如果已有归因信息（从回调中获取），立即调用 getChannelByAdjust
    if (self.currentAttribution) {
        [self requestChannelByAdjust:self.currentAttribution];
    }
}

- (void)tryGetAttributionIfNeeded {
    // 如果已经有归因信息（从回调中获取），不需要再次获取
    if (self.currentAttribution) {
        return;
    }
    
    // 注意：iOS 的 Adjust SDK 没有直接获取归因信息的方法
    // 归因信息只能通过回调获取，所以这里不做处理
}

- (void)getIDFAAsync {
    // 确保在主线程检查状态和弹窗（requestTrackingAuthorization 必须在主线程调用）
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 14.0, *)) {
            ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];
            
            if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
                // 未请求过授权（首次安装或之前版本未请求过），主动弹窗请求用户同意
                [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus newStatus) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        if (newStatus == ATTrackingManagerAuthorizationStatusAuthorized) {
                            // 用户同意，获取 IDFA 并标记流程完成
                            [self fetchIDFA];
                        } else if (newStatus == ATTrackingManagerAuthorizationStatusDenied) {
                            // 用户明确拒绝，标记 idfa 流程已完成
                            self.hasCompletedIDFA = YES;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self checkInitComplete];
                            });
                        } else if (newStatus == ATTrackingManagerAuthorizationStatusNotDetermined) {
                            // 回调立即返回 NotDetermined，说明弹窗未显示（可能是UI未准备好或系统限制）
                            // 延迟重试，确保UI稳定后再请求
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                // 再次检查状态，如果仍然是 NotDetermined，尝试再次请求
                                ATTrackingManagerAuthorizationStatus retryStatus = [ATTrackingManager trackingAuthorizationStatus];
                                if (retryStatus == ATTrackingManagerAuthorizationStatusNotDetermined) {
                                    // UI应该已经稳定，再次尝试请求授权
                                    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus finalStatus) {
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                            if (finalStatus == ATTrackingManagerAuthorizationStatusAuthorized) {
                                                [self fetchIDFA];
                                            } else {
                                                // 无论什么状态，都标记流程完成
                                                self.hasCompletedIDFA = YES;
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self checkInitComplete];
                                                });
                                            }
                                        });
                                    }];
                                } else {
                                    // 状态已改变，按新状态处理
                                    if (retryStatus == ATTrackingManagerAuthorizationStatusAuthorized) {
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                            [self fetchIDFA];
                                        });
                                    } else {
                                        // 已拒绝或受限，标记流程完成
                                        self.hasCompletedIDFA = YES;
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self checkInitComplete];
                                        });
                                    }
                                }
                            });
                        } else {
                            // Restricted 状态，标记流程已完成
                            self.hasCompletedIDFA = YES;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self checkInitComplete];
                            });
                        }
                    });
                }];
                return;
            } else if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
                // 已授权，直接获取
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self fetchIDFA];
                });
                return;
            } else {
                // 已拒绝或受限，无法获取，标记 idfa 流程已完成
                self.hasCompletedIDFA = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self checkInitComplete];
                });
                return;
            }
        }
        
        // iOS 14 以下，直接获取
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self fetchIDFA];
        });
    });
}

- (void)fetchIDFA {
    // 获取 IDFA
    NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    if (idfa && idfa.length > 0 && ![idfa isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
        self.idfa = idfa;
        [self saveIDFAToCache:idfa];
        
        BUNNYX_LOG(@"获取 IDFA 成功: %@", idfa);
    } else {
        BUNNYX_LOG(@"获取 IDFA 失败或为空");
    }
    
    // 标记 idfa 流程已完成（无论是否获取到）
    self.hasCompletedIDFA = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkInitComplete];
    });
}

- (void)getAdidInternal {
    __weak typeof(self) weakSelf = self;
    [Adjust adidWithCompletionHandler:^(NSString * _Nullable adid) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (adid && adid.length > 0) {
            strongSelf.adid = adid;
            [strongSelf saveAdidToCache:adid];
            
            BUNNYX_LOG(@"获取 adid 成功: %@", adid);
        } else {
            BUNNYX_LOG(@"获取 adid 失败或为空");
        }
        
        // 标记 adid 流程已完成（无论是否获取到）
        strongSelf.hasCompletedAdid = YES;
        
        // 获取 adid 后（无论成功还是失败），检查是否可以调用 open 事件
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf checkInitComplete];
        });
    }];
}

- (void)requestChannelByAdjust:(ADJAttribution *)attribution {
    if (!attribution) {
        return;
    }
    
    // 将归因信息转换为 JSON 字符串
    NSMutableDictionary *attributionDict = [NSMutableDictionary dictionary];
    if (attribution.network) {
        attributionDict[@"network"] = attribution.network;
    }
    if (attribution.campaign) {
        attributionDict[@"campaign"] = attribution.campaign;
    }
    if (attribution.adgroup) {
        attributionDict[@"adgroup"] = attribution.adgroup;
    }
    if (attribution.creative) {
        attributionDict[@"creative"] = attribution.creative;
    }
    if (attribution.clickLabel) {
        attributionDict[@"clickLabel"] = attribution.clickLabel;
    }
    if (attribution.trackerToken) {
        attributionDict[@"trackerToken"] = attribution.trackerToken;
    }
    if (attribution.trackerName) {
        attributionDict[@"trackerName"] = attribution.trackerName;
    }
    if (self.adid.length > 0) {
        attributionDict[@"adid"] = self.adid;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:attributionDict options:0 error:&error];
    if (error || !jsonData) {
        BUNNYX_ERROR(@"归因信息序列化失败: %@", error);
        [self checkInitComplete];
        return;
    }
    
    NSString *attributionJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // 调用接口
    NSDictionary *parameters = @{@"attribution": attributionJson ?: @""};
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_SERVER_GET_CHANNEL_BY_ADJUST
                              parameters:parameters
                                 success:^(id responseObject) {
        APIResponseModel *response = [APIResponseModel modelWithDictionary:responseObject];
        if (response && response.code == 0) {
            // 根据安卓代码，响应结构是 HttpData<Bean>，Bean.data 是字符串类型（如 "facebook"）
            // 需要兼容两种响应格式：
            // 1. data 是字典：{"code": 0, "data": "facebook", "promptType": "..."}
            // 2. data 是字符串："facebook"
            NSString *channel = nil;
            if ([response.data isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dataDict = (NSDictionary *)response.data;
                id channelValue = dataDict[@"data"];
                if ([channelValue isKindOfClass:[NSString class]]) {
                    channel = (NSString *)channelValue;
                }
            } else if ([response.data isKindOfClass:[NSString class]]) {
                channel = (NSString *)response.data;
            }
            
            if (channel && channel.length > 0) {
                self.channel = channel;
                [self saveChannelToCache:channel];
            }
        }
        
        [self checkInitComplete];
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"调用 getChannelByAdjust 失败: %@", error);
        [self checkInitComplete];
    }];
}

- (void)checkInitComplete {
    // 检查是否已经完成过
    if (self.isInitComplete) {
        return;
    }
    
    // 根据需求 7.5：等 adid 有回调结果（有走回调，没有结果也行）
    // idfa 也有走用户设置流程（无论是否同意）
    // 上述两个步骤都完成之后再调用 server/addAdjustEvent 接口
    if (self.hasCompletedIDFA && self.hasCompletedAdid) {
        self.isInitComplete = YES;
        
        // 调用 addAdjustEvent 上报打开事件（首次打开才调用）
        [self requestAddAdjustEventIfNeeded:@"open"];
        
        // 触发回调
        if (self.initCompleteCallback) {
            self.initCompleteCallback();
        }
    }
}

- (void)requestAddAdjustEventIfNeeded:(NSString *)eventName {
    // 如果是 open 事件，检查是否已经上报过
    if ([eventName isEqualToString:@"open"]) {
        if ([self hasReportedOpenEvent]) {
            return;
        }
    }
    
    // 调用上报接口（成功后会保存标记）
    [self requestAddAdjustEvent:eventName];
}

- (void)requestAddAdjustEvent:(NSString *)eventName {
    NSDictionary *parameters = @{@"eventName": eventName ?: @""};
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_SERVER_ADD_ADJUST_EVENT
                              parameters:parameters
                                 success:^(id responseObject) {
        // 如果是 open 事件，上报成功后保存标记
        if ([eventName isEqualToString:@"open"]) {
            [self saveOpenEventReported];
        }
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"addAdjustEvent 上报失败: %@, 错误: %@", eventName, error);
        // 注意：失败时不保存标记，下次可以重试
    }];
}

#pragma mark - 本地存储

- (void)loadCachedData {
    if ([self.userDefaults objectForKey:KEY_CHANNEL]) {
        self.channel = [self.userDefaults stringForKey:KEY_CHANNEL];
    }
    if ([self.userDefaults objectForKey:KEY_IDFA]) {
        self.idfa = [self.userDefaults stringForKey:KEY_IDFA];
    }
    if ([self.userDefaults objectForKey:KEY_ADID]) {
        self.adid = [self.userDefaults stringForKey:KEY_ADID];
    }
    // 加载 Facebook 引流状态
    [self loadFacebookAttributionFromCache];
}

- (void)saveChannelToCache:(NSString *)channel {
    if (channel) {
        [self.userDefaults setObject:channel forKey:KEY_CHANNEL];
        [self.userDefaults synchronize];
    }
}

- (void)saveIDFAToCache:(NSString *)idfa {
    if (idfa) {
        [self.userDefaults setObject:idfa forKey:KEY_IDFA];
        [self.userDefaults synchronize];
    }
}

- (void)saveAdidToCache:(NSString *)adid {
    if (adid) {
        [self.userDefaults setObject:adid forKey:KEY_ADID];
        [self.userDefaults synchronize];
    }
}

- (BOOL)hasReportedOpenEvent {
    return [self.userDefaults boolForKey:KEY_HAS_REPORTED_OPEN_EVENT];
}

- (void)saveOpenEventReported {
    [self.userDefaults setBool:YES forKey:KEY_HAS_REPORTED_OPEN_EVENT];
    [self.userDefaults synchronize];
}

#pragma mark - Facebook 引流判断

/**
 * 判断是否为Facebook引流（改进版）
 * 覆盖所有会返回 Facebook 信息的字段
 * 轻量，稳定，适配 FB/Meta 广告常见命名规范
 * 直接兼容 Adjust 后台 Tracker 配置名
 */
- (BOOL)isFacebookAttribution:(ADJAttribution *)attribution {
    if (!attribution) {
        return NO;
    }
    
    return [self matchFB:attribution.network]
        || [self matchFB:attribution.trackerName]
        || [self matchFB:attribution.campaign]
        || [self matchFB:attribution.adgroup]
        || [self matchFB:self.adid];
}

/**
 * 匹配 Facebook 相关关键词
 */
- (BOOL)matchFB:(NSString *)value {
    if (!value || value.length == 0) {
        return NO;
    }
    
    NSString *lowerValue = [value lowercaseString];
    
    // Facebook，Meta，Instagram 常见标记
    return [lowerValue containsString:@"facebook"]
        || [lowerValue containsString:@"fb"]
        || [lowerValue containsString:@"meta"]
        || [lowerValue containsString:@"instagram"];
}

/**
 * 保存 Facebook 引流状态到本地存储
 * 重要：因为 Adjust 的 Attribution 回调只在以下时机触发：
 * - 新安装激活
 * - 重归因（re-attribution）
 * - 归因变更（广告追踪跳转的情况下）
 * 所以必须保存到本地，否则 APP 冷启动用户就永远拿不到归因信息
 */
- (void)saveFacebookAttributionToCache:(BOOL)isFromFB {
    [self.userDefaults setBool:isFromFB forKey:KEY_IS_FROM_FB];
    [self.userDefaults synchronize];
    
    BUNNYX_LOG(@"Facebook 引流状态已保存到本地: %@", isFromFB ? @"是" : @"否");
}

/**
 * 从本地存储加载 Facebook 引流状态
 */
- (void)loadFacebookAttributionFromCache {
    if ([self.userDefaults objectForKey:KEY_IS_FROM_FB]) {
        BOOL isFromFB = [self.userDefaults boolForKey:KEY_IS_FROM_FB];
        self.facebookAttributionCache = @(isFromFB);
        
        BUNNYX_LOG(@"从本地加载 Facebook 引流状态: %@", isFromFB ? @"是" : @"否");
    }
}

/**
 * 获取当前是否为Facebook引流
 * 优先从内存缓存读取，如果没有则从本地存储读取
 * @return YES表示是Facebook引流，NO表示不是
 */
- (BOOL)isFacebookAttribution {
    // 优先使用内存缓存
    if (self.facebookAttributionCache != nil) {
        return [self.facebookAttributionCache boolValue];
    }
    
    // 如果内存缓存为空，从本地存储读取
    if ([self.userDefaults objectForKey:KEY_IS_FROM_FB]) {
        BOOL isFromFB = [self.userDefaults boolForKey:KEY_IS_FROM_FB];
        self.facebookAttributionCache = @(isFromFB);
        return isFromFB;
    }
    
    // 如果都没有，返回 NO（默认不是 Facebook 引流）
    return NO;
}

#pragma mark - 公共方法

- (NSString *)getChannel {
    return self.channel;
}

- (NSString *)getIDFA {
    // 如果内存中没有，尝试从系统获取
    if (!self.idfa || self.idfa.length == 0) {
        // 检查是否允许追踪
        if (@available(iOS 14.0, *)) {
            ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];
            if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
                NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
                if (idfa && idfa.length > 0 && ![idfa isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
                    self.idfa = idfa;
                    [self saveIDFAToCache:idfa];
                }
            }
        } else {
            NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            if (idfa && idfa.length > 0 && ![idfa isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
                self.idfa = idfa;
                [self saveIDFAToCache:idfa];
            }
        }
    }
    return self.idfa;
}

- (void)requestIDFAAuthorizationIfNeeded {
    // 如果已经有 IDFA，不需要再次请求
    if (self.idfa && self.idfa.length > 0) {
        return;
    }
    
    // 调用 getIDFAAsync 来请求授权（如果状态是 NotDetermined）
    [self getIDFAAsync];
}

- (NSString *)getAdid {
    // 如果内存中没有，尝试从 Adjust SDK 获取
    if (!self.adid || self.adid.length == 0) {
        __weak typeof(self) weakSelf = self;
        [Adjust adidWithCompletionHandler:^(NSString * _Nullable adid) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            if (adid && adid.length > 0) {
                strongSelf.adid = adid;
                [strongSelf saveAdidToCache:adid];
            }
        }];
    }
    return self.adid;
}

- (void)setInitCompleteCallback:(AdjustInitCompleteCallback)callback {
    self.initCompleteCallback = callback;
}

@end

