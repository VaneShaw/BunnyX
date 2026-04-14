//
//  ImageUploadManager.m
//  Bunnyx
//

#import "ImageUploadManager.h"
#import "ImageCompressor.h"
#import "AWSUploader.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "BunnyxMacros.h"

@implementation ImageUploadManager

+ (instancetype)sharedManager {
    static ImageUploadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ImageUploadManager alloc] init];
    });
    return instance;
}

- (void)uploadImage:(NSInteger)materialId
              image:(UIImage *)image
            progress:(ImageUploadProgressBlock)progressBlock
             success:(ImageUploadSuccessBlock)successBlock
             failure:(ImageUploadFailureBlock)failureBlock {
    
    if (!image) {
        NSError *error = [NSError errorWithDomain:@"ImageUploadManager" 
                                             code:-1001 
                                         userInfo:@{NSLocalizedDescriptionKey: @"图片为空"}];
        if (failureBlock) {
            failureBlock(error);
        }
        return;
    }
    
    BUNNYX_LOG(@"开始上传图片，materialId: %ld", (long)materialId);
    
    // Step 1: 压缩图片
    if (progressBlock) {
        progressBlock(0.1, LocalString(@"正在压缩图片..."));
    }
    
    [ImageCompressor compressImage:image
                        toMaxBytes:1024 * 1024
                          progress:^(CGFloat progress) {
        if (progressBlock) {
            CGFloat totalProgress = 0.1 + progress * 0.2;
            progressBlock(totalProgress, LocalString(@"正在压缩图片..."));
        }
    } completion:^(NSData *imageData, UIImage *compressedImage) {
        if (!imageData || !compressedImage) {
            NSError *error = [NSError errorWithDomain:@"ImageUploadManager" 
                                                 code:-1002 
                                             userInfo:@{NSLocalizedDescriptionKey: LocalString(@"图片压缩失败")}];
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        BUNNYX_LOG(@"图片压缩完成，大小：%lu 字节", (unsigned long)imageData.length);
        
        // Step 2: 获取 AWS 上传配置
        if (progressBlock) {
            progressBlock(0.3, LocalString(@"正在获取上传配置..."));
        }
        
        [self getAWSConfigWithMaterialId:materialId
                                imageData:imageData
                                  progress:progressBlock
                                   success:^(NSString *poolId, NSString *region, NSString *bucket, NSString *filePathName) {
            // Step 3: 上传到 AWS S3（使用poolId、region、bucket）
            if (progressBlock) {
                progressBlock(0.4, LocalString(@"正在上传图片..."));
            }
            
            [self uploadToS3WithImage:compressedImage
                               poolId:poolId
                               region:region
                               bucket:bucket
                          filePathName:filePathName
                              progress:progressBlock
                               success:^(NSString *relativePath, NSString *fullUrl) {
                // Step 4: 返回上传后的图片路径
                BUNNYX_LOG(@"图片上传成功，路径: %@", relativePath);
                if (successBlock) {
                    successBlock(relativePath, fullUrl);
                }
            } failure:^(NSError *error) {
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        } failure:^(NSError *error) {
            if (failureBlock) {
                failureBlock(error);
            }
        }];
    }];
}

- (void)getAWSConfigWithMaterialId:(NSInteger)materialId
                          imageData:(NSData *)imageData
                            progress:(ImageUploadProgressBlock)progressBlock
                             success:(void(^)(NSString *poolId, NSString *region, NSString *bucket, NSString *filePathName))successBlock
                             failure:(ImageUploadFailureBlock)failureBlock {
    [self getAWSConfigWithMaterialId:materialId
                            imageData:imageData
                              progress:progressBlock
                               success:successBlock
                               failure:failureBlock
                            retryCount:0];
}

- (void)getAWSConfigWithMaterialId:(NSInteger)materialId
                          imageData:(NSData *)imageData
                            progress:(ImageUploadProgressBlock)progressBlock
                             success:(void(^)(NSString *poolId, NSString *region, NSString *bucket, NSString *filePathName))successBlock
                             failure:(ImageUploadFailureBlock)failureBlock
                          retryCount:(NSInteger)retryCount {
    
    // 获取文件后缀（iOS压缩后都是JPEG格式，所以固定为jpg，与安卓版逻辑一致）
    // 安卓版是从压缩后的文件名提取后缀，但由于iOS压缩都是JPEG，所以固定为jpg
    NSString *suffix = @"jpg";
    
    // 请求参数（与安卓版一致）
    NSDictionary *params = @{
        @"typeCode": @"aiupload",  // AI生成上传图片
        @"suffix": suffix
    };
    
    // 使用POST请求（与安卓版一致）
    [[NetworkManager sharedManager] POST:BUNNYX_API_AWS_UPLOAD
                                parameters:params
                                   success:^(id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        
        if (code == 0) {
            NSDictionary *data = dict[@"data"];
            if (data && [data isKindOfClass:[NSDictionary class]]) {
                NSString *poolId = data[@"poolId"];
                NSString *region = data[@"region"];
                NSString *bucket = data[@"bucket"];
                NSString *filePathName = data[@"filePathName"];
                
                if (poolId && region && bucket && filePathName) {
                    if (successBlock) {
                        successBlock(poolId, region, bucket, filePathName);
                    }
                } else {
                    // 配置信息不完整，进行重试（与安卓版一致）
                    [self handleAWSConfigRetry:materialId
                                     imageData:imageData
                                       progress:progressBlock
                                        success:successBlock
                                        failure:failureBlock
                                     retryCount:retryCount
                                   errorMessage:LocalString(@"AWS配置信息不完整")];
                }
            } else {
                // 配置格式错误，进行重试（与安卓版一致）
                [self handleAWSConfigRetry:materialId
                                 imageData:imageData
                                   progress:progressBlock
                                    success:successBlock
                                    failure:failureBlock
                                 retryCount:retryCount
                               errorMessage:LocalString(@"AWS配置格式错误")];
            }
        } else {
            // 请求成功但返回错误，进行重试（与安卓版一致）
            NSString *message = dict[@"message"] ?: LocalString(@"获取上传配置失败");
            [self handleAWSConfigRetry:materialId
                             imageData:imageData
                               progress:progressBlock
                                success:successBlock
                                failure:failureBlock
                             retryCount:retryCount
                           errorMessage:message];
        }
    } failure:^(NSError *error) {
        // 请求失败，进行重试（与安卓版一致）
        NSString *errorMessage = [NSString stringWithFormat:@"%@：%@", LocalString(@"获取上传配置失败"), error.localizedDescription];
        [self handleAWSConfigRetry:materialId
                         imageData:imageData
                           progress:progressBlock
                            success:successBlock
                            failure:failureBlock
                         retryCount:retryCount
                       errorMessage:errorMessage];
    }];
}

- (void)handleAWSConfigRetry:(NSInteger)materialId
                    imageData:(NSData *)imageData
                      progress:(ImageUploadProgressBlock)progressBlock
                       success:(void(^)(NSString *poolId, NSString *region, NSString *bucket, NSString *filePathName))successBlock
                       failure:(ImageUploadFailureBlock)failureBlock
                    retryCount:(NSInteger)retryCount
                  errorMessage:(NSString *)errorMessage {
    // 与安卓版一致：最多重试3次
    if (retryCount < 3) {
        BUNNYX_LOG(@"获取AWS配置失败，准备重试第%ld次: %@", (long)(retryCount + 1), errorMessage);
        
        // 延迟1秒后重试（与安卓版一致）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self getAWSConfigWithMaterialId:materialId
                                    imageData:imageData
                                      progress:progressBlock
                                       success:successBlock
                                       failure:failureBlock
                                    retryCount:retryCount + 1];
        });
    } else {
        // 重试次数用完，显示最终错误
        BUNNYX_ERROR(@"获取AWS配置重试3次后仍然失败: %@", errorMessage);
        NSError *error = [NSError errorWithDomain:@"ImageUploadManager" 
                                             code:-1006 
                                         userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        if (failureBlock) {
            failureBlock(error);
        }
    }
}

- (void)uploadToS3WithImage:(UIImage *)image
                     poolId:(NSString *)poolId
                     region:(NSString *)region
                     bucket:(NSString *)bucket
                filePathName:(NSString *)filePathName
                    progress:(ImageUploadProgressBlock)progressBlock
                     success:(void(^)(NSString *relativePath, NSString *fullUrl))successBlock
                     failure:(ImageUploadFailureBlock)failureBlock {
    
    AWSUploader *uploader = [AWSUploader sharedUploader];
    [uploader uploadImage:image
                   poolId:poolId
                   region:region
                   bucket:bucket
              filePathName:filePathName
                  progress:^(NSInteger percent) {
        if (progressBlock) {
            CGFloat totalProgress = 0.4 + (percent / 100.0) * 0.4; // 40%-80%
            progressBlock(totalProgress, LocalString(@"正在上传图片..."));
        }
    } success:^(NSString *fullUrl, NSString *relativePath) {
        // 传递relativePath和fullUrl（用于历史记录显示）
        if (successBlock) {
            successBlock(relativePath ?: filePathName, fullUrl);
        }
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"AWS S3 上传失败: %@", error.localizedDescription);
        NSError *uploadError = [NSError errorWithDomain:@"ImageUploadManager" 
                                                    code:-1005 
                                                userInfo:@{NSLocalizedDescriptionKey: LocalString(@"图片上传失败"), 
                                                          NSUnderlyingErrorKey: error}];
        if (failureBlock) {
            failureBlock(uploadError);
        }
    }];
}


@end
