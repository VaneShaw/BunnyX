//
//  AppConfigUsageExample.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import <Foundation/Foundation.h>
#import "AppConfigManager.h"
#import "BunnyxMacros.h"

/**
 * AppConfigManager 使用示例
 * 展示如何使用应用配置管理器
 */

@implementation NSObject (AppConfigUsageExample)

#pragma mark - 基本使用示例

+ (void)basicUsageExample {
    BUNNYX_LOG(@"=== AppConfigManager 基本使用示例 ===");
    
    AppConfigManager *configManager = [AppConfigManager sharedManager];
    
    // 获取应用配置
    [configManager getAppConfigWithSuccess:^(AppConfigModel *configModel) {
        BUNNYX_LOG(@"配置获取成功: %@", [configModel configDescription]);
        
        // 检查是否需要更新
        if ([configModel needUpdate]) {
            BUNNYX_LOG(@"应用需要更新");
            if ([configModel isForceUpdate]) {
                BUNNYX_LOG(@"强制更新: %@", configModel.updateDescription);
            }
        } else {
            BUNNYX_LOG(@"应用已是最新版本");
        }
        
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"配置获取失败: %@", error.localizedDescription);
    }];
}

#pragma mark - 强制刷新示例

+ (void)forceRefreshExample {
    BUNNYX_LOG(@"=== 强制刷新配置示例 ===");
    
    AppConfigManager *configManager = [AppConfigManager sharedManager];
    
    // 强制刷新配置
    [configManager getAppConfigWithForceRefresh:YES success:^(AppConfigModel *configModel) {
        BUNNYX_LOG(@"强制刷新成功: %@", [configModel configDescription]);
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"强制刷新失败: %@", error.localizedDescription);
    }];
}

#pragma mark - 配置信息获取示例

+ (void)configInfoExample {
    BUNNYX_LOG(@"=== 配置信息获取示例 ===");
    
    AppConfigManager *configManager = [AppConfigManager sharedManager];
    
    // 获取版本信息
    NSDictionary *versionInfo = [configManager getVersionInfo];
    BUNNYX_LOG(@"版本信息: %@", versionInfo);
    
    // 获取客服信息
    NSDictionary *serviceInfo = [configManager getCustomerServiceInfo];
    BUNNYX_LOG(@"客服信息: %@", serviceInfo);
    
    // 获取链接信息
    NSDictionary *linkInfo = [configManager getLinkInfo];
    BUNNYX_LOG(@"链接信息: %@", linkInfo);
    
    // 获取分享信息
    NSDictionary *shareInfo = [configManager getShareInfo];
    BUNNYX_LOG(@"分享信息: %@", shareInfo);
    
    // 获取调试信息
    NSDictionary *debugInfo = [configManager getDebugInfo];
    BUNNYX_LOG(@"调试信息: %@", debugInfo);
}

#pragma mark - 缓存管理示例

+ (void)cacheManagementExample {
    BUNNYX_LOG(@"=== 缓存管理示例 ===");
    
    AppConfigManager *configManager = [AppConfigManager sharedManager];
    
    // 检查是否需要更新配置
    BOOL shouldUpdate = [configManager shouldUpdateConfig];
    BUNNYX_LOG(@"是否需要更新配置: %@", shouldUpdate ? @"是" : @"否");
    
    // 获取缓存的配置
    AppConfigModel *cachedConfig = [configManager getCachedConfig];
    if (cachedConfig) {
        BUNNYX_LOG(@"缓存配置: %@", [cachedConfig configDescription]);
    } else {
        BUNNYX_LOG(@"没有缓存配置");
    }
    
    // 清除配置缓存
    [configManager clearConfigCache];
    BUNNYX_LOG(@"配置缓存已清除");
}

#pragma mark - 实际应用场景示例

+ (void)realWorldUsageExample {
    BUNNYX_LOG(@"=== 实际应用场景示例 ===");
    
    AppConfigManager *configManager = [AppConfigManager sharedManager];
    
    // 场景1: 应用启动时检查更新
    [configManager getAppConfigWithSuccess:^(AppConfigModel *configModel) {
        if ([configModel needUpdate]) {
            // 显示更新提示
            [self showUpdateAlert:configModel];
        }
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"启动时获取配置失败: %@", error.localizedDescription);
    }];
    
    // 场景2: 获取客服联系方式
    NSDictionary *serviceInfo = [configManager getCustomerServiceInfo];
    NSString *phone = serviceInfo[@"phone"];
    NSString *email = serviceInfo[@"email"];
    
    if (phone.length > 0) {
        BUNNYX_LOG(@"客服电话: %@", phone);
    }
    
    if (email.length > 0) {
        BUNNYX_LOG(@"客服邮箱: %@", email);
    }
    
    // 场景3: 获取分享信息
    NSDictionary *shareInfo = [configManager getShareInfo];
    NSString *shareUrl = shareInfo[@"url"];
    NSString *shareTitle = shareInfo[@"title"];
    NSString *shareDescription = shareInfo[@"description"];
    
    if (shareUrl.length > 0) {
        BUNNYX_LOG(@"分享链接: %@", shareUrl);
        BUNNYX_LOG(@"分享标题: %@", shareTitle);
        BUNNYX_LOG(@"分享描述: %@", shareDescription);
    }
    
    // 场景4: 检查调试模式
    NSDictionary *debugInfo = [configManager getDebugInfo];
    BOOL debugMode = [debugInfo[@"debugMode"] boolValue];
    BOOL logEnabled = [debugInfo[@"logEnabled"] boolValue];
    
    if (debugMode) {
        BUNNYX_LOG(@"调试模式已开启");
    }
    
    if (logEnabled) {
        BUNNYX_LOG(@"日志记录已开启");
    }
}

#pragma mark - 辅助方法

+ (void)showUpdateAlert:(AppConfigModel *)configModel {
    // 这里可以显示更新提示对话框
    BUNNYX_LOG(@"显示更新提示: %@", configModel.updateDescription);
    
    if ([configModel isForceUpdate]) {
        BUNNYX_LOG(@"强制更新，用户必须更新才能继续使用");
    } else {
        BUNNYX_LOG(@"可选更新，用户可以稍后更新");
    }
}

#pragma mark - 运行所有示例

+ (void)runAllExamples {
    BUNNYX_LOG(@"开始运行AppConfigManager使用示例...");
    
    [self basicUsageExample];
    [self forceRefreshExample];
    [self configInfoExample];
    [self cacheManagementExample];
    [self realWorldUsageExample];
    
    BUNNYX_LOG(@"AppConfigManager使用示例运行完成！");
}

@end
