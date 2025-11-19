//
//  VectorImageHelper.h
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Vector图片辅助类：用于将vector drawable转换为iOS图片
@interface VectorImageHelper : NSObject

/// 生成特定的vector图片（vector drawable）
/// @param size 图片大小（默认180x180）
/// @return 生成的UIImage
+ (UIImage *)generateVectorImageWithSize:(CGSize)size;

/// 获取默认的loading图片（带缓存，用于替换image_loading_ic）
/// @return 缓存的UIImage
+ (UIImage *)defaultLoadingImage;

@end

NS_ASSUME_NONNULL_END

