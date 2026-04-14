//
//  AWSUploader.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// AWS S3 上传回调
@protocol AWSUploaderDelegate <NSObject>

@optional
/// 上传进度
- (void)awsUploaderDidUpdateProgress:(NSInteger)percent;

/// 上传成功
- (void)awsUploaderDidUploadSuccessWithFullUrl:(NSString *)fullUrl relativePath:(NSString *)relativePath;

/// 上传失败
- (void)awsUploaderDidUploadFailWithError:(NSError *)error;

@end

/// AWS S3 上传工具类
/// 适配 iOS，通过 Cognito 身份池授权上传
@interface AWSUploader : NSObject

/// 上传代理
@property (nonatomic, weak) id<AWSUploaderDelegate> delegate;

/// 单例
+ (instancetype)sharedUploader;

/**
 * 上传图片到 AWS S3（使用预签名URL，推荐）
 * @param imageData 图片数据
 * @param presignedUrl 后端提供的预签名上传URL
 * @param progressBlock 进度回调
 * @param successBlock 成功回调（relativePath: 相对路径）
 * @param failureBlock 失败回调
 */
- (void)uploadImageData:(NSData *)imageData
           presignedUrl:(NSString *)presignedUrl
               progress:(void(^_Nullable)(NSInteger percent))progressBlock
                success:(void(^)(NSString *relativePath))successBlock
                failure:(void(^)(NSError *error))failureBlock;

/**
 * 上传图片到 AWS S3（直接上传，需要 AWS SDK 支持签名）
 * @param image 要上传的图片
 * @param poolId Cognito 身份池 ID（从后端获取）
 * @param region AWS 区域（例如：ap-northeast-1）
 * @param bucket S3 存储桶名称
 * @param filePathName 上传后 S3 路径（例如：avatar/2024/04/30/xxx.png）
 */
- (void)uploadImage:(UIImage *)image
            poolId:(NSString *)poolId
            region:(NSString *)region
            bucket:(NSString *)bucket
       filePathName:(NSString *)filePathName;

/**
 * 上传图片到 AWS S3（Block 回调方式）
 * @param image 要上传的图片
 * @param poolId Cognito 身份池 ID
 * @param region AWS 区域
 * @param bucket S3 存储桶名称
 * @param filePathName 上传后 S3 路径
 * @param progressBlock 进度回调
 * @param successBlock 成功回调（fullUrl: 完整URL, relativePath: 相对路径）
 * @param failureBlock 失败回调
 */
- (void)uploadImage:(UIImage *)image
            poolId:(NSString *)poolId
            region:(NSString *)region
            bucket:(NSString *)bucket
       filePathName:(NSString *)filePathName
           progress:(void(^_Nullable)(NSInteger percent))progressBlock
            success:(void(^)(NSString *fullUrl, NSString *relativePath))successBlock
            failure:(void(^)(NSError *error))failureBlock;

@end

NS_ASSUME_NONNULL_END

