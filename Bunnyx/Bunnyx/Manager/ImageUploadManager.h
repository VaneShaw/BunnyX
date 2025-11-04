//
//  ImageUploadManager.h
//  Bunnyx
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ImageUploadSuccessBlock)(NSString *initImage);
typedef void(^ImageUploadFailureBlock)(NSError *error);
typedef void(^ImageUploadProgressBlock)(CGFloat progress, NSString *status);

/// 图片上传管理器
/// 封装图片上传到AWS S3的完整流程
@interface ImageUploadManager : NSObject

+ (instancetype)sharedManager;

/**
 * 上传图片（完整流程：压缩 -> 获取配置 -> 上传 -> 返回路径）
 * @param materialId 素材ID
 * @param image 要上传的图片
 * @param progressBlock 进度回调（可选）
 * @param successBlock 成功回调（返回 initImage 路径）
 * @param failureBlock 失败回调
 */
- (void)uploadImage:(NSInteger)materialId
              image:(UIImage *)image
            progress:(ImageUploadProgressBlock _Nullable)progressBlock
             success:(ImageUploadSuccessBlock)successBlock
             failure:(ImageUploadFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
