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

/// IMEI快速登录签名盐值
@property (nonatomic, strong) NSString *loginImeiSalt;

// MARK: - 服务器配置字段
/// 封面版本
@property (nonatomic, strong) NSString *coverVersion;
/// 腾讯云点播配置
@property (nonatomic, strong) NSString *tencentVodConfig;
/// iOS配置
@property (nonatomic, strong) NSDictionary *iOS;
/// 投票抽奖URL
@property (nonatomic, strong) NSString *voteDrawUrl;
/// Google客户端ID
@property (nonatomic, strong) NSString *googleClientId;
/// 互动消息配置
@property (nonatomic, strong) NSString *interactMsg;
/// 投票路径
@property (nonatomic, strong) NSString *votePath;
/// 导航菜单
@property (nonatomic, strong) NSArray *navigationMenu;
/// 是否可编辑性别
@property (nonatomic, strong) NSString *isEditSex;
/// 直播通知标题
@property (nonatomic, strong) NSString *liveNotifyTitle;
/// 服务器IP
@property (nonatomic, strong) NSString *serverIp;
/// 购买协议URL
@property (nonatomic, strong) NSString *purchaseAgreementUrl;
/// 站点服务器
@property (nonatomic, strong) NSString *siteServer;
/// 系统消息配置
@property (nonatomic, strong) NSDictionary *systemMsg;
/// H5服务器
@property (nonatomic, strong) NSString *h5Server;
/// 微信客户端ID
@property (nonatomic, strong) NSString *weixinClientId;
/// 助手消息配置
@property (nonatomic, strong) NSDictionary *helperMsg;
/// Android配置
@property (nonatomic, strong) NSDictionary *android;
/// 信鸽配置
@property (nonatomic, strong) NSString *msgXingeConfig;
/// TPNS App Key
@property (nonatomic, strong) NSString *tpnsAppKey;
/// TPNS App ID
@property (nonatomic, strong) NSString *tpnsAppID;
/// 推荐主播列表
@property (nonatomic, strong) NSString *recommendAnchorList;
/// 图片服务器
@property (nonatomic, strong) NSString *imageServer;
/// 直播返回提示
@property (nonatomic, strong) NSString *liveGoBackTips;
/// 直播许可证URL
@property (nonatomic, strong) NSString *liveLicenceUrl;
/// 直播通知粉丝消息
@property (nonatomic, strong) NSString *liveNotifyFansMsg;
/// 用户注册消息
@property (nonatomic, strong) NSString *userRegisterMsg;
/// OSS配置
@property (nonatomic, strong) NSDictionary *ossConfig;
/// 默认头像URL
@property (nonatomic, strong) NSString *avatarDefaultUrl;
/// 平台公告
@property (nonatomic, strong) NSString *platformNotice;
/// ES索引
@property (nonatomic, strong) NSString *esIndex;
/// 级联关注
@property (nonatomic, strong) NSString *cascadeFollow;
/// 访客消息配置
@property (nonatomic, strong) NSDictionary *visitorMsg;
/// 直播节目返回提示
@property (nonatomic, strong) NSString *liveProgramGoBackTips;
/// TPNS Host
@property (nonatomic, strong) NSString *tpnsHost;
/// VIP特权配置
@property (nonatomic, strong) NSString *vipPrivilegeConfig;
/// TIM业务ID
@property (nonatomic, strong) NSString *timBusinessID;
/// 设备最大登录数
@property (nonatomic, strong) NSString *deviceMaxLogin;
/// 网站URL
@property (nonatomic, strong) NSString *websiteUrl;
/// 直播节目首播标题
@property (nonatomic, strong) NSString *liveProgramPremiereTitle;
/// 消息配置
@property (nonatomic, strong) NSString *msgConfig;
/// 弹幕价格
@property (nonatomic, strong) NSString *barragePrice;
/// 主播管理员数量
@property (nonatomic, strong) NSString *anchorAdminNumber;
/// Facebook客户端ID
@property (nonatomic, strong) NSString *facebookClientId;
/// TIM App ID
@property (nonatomic, strong) NSString *timAppID;
/// 直播节目首播消息
@property (nonatomic, strong) NSString *liveProgramPremiereMsg;
/// 直播许可证Key
@property (nonatomic, strong) NSString *liveLicenceKey;
/// VIP折扣率
@property (nonatomic, strong) NSString *vipDiscountRate;
/// 直播支付提示
@property (nonatomic, strong) NSString *livePayTips;
/// 直播节目支付提示
@property (nonatomic, strong) NSString *liveProgramPayTips;
/// 免责声明提示
@property (nonatomic, strong) NSString *disclaimerTips;
/// IP最大登录数
@property (nonatomic, strong) NSString *ipMaxLogin;
/// 订阅VIP提示
@property (nonatomic, strong) NSString *subscribeVipTips;
/// VIP折扣提示
@property (nonatomic, strong) NSString *vipDiscountTips;

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
