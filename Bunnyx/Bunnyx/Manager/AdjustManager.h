//
//  AdjustManager.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <Foundation/Foundation.h>

@class UIApplication;

NS_ASSUME_NONNULL_BEGIN

typedef void(^AdjustInitCompleteCallback)(void);

/**
 * Adjust SDK 和 Facebook SDK 管理器
 * 负责初始化 SDK、获取归因信息、获取渠道信息等
 */
@interface AdjustManager : NSObject

+ (instancetype)sharedManager;

/**
 * 初始化 Adjust SDK 和 Facebook SDK
 * @param application Application 实例
 */
- (void)initializeWithApplication:(UIApplication *)application;

/**
 * 获取渠道名称（channel）
 * @return 渠道名称，如 "facebook" 或 nil
 */
- (nullable NSString *)getChannel;

/**
 * 获取广告标识符（IDFA）
 * @return IDFA 或 nil
 */
- (nullable NSString *)getIDFA;

/**
 * 获取 Adjust ID（adid）
 * @return adid 或 nil
 */
- (nullable NSString *)getAdid;

/**
 * 检查是否已初始化
 */
- (BOOL)isInitialized;

/**
 * 检查初始化流程是否完成
 */
- (BOOL)isInitComplete;

/**
 * 初始化完成回调
 */
- (void)setInitCompleteCallback:(nullable AdjustInitCompleteCallback)callback;

/**
 * 获取当前是否为Facebook引流
 * 优先从内存缓存读取，如果没有则从本地存储读取
 * @return YES表示是Facebook引流，NO表示不是
 */
- (BOOL)isFacebookAttribution;

@end

NS_ASSUME_NONNULL_END

