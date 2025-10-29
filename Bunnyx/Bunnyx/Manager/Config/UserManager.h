//
//  UserManager.h
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserManager : NSObject

+ (instancetype)sharedManager;

/**
 * 保存用户token信息
 * @param accessToken 访问token
 * @param refreshToken 刷新token
 * @param tokenType token类型
 * @param expiresIn 过期时间（秒）
 */
- (void)saveUserTokensWithAccessToken:(NSString *)accessToken
                         refreshToken:(NSString *)refreshToken
                            tokenType:(NSString *)tokenType
                            expiresIn:(NSNumber *)expiresIn;

/**
 * 获取访问token
 * @return 访问token，如果不存在返回nil
 */
- (NSString *)getAccessToken;

/**
 * 获取刷新token
 * @return 刷新token，如果不存在返回nil
 */
- (NSString *)getRefreshToken;

/**
 * 获取token类型
 * @return token类型，默认为bearer
 */
- (NSString *)getTokenType;

/**
 * 检查token是否过期
 * @return YES表示已过期，NO表示未过期
 */
- (BOOL)isTokenExpired;

/**
 * 刷新token
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)refreshTokenWithSuccess:(void(^)(void))success
                        failure:(void(^)(NSError *error))failure;

/**
 * 清除用户token
 */
- (void)clearUserToken;

/**
 * 检查用户是否已登录
 * @return YES表示已登录，NO表示未登录
 */
- (BOOL)isUserLoggedIn;

/**
 * 保存用户信息
 * @param userInfo 用户信息字典
 */
- (void)saveUserInfo:(NSDictionary *)userInfo;

/**
 * 获取用户信息
 * @return 用户信息字典
 */
- (NSDictionary *)getUserInfo;

/**
 * 清除所有用户信息
 */
- (void)clearUserInfo;

/**
 * 用户登出
 * 清除所有用户信息和token，并清除网络认证
 */
- (void)logout;

@end

NS_ASSUME_NONNULL_END
