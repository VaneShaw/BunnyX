//
//  NewAppInfo.h
//  Bunnyx
//
//  新版本信息模型（GetAppConfigApi.NewAppInfo）
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 新版本信息模型（GetAppConfigApi.NewAppInfo）
 */
@interface NewAppInfo : BaseModel

/// 强制更新类型：1=强制更新，其他=非强制（forceType）
@property (nonatomic, assign) NSInteger forceType;

/// 应用版本号（appVersion）
@property (nonatomic, strong) NSString *appVersion;

/// 更新消息（updateMsg）
@property (nonatomic, strong) NSString *updateMsg;

/// 应用下载URL（appUrl）
@property (nonatomic, strong) NSString *appUrl;

/// 应用代码（平台标识）（appCode）
@property (nonatomic, strong) NSString *appCode;

/// 应用大小（appSize）
@property (nonatomic, strong) NSString *appSize;

@end

NS_ASSUME_NONNULL_END

