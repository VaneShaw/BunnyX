//
//  NewAppInfo.m
//  Bunnyx
//
//  新版本信息模型（对齐安卓GetAppConfigApi.NewAppInfo）
//

#import "NewAppInfo.h"
#import "BunnyxMacros.h"

@implementation NewAppInfo

#pragma mark - YYModel 映射配置

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"forceType": @"force_type",
        @"appVersion": @"app_version",
        @"updateMsg": @"update_msg",
        @"appUrl": @"app_url",
        @"appCode": @"app_code",
        @"appSize": @"app_size"
    };
}

// 手动处理字段映射，同时支持下划线和驼峰格式
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    // 尝试从字典中获取值，支持多种字段名格式
    // forceType / force_type
    id forceTypeValue = dic[@"forceType"] ?: dic[@"force_type"];
    if (forceTypeValue) {
        if ([forceTypeValue isKindOfClass:[NSNumber class]]) {
            self.forceType = [forceTypeValue integerValue];
        } else if ([forceTypeValue isKindOfClass:[NSString class]]) {
            self.forceType = [forceTypeValue integerValue];
        }
    }
    
    // appVersion / app_version
    id appVersionValue = dic[@"appVersion"] ?: dic[@"app_version"];
    if (appVersionValue && appVersionValue != [NSNull null]) {
        self.appVersion = [appVersionValue isKindOfClass:[NSString class]] ? appVersionValue : [appVersionValue stringValue];
    }
    
    // updateMsg / update_msg
    id updateMsgValue = dic[@"updateMsg"] ?: dic[@"update_msg"];
    if (updateMsgValue && updateMsgValue != [NSNull null]) {
        self.updateMsg = [updateMsgValue isKindOfClass:[NSString class]] ? updateMsgValue : [updateMsgValue stringValue];
    }
    
    // appUrl / app_url
    id appUrlValue = dic[@"appUrl"] ?: dic[@"app_url"];
    if (appUrlValue && appUrlValue != [NSNull null]) {
        self.appUrl = [appUrlValue isKindOfClass:[NSString class]] ? appUrlValue : [appUrlValue stringValue];
    }
    
    // appCode / app_code
    id appCodeValue = dic[@"appCode"] ?: dic[@"app_code"];
    if (appCodeValue && appCodeValue != [NSNull null]) {
        self.appCode = [appCodeValue isKindOfClass:[NSString class]] ? appCodeValue : [appCodeValue stringValue];
    }
    
    // appSize / app_size
    id appSizeValue = dic[@"appSize"] ?: dic[@"app_size"];
    if (appSizeValue && appSizeValue != [NSNull null]) {
        self.appSize = [appSizeValue isKindOfClass:[NSString class]] ? appSizeValue : [appSizeValue stringValue];
    }
    
    BUNNYX_LOG(@"NewAppInfo手动解析完成:");
    BUNNYX_LOG(@"  forceType: %ld", (long)self.forceType);
    BUNNYX_LOG(@"  appVersion: %@", self.appVersion);
    BUNNYX_LOG(@"  updateMsg: %@", self.updateMsg);
    BUNNYX_LOG(@"  appUrl: %@", self.appUrl);
    BUNNYX_LOG(@"  appCode: %@", self.appCode);
    BUNNYX_LOG(@"  appSize: %@", self.appSize);
    
    return YES;
}

@end

