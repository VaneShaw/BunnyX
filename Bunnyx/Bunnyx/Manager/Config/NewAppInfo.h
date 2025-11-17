//
//  NewAppInfo.h
//  Bunnyx
//
//  新版本信息模型（对齐安卓GetAppConfigApi.NewAppInfo）
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 新版本信息模型（对齐安卓GetAppConfigApi.NewAppInfo）
 */
@interface NewAppInfo : BaseModel

/// 强制更新类型：1=强制更新，其他=非强制（对齐安卓：forceType）
@property (nonatomic, assign) NSInteger forceType;

/// 应用版本号（对齐安卓：appVersion）
@property (nonatomic, strong) NSString *appVersion;

/// 更新消息（对齐安卓：updateMsg）
@property (nonatomic, strong) NSString *updateMsg;

/// 应用下载URL（对齐安卓：appUrl）
@property (nonatomic, strong) NSString *appUrl;

/// 应用代码（android/ios）（对齐安卓：appCode）
@property (nonatomic, strong) NSString *appCode;

/// 应用大小（对齐安卓：appSize）
@property (nonatomic, strong) NSString *appSize;

@end

NS_ASSUME_NONNULL_END

