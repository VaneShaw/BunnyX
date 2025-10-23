//
//  NetworkManager.h
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import <Foundation/Foundation.h>

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

@end

NS_ASSUME_NONNULL_END
