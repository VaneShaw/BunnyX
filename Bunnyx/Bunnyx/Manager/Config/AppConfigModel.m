//
//  AppConfigModel.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "AppConfigModel.h"
#import "BunnyxMacros.h"

@implementation AppConfigModel

#pragma mark - 便利方法

- (BOOL)needUpdate {
    return [self versionCompareResult] > 0;
}

- (BOOL)isForceUpdate {
    return self.forceUpdate && [self needUpdate];
}

- (NSInteger)versionCompareResult {
    if (BUNNYX_IS_EMPTY_STRING(self.appVersion) || BUNNYX_IS_EMPTY_STRING(self.latestVersion)) {
        return 0;
    }
    
    return [self compareVersion:self.appVersion withVersion:self.latestVersion];
}

- (NSString *)configDescription {
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"应用名称: %@", BUNNYX_SAFE_STRING(self.appName)];
    [description appendFormat:@"\n应用版本: %@", BUNNYX_SAFE_STRING(self.appVersion)];
    [description appendFormat:@"\n最新版本: %@", BUNNYX_SAFE_STRING(self.latestVersion)];
    [description appendFormat:@"\n最低版本: %@", BUNNYX_SAFE_STRING(self.minVersion)];
    [description appendFormat:@"\n是否需要更新: %@", [self needUpdate] ? @"是" : @"否"];
    [description appendFormat:@"\n是否强制更新: %@", [self isForceUpdate] ? @"是" : @"否"];
    [description appendFormat:@"\n调试模式: %@", self.debugMode ? @"开启" : @"关闭"];
    [description appendFormat:@"\n日志记录: %@", self.logEnabled ? @"开启" : @"关闭"];
    [description appendFormat:@"\n配置更新时间: %@", BUNNYX_SAFE_STRING(self.updateTime)];
    
    return [description copy];
}

#pragma mark - 私有方法

- (NSInteger)compareVersion:(NSString *)version1 withVersion:(NSString *)version2 {
    if (BUNNYX_IS_EMPTY_STRING(version1) || BUNNYX_IS_EMPTY_STRING(version2)) {
        return 0;
    }
    
    NSArray *components1 = [version1 componentsSeparatedByString:@"."];
    NSArray *components2 = [version2 componentsSeparatedByString:@"."];
    
    NSInteger maxCount = MAX(components1.count, components2.count);
    
    for (NSInteger i = 0; i < maxCount; i++) {
        NSInteger value1 = 0;
        NSInteger value2 = 0;
        
        if (i < components1.count) {
            value1 = [components1[i] integerValue];
        }
        
        if (i < components2.count) {
            value2 = [components2[i] integerValue];
        }
        
        if (value1 > value2) {
            return -1; // version1 > version2
        } else if (value1 < value2) {
            return 1;  // version1 < version2
        }
    }
    
    return 0; // 相等
}

#pragma mark - 验证方法重写

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    // 验证应用版本
    if (BUNNYX_IS_EMPTY_STRING(self.appVersion)) {
        [errors addObject:@"应用版本不能为空"];
    }
    
    // 验证最新版本
    if (BUNNYX_IS_EMPTY_STRING(self.latestVersion)) {
        [errors addObject:@"最新版本不能为空"];
    }
    
    // 验证最低版本
    if (BUNNYX_IS_EMPTY_STRING(self.minVersion)) {
        [errors addObject:@"最低版本不能为空"];
    }
    
    // 验证版本号格式
    if (![self isValidVersion:self.appVersion]) {
        [errors addObject:@"应用版本格式不正确"];
    }
    
    if (![self isValidVersion:self.latestVersion]) {
        [errors addObject:@"最新版本格式不正确"];
    }
    
    if (![self isValidVersion:self.minVersion]) {
        [errors addObject:@"最低版本格式不正确"];
    }
    
    // 验证客服电话格式
    if (!BUNNYX_IS_EMPTY_STRING(self.customerServicePhone)) {
        NSString *phoneRegex = BUNNYX_REGEX_PHONE;
        NSPredicate *phonePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
        if (![phonePredicate evaluateWithObject:self.customerServicePhone]) {
            [errors addObject:@"客服电话格式不正确"];
        }
    }
    
    // 验证客服邮箱格式
    if (!BUNNYX_IS_EMPTY_STRING(self.customerServiceEmail)) {
        NSString *emailRegex = BUNNYX_REGEX_EMAIL;
        NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if (![emailPredicate evaluateWithObject:self.customerServiceEmail]) {
            [errors addObject:@"客服邮箱格式不正确"];
        }
    }
    
    // 验证缓存时间
    if (self.cacheTime < 0) {
        [errors addObject:@"缓存时间不能为负数"];
    }
    
    // 验证日志级别
    if (self.logLevel < 0 || self.logLevel > 5) {
        [errors addObject:@"日志级别必须在0-5之间"];
    }
    
    return [errors copy];
}

- (BOOL)isValidVersion:(NSString *)version {
    if (BUNNYX_IS_EMPTY_STRING(version)) {
        return NO;
    }
    
    // 版本号格式: x.y.z 或 x.y
    NSString *versionRegex = @"^\\d+(\\.\\d+){1,2}$";
    NSPredicate *versionPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", versionRegex];
    return [versionPredicate evaluateWithObject:version];
}

#pragma mark - 描述方法

- (NSString *)modelDescription {
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"<%@: %p>", NSStringFromClass([self class]), self];
    [description appendFormat:@"\n%@", [self configDescription]];
    return [description copy];
}

@end
