//
//  AppConfigManager.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import <Foundation/Foundation.h>
#import "AppConfigModel.h"
#import "BunnyxMacros.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^AppConfigSuccessBlock)(AppConfigModel *configModel);
typedef void(^AppConfigFailureBlock)(NSError *error);

/**
 * 应用配置管理器
 * 负责获取和管理应用配置信息
 */
@interface AppConfigManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

/// 当前应用配置
@property (nonatomic, strong, readonly) AppConfigModel *currentConfig;

/// 配置是否已加载
@property (nonatomic, assign, readonly) BOOL isConfigLoaded;

/// 配置最后更新时间
@property (nonatomic, strong, readonly) NSDate *lastUpdateTime;

#pragma mark - 配置获取

/**
 * 获取应用配置
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)getAppConfigWithSuccess:(AppConfigSuccessBlock)success
                        failure:(AppConfigFailureBlock)failure;

/**
 * 获取应用配置（带缓存）
 * @param forceRefresh 是否强制刷新
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)getAppConfigWithForceRefresh:(BOOL)forceRefresh
                              success:(AppConfigSuccessBlock)success
                              failure:(AppConfigFailureBlock)failure;

#pragma mark - 配置管理

/**
 * 清除配置缓存
 */
- (void)clearConfigCache;

/**
 * 检查配置是否需要更新
 * @return 是否需要更新
 */
- (BOOL)shouldUpdateConfig;

/**
 * 获取缓存的配置
 * @return 缓存的配置，如果没有则返回nil
 */
- (AppConfigModel * _Nullable)getCachedConfig;

#pragma mark - 配置信息获取

/**
 * 获取应用版本信息
 * @return 版本信息字典
 */
- (NSDictionary *)getVersionInfo;

/**
 * 获取客服信息
 * @return 客服信息字典
 */
- (NSDictionary *)getCustomerServiceInfo;

/**
 * 获取链接信息
 * @return 链接信息字典
 */
- (NSDictionary *)getLinkInfo;

/**
 * 获取分享信息
 * @return 分享信息字典
 */
- (NSDictionary *)getShareInfo;

/**
 * 获取调试信息
 * @return 调试信息字典
 */
- (NSDictionary *)getDebugInfo;

@end

NS_ASSUME_NONNULL_END
