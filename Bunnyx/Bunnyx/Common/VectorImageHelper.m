//
//  VectorImageHelper.m
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import "VectorImageHelper.h"

@implementation VectorImageHelper

static UIImage *_defaultLoadingImage = nil;

+ (UIImage *)defaultLoadingImage {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 生成默认大小的loading图片并缓存
        _defaultLoadingImage = [self generateVectorImageWithSize:CGSizeZero];
    });
    return _defaultLoadingImage;
}

+ (UIImage *)generateVectorImageWithSize:(CGSize)size {
    // 默认大小180x180（对应Android的dp_180）
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        size = CGSizeMake(90, 90);
    }
    
    // 创建图形上下文
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (!context) {
        return nil;
    }
    
    // 设置填充颜色：黑色，透明度0.18（对应Android的fillAlpha="0.18"）
    UIColor *fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.18];
    
    // 计算缩放比例（Android viewport是180x180）
    CGFloat scaleX = size.width / 180.0;
    CGFloat scaleY = size.height / 180.0;
    
    // Path 1: M116.69,42.5 C118.34,42.3,120.68,41.43,121.74,43.27 C122.94,46.03,123.19,49.07,123.84,51.98 C124.39,55.2,125.59,58.45,124.77,61.74 C110.83,60.27,96.93,58.41,83.01,56.68 C79.82,56.36,76.64,55.92,73.55,55.04 C74.11,53.54,74.86,51.92,76.67,51.72 C89.99,48.59,103.36,45.63,116.69,42.5 Z
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointMake(116.69 * scaleX, 42.5 * scaleY)];
    // C118.34,42.3,120.68,41.43,121.74,43.27
    [path1 addCurveToPoint:CGPointMake(121.74 * scaleX, 43.27 * scaleY)
             controlPoint1:CGPointMake(118.34 * scaleX, 42.3 * scaleY)
             controlPoint2:CGPointMake(120.68 * scaleX, 41.43 * scaleY)];
    // C122.94,46.03,123.19,49.07,123.84,51.98
    [path1 addCurveToPoint:CGPointMake(123.84 * scaleX, 51.98 * scaleY)
             controlPoint1:CGPointMake(122.94 * scaleX, 46.03 * scaleY)
             controlPoint2:CGPointMake(123.19 * scaleX, 49.07 * scaleY)];
    // C124.39,55.2,125.59,58.45,124.77,61.74
    [path1 addCurveToPoint:CGPointMake(124.77 * scaleX, 61.74 * scaleY)
             controlPoint1:CGPointMake(124.39 * scaleX, 55.2 * scaleY)
             controlPoint2:CGPointMake(125.59 * scaleX, 58.45 * scaleY)];
    // C110.83,60.27,96.93,58.41,83.01,56.68
    [path1 addCurveToPoint:CGPointMake(83.01 * scaleX, 56.68 * scaleY)
             controlPoint1:CGPointMake(110.83 * scaleX, 60.27 * scaleY)
             controlPoint2:CGPointMake(96.93 * scaleX, 58.41 * scaleY)];
    // C79.82,56.36,76.64,55.92,73.55,55.04
    [path1 addCurveToPoint:CGPointMake(73.55 * scaleX, 55.04 * scaleY)
             controlPoint1:CGPointMake(79.82 * scaleX, 56.36 * scaleY)
             controlPoint2:CGPointMake(76.64 * scaleX, 55.92 * scaleY)];
    // C74.11,53.54,74.86,51.92,76.67,51.72
    [path1 addCurveToPoint:CGPointMake(76.67 * scaleX, 51.72 * scaleY)
             controlPoint1:CGPointMake(74.11 * scaleX, 53.54 * scaleY)
             controlPoint2:CGPointMake(74.86 * scaleX, 51.92 * scaleY)];
    // C89.99,48.59,103.36,45.63,116.69,42.5
    [path1 addCurveToPoint:CGPointMake(116.69 * scaleX, 42.5 * scaleY)
             controlPoint1:CGPointMake(89.99 * scaleX, 48.59 * scaleY)
             controlPoint2:CGPointMake(103.36 * scaleX, 45.63 * scaleY)];
    [path1 closePath];
    
    // Path 2: M39.17,62.06 C39.85,59.59,42.92,59.71,44.91,59.02 C45.75,64.24,44.56,69.47,43.63,74.6 C43.05,74.66,41.91,74.77,41.34,74.83 C40.41,70.62,39.1,66.41,39.17,62.06 Z
    UIBezierPath *path2 = [UIBezierPath bezierPath];
    [path2 moveToPoint:CGPointMake(39.17 * scaleX, 62.06 * scaleY)];
    // C39.85,59.59,42.92,59.71,44.91,59.02
    [path2 addCurveToPoint:CGPointMake(44.91 * scaleX, 59.02 * scaleY)
             controlPoint1:CGPointMake(39.85 * scaleX, 59.59 * scaleY)
             controlPoint2:CGPointMake(42.92 * scaleX, 59.71 * scaleY)];
    // C45.75,64.24,44.56,69.47,43.63,74.6
    [path2 addCurveToPoint:CGPointMake(43.63 * scaleX, 74.6 * scaleY)
             controlPoint1:CGPointMake(45.75 * scaleX, 64.24 * scaleY)
             controlPoint2:CGPointMake(44.56 * scaleX, 69.47 * scaleY)];
    // C43.05,74.66,41.91,74.77,41.34,74.83
    [path2 addCurveToPoint:CGPointMake(41.34 * scaleX, 74.83 * scaleY)
             controlPoint1:CGPointMake(43.05 * scaleX, 74.66 * scaleY)
             controlPoint2:CGPointMake(41.91 * scaleX, 74.77 * scaleY)];
    // C40.41,70.62,39.1,66.41,39.17,62.06
    [path2 addCurveToPoint:CGPointMake(39.17 * scaleX, 62.06 * scaleY)
             controlPoint1:CGPointMake(40.41 * scaleX, 70.62 * scaleY)
             controlPoint2:CGPointMake(39.1 * scaleX, 66.41 * scaleY)];
    [path2 closePath];
    
    // Path 3: 复杂的路径，包含多个子路径
    // M55.17,63.02 C56.68,62.27,58.44,62.9,60.04,62.93 C85.05,66.1,110.07,69.09,135.08,72.19 C138.1,72.15,139.04,75.49,138.56,77.95 C136.78,94.98,134.69,111.99,132.7,129 C132.23,132.41,132.31,135.96,131.14,139.24 C129.69,141.09,127.08,140.18,125.09,140.15 C102.51,137.22,79.9,134.5,57.32,131.53 C54.25,131.04,51,131.11,48.08,129.93 C46.39,128.87,46.92,126.63,46.99,124.98 C49.21,106.65,51.23,88.31,53.18,69.95 C53.69,67.69,53.14,64.57,55.17,63.02
    UIBezierPath *path3 = [UIBezierPath bezierPath];
    
    // 主路径
    [path3 moveToPoint:CGPointMake(55.17 * scaleX, 63.02 * scaleY)];
    // C56.68,62.27,58.44,62.9,60.04,62.93
    [path3 addCurveToPoint:CGPointMake(60.04 * scaleX, 62.93 * scaleY)
             controlPoint1:CGPointMake(56.68 * scaleX, 62.27 * scaleY)
             controlPoint2:CGPointMake(58.44 * scaleX, 62.9 * scaleY)];
    // C85.05,66.1,110.07,69.09,135.08,72.19
    [path3 addCurveToPoint:CGPointMake(135.08 * scaleX, 72.19 * scaleY)
             controlPoint1:CGPointMake(85.05 * scaleX, 66.1 * scaleY)
             controlPoint2:CGPointMake(110.07 * scaleX, 69.09 * scaleY)];
    // C138.1,72.15,139.04,75.49,138.56,77.95
    [path3 addCurveToPoint:CGPointMake(138.56 * scaleX, 77.95 * scaleY)
             controlPoint1:CGPointMake(138.1 * scaleX, 72.15 * scaleY)
             controlPoint2:CGPointMake(139.04 * scaleX, 75.49 * scaleY)];
    // C136.78,94.98,134.69,111.99,132.7,129
    [path3 addCurveToPoint:CGPointMake(132.7 * scaleX, 129 * scaleY)
             controlPoint1:CGPointMake(136.78 * scaleX, 94.98 * scaleY)
             controlPoint2:CGPointMake(134.69 * scaleX, 111.99 * scaleY)];
    // C132.23,132.41,132.31,135.96,131.14,139.24
    [path3 addCurveToPoint:CGPointMake(131.14 * scaleX, 139.24 * scaleY)
             controlPoint1:CGPointMake(132.23 * scaleX, 132.41 * scaleY)
             controlPoint2:CGPointMake(132.31 * scaleX, 135.96 * scaleY)];
    // C129.69,141.09,127.08,140.18,125.09,140.15
    [path3 addCurveToPoint:CGPointMake(125.09 * scaleX, 140.15 * scaleY)
             controlPoint1:CGPointMake(129.69 * scaleX, 141.09 * scaleY)
             controlPoint2:CGPointMake(127.08 * scaleX, 140.18 * scaleY)];
    // C102.51,137.22,79.9,134.5,57.32,131.53
    [path3 addCurveToPoint:CGPointMake(57.32 * scaleX, 131.53 * scaleY)
             controlPoint1:CGPointMake(102.51 * scaleX, 137.22 * scaleY)
             controlPoint2:CGPointMake(79.9 * scaleX, 134.5 * scaleY)];
    // C54.25,131.04,51,131.11,48.08,129.93
    [path3 addCurveToPoint:CGPointMake(48.08 * scaleX, 129.93 * scaleY)
             controlPoint1:CGPointMake(54.25 * scaleX, 131.04 * scaleY)
             controlPoint2:CGPointMake(51 * scaleX, 131.11 * scaleY)];
    // C46.39,128.87,46.92,126.63,46.99,124.98
    [path3 addCurveToPoint:CGPointMake(46.99 * scaleX, 124.98 * scaleY)
             controlPoint1:CGPointMake(46.39 * scaleX, 128.87 * scaleY)
             controlPoint2:CGPointMake(46.92 * scaleX, 126.63 * scaleY)];
    // C49.21,106.65,51.23,88.31,53.18,69.95
    [path3 addCurveToPoint:CGPointMake(53.18 * scaleX, 69.95 * scaleY)
             controlPoint1:CGPointMake(49.21 * scaleX, 106.65 * scaleY)
             controlPoint2:CGPointMake(51.23 * scaleX, 88.31 * scaleY)];
    // C53.69,67.69,53.14,64.57,55.17,63.02
    [path3 addCurveToPoint:CGPointMake(55.17 * scaleX, 63.02 * scaleY)
             controlPoint1:CGPointMake(53.69 * scaleX, 67.69 * scaleY)
             controlPoint2:CGPointMake(53.14 * scaleX, 64.57 * scaleY)];
    [path3 closePath];
    
    // 子路径1: M118.3,81.47 C114.1,83.2,112.65,88.96,115.62,92.43...
    [path3 moveToPoint:CGPointMake(118.3 * scaleX, 81.47 * scaleY)];
    [path3 addCurveToPoint:CGPointMake(115.62 * scaleX, 92.43 * scaleY)
             controlPoint1:CGPointMake(114.1 * scaleX, 83.2 * scaleY)
             controlPoint2:CGPointMake(112.65 * scaleX, 88.96 * scaleY)];
    [path3 addCurveToPoint:CGPointMake(126.76 * scaleX, 90.86 * scaleY)
             controlPoint1:CGPointMake(118.38 * scaleX, 96.38 * scaleY)
             controlPoint2:CGPointMake(125.14 * scaleX, 95.34 * scaleY)];
    [path3 addCurveToPoint:CGPointMake(118.3 * scaleX, 81.47 * scaleY)
             controlPoint1:CGPointMake(128.97 * scaleX, 85.83 * scaleY)
             controlPoint2:CGPointMake(123.8 * scaleX, 79.05 * scaleY)];
    [path3 closePath];
    
    // 子路径2: M84.19,87.31 C82.76,88.13,81.59,89.33,80.43,90.49 C73.1,98.12,65.54,105.54,58.11,113.07 C56.74,114.2,56.52,116.68,58.35,117.48 C61.47,118.46,64.76,118.66,67.99,119.05 C79.67,120.21,91.26,122.13,102.94,123.32 C108.96,123.91,114.94,125.48,121,125.15 C122.17,125.26,123.01,123.61,122.26,122.73 C118.02,115.66,113.63,108.67,109.28,101.66 C108.33,100.31,107.51,98.68,105.95,97.94 C102.43,97.99,100.63,103.03,97.03,101.9 C93.15,97.93,91.6,92.26,87.88,88.14 C86.97,87.13,85.45,86.64,84.19,87.31 Z
    [path3 moveToPoint:CGPointMake(84.19 * scaleX, 87.31 * scaleY)];
    // C82.76,88.13,81.59,89.33,80.43,90.49
    [path3 addCurveToPoint:CGPointMake(80.43 * scaleX, 90.49 * scaleY)
             controlPoint1:CGPointMake(82.76 * scaleX, 88.13 * scaleY)
             controlPoint2:CGPointMake(81.59 * scaleX, 89.33 * scaleY)];
    // C73.1,98.12,65.54,105.54,58.11,113.07
    [path3 addCurveToPoint:CGPointMake(58.11 * scaleX, 113.07 * scaleY)
             controlPoint1:CGPointMake(73.1 * scaleX, 98.12 * scaleY)
             controlPoint2:CGPointMake(65.54 * scaleX, 105.54 * scaleY)];
    // C56.74,114.2,56.52,116.68,58.35,117.48
    [path3 addCurveToPoint:CGPointMake(58.35 * scaleX, 117.48 * scaleY)
             controlPoint1:CGPointMake(56.74 * scaleX, 114.2 * scaleY)
             controlPoint2:CGPointMake(56.52 * scaleX, 116.68 * scaleY)];
    // C61.47,118.46,64.76,118.66,67.99,119.05
    [path3 addCurveToPoint:CGPointMake(67.99 * scaleX, 119.05 * scaleY)
             controlPoint1:CGPointMake(61.47 * scaleX, 118.46 * scaleY)
             controlPoint2:CGPointMake(64.76 * scaleX, 118.66 * scaleY)];
    // C79.67,120.21,91.26,122.13,102.94,123.32
    [path3 addCurveToPoint:CGPointMake(102.94 * scaleX, 123.32 * scaleY)
             controlPoint1:CGPointMake(79.67 * scaleX, 120.21 * scaleY)
             controlPoint2:CGPointMake(91.26 * scaleX, 122.13 * scaleY)];
    // C108.96,123.91,114.94,125.48,121,125.15
    [path3 addCurveToPoint:CGPointMake(121 * scaleX, 125.15 * scaleY)
             controlPoint1:CGPointMake(108.96 * scaleX, 123.91 * scaleY)
             controlPoint2:CGPointMake(114.94 * scaleX, 125.48 * scaleY)];
    // C122.17,125.26,123.01,123.61,122.26,122.73
    [path3 addCurveToPoint:CGPointMake(122.26 * scaleX, 122.73 * scaleY)
             controlPoint1:CGPointMake(122.17 * scaleX, 125.26 * scaleY)
             controlPoint2:CGPointMake(123.01 * scaleX, 123.61 * scaleY)];
    // C118.02,115.66,113.63,108.67,109.28,101.66
    [path3 addCurveToPoint:CGPointMake(109.28 * scaleX, 101.66 * scaleY)
             controlPoint1:CGPointMake(118.02 * scaleX, 115.66 * scaleY)
             controlPoint2:CGPointMake(113.63 * scaleX, 108.67 * scaleY)];
    // C108.33,100.31,107.51,98.68,105.95,97.94
    [path3 addCurveToPoint:CGPointMake(105.95 * scaleX, 97.94 * scaleY)
             controlPoint1:CGPointMake(108.33 * scaleX, 100.31 * scaleY)
             controlPoint2:CGPointMake(107.51 * scaleX, 98.68 * scaleY)];
    // C102.43,97.99,100.63,103.03,97.03,101.9
    [path3 addCurveToPoint:CGPointMake(97.03 * scaleX, 101.9 * scaleY)
             controlPoint1:CGPointMake(102.43 * scaleX, 97.99 * scaleY)
             controlPoint2:CGPointMake(100.63 * scaleX, 103.03 * scaleY)];
    // C93.15,97.93,91.6,92.26,87.88,88.14
    [path3 addCurveToPoint:CGPointMake(87.88 * scaleX, 88.14 * scaleY)
             controlPoint1:CGPointMake(93.15 * scaleX, 97.93 * scaleY)
             controlPoint2:CGPointMake(91.6 * scaleX, 92.26 * scaleY)];
    // C86.97,87.13,85.45,86.64,84.19,87.31
    [path3 addCurveToPoint:CGPointMake(84.19 * scaleX, 87.31 * scaleY)
             controlPoint1:CGPointMake(86.97 * scaleX, 87.13 * scaleY)
             controlPoint2:CGPointMake(85.45 * scaleX, 86.64 * scaleY)];
    [path3 closePath];
    
    // 绘制所有路径
    [fillColor setFill];
    [path1 fill];
    [path2 fill];
    [path3 fill];
    
    // 获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

