//
//  ImageCompressor.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 图片压缩工具类
@interface ImageCompressor : NSObject

/**
 * 压缩图片到指定大小（字节）
 * @param image 原始图片
 * @param maxBytes 最大字节数（例如：1024 * 1024 = 1MB）
 * @return 压缩后的图片数据，如果失败返回nil
 */
+ (NSData * _Nullable)compressImage:(UIImage *)image toMaxBytes:(NSUInteger)maxBytes;

/**
 * 压缩图片到指定大小，返回 UIImage
 * @param image 原始图片
 * @param maxBytes 最大字节数
 * @return 压缩后的图片
 */
+ (UIImage * _Nullable)compressImageToUIImage:(UIImage *)image toMaxBytes:(NSUInteger)maxBytes;

/**
 * 压缩图片到指定大小（带进度回调）
 * @param image 原始图片
 * @param maxBytes 最大字节数
 * @param progressBlock 进度回调（可选）
 * @param completionBlock 完成回调
 */
+ (void)compressImage:(UIImage *)image
           toMaxBytes:(NSUInteger)maxBytes
             progress:(void(^_Nullable)(CGFloat progress))progressBlock
           completion:(void(^)(NSData * _Nullable imageData, UIImage * _Nullable compressedImage))completionBlock;

@end

NS_ASSUME_NONNULL_END

