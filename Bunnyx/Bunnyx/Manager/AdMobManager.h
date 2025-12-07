//
//  AdMobManager.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <Foundation/Foundation.h>
#import "AdMobConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

// 广告位枚举
typedef NS_ENUM(NSInteger, AdMobPlacement) {
    AdMobPlacementSplash = 0,    // 开屏广告
    AdMobPlacementSignIn = 1,    // 签到广告
    AdMobPlacementRecharge = 2   // 充值广告
};

// 广告类型枚举
typedef NS_ENUM(NSInteger, AdMobType) {
    AdMobTypeSplash = 0,         // 开屏广告
    AdMobTypeRewarded = 1        // 激励广告
};

// 回调block
typedef void(^AdMobConfigSuccessBlock)(NSArray<AdMobConfigModel *> *configs);
typedef void(^AdMobConfigFailureBlock)(NSError *error);
typedef void(^AdMobRewardSuccessBlock)(NSInteger coins);
typedef void(^AdMobRewardFailureBlock)(NSError *error);
typedef void(^AdMobLeftCountSuccessBlock)(NSInteger leftCount);
typedef void(^AdMobShowSuccessBlock)(void);
typedef void(^AdMobShowFailureBlock)(NSError *error);

/**
 * AdMob广告管理器
 */
@interface AdMobManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

/// 是否已初始化
@property (nonatomic, assign, readonly) BOOL isInitialized;

/// 当前广告配置列表
@property (nonatomic, strong, readonly) NSArray<AdMobConfigModel *> *currentConfigs;

#pragma mark - 初始化

/**
 * 初始化AdMob SDK
 * @param appId AdMob应用ID
 */
- (void)initializeWithAppId:(NSString *)appId;

/**
 * 获取广告配置
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)loadAdConfigWithSuccess:(AdMobConfigSuccessBlock)success
                         failure:(AdMobConfigFailureBlock)failure;

/**
 * 获取指定广告位的配置
 * @param placement 广告位
 * @param adType 广告类型
 * @return 配置模型，如果没有则返回nil
 */
- (AdMobConfigModel * _Nullable)getConfigForPlacement:(AdMobPlacement)placement adType:(AdMobType)adType;

#pragma mark - 开屏广告

/**
 * 展示开屏广告
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)showSplashAdWithSuccess:(AdMobShowSuccessBlock)success
                         failure:(AdMobShowFailureBlock)failure;

#pragma mark - 激励广告

/**
 * 展示激励广告
 * @param placement 广告位
 * @param success 成功回调（用户看完广告）
 * @param failure 失败回调
 */
- (void)showRewardedAdForPlacement:(AdMobPlacement)placement
                            success:(AdMobRewardSuccessBlock)success
                            failure:(AdMobShowFailureBlock)failure;

/**
 * 获取激励广告剩余次数
 * @param placement 广告位
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)getLeftRewardCountForPlacement:(AdMobPlacement)placement
                                success:(AdMobLeftCountSuccessBlock)success
                                failure:(AdMobConfigFailureBlock)failure;

/**
 * 检查指定广告位是否可以展示（有配置且次数未用完）
 * @param placement 广告位
 * @return 是否可以展示
 */
- (BOOL)canShowRewardedAdForPlacement:(AdMobPlacement)placement;

@end

NS_ASSUME_NONNULL_END

