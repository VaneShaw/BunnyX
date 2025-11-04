//
//  ImageCompressor.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "ImageCompressor.h"
#import "BunnyxMacros.h"

@implementation ImageCompressor

+ (NSData *)compressImage:(UIImage *)image toMaxBytes:(NSUInteger)maxBytes {
    if (!image) {
        return nil;
    }
    
    // 先尝试不同质量，逐步降低直到符合大小要求
    CGFloat compression = 0.9f;
    NSData *imageData = UIImageJPEGRepresentation(image, compression);
    
    // 如果原始大小已经满足要求，直接返回
    if (imageData.length <= maxBytes) {
        return imageData;
    }
    
    // 二分法查找合适的压缩质量
    CGFloat minCompression = 0.1f;
    CGFloat maxCompression = 0.9f;
    
    while (maxCompression - minCompression > 0.05f) {
        compression = (minCompression + maxCompression) / 2.0f;
        imageData = UIImageJPEGRepresentation(image, compression);
        
        if (imageData.length <= maxBytes) {
            // 压缩后大小符合要求，尝试提高质量
            maxCompression = compression;
        } else {
            // 压缩后仍然太大，需要降低质量
            minCompression = compression;
        }
    }
    
    // 如果还是太大，尝试缩小尺寸
    if (imageData.length > maxBytes) {
        CGFloat scale = sqrt((CGFloat)maxBytes / (CGFloat)imageData.length);
        CGSize newSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
        
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // 再次压缩
        imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
        
        // 如果还是太大，继续降低质量
        if (imageData.length > maxBytes) {
            compression = 0.5f;
            while (imageData.length > maxBytes && compression > 0.1f) {
                compression -= 0.1f;
                imageData = UIImageJPEGRepresentation(resizedImage, compression);
            }
        }
    }
    
    BUNNYX_LOG(@"图片压缩完成：原始大小未知，压缩后大小：%lu 字节（目标：%lu 字节）", (unsigned long)imageData.length, (unsigned long)maxBytes);
    
    return imageData;
}

+ (UIImage *)compressImageToUIImage:(UIImage *)image toMaxBytes:(NSUInteger)maxBytes {
    NSData *imageData = [self compressImage:image toMaxBytes:maxBytes];
    if (imageData) {
        return [UIImage imageWithData:imageData];
    }
    return nil;
}

+ (void)compressImage:(UIImage *)image
           toMaxBytes:(NSUInteger)maxBytes
             progress:(void(^_Nullable)(CGFloat))progressBlock
           completion:(void(^)(NSData * _Nullable, UIImage * _Nullable))completionBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(0.3);
            });
        }
        
        NSData *imageData = [self compressImage:image toMaxBytes:maxBytes];
        
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(0.8);
            });
        }
        
        UIImage *compressedImage = nil;
        if (imageData) {
            compressedImage = [UIImage imageWithData:imageData];
        }
        
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(1.0);
            });
        }
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(imageData, compressedImage);
            });
        }
    });
}

@end

