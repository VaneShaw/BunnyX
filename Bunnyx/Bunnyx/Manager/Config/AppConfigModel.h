//
//  AppConfigModel.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 应用配置模型
 * 用于处理服务器返回的应用配置信息
 */
@interface AppConfigModel : BaseModel

/// 应用版本
@property (nonatomic, strong) NSString *appVersion;

/// 最低支持版本
@property (nonatomic, strong) NSString *minVersion;

/// 最新版本
@property (nonatomic, strong) NSString *latestVersion;

/// 是否强制更新
@property (nonatomic, assign) BOOL forceUpdate;

/// 更新描述
@property (nonatomic, strong) NSString *updateDescription;

/// 下载链接
@property (nonatomic, strong) NSString *downloadUrl;

/// 应用名称
@property (nonatomic, strong) NSString *appName;

/// 应用描述
@property (nonatomic, strong) NSString *appDescription;

/// 客服电话
@property (nonatomic, strong) NSString *customerServicePhone;

/// 客服邮箱
@property (nonatomic, strong) NSString *customerServiceEmail;

/// 官方网站
@property (nonatomic, strong) NSString *officialWebsite;

/// 隐私政策链接
@property (nonatomic, strong) NSString *privacyPolicyUrl;

/// 用户协议链接
@property (nonatomic, strong) NSString *userAgreementUrl;

/// 关于我们链接
@property (nonatomic, strong) NSString *aboutUsUrl;

/// 帮助中心链接
@property (nonatomic, strong) NSString *helpCenterUrl;

/// 反馈链接
@property (nonatomic, strong) NSString *feedbackUrl;

/// 分享链接
@property (nonatomic, strong) NSString *shareUrl;

/// 分享标题
@property (nonatomic, strong) NSString *shareTitle;

/// 分享描述
@property (nonatomic, strong) NSString *shareDescription;

/// 分享图片
@property (nonatomic, strong) NSString *shareImage;

/// 是否开启调试模式
@property (nonatomic, assign) BOOL debugMode;

/// 是否开启日志记录
@property (nonatomic, assign) BOOL logEnabled;

/// 日志级别
@property (nonatomic, assign) NSInteger logLevel;

/// 缓存时间（秒）
@property (nonatomic, assign) NSInteger cacheTime;

/// 配置更新时间
@property (nonatomic, strong) NSString *updateTime;

#pragma mark - 便利方法

/**
 * 检查是否需要更新
 * @return 是否需要更新
 */
- (BOOL)needUpdate;

/**
 * 检查是否强制更新
 * @return 是否强制更新
 */
- (BOOL)isForceUpdate;

/**
 * 获取版本比较结果
 * @return 版本比较结果 (1:需要更新, 0:最新版本, -1:版本过低)
 */
- (NSInteger)versionCompareResult;

/**
 * 获取配置描述信息
 * @return 配置描述字符串
 */
- (NSString *)configDescription;

@end

NS_ASSUME_NONNULL_END
