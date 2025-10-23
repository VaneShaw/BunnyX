//
//  UserModel.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "UserModel.h"
#import "BunnyxMacros.h"

@implementation UserModel

#pragma mark - 便利方法

- (NSString *)genderDescription {
    switch (self.gender) {
        case 1:
            return @"男";
        case 2:
            return @"女";
        default:
            return @"未知";
    }
}

- (NSString *)statusDescription {
    switch (self.status) {
        case 0:
            return @"正常";
        case 1:
            return @"禁用";
        default:
            return @"未知";
    }
}

- (BOOL)isVipUser {
    return self.isVip && ![self isVipExpired];
}

- (BOOL)isVipExpired {
    if (!self.isVip || BUNNYX_IS_EMPTY_STRING(self.vipExpireTime)) {
        return YES;
    }
    
    // 这里可以添加具体的VIP过期时间判断逻辑
    // 示例：比较当前时间与VIP过期时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *expireDate = [formatter dateFromString:self.vipExpireTime];
    NSDate *currentDate = [NSDate date];
    
    return [currentDate compare:expireDate] == NSOrderedDescending;
}

#pragma mark - 验证方法重写

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    // 验证用户ID
    if (BUNNYX_IS_EMPTY_STRING(self.userId)) {
        [errors addObject:@"用户ID不能为空"];
    }
    
    // 验证用户名
    if (BUNNYX_IS_EMPTY_STRING(self.username)) {
        [errors addObject:@"用户名不能为空"];
    } else if (self.username.length < 3 || self.username.length > 20) {
        [errors addObject:@"用户名长度必须在3-20个字符之间"];
    }
    
    // 验证邮箱格式
    if (!BUNNYX_IS_EMPTY_STRING(self.email)) {
        NSString *emailRegex = BUNNYX_REGEX_EMAIL;
        NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if (![emailPredicate evaluateWithObject:self.email]) {
            [errors addObject:@"邮箱格式不正确"];
        }
    }
    
    // 验证手机号格式
    if (!BUNNYX_IS_EMPTY_STRING(self.phone)) {
        NSString *phoneRegex = BUNNYX_REGEX_PHONE;
        NSPredicate *phonePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
        if (![phonePredicate evaluateWithObject:self.phone]) {
            [errors addObject:@"手机号格式不正确"];
        }
    }
    
    // 验证性别
    if (self.gender < 0 || self.gender > 2) {
        [errors addObject:@"性别值无效"];
    }
    
    // 验证状态
    if (self.status < 0 || self.status > 1) {
        [errors addObject:@"用户状态值无效"];
    }
    
    return [errors copy];
}

#pragma mark - 描述方法

- (NSString *)modelDescription {
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"<%@: %p>", NSStringFromClass([self class]), self];
    [description appendFormat:@"\n用户ID: %@", BUNNYX_SAFE_STRING(self.userId)];
    [description appendFormat:@"\n用户名: %@", BUNNYX_SAFE_STRING(self.username)];
    [description appendFormat:@"\n昵称: %@", BUNNYX_SAFE_STRING(self.nickname)];
    [description appendFormat:@"\n邮箱: %@", BUNNYX_SAFE_STRING(self.email)];
    [description appendFormat:@"\n手机号: %@", BUNNYX_SAFE_STRING(self.phone)];
    [description appendFormat:@"\n性别: %@", [self genderDescription]];
    [description appendFormat:@"\n状态: %@", [self statusDescription]];
    [description appendFormat:@"\nVIP用户: %@", self.isVipUser ? @"是" : @"否"];
    return [description copy];
}

@end
