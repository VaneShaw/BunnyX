//
//  GradientButton.h
//  Bunnyx
//
//  Created by Assistant on 2025/01/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 渐变按钮组件
/// 支持水平渐变效果，常见用于主要操作按钮
@interface GradientButton : UIButton

/// 渐变起始颜色（左侧）
@property (nonatomic, strong) UIColor *gradientStartColor;

/// 渐变结束颜色（右侧）
@property (nonatomic, strong) UIColor *gradientEndColor;

/// 圆角半径，默认12
@property (nonatomic, assign) CGFloat cornerRadius;

/// 按钮高度，默认50
@property (nonatomic, assign) CGFloat buttonHeight;

/// 便利构造方法
/// @param title 按钮标题
/// @param startColor 渐变起始颜色
/// @param endColor 渐变结束颜色
+ (instancetype)buttonWithTitle:(NSString *)title
                      startColor:(UIColor *)startColor
                        endColor:(UIColor *)endColor;

/// 便利构造方法（使用默认渐变颜色：绿色到蓝绿色）
/// @param title 按钮标题
+ (instancetype)buttonWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END

