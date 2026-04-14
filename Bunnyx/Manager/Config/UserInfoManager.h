//
//  UserInfoManager.h
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import <Foundation/Foundation.h>
#import "UserInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^UserInfoSuccessBlock)(UserInfoModel *userInfo);
typedef void(^UserInfoFailureBlock)(NSError *error);

@interface UserInfoManager : NSObject

+ (instancetype)sharedManager;

/**
 * 获取当前用户信息
 * @return 当前用户信息，如果未登录返回nil
 */
- (UserInfoModel *)getCurrentUserInfo;

/**
 * 刷新用户信息
 * @param account 被查看人账号，自己则不传
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)refreshUserInfoWithAccount:(NSString * _Nullable)account
                           success:(UserInfoSuccessBlock)success
                           failure:(UserInfoFailureBlock)failure;

/**
 * 刷新当前用户信息
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)refreshCurrentUserInfoWithSuccess:(UserInfoSuccessBlock)success
                                  failure:(UserInfoFailureBlock)failure;

/**
 * 清除用户信息
 */
- (void)clearUserInfo;

#pragma mark - 便捷访问方法

// 基本信息
- (NSNumber *)getUserId;
- (NSString *)getAccount;
- (NSString *)getNickname;
- (NSString *)getAvatar;
- (NSNumber *)getLevel;
- (NSString *)getSignature;
- (NSString *)getRoleName;
- (NSString *)getRealName;
- (NSString *)getCity;
- (NSString *)getInviteCode;

// 社交信息
- (NSNumber *)getFansNum;
- (NSNumber *)getFollowNum;
- (NSString *)getCountry;
- (NSString *)getProvince;
- (NSNumber *)getInviteNum;
- (NSNumber *)getChatNum;

// 消费信息
- (NSNumber *)getTotalConsume;
- (NSNumber *)getTotalTicket;
- (NSNumber *)getSurplusDiamond;
- (NSNumber *)getSurplusMxdDiamond; // 金币数量余额
- (NSNumber *)getSurplusMxpDiamond;

// 状态信息
- (BOOL)isVip;
- (NSNumber *)getVipEndTime;
- (NSString *)getEmail;
- (BOOL)isBlack;
- (BOOL)isWhiteUser;
- (BOOL)isPerfectInfo;
- (NSString *)getCareer;
- (NSString *)getConstellate;

@end

NS_ASSUME_NONNULL_END
