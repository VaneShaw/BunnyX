//
//  GradientButton.m
//  Bunnyx
//
//  Created by Assistant on 2025/01/30.
//

#import "GradientButton.h"
#import "BunnyxMacros.h"
#import <Masonry/Masonry.h>

@interface GradientButton ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation GradientButton

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultValues];
        [self setupUI];
    }
    return self;
}

- (void)setupDefaultValues {
    // 默认渐变颜色：绿色到蓝绿色
    _gradientStartColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0]; // 绿色
    _gradientEndColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.7 alpha:1.0]; // 蓝绿色
    _cornerRadius = 12.0;
    _buttonHeight = 50.0;
}

- (void)setupUI {
    // 设置文字样式
    [self setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
    self.titleLabel.font = BOLD_FONT(FONT_SIZE_16);
    
    // 创建渐变层
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.startPoint = CGPointMake(0, 0.5);
    self.gradientLayer.endPoint = CGPointMake(1, 0.5);
    self.gradientLayer.cornerRadius = self.cornerRadius;
    [self.layer insertSublayer:self.gradientLayer atIndex:0];
    
    // 设置渐变颜色（使用统一方法，包含 nil 检查）
    [self updateGradientColors];
    
    // 设置圆角
    self.layer.cornerRadius = self.cornerRadius;
    self.layer.masksToBounds = YES;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新渐变层的frame和圆角
    self.gradientLayer.frame = self.bounds;
    self.gradientLayer.cornerRadius = self.cornerRadius;
}

#pragma mark - Setters

- (void)setGradientStartColor:(UIColor *)gradientStartColor {
    if (_gradientStartColor != gradientStartColor) {
        _gradientStartColor = gradientStartColor;
        [self updateGradientColors];
    }
}

- (void)setGradientEndColor:(UIColor *)gradientEndColor {
    if (_gradientEndColor != gradientEndColor) {
        _gradientEndColor = gradientEndColor;
        [self updateGradientColors];
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;
        self.layer.cornerRadius = cornerRadius;
        self.gradientLayer.cornerRadius = cornerRadius;
    }
}

- (void)updateGradientColors {
    // 防止颜色为 nil 导致崩溃
    if (!self.gradientStartColor || !self.gradientEndColor) {
        return;
    }
    self.gradientLayer.colors = @[
        (id)self.gradientStartColor.CGColor,
        (id)self.gradientEndColor.CGColor
    ];
}

#pragma mark - Class Methods

+ (instancetype)buttonWithTitle:(NSString *)title
                      startColor:(UIColor *)startColor
                        endColor:(UIColor *)endColor {
    GradientButton *button = [[GradientButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    // 只有当颜色不为 nil 时才设置，否则使用默认值
    if (startColor) {
        button.gradientStartColor = startColor;
    }
    if (endColor) {
        button.gradientEndColor = endColor;
    }
    return button;
}

+ (instancetype)buttonWithTitle:(NSString *)title {
    return [self buttonWithTitle:title
                       startColor:nil
                         endColor:nil];
}

#pragma mark - Override

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.alpha = enabled ? 1.0 : 0.6;
}

@end

