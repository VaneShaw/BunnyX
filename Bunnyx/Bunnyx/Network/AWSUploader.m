//
//  AWSUploader.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "AWSUploader.h"
#import "BunnyxMacros.h"
#import <AFNetworking/AFNetworking.h>
#import <AWSCore/AWSCore.h>
#import <AWSS3/AWSS3.h>

@interface AWSUploader ()

@property (nonatomic, strong) AFURLSessionManager *sessionManager;

@end

@implementation AWSUploader

+ (instancetype)sharedUploader {
    static AWSUploader *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AWSUploader alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return self;
}

#pragma mark - Presigned URL Upload (推荐方式)

- (void)uploadImageData:(NSData *)imageData
           presignedUrl:(NSString *)presignedUrl
               progress:(void(^_Nullable)(NSInteger))progressBlock
                success:(void(^)(NSString *))successBlock
                failure:(void(^)(NSError *))failureBlock {
    
    if (!imageData || imageData.length == 0) {
        NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1001 userInfo:@{NSLocalizedDescriptionKey: @"图片数据为空"}];
        if (failureBlock) failureBlock(error);
        return;
    }
    
    if (!presignedUrl || presignedUrl.length == 0) {
        NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1002 userInfo:@{NSLocalizedDescriptionKey: @"预签名URL为空"}];
        if (failureBlock) failureBlock(error);
        return;
    }
    
    BUNNYX_LOG(@"使用预签名URL上传图片，大小：%lu 字节", (unsigned long)imageData.length);
    
    NSURL *url = [NSURL URLWithString:presignedUrl];
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1003 userInfo:@{NSLocalizedDescriptionKey: @"预签名URL格式错误"}];
        if (failureBlock) failureBlock(error);
        return;
    }
    
    // 创建 PUT 请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"PUT";
    [request setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)imageData.length] forHTTPHeaderField:@"Content-Length"];
    
    // 创建上传任务
    NSURLSessionUploadTask *uploadTask = [self.sessionManager uploadTaskWithRequest:request fromData:imageData progress:^(NSProgress * _Nonnull uploadProgress) {
        if (uploadProgress.totalUnitCount > 0) {
            NSInteger percent = (NSInteger)((uploadProgress.completedUnitCount * 100) / uploadProgress.totalUnitCount);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progressBlock) {
                    progressBlock(percent);
                }
                if ([self.delegate respondsToSelector:@selector(awsUploaderDidUpdateProgress:)]) {
                    [self.delegate awsUploaderDidUpdateProgress:percent];
                }
            });
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            BUNNYX_ERROR(@"AWS S3 上传失败: %@", error.localizedDescription);
            if (failureBlock) failureBlock(error);
            if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
                [self.delegate awsUploaderDidUploadFailWithError:error];
            }
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
                // 从 URL 中提取相对路径
                NSString *relativePath = [self extractRelativePathFromURL:presignedUrl];
                
                BUNNYX_LOG(@"AWS S3 上传成功，相对路径: %@", relativePath);
                
                if (successBlock) {
                    successBlock(relativePath);
                }
                if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadSuccessWithFullUrl:relativePath:)]) {
                    NSString *fullUrl = presignedUrl;
                    [self.delegate awsUploaderDidUploadSuccessWithFullUrl:fullUrl relativePath:relativePath];
                }
            } else {
                NSError *httpError = [NSError errorWithDomain:@"AWSUploader" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"上传失败，HTTP状态码：%ld", (long)httpResponse.statusCode]}];
                if (failureBlock) failureBlock(httpError);
                if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
                    [self.delegate awsUploaderDidUploadFailWithError:httpError];
                }
            }
        }
    }];
    
    [uploadTask resume];
}

- (NSString *)extractRelativePathFromURL:(NSString *)urlString {
    // 从 URL 中提取相对路径
    // 例如：https://bucket.s3.region.amazonaws.com/avatar/2024/04/30/xxx.jpg
    // 返回：avatar/2024/04/30/xxx.jpg
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return @"";
    
    NSString *path = url.path;
    if (path && path.length > 0) {
        // 去掉开头的 "/"
        if ([path hasPrefix:@"/"]) {
            path = [path substringFromIndex:1];
        }
        return path;
    }
    
    return @"";
}

- (void)uploadImage:(UIImage *)image
            poolId:(NSString *)poolId
            region:(NSString *)region
            bucket:(NSString *)bucket
       filePathName:(NSString *)filePathName {
    [self uploadImage:image poolId:poolId region:region bucket:bucket filePathName:filePathName progress:nil success:nil failure:nil];
}

- (void)uploadImage:(UIImage *)image
            poolId:(NSString *)poolId
            region:(NSString *)region
            bucket:(NSString *)bucket
       filePathName:(NSString *)filePathName
           progress:(void(^_Nullable)(NSInteger))progressBlock
            success:(void(^)(NSString *, NSString *))successBlock
            failure:(void(^)(NSError *))failureBlock {
    
    BUNNYX_LOG(@"开始上传图片到 AWS S3: bucket=%@, region=%@, path=%@", bucket, region, filePathName);
    
    // 参数验证
    if (!image) {
        NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1001 userInfo:@{NSLocalizedDescriptionKey: @"图片为空"}];
        if (failureBlock) failureBlock(error);
        if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
            [self.delegate awsUploaderDidUploadFailWithError:error];
        }
        return;
    }
    
    if (!poolId || !region || !bucket || !filePathName) {
        NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1002 userInfo:@{NSLocalizedDescriptionKey: @"AWS配置参数不完整"}];
        if (failureBlock) failureBlock(error);
        if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
            [self.delegate awsUploaderDidUploadFailWithError:error];
        }
        return;
    }
    
    // 在后台线程执行上传（与安卓版一致）
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            // 1. 将图片转换为临时文件（与安卓版逻辑一致）
            NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
            if (!imageData) {
                NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1003 userInfo:@{NSLocalizedDescriptionKey: @"图片数据转换失败"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failureBlock) failureBlock(error);
                    if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
                        [self.delegate awsUploaderDidUploadFailWithError:error];
                    }
                });
                return;
            }
            
            // 创建临时文件路径
            NSString *tempFileName = [NSString stringWithFormat:@"upload_temp_%ld.jpg", (long)[[NSDate date] timeIntervalSince1970]];
            NSString *tempDir = NSTemporaryDirectory();
            NSString *tempFilePath = [tempDir stringByAppendingPathComponent:tempFileName];
            
            // 将图片数据写入临时文件
            NSError *writeError = nil;
            BOOL writeSuccess = [imageData writeToFile:tempFilePath options:NSDataWritingAtomic error:&writeError];
            if (!writeSuccess || writeError) {
                NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1004 userInfo:@{NSLocalizedDescriptionKey: @"临时文件创建失败", NSUnderlyingErrorKey: writeError ?: [NSError new]}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failureBlock) failureBlock(error);
                    if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
                        [self.delegate awsUploaderDidUploadFailWithError:error];
                    }
                });
                return;
            }
            
            NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
            
            // 2. 配置 AWS 服务（使用 Cognito 凭证提供者，与安卓版一致）
            AWSRegionType awsRegion = [self regionTypeFromString:region];
            if (awsRegion == AWSRegionUnknown) {
                NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1005 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"不支持的AWS区域: %@", region]}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failureBlock) failureBlock(error);
                    if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
                        [self.delegate awsUploaderDidUploadFailWithError:error];
                    }
                });
                return;
            }
            
            // 创建 Cognito 凭证提供者（与安卓版 CognitoCachingCredentialsProvider 一致）
            AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:awsRegion identityPoolId:poolId];
            
            // 配置 AWS 服务配置
            AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:awsRegion credentialsProvider:credentialsProvider];
            
            // 3. 创建 S3 Transfer Utility（与安卓版 TransferUtility 一致）
            // 设置默认服务配置
            [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
            
            // 使用默认的 Transfer Utility（简单可靠的方式）
            AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
            
            // 4. 开始上传（与安卓版 TransferUtility.upload() 一致）
            AWSS3TransferUtilityUploadExpression *expression = [[AWSS3TransferUtilityUploadExpression alloc] init];
            expression.progressBlock = ^(AWSS3TransferUtilityTask *task, NSProgress *progress) {
                if (progress.totalUnitCount > 0) {
                    NSInteger percent = (NSInteger)((progress.completedUnitCount * 100) / progress.totalUnitCount);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressBlock) {
                            progressBlock(percent);
                        }
                        if ([self.delegate respondsToSelector:@selector(awsUploaderDidUpdateProgress:)]) {
                            [self.delegate awsUploaderDidUpdateProgress:percent];
                        }
                    });
                }
            };
            
            // 使用 uploadFile 方法上传（返回 AWSTask）
            AWSTask<AWSS3TransferUtilityUploadTask *> *uploadTask = [transferUtility uploadFile:tempFileURL
                                                                                            bucket:bucket
                                                                                               key:filePathName
                                                                                       contentType:@"image/jpeg"
                                                                                        expression:expression
                                                                                 completionHandler:^(AWSS3TransferUtilityUploadTask *task, NSError *error) {
                // 删除临时文件
                [[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:nil];
                
                if (error) {
                    BUNNYX_ERROR(@"AWS S3 上传失败: %@", error.localizedDescription);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failureBlock) failureBlock(error);
                        if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
                            [self.delegate awsUploaderDidUploadFailWithError:error];
                        }
                    });
                } else {
                    // 构建完整URL（与安卓版一致）
                    NSString *fullUrl = [NSString stringWithFormat:@"https://%@.s3.%@.amazonaws.com/%@", bucket, region, filePathName];
                    NSString *relativePath = filePathName;
                    
                    BUNNYX_LOG(@"AWS S3 上传成功: %@", fullUrl);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (successBlock) {
                            successBlock(fullUrl, relativePath);
                        }
                        if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadSuccessWithFullUrl:relativePath:)]) {
                            [self.delegate awsUploaderDidUploadSuccessWithFullUrl:fullUrl relativePath:relativePath];
                        }
                    });
                }
            }];
            
            // 处理任务创建失败的情况
            [uploadTask continueWithBlock:^id _Nullable(AWSTask<AWSS3TransferUtilityUploadTask *> * _Nonnull task) {
                if (task.error) {
                    // 删除临时文件
                    [[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:nil];
                    
                    BUNNYX_ERROR(@"AWS S3 上传任务创建失败: %@", task.error.localizedDescription);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failureBlock) failureBlock(task.error);
                        if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
                            [self.delegate awsUploaderDidUploadFailWithError:task.error];
                        }
                    });
                }
                return nil;
            }];
            
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"AWSUploader" code:-1006 userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"上传过程发生异常"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failureBlock) failureBlock(error);
                if ([self.delegate respondsToSelector:@selector(awsUploaderDidUploadFailWithError:)]) {
                    [self.delegate awsUploaderDidUploadFailWithError:error];
                }
            });
        }
    });
}

// 将字符串区域转换为 AWSRegionType
- (AWSRegionType)regionTypeFromString:(NSString *)regionString {
    NSDictionary *regionMap = @{
        @"us-east-1": @(AWSRegionUSEast1),
        @"us-east-2": @(AWSRegionUSEast2),
        @"us-west-1": @(AWSRegionUSWest1),
        @"us-west-2": @(AWSRegionUSWest2),
        @"ap-northeast-1": @(AWSRegionAPNortheast1),
        @"ap-northeast-2": @(AWSRegionAPNortheast2),
        @"ap-southeast-1": @(AWSRegionAPSoutheast1),
        @"ap-southeast-2": @(AWSRegionAPSoutheast2),
        @"ap-south-1": @(AWSRegionAPSouth1),
        @"eu-west-1": @(AWSRegionEUWest1),
        @"eu-west-2": @(AWSRegionEUWest2),
        @"eu-central-1": @(AWSRegionEUCentral1),
        @"sa-east-1": @(AWSRegionSAEast1),
        @"cn-north-1": @(AWSRegionCNNorth1),
        @"ca-central-1": @(AWSRegionCACentral1)
    };
    
    NSNumber *regionNumber = regionMap[regionString.lowercaseString];
    if (regionNumber) {
        return [regionNumber integerValue];
    }
    
    return AWSRegionUnknown;
}

@end

