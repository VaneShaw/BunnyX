//
//  NewAppInfo.m
//  Bunnyx
//
//  新版本信息模型（对齐安卓GetAppConfigApi.NewAppInfo）
//

#import "NewAppInfo.h"

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

@end

