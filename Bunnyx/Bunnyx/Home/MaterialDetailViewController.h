//
//  MaterialDetailViewController.h
//  Bunnyx
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

// 页面类型常量（对齐安卓：VideoDetailActivity）
typedef NS_ENUM(NSInteger, MaterialDetailPageType) {
    MaterialDetailPageTypeMaterial = 0,  // 素材详情
    MaterialDetailPageTypeGenerate = 1,   // 生成详情（从我的页面生成列表进入）
    MaterialDetailPageTypeGenerateFromUploading = 2  // 从上传页面生成完成进入
};

@interface MaterialDetailViewController : BaseViewController

- (instancetype)initWithMaterialId:(NSInteger)materialId;
- (instancetype)initWithMaterialId:(NSInteger)materialId pageType:(MaterialDetailPageType)pageType;

@end

NS_ASSUME_NONNULL_END
