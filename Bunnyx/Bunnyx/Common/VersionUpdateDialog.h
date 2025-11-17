//
//  VersionUpdateDialog.h
//  Bunnyx
//
//  版本更新弹窗（对齐安卓VersionUpdateDialog）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VersionUpdateDialog;

/// 版本信息模型（对齐安卓GetAppConfigApi.NewAppInfo）
@interface VersionUpdateInfo : NSObject

/// 强制更新类型：1=强制更新，其他=非强制
@property (nonatomic, assign) NSInteger forceType;

/// 应用版本号
@property (nonatomic, copy) NSString *appVersion;

/// 更新消息
@property (nonatomic, copy) NSString *updateMsg;

/// 应用下载URL
@property (nonatomic, copy) NSString *appUrl;

/// 应用代码（android/ios）
@property (nonatomic, copy) NSString *appCode;

/// 应用大小
@property (nonatomic, copy) NSString *appSize;

@end

/// 关闭监听器（对齐安卓OnDismissListener）
typedef void(^OnDismissListener)(void);

/// 版本更新弹窗
@interface VersionUpdateDialog : UIView

/// 显示版本更新弹窗（对齐安卓：show）
/// @param appInfo 版本信息
+ (void)showWithAppInfo:(VersionUpdateInfo *)appInfo;

/// 显示版本更新弹窗，并设置关闭监听器（对齐安卓：showWithListener）
/// @param appInfo 版本信息
/// @param onDismissListener 关闭监听器
+ (VersionUpdateDialog *)showWithAppInfo:(VersionUpdateInfo *)appInfo onDismiss:(OnDismissListener _Nullable)onDismissListener;

/// 关闭弹窗
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

