//
//  UserModel.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 用户模型
 * 继承自BaseModel，提供用户相关的数据模型
 */
@interface UserModel : BaseModel

/// 用户ID
@property (nonatomic, strong) NSString *userId;

/// 用户名
@property (nonatomic, strong) NSString *username;

/// 昵称
@property (nonatomic, strong) NSString *nickname;

/// 邮箱
@property (nonatomic, strong) NSString *email;

/// 手机号
@property (nonatomic, strong) NSString *phone;

/// 头像URL
@property (nonatomic, strong) NSString *avatar;

/// 性别 (0:未知, 1:男, 2:女)
@property (nonatomic, assign) NSInteger gender;

/// 生日
@property (nonatomic, strong) NSString *birthday;

/// 注册时间
@property (nonatomic, strong) NSString *registerTime;

/// 最后登录时间
@property (nonatomic, strong) NSString *lastLoginTime;

/// 用户状态 (0:正常, 1:禁用)
@property (nonatomic, assign) NSInteger status;

/// 是否VIP用户
@property (nonatomic, assign) BOOL isVip;

/// VIP过期时间
@property (nonatomic, strong) NSString *vipExpireTime;

#pragma mark - 便利方法

/**
 * 获取性别描述
 * @return 性别描述字符串
 */
- (NSString *)genderDescription;

/**
 * 获取状态描述
 * @return 状态描述字符串
 */
- (NSString *)statusDescription;

/**
 * 检查是否为VIP用户
 * @return 是否为VIP用户
 */
- (BOOL)isVipUser;

/**
 * 检查VIP是否过期
 * @return VIP是否过期
 */
- (BOOL)isVipExpired;

@end

NS_ASSUME_NONNULL_END
