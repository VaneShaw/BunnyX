//
//  UserManager.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "UserManager.h"
#import "BunnyxNetworkMacros.h"
#import "UserInfoManager.h"
#import "NetworkManager.h"

@interface UserManager ()

@end

@implementation UserManager

+ (instancetype)sharedManager {
    static UserManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UserManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化时不需要特殊处理
    }
    return self;
}

#pragma mark - Token Management

- (void)saveUserTokensWithAccessToken:(NSString *)accessToken
                         refreshToken:(NSString *)refreshToken
                            tokenType:(NSString *)tokenType
                            expiresIn:(NSNumber *)expiresIn {
    if (accessToken && accessToken.length > 0 && refreshToken && refreshToken.length > 0) {
        // 保存访问token
        [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"BunnyxAccessToken"];
        
        // 保存刷新token
        [[NSUserDefaults standardUserDefaults] setObject:refreshToken forKey:@"BunnyxRefreshToken"];
        
        // 保存token类型
        [[NSUserDefaults standardUserDefaults] setObject:(tokenType ?: @"bearer") forKey:@"BunnyxTokenType"];
        
        // 保存过期时间
        NSTimeInterval expireTime = [[NSDate date] timeIntervalSince1970] + [expiresIn doubleValue];
        [[NSUserDefaults standardUserDefaults] setObject:@(expireTime) forKey:@"BunnyxTokenExpireTime"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"[UserManager] 保存用户token信息成功");
    } else {
        NSLog(@"[UserManager] Token信息不完整，保存失败");
    }
}

- (NSString *)getAccessToken {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"BunnyxAccessToken"];
    if (token && token.length > 0) {
        NSLog(@"[UserManager] 获取访问token成功");
        return token;
    } else {
        NSLog(@"[UserManager] 访问token不存在");
        return nil;
    }
}

- (NSString *)getRefreshToken {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"BunnyxRefreshToken"];
    if (token && token.length > 0) {
        NSLog(@"[UserManager] 获取刷新token成功");
        return token;
    } else {
        NSLog(@"[UserManager] 刷新token不存在");
        return nil;
    }
}

- (NSString *)getTokenType {
    NSString *tokenType = [[NSUserDefaults standardUserDefaults] objectForKey:@"BunnyxTokenType"];
    return tokenType ?: @"bearer";
}

- (BOOL)isTokenExpired {
    NSTimeInterval expireTime = [[NSUserDefaults standardUserDefaults] doubleForKey:@"BunnyxTokenExpireTime"];
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // 提前5分钟判断为过期，避免临界时间问题
    BOOL expired = (currentTime >= (expireTime - 300));
    
    if (expired) {
        NSLog(@"[UserManager] Token已过期");
    } else {
        NSLog(@"[UserManager] Token未过期");
    }
    
    return expired;
}

- (void)refreshTokenWithSuccess:(void(^)(void))success
                        failure:(void(^)(NSError *error))failure {
    NSString *refreshToken = [self getRefreshToken];
    if (!refreshToken) {
        NSError *error = [NSError errorWithDomain:@"TokenError" 
                                             code:-1001 
                                         userInfo:@{NSLocalizedDescriptionKey: @"刷新token不存在"}];
        if (failure) {
            failure(error);
        }
        return;
    }
    
    // 刷新token时使用Basic认证，不携带access_token
    [[NetworkManager sharedManager] setBasicAuth];
    
    NSDictionary *parameters = @{@"refresh_token": refreshToken};
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_USER_REFRESH_TOKEN
                              parameters:parameters
                                 success:^(id responseObject) {
        NSLog(@"[UserManager] 刷新token成功: %@", responseObject);
        
        // 解析新的token信息
        NSDictionary *data = responseObject[@"data"];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            NSString *newAccessToken = data[@"access_token"];
            NSString *newRefreshToken = data[@"refresh_token"];
            NSString *tokenType = data[@"token_type"];
            NSNumber *expiresIn = data[@"expires_in"];
            
            if (newAccessToken && newRefreshToken) {
                // 保存新的token信息
                [self saveUserTokensWithAccessToken:newAccessToken
                                        refreshToken:newRefreshToken
                                           tokenType:tokenType
                                           expiresIn:expiresIn];
                
                // 设置新的Bearer认证
                [[NetworkManager sharedManager] setBearerAuthWithToken:newAccessToken];
                
                if (success) {
                    success();
                }
            } else {
                NSError *error = [NSError errorWithDomain:@"TokenError" 
                                                     code:-1002 
                                                 userInfo:@{NSLocalizedDescriptionKey: @"刷新token响应格式错误"}];
                if (failure) {
                    failure(error);
                }
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"TokenError" 
                                                 code:-1003 
                                             userInfo:@{NSLocalizedDescriptionKey: @"刷新token响应数据错误"}];
            if (failure) {
                failure(error);
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"[UserManager] 刷新token失败: %@", error);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)clearUserToken {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BunnyxAccessToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BunnyxRefreshToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BunnyxTokenType"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BunnyxTokenExpireTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"[UserManager] 清除用户token成功");
}

- (BOOL)isUserLoggedIn {
    NSString *accessToken = [self getAccessToken];
    return (accessToken && accessToken.length > 0);
}

#pragma mark - User Info Management

- (void)saveUserInfo:(NSDictionary *)userInfo {
    if (userInfo && [userInfo isKindOfClass:[NSDictionary class]]) {
        NSData *userInfoData = [NSKeyedArchiver archivedDataWithRootObject:userInfo];
        [[NSUserDefaults standardUserDefaults] setObject:userInfoData forKey:@"BunnyxUserInfo"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"[UserManager] 保存用户信息成功: %@", userInfo);
    } else {
        NSLog(@"[UserManager] 用户信息为空或格式错误，保存失败");
    }
}

- (NSDictionary *)getUserInfo {
    NSData *userInfoData = [[NSUserDefaults standardUserDefaults] objectForKey:@"BunnyxUserInfo"];
    if (userInfoData) {
        NSDictionary *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:userInfoData];
        if (userInfo && [userInfo isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[UserManager] 获取用户信息成功");
            return userInfo;
        }
    }
    NSLog(@"[UserManager] 用户信息不存在或格式错误");
    return nil;
}

- (void)clearUserInfo {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BunnyxUserInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"[UserManager] 清除用户信息成功");
}

- (void)logout {
    // 清除token
    [self clearUserToken];
    
    // 清除用户信息
    [self clearUserInfo];
    
    // 清除用户详细信息
    [[UserInfoManager sharedManager] clearUserInfo];
    
    // 清除网络认证
    [[NetworkManager sharedManager] clearAuth];
    
    NSLog(@"[UserManager] 用户登出完成");
}

- (void)logoutWithSuccess:(void(^)(void))success
                   failure:(void(^)(NSError *error))failure {
    // 先调用退出登录接口
    [[NetworkManager sharedManager] POST:BUNNYX_API_USER_LOGOUT
                               parameters:nil
                                  success:^(id responseObject) {
        NSLog(@"[UserManager] 退出登录接口调用成功: %@", responseObject);
        
        // 只有接口调用成功，才清除本地数据
        [self logout];
        
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        NSLog(@"[UserManager] 退出登录接口调用失败: %@", error);
        
        // 接口调用失败，不清除本地数据，只回调失败
        if (failure) {
            failure(error);
        }
    }];
}

- (void)quickLoginWithUsername:(NSString *)username
                     signature:(NSString *)signature
                       success:(void(^)(NSDictionary *tokenInfo))success
                       failure:(void(^)(NSError *error))failure {
    // 构建请求参数
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (username) {
        parameters[@"username"] = username;
    }
    if (signature) {
        parameters[@"signature"] = signature;
    }
    
    // 快速登录接口使用Basic认证
    [[NetworkManager sharedManager] setBasicAuth];
    
    NSLog(@"[UserManager] 快速登录请求参数: %@", parameters);
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_USER_LOGIN_QUICK
                              parameters:parameters
                                 success:^(id responseObject) {
        NSLog(@"[UserManager] 快速登录成功: %@", responseObject);
        
        // 解析token信息
        NSDictionary *data = responseObject[@"data"];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            if (success) {
                success(data);
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"QuickLoginError" 
                                                 code:-1001 
                                             userInfo:@{NSLocalizedDescriptionKey: @"登录响应数据格式错误"}];
            if (failure) {
                failure(error);
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"[UserManager] 快速登录失败: %@", error);
        if (failure) {
            failure(error);
        }
    }];
}

@end
