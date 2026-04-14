//
//  UploadMaterialViewController.h
//  Bunnyx
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 素材上传页面（生产素材）
@interface UploadMaterialViewController : BaseViewController

/// 初始化时可传入素材ID
- (instancetype)initWithMaterialId:(NSInteger)materialId;

@end

NS_ASSUME_NONNULL_END


