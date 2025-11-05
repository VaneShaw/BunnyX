//
//  UploadingViewController.h
//  Bunnyx
//
//  上传中页面（仿照安卓 UploadingActivity）
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 上传中页面
/// 显示上传进度，处理图片上传和生成任务提交
@interface UploadingViewController : BaseViewController

/// 初始化上传中页面（需要上传图片）
/// @param materialId 素材ID
/// @param image 要上传的图片
- (instancetype)initWithMaterialId:(NSInteger)materialId image:(UIImage *)image;

/// 初始化上传中页面（从历史记录生成，直接进入轮询）
/// @param materialId 素材ID
/// @param image 图片（可选，用于显示）
/// @param createIds 生成任务ID（多个用逗号分隔）
/// @param uploadedImagePath 已上传的图片路径（用于显示）
/// @param templateImageUrl 模板图片URL（用于显示）
- (instancetype)initWithMaterialId:(NSInteger)materialId 
                             image:(UIImage * _Nullable)image 
                          createIds:(NSString *)createIds 
                  uploadedImagePath:(NSString * _Nullable)uploadedImagePath 
                   templateImageUrl:(NSString * _Nullable)templateImageUrl;

/// 模板图片URL（用于显示）
@property (nonatomic, strong, nullable) NSString *templateImageUrl;

@end

NS_ASSUME_NONNULL_END

