//
//  APIResponseModel.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "APIResponseModel.h"
#import "BunnyxMacros.h"

@implementation APIResponseModel

#pragma mark - 便利方法

- (BOOL)isSuccess {
    return self.code == BUNNYX_CODE_SUCCESS;
}

- (NSString *)errorMessage {
    if (self.isSuccess) {
        return nil;
    }
    
    if (!BUNNYX_IS_EMPTY_STRING(self.message)) {
        return self.message;
    }
    
    // 根据错误码返回默认错误信息
    switch (self.code) {
        case BUNNYX_CODE_ERROR:
            return @"未知错误";
        case BUNNYX_CODE_TOKEN_EXPIRED:
            return @"登录已过期，请重新登录";
        case BUNNYX_CODE_USER_NOT_FOUND:
            return @"用户不存在";
        case BUNNYX_CODE_PARAM_ERROR:
            return @"参数错误";
        default:
            return [NSString stringWithFormat:@"请求失败 (错误码: %ld)", (long)self.code];
    }
}

- (NSDictionary *)dataDictionary {
    if ([self.data isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)self.data;
    }
    return @{};
}

- (NSArray *)dataArray {
    if ([self.data isKindOfClass:[NSArray class]]) {
        return (NSArray *)self.data;
    }
    return @[];
}

- (NSString *)dataString {
    if ([self.data isKindOfClass:[NSString class]]) {
        return (NSString *)self.data;
    }
    return @"";
}

#pragma mark - 验证方法重写

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    // 验证响应码
    if (self.code < 0) {
        [errors addObject:@"响应码不能为负数"];
    }
    
    // 验证消息
    if (BUNNYX_IS_EMPTY_STRING(self.message) && !self.isSuccess) {
        [errors addObject:@"错误响应缺少消息"];
    }
    
    return [errors copy];
}

#pragma mark - 描述方法

- (NSString *)modelDescription {
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"<%@: %p>", NSStringFromClass([self class]), self];
    [description appendFormat:@"\n响应码: %ld", (long)self.code];
    [description appendFormat:@"\n响应消息: %@", BUNNYX_SAFE_STRING(self.message)];
    [description appendFormat:@"\n是否成功: %@", self.isSuccess ? @"是" : @"否"];
    [description appendFormat:@"\n时间戳: %@", BUNNYX_SAFE_STRING(self.timestamp)];
    [description appendFormat:@"\n请求ID: %@", BUNNYX_SAFE_STRING(self.requestId)];
    
    if (self.data) {
        [description appendFormat:@"\n数据: %@", self.data];
    }
    
    return [description copy];
}

@end
