//
//  AppConfigModel.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "AppConfigModel.h"
#import "NewAppInfo.h"
#import "BunnyxMacros.h"

@implementation AppConfigModel

#pragma mark - YYModel 映射配置

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        // IMEI登录
        @"loginImeiSalt": @"login_imei_salt",
        
        // 服务器配置
        @"tencentVodConfig": @"tencent_vod_config",
        @"voteDrawUrl": @"vote_draw_url",
        @"feedbackUrl": @"feedback_url",
        @"interactMsg": @"interact_msg",
        @"votePath": @"vote_path",
        @"navigationMenu": @"navigation_menu",
        @"isEditSex": @"is_edit_sex",
        @"liveNotifyTitle": @"live_notify_title",
        @"serverIp": @"server_ip",
        @"purchaseAgreementUrl": @"purchase_agreement_url",
        @"siteServer": @"site_server",
        @"h5Server": @"h5_server",
        @"weixinClientId": @"weixinClientId",
        @"msgXingeConfig": @"msg_xinge_config",
        @"userAgreementUrl": @"user_agreement_url",
        @"recommendAnchorList": @"recommend_anchor_list",
        @"imageServer": @"image_server",
        @"liveGoBackTips": @"live_goBack_tips",
        @"liveLicenceUrl": @"live_licence_url",
        @"liveNotifyFansMsg": @"live_notify_fans_msg",
        @"userRegisterMsg": @"user_register_msg",
        @"avatarDefaultUrl": @"avatar_default_url",
        @"platformNotice": @"platform_notice",
        @"esIndex": @"es_index",
        @"cascadeFollow": @"cascade_follow",
        @"liveProgramGoBackTips": @"live_program_goBack_tips",
        @"vipPrivilegeConfig": @"vip_privilege_config",
        @"deviceMaxLogin": @"device_max_login",
        @"websiteUrl": @"website_url",
        @"liveProgramPremiereTitle": @"live_program_premiere_title",
        @"msgConfig": @"msg_config",
        @"barragePrice": @"barrage_price",
        @"anchorAdminNumber": @"anchor_admin_number",
        @"liveProgramPremiereMsg": @"live_program_premiere_msg",
        @"liveLicenceKey": @"live_licence_key",
        @"vipDiscountRate": @"vip_discount_rate",
        @"livePayTips": @"live_pay_tips",
        @"liveProgramPayTips": @"live_program_pay_tips",
        @"disclaimerTips": @"disclaimer_tips",
        @"ipMaxLogin": @"ip_max_login",
        @"privacyPolicyUrl": @"privacy_policy_url",
        @"subscribeVipTips": @"subscribe_vip_tips",
        @"vipDiscountTips": @"vip_discount_tips",
        @"latestAppInfo": @"new_app_info"
    };
}

+ (NSDictionary *)modelContainerPropertyGenericClass {
    // modelContainerPropertyGenericClass 主要用于数组类型
    // 对于单个嵌套对象，我们使用modelCustomTransformFromDictionary手动处理
    return @{};
}

// 手动处理new_app_info字段到latestAppInfo的转换
// 确保嵌套对象能正确解析
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    // 手动解析new_app_info字段
    id newAppInfoData = dic[@"new_app_info"];
    if (newAppInfoData && [newAppInfoData isKindOfClass:[NSDictionary class]]) {
        // 打印原始数据，用于调试
        BUNNYX_LOG(@"new_app_info原始数据: %@", newAppInfoData);
        
        // 尝试解析
        self.latestAppInfo = [NewAppInfo modelWithDictionary:newAppInfoData];
        
        // 打印解析结果
        if (self.latestAppInfo) {
            BUNNYX_LOG(@"成功解析new_app_info:");
            BUNNYX_LOG(@"  forceType: %ld", (long)self.latestAppInfo.forceType);
            BUNNYX_LOG(@"  appVersion: %@", self.latestAppInfo.appVersion);
            BUNNYX_LOG(@"  updateMsg: %@", self.latestAppInfo.updateMsg);
            BUNNYX_LOG(@"  appUrl: %@", self.latestAppInfo.appUrl);
            BUNNYX_LOG(@"  appCode: %@", self.latestAppInfo.appCode);
            BUNNYX_LOG(@"  appSize: %@", self.latestAppInfo.appSize);
            BUNNYX_LOG(@"完整对象: %@", [self.latestAppInfo toDictionary]);
        } else {
            BUNNYX_ERROR(@"NewAppInfo解析失败，原始数据: %@", newAppInfoData);
        }
    } else if (newAppInfoData == nil || newAppInfoData == [NSNull null]) {
        self.latestAppInfo = nil;
        BUNNYX_LOG(@"new_app_info字段为空或NSNull");
    } else {
        BUNNYX_ERROR(@"new_app_info字段类型错误: %@", [newAppInfoData class]);
        self.latestAppInfo = nil;
    }
    return YES;
}


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
