//
//  NetworkManager.h
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import <Foundation/Foundation.h>
#import "BunnyxMacros.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^NetworkSuccessBlock)(id responseObject);
typedef void(^NetworkFailureBlock)(NSError *error);

@interface NetworkManager : NSObject

+ (instancetype)sharedManager;

/**
 * GET 请求 - 使用 form-data 格式
 * @param url 请求地址
 * @param parameters 请求参数
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)GET:(NSString *)url
 parameters:(NSDictionary * _Nullable)parameters
    success:(NetworkSuccessBlock)success
    failure:(NetworkFailureBlock)failure;

/**
 * POST 请求 - 使用 x-www-form-urlencoded 格式
 * @param url 请求地址
 * @param parameters 请求参数
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)POST:(NSString *)url
  parameters:(NSDictionary * _Nullable)parameters
     success:(NetworkSuccessBlock)success
     failure:(NetworkFailureBlock)failure;

/**
 * 设置Basic认证 (用于登录和刷新token接口)
 */
- (void)setBasicAuth;

/**
 * 设置Bearer认证 (用于除登录和刷新token外的其他接口)
 * @param token 从登录或刷新token接口返回的token
 */
- (void)setBearerAuthWithToken:(NSString *)token;

/**
 * 清除认证信息
 */
- (void)clearAuth;

/**
 * 更新公共请求头（用于语言切换等场景）
 */
- (void)updateCommonHeaders;

@end

NS_ASSUME_NONNULL_END
