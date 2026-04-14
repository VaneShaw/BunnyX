//
//  AdMobManager.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "AdMobManager.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "BunnyxMacros.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "SignSuccessDialog.h"
#import "UserManager.h"

@interface AdMobManager () <GADFullScreenContentDelegate>

@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, strong) NSArray<AdMobConfigModel *> *currentConfigs;
@property (nonatomic, strong) GADAppOpenAd *appOpenAd;
@property (nonatomic, strong) GADRewardedAd *rewardedAd;
@property (nonatomic, assign) AdMobPlacement currentRewardedPlacement;
@property (nonatomic, copy) AdMobRewardSuccessBlock rewardSuccessBlock;
@property (nonatomic, copy) AdMobShowFailureBlock rewardFailureBlock;
@property (nonatomic, copy) AdMobShowSuccessBlock splashSuccessBlock;
@property (nonatomic, copy) AdMobShowFailureBlock splashFailureBlock;
@property (nonatomic, strong) NSDate *appOpenAdLoadTime;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *leftRewardCountCache; // 缓存剩余次数
@property (nonatomic, assign) BOOL isLoadingAppOpenAd; // 是否正在加载开屏广告
@property (nonatomic, assign) BOOL isLoadingRewardedAd; // 是否正在加载激励广告
@property (nonatomic, assign) BOOL isShowingAppOpenAd; // 是否正在展示开屏广告
@property (nonatomic, assign) BOOL isLoadingAdConfig; // 是否正在加载广告配置
@property (nonatomic, strong) NSMutableArray<AdMobConfigSuccessBlock> *pendingConfigSuccessBlocks; // 等待配置加载完成的成功回调队列
@property (nonatomic, strong) NSMutableArray<AdMobConfigFailureBlock> *pendingConfigFailureBlocks; // 等待配置加载完成的失败回调队列
@property (nonatomic, assign) BOOL hasLoadedConfig; // 是否已经加载过配置（用于判断是否可以直接返回）

@end

@implementation AdMobManager

+ (instancetype)sharedManager {
    static AdMobManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AdMobManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.currentConfigs = @[];
        self.leftRewardCountCache = [NSMutableDictionary dictionary];
        self.isLoadingAppOpenAd = NO;
        self.isLoadingRewardedAd = NO;
        self.isShowingAppOpenAd = NO;
        self.isLoadingAdConfig = NO;
        self.pendingConfigSuccessBlocks = [NSMutableArray array];
        self.pendingConfigFailureBlocks = [NSMutableArray array];
        self.hasLoadedConfig = NO;
    }
    return self;
}

#pragma mark - 初始化

- (void)initializeWithAppId:(NSString *)appId {
    if (self.isInitialized) {
        BUNNYX_LOG(@"AdMob SDK已经初始化");
        return;
    }
    
    if (BUNNYX_IS_EMPTY_STRING(appId)) {
        BUNNYX_ERROR(@"AdMob App ID为空，无法初始化");
        return;
    }
    
    BUNNYX_LOG(@"初始化AdMob SDK，App ID: %@", appId);
    
    // 初始化Google Mobile Ads SDK
    [GADMobileAds.sharedInstance startWithCompletionHandler:^(GADInitializationStatus * _Nonnull status) {
        BUNNYX_LOG(@"AdMob SDK初始化完成");
        self.isInitialized = YES;
    }];
}

#pragma mark - 配置管理

/**
 * 加载广告配置（防重复请求机制）
 * 
 * 防重复机制说明：
 * 1. 如果配置已加载完成，直接返回缓存的配置（避免重复请求）
 * 2. 如果正在加载中，将回调加入等待队列（多个调用者共享同一个请求）
 * 3. 如果还没开始加载，开始加载并将回调加入队列
 * 
 * 这样可以确保：
 * - AppDelegate、SceneDelegate、LaunchViewController 等多个地方调用时，只会发起一次网络请求
 * - 所有调用者都能收到配置加载完成的通知
 */
- (void)loadAdConfigWithSuccess:(AdMobConfigSuccessBlock)success
                         failure:(AdMobConfigFailureBlock)failure {
    // 检查用户登录状态，未登录时不调用广告配置接口
    BOOL isLoggedIn = [[UserManager sharedManager] isUserLoggedIn];
    if (!isLoggedIn) {
        BUNNYX_LOG(@"用户未登录，跳过广告配置加载");
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"用户未登录"}];
            failure(error);
        }
        return;
    }
    
    // 如果已经加载过配置，直接返回缓存的配置
    if (self.hasLoadedConfig && self.currentConfigs.count > 0) {
        BUNNYX_LOG(@"使用已加载的AdMob配置，共%lu个配置", (unsigned long)self.currentConfigs.count);
        if (success) {
            success(self.currentConfigs);
        }
        return;
    }
    
    // 如果正在加载配置，将回调加入等待队列
    if (self.isLoadingAdConfig) {
        BUNNYX_LOG(@"AdMob配置正在加载中，将回调加入等待队列");
        if (success) {
            [self.pendingConfigSuccessBlocks addObject:[success copy]];
        }
        if (failure) {
            [self.pendingConfigFailureBlocks addObject:[failure copy]];
        }
        return;
    }
    
    // 开始加载配置
    self.isLoadingAdConfig = YES;
    
    // 将当前回调加入队列（第一个请求）
    if (success) {
        [self.pendingConfigSuccessBlocks addObject:[success copy]];
    }
    if (failure) {
        [self.pendingConfigFailureBlocks addObject:[failure copy]];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/user/admob/getConfig", BUNNYX_API_BASE_URL];
    
    BUNNYX_LOG(@"请求AdMob配置: %@", url);
    
    __weak typeof(self) weakSelf = self;
    [[NetworkManager sharedManager] GET:url
                               parameters:nil
                                  success:^(id responseObject) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        strongSelf.isLoadingAdConfig = NO;
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            
            if (code == 0) {
                NSArray *dataArray = response[@"data"];
                if ([dataArray isKindOfClass:[NSArray class]]) {
                    NSMutableArray<AdMobConfigModel *> *configs = [NSMutableArray array];
                    for (NSDictionary *dict in dataArray) {
                        if ([dict isKindOfClass:[NSDictionary class]]) {
                            AdMobConfigModel *config = [AdMobConfigModel modelWithDictionary:dict];
                            if (config && [config isValid]) {
                                [configs addObject:config];
                            }
                        }
                    }
                    strongSelf.currentConfigs = [configs copy];
                    strongSelf.hasLoadedConfig = YES;
                    BUNNYX_LOG(@"AdMob配置加载成功，共%lu个配置", (unsigned long)configs.count);
                    
                    // 配置加载成功后，预加载开屏广告和激励广告
                    [strongSelf preloadAppOpenAdIfNeeded];
                    [strongSelf preloadRewardedAdsIfNeeded];
                    
                    // 执行所有等待的成功回调
                    NSArray<AdMobConfigSuccessBlock> *successBlocks = [strongSelf.pendingConfigSuccessBlocks copy];
                    [strongSelf.pendingConfigSuccessBlocks removeAllObjects];
                    [strongSelf.pendingConfigFailureBlocks removeAllObjects];
                    
                    for (AdMobConfigSuccessBlock successBlock in successBlocks) {
                        if (successBlock) {
                            successBlock(strongSelf.currentConfigs);
                        }
                    }
                } else {
                    strongSelf.currentConfigs = @[];
                    strongSelf.hasLoadedConfig = YES;
                    BUNNYX_LOG(@"AdMob配置数据格式错误，返回空配置");
                    
                    // 执行所有等待的成功回调（即使数据格式错误，也返回空配置）
                    NSArray<AdMobConfigSuccessBlock> *successBlocks = [strongSelf.pendingConfigSuccessBlocks copy];
                    [strongSelf.pendingConfigSuccessBlocks removeAllObjects];
                    [strongSelf.pendingConfigFailureBlocks removeAllObjects];
                    
                    for (AdMobConfigSuccessBlock successBlock in successBlocks) {
                        if (successBlock) {
                            successBlock(@[]);
                        }
                    }
                }
            } else {
                NSString *message = response[@"message"] ?: @"获取广告配置失败";
                NSError *error = [NSError errorWithDomain:@"AdMobError" code:code userInfo:@{NSLocalizedDescriptionKey: message}];
                BUNNYX_ERROR(@"获取AdMob配置失败: %@", message);
                
                // 执行所有等待的失败回调
                NSArray<AdMobConfigFailureBlock> *failureBlocks = [strongSelf.pendingConfigFailureBlocks copy];
                [strongSelf.pendingConfigSuccessBlocks removeAllObjects];
                [strongSelf.pendingConfigFailureBlocks removeAllObjects];
                
                for (AdMobConfigFailureBlock failureBlock in failureBlocks) {
                    if (failureBlock) {
                        failureBlock(error);
                    }
                }
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"响应格式错误"}];
            BUNNYX_ERROR(@"AdMob配置响应格式错误");
            
            // 执行所有等待的失败回调
            NSArray<AdMobConfigFailureBlock> *failureBlocks = [strongSelf.pendingConfigFailureBlocks copy];
            [strongSelf.pendingConfigSuccessBlocks removeAllObjects];
            [strongSelf.pendingConfigFailureBlocks removeAllObjects];
            
            for (AdMobConfigFailureBlock failureBlock in failureBlocks) {
                if (failureBlock) {
                    failureBlock(error);
                }
            }
        }
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        strongSelf.isLoadingAdConfig = NO;
        BUNNYX_ERROR(@"获取AdMob配置失败: %@", error.localizedDescription);
        
        // 执行所有等待的失败回调
        NSArray<AdMobConfigFailureBlock> *failureBlocks = [strongSelf.pendingConfigFailureBlocks copy];
        [strongSelf.pendingConfigSuccessBlocks removeAllObjects];
        [strongSelf.pendingConfigFailureBlocks removeAllObjects];
        
        for (AdMobConfigFailureBlock failureBlock in failureBlocks) {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}

- (AdMobConfigModel *)getConfigForPlacement:(AdMobPlacement)placement adType:(AdMobType)adType {
    for (AdMobConfigModel *config in self.currentConfigs) {
        if (config.adPlacement == placement && config.adType == adType) {
            return config;
        }
    }
    return nil;
}

/**
 * 强制重新加载广告配置（忽略缓存）
 * 用于网络恢复后重新获取配置
 */
- (void)reloadAdConfigWithSuccess:(AdMobConfigSuccessBlock)success
                          failure:(AdMobConfigFailureBlock)failure {
    BUNNYX_LOG(@"强制重新加载广告配置（忽略缓存）");
    
    // 清除所有状态，确保强制重新加载
    self.hasLoadedConfig = NO;
    self.isLoadingAdConfig = NO;
    
    // 清空等待队列（避免旧的回调干扰）
    [self.pendingConfigSuccessBlocks removeAllObjects];
    [self.pendingConfigFailureBlocks removeAllObjects];
    
    // 调用正常的加载方法（因为hasLoadedConfig和isLoadingAdConfig已清除，会立即重新请求）
    [self loadAdConfigWithSuccess:success failure:failure];
}

#pragma mark - 开屏广告

- (void)preloadAppOpenAdIfNeeded {
    AdMobConfigModel *config = [self getConfigForPlacement:AdMobPlacementSplash adType:AdMobTypeSplash];
    if (!config || BUNNYX_IS_EMPTY_STRING(config.adUnitId)) {
        return;
    }
    
    // 如果已经有有效的广告，不需要重新加载
    if ([self isAppOpenAdAvailable]) {
        return;
    }
    
    // 如果正在加载，不需要重复加载
    if (self.isLoadingAppOpenAd) {
        return;
    }
    
    // 预加载开屏广告
    [self loadAppOpenAdWithAdUnitId:config.adUnitId];
}

- (BOOL)isAppOpenAdAvailable {
    // 检查广告是否存在且未过期（4小时有效期）
    if (!self.appOpenAd) {
        return NO;
    }
    
    // 检查广告是否过期（4小时 = 14400秒）
    if (self.appOpenAdLoadTime) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.appOpenAdLoadTime];
        if (timeInterval > 4 * 3600) {
            BUNNYX_LOG(@"开屏广告已过期，需要重新加载");
            self.appOpenAd = nil;
            self.appOpenAdLoadTime = nil;
            return NO;
        }
    }
    
    return YES;
}

- (void)showSplashAdWithSuccess:(AdMobShowSuccessBlock)success
                         failure:(AdMobShowFailureBlock)failure {
    AdMobConfigModel *config = [self getConfigForPlacement:AdMobPlacementSplash adType:AdMobTypeSplash];
    if (!config || BUNNYX_IS_EMPTY_STRING(config.adUnitId)) {
        BUNNYX_LOG(@"没有开屏广告配置，跳过展示");
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"没有开屏广告配置"}];
            failure(error);
        }
        return;
    }
    
    // 如果正在展示，不重复展示
    if (self.isShowingAppOpenAd) {
        BUNNYX_LOG(@"开屏广告正在展示中，跳过重复展示");
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"广告正在展示中"}];
            failure(error);
        }
        return;
    }
    
    self.splashSuccessBlock = success;
    self.splashFailureBlock = failure;
    
    // 检查是否有有效的广告可用
    if ([self isAppOpenAdAvailable]) {
        [self presentAppOpenAd];
        return;
    }
    
    // 如果没有可用广告，尝试加载
    [self loadAppOpenAdWithAdUnitId:config.adUnitId];
}

- (void)loadAppOpenAdWithAdUnitId:(NSString *)adUnitId {
    // 如果正在加载，不重复加载
    if (self.isLoadingAppOpenAd) {
        BUNNYX_LOG(@"开屏广告正在加载中，跳过重复加载");
        return;
    }
    
    self.isLoadingAppOpenAd = YES;
    GADRequest *request = [GADRequest request];
    [GADAppOpenAd loadWithAdUnitID:adUnitId
                            request:request
                  completionHandler:^(GADAppOpenAd * _Nullable appOpenAd, NSError * _Nullable error) {
        self.isLoadingAppOpenAd = NO;
        
        if (error) {
            BUNNYX_ERROR(@"加载开屏广告失败: %@", error.localizedDescription);
            if (self.splashFailureBlock) {
                self.splashFailureBlock(error);
            }
            self.splashSuccessBlock = nil;
            self.splashFailureBlock = nil;
            return;
        }
        
        self.appOpenAd = appOpenAd;
        self.appOpenAd.fullScreenContentDelegate = self;
        self.appOpenAdLoadTime = [NSDate date];
        
        BUNNYX_LOG(@"开屏广告加载成功");
        
        // 如果有等待展示的回调，立即展示；否则只是预加载
        if (self.splashSuccessBlock || self.splashFailureBlock) {
            [self presentAppOpenAd];
        }
    }];
}

- (void)presentAppOpenAd {
    if (![self isAppOpenAdAvailable]) {
        BUNNYX_ERROR(@"开屏广告不可用");
        if (self.splashFailureBlock) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"开屏广告不可用"}];
            self.splashFailureBlock(error);
        }
        self.splashSuccessBlock = nil;
        self.splashFailureBlock = nil;
        return;
    }
    
    UIViewController *rootViewController = [self getRootViewController];
    if (!rootViewController) {
        BUNNYX_ERROR(@"无法获取根视图控制器");
        if (self.splashFailureBlock) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无法获取根视图控制器"}];
            self.splashFailureBlock(error);
        }
        self.splashSuccessBlock = nil;
        self.splashFailureBlock = nil;
        return;
    }
    
    // 在显示开屏广告前，先隐藏所有签到成功弹窗（但不销毁），确保开屏广告显示在最上层
    [SignSuccessDialog hideAll];
    
    self.isShowingAppOpenAd = YES;
    [self.appOpenAd presentFromRootViewController:rootViewController];
}

#pragma mark - 激励广告

- (void)preloadRewardedAdsIfNeeded {
    // 预加载所有激励广告位的广告
    NSArray<NSNumber *> *placements = @[@(AdMobPlacementSignIn), @(AdMobPlacementRecharge)];
    
    for (NSNumber *placementNum in placements) {
        AdMobPlacement placement = [placementNum integerValue];
        [self preloadRewardedAdForPlacement:placement];
    }
}

- (void)preloadRewardedAdForPlacement:(AdMobPlacement)placement {
    AdMobConfigModel *config = [self getConfigForPlacement:placement adType:AdMobTypeRewarded];
    
    if (!config || BUNNYX_IS_EMPTY_STRING(config.adUnitId)) {
        return;
    }
    
    // 如果已经有广告且是当前广告位，不需要重新加载
    if (self.rewardedAd && self.currentRewardedPlacement == placement) {
        return;
    }
    
    // 如果正在加载，不需要重复加载
    if (self.isLoadingRewardedAd) {
        return;
    }
    
    // 预加载激励广告（不设置回调，只是预加载）
    [self loadRewardedAdWithAdUnitId:config.adUnitId forPlacement:placement];
}

- (void)showRewardedAdForPlacement:(AdMobPlacement)placement
                            success:(AdMobRewardSuccessBlock)success
                            failure:(AdMobShowFailureBlock)failure {
    AdMobConfigModel *config = [self getConfigForPlacement:placement adType:AdMobTypeRewarded];
    if (!config || BUNNYX_IS_EMPTY_STRING(config.adUnitId)) {
        BUNNYX_LOG(@"没有激励广告配置，广告位: %ld", (long)placement);
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"没有激励广告配置"}];
            failure(error);
        }
        return;
    }
    
    // 检查是否可以展示（充值广告位需要检查剩余次数）
    if (placement == AdMobPlacementRecharge && ![self canShowRewardedAdForPlacement:placement]) {
        BUNNYX_LOG(@"充值广告位次数已用完");
        if (failure) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"今日观看次数已用完"}];
            failure(error);
        }
        return;
    }
    
    self.currentRewardedPlacement = placement;
    self.rewardSuccessBlock = success;
    self.rewardFailureBlock = failure;
    
    // 如果已经有加载好的广告且是当前广告位，直接展示
    if (self.rewardedAd && self.currentRewardedPlacement == placement) {
        [self presentRewardedAd];
        return;
    }
    
    // 如果没有可用广告或广告位不匹配，加载新的广告
    [self loadRewardedAdWithAdUnitId:config.adUnitId forPlacement:placement];
}

- (void)loadRewardedAdWithAdUnitId:(NSString *)adUnitId {
    // 使用当前广告位加载
    [self loadRewardedAdWithAdUnitId:adUnitId forPlacement:self.currentRewardedPlacement];
}

- (void)loadRewardedAdWithAdUnitId:(NSString *)adUnitId forPlacement:(AdMobPlacement)placement {
    // 如果正在加载，不重复加载
    if (self.isLoadingRewardedAd) {
        BUNNYX_LOG(@"激励广告正在加载中，跳过重复加载");
        return;
    }
    
    self.isLoadingRewardedAd = YES;
    self.currentRewardedPlacement = placement;
    
    GADRequest *request = [GADRequest request];
    [GADRewardedAd loadWithAdUnitID:adUnitId
                             request:request
                   completionHandler:^(GADRewardedAd * _Nullable rewardedAd, NSError * _Nullable error) {
        self.isLoadingRewardedAd = NO;
        
        if (error) {
            BUNNYX_ERROR(@"加载激励广告失败: %@", error.localizedDescription);
            if (self.rewardFailureBlock) {
                self.rewardFailureBlock(error);
            }
            self.rewardSuccessBlock = nil;
            self.rewardFailureBlock = nil;
            return;
        }
        
        self.rewardedAd = rewardedAd;
        self.rewardedAd.fullScreenContentDelegate = self;
        
        BUNNYX_LOG(@"激励广告加载成功，广告位: %ld", (long)placement);
        
        // 如果有等待展示的回调，立即展示；否则只是预加载
        if (self.rewardSuccessBlock || self.rewardFailureBlock) {
            [self presentRewardedAd];
        }
    }];
}

- (void)presentRewardedAd {
    if (!self.rewardedAd) {
        BUNNYX_ERROR(@"激励广告未加载");
        if (self.rewardFailureBlock) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"激励广告未加载"}];
            self.rewardFailureBlock(error);
        }
        self.rewardSuccessBlock = nil;
        self.rewardFailureBlock = nil;
        return;
    }
    
    UIViewController *rootViewController = [self getRootViewController];
    if (!rootViewController) {
        BUNNYX_ERROR(@"无法获取根视图控制器");
        if (self.rewardFailureBlock) {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无法获取根视图控制器"}];
            self.rewardFailureBlock(error);
        }
        self.rewardSuccessBlock = nil;
        self.rewardFailureBlock = nil;
        return;
    }
    
    [self.rewardedAd presentFromRootViewController:rootViewController userDidEarnRewardHandler:^{
        // 用户看完广告，发放奖励
        [self handleRewardEarned];
    }];
}

- (void)handleRewardEarned {
    AdMobConfigModel *config = [self getConfigForPlacement:self.currentRewardedPlacement adType:AdMobTypeRewarded];
    if (!config) {
        BUNNYX_ERROR(@"无法获取广告配置，无法发放奖励");
        return;
    }
    
    NSInteger rewardCoins = config.rewardCoins;
    
    // 调用服务器接口发放奖励
    NSString *url = [NSString stringWithFormat:@"%@/user/admob/addReward", BUNNYX_API_BASE_URL];
    NSDictionary *params = @{
        @"adPlacement": @(self.currentRewardedPlacement),
        @"adType": @(AdMobTypeRewarded)
    };
    
    [[NetworkManager sharedManager] POST:url
                                parameters:params
                                   success:^(id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            
            if (code == 0) {
                NSInteger actualReward = [response[@"data"] integerValue];
                BUNNYX_LOG(@"奖励发放成功，奖励金币: %ld", (long)actualReward);
                
                // 更新剩余次数缓存（如果是充值广告位）
                if (self.currentRewardedPlacement == AdMobPlacementRecharge) {
                    [self refreshLeftRewardCountForPlacement:self.currentRewardedPlacement];
                }
                
                if (self.rewardSuccessBlock) {
                    self.rewardSuccessBlock(actualReward);
                }
            } else {
                NSString *message = response[@"message"] ?: @"发放奖励失败";
                BUNNYX_ERROR(@"发放奖励失败: %@", message);
                if (self.rewardSuccessBlock) {
                    // 即使服务器失败，也返回配置的奖励数量
                    self.rewardSuccessBlock(rewardCoins);
                }
            }
        } else {
            BUNNYX_ERROR(@"奖励响应格式错误");
            if (self.rewardSuccessBlock) {
                self.rewardSuccessBlock(rewardCoins);
            }
        }
        
        self.rewardSuccessBlock = nil;
        self.rewardFailureBlock = nil;
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"发放奖励失败: %@", error.localizedDescription);
        // 即使网络失败，也返回配置的奖励数量
        if (self.rewardSuccessBlock) {
            self.rewardSuccessBlock(rewardCoins);
        }
        self.rewardSuccessBlock = nil;
        self.rewardFailureBlock = nil;
    }];
}

- (void)getLeftRewardCountForPlacement:(AdMobPlacement)placement
                                success:(AdMobLeftCountSuccessBlock)success
                                failure:(AdMobConfigFailureBlock)failure {
    NSString *url = [NSString stringWithFormat:@"%@/user/admob/getLeftRewardCount", BUNNYX_API_BASE_URL];
    NSDictionary *params = @{
        @"adPlacement": @(placement),
        @"adType": @(AdMobTypeRewarded)
    };
    
    [[NetworkManager sharedManager] GET:url
                               parameters:params
                                  success:^(id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            
            if (code == 0) {
                NSInteger leftCount = [response[@"data"] integerValue];
                // 更新缓存
                self.leftRewardCountCache[@(placement)] = @(leftCount);
                BUNNYX_LOG(@"获取剩余次数成功，广告位: %ld, 剩余次数: %ld", (long)placement, (long)leftCount);
                if (success) {
                    success(leftCount);
                }
            } else {
                NSString *message = response[@"message"] ?: @"获取剩余次数失败";
                NSError *error = [NSError errorWithDomain:@"AdMobError" code:code userInfo:@{NSLocalizedDescriptionKey: message}];
                BUNNYX_ERROR(@"获取剩余次数失败: %@", message);
                if (failure) {
                    failure(error);
                }
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"AdMobError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"响应格式错误"}];
            BUNNYX_ERROR(@"剩余次数响应格式错误");
            if (failure) {
                failure(error);
            }
        }
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"获取剩余次数失败: %@", error.localizedDescription);
        if (failure) {
            failure(error);
        }
    }];
}

- (BOOL)canShowRewardedAdForPlacement:(AdMobPlacement)placement {
    AdMobConfigModel *config = [self getConfigForPlacement:placement adType:AdMobTypeRewarded];
    if (!config) {
        return NO;
    }
    
    // 只有充值广告位需要检查次数
    if (placement == AdMobPlacementRecharge && config.rewardMaxCount > 0) {
        NSNumber *cachedCount = self.leftRewardCountCache[@(placement)];
        if (cachedCount) {
            return [cachedCount integerValue] > 0;
        }
        // 如果没有缓存，返回YES，实际展示时会检查
        return YES;
    }
    
    return YES;
}

- (void)refreshLeftRewardCountForPlacement:(AdMobPlacement)placement {
    [self getLeftRewardCountForPlacement:placement success:^(NSInteger leftCount) {
        BUNNYX_LOG(@"刷新剩余次数成功，广告位: %ld, 剩余次数: %ld", (long)placement, (long)leftCount);
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"刷新剩余次数失败: %@", error.localizedDescription);
    }];
}

#pragma mark - GADFullScreenContentDelegate

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    BUNNYX_ERROR(@"广告展示失败: %@", error.localizedDescription);
    
    if (ad == self.appOpenAd) {
        self.isShowingAppOpenAd = NO;
        if (self.splashFailureBlock) {
            self.splashFailureBlock(error);
        }
        self.splashSuccessBlock = nil;
        self.splashFailureBlock = nil;
        self.appOpenAd = nil;
        self.appOpenAdLoadTime = nil;
        // 展示失败后，重新显示之前隐藏的签到弹窗
        [SignSuccessDialog showAllHidden];
        // 展示失败后，重新预加载下一个广告
        [self preloadAppOpenAdIfNeeded];
    } else if (ad == self.rewardedAd) {
        AdMobPlacement failedPlacement = self.currentRewardedPlacement;
        if (self.rewardFailureBlock) {
            self.rewardFailureBlock(error);
        }
        self.rewardSuccessBlock = nil;
        self.rewardFailureBlock = nil;
        self.rewardedAd = nil;
        // 展示失败后，重新预加载
        [self preloadRewardedAdForPlacement:failedPlacement];
    }
}

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    BUNNYX_LOG(@"广告即将展示");
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    BUNNYX_LOG(@"广告已关闭");
    
    if (ad == self.appOpenAd) {
        self.isShowingAppOpenAd = NO;
        if (self.splashSuccessBlock) {
            self.splashSuccessBlock();
        }
        self.splashSuccessBlock = nil;
        self.splashFailureBlock = nil;
        self.appOpenAd = nil;
        self.appOpenAdLoadTime = nil;
        // 广告关闭后，重新显示之前隐藏的签到弹窗
        [SignSuccessDialog showAllHidden];
        // 广告关闭后，预加载下一个广告
        [self preloadAppOpenAdIfNeeded];
    } else if (ad == self.rewardedAd) {
        // 激励广告关闭时不调用success，奖励在handleRewardEarned中处理
        AdMobPlacement closedPlacement = self.currentRewardedPlacement;
        self.rewardedAd = nil;
        // 广告关闭后，预加载下一个广告
        [self preloadRewardedAdForPlacement:closedPlacement];
    }
}

#pragma mark - 工具方法

- (UIViewController *)getRootViewController {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                window = windowScene.windows.firstObject;
                break;
            }
        }
    } else {
        window = [UIApplication sharedApplication].delegate.window;
    }
    
    if (!window) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    
    UIViewController *rootViewController = window.rootViewController;
    while (rootViewController.presentedViewController) {
        rootViewController = rootViewController.presentedViewController;
    }
    
    return rootViewController;
}

@end

