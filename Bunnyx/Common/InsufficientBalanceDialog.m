//
//  InsufficientBalanceDialog.m
//  Bunnyx
//
//  余额不足弹窗
//

#import "InsufficientBalanceDialog.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "GradientButton.h"

@interface InsufficientBalanceDialog ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) GradientButton *confirmButton;
@property (nonatomic, strong) GradientButton *watchAdButton;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) BOOL canShowAd; // 是否有广告配置
@property (nonatomic, assign) NSInteger leftCount;
@property (nonatomic, copy) void(^cancelBlock)(void);
@property (nonatomic, copy) void(^confirmBlock)(void);
@property (nonatomic, copy) void(^watchAdBlock)(void);

@end

@implementation InsufficientBalanceDialog

+ (void)showWithTitle:(NSString *)title
            canShowAd:(BOOL)canShowAd
            leftCount:(NSInteger)leftCount
           cancelBlock:(void(^)(void))cancelBlock
          confirmBlock:(void(^)(void))confirmBlock
          watchAdBlock:(void(^)(void))watchAdBlock {
    InsufficientBalanceDialog *dialog = [[InsufficientBalanceDialog alloc] init];
    dialog.title = title;
    dialog.canShowAd = canShowAd;
    dialog.leftCount = leftCount;
    dialog.cancelBlock = cancelBlock;
    dialog.confirmBlock = confirmBlock;
    dialog.watchAdBlock = watchAdBlock;
    [dialog setupUI];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化
    }
    return self;
}

- (void)setupUI {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.frame = window.bounds;
    [window addSubview:self];
    
    // 背景遮罩
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:self.backgroundView];
    
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [self.backgroundView addGestureRecognizer:tap];
    
    // 内容容器
    self.containerView = [[UIView alloc] init];
    [self addSubview:self.containerView];
    
    // 根据是否有广告配置决定容器高度
    CGFloat containerHeight = self.canShowAd ? 300 : 234; // 有看广告按钮时更高
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.offset(290);
        make.height.offset(containerHeight);
    }];
    
    // 背景图片（根据是否有广告配置选择不同的背景图）
    self.backgroundImageView = [[UIImageView alloc] init];
    NSString *backgroundImageName = self.canShowAd ? @"bg_topup_2" : @"bg_topup";
    self.backgroundImageView.image = [UIImage imageNamed:backgroundImageName];
    self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    self.backgroundImageView.clipsToBounds = YES;
    self.backgroundImageView.layer.cornerRadius = 20;
    [self.containerView addSubview:self.backgroundImageView];
    
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    
    // 标题（18字号，333333颜色，距离image背景顶部100，左右空15，居中）
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = self.title;
    self.titleLabel.textColor = HEX_COLOR(0x333333);
    self.titleLabel.font = FONT(18);
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    [self.containerView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView).offset(15);
        make.right.equalTo(self.containerView).offset(-15);
        make.top.equalTo(self.containerView).offset(100);
    }];
    
    // 取消按钮（左边距离image背景18，字号17）
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setTitle:LocalString(@"取消") ?: @"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = FONT(17);
    self.cancelButton.layer.masksToBounds = YES;
    self.cancelButton.layer.cornerRadius = 25;
    self.cancelButton.layer.borderColor = HEX_COLOR(0x1AB8B9).CGColor;
    self.cancelButton.layer.borderWidth = 1;
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.cancelButton];
    
    // 确认按钮（右边距离image背景18，字号17，使用默认渐变背景）
    self.confirmButton = [GradientButton buttonWithTitle:LocalString(@"去充值") ?: @"去充值"];
    self.confirmButton.cornerRadius = 25;
    self.confirmButton.buttonHeight = 50;
    [self.confirmButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = FONT(17);
    [self.confirmButton addTarget:self action:@selector(confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.confirmButton];
    
    // 两个按钮的布局：取消在左，确认在右，中间隔18，顶部距离标题24
    // 计算按钮宽度：(290 - 18 - 18 - 18) / 2 = 118
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView).offset(18);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(50);
        make.width.mas_equalTo(118);
    }];
    
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.containerView).offset(-18);
        make.left.equalTo(self.cancelButton.mas_right).offset(18);
        make.top.equalTo(self.cancelButton);
        make.width.equalTo(self.cancelButton);
        make.height.mas_equalTo(50);
    }];
    
    // 看广告按钮（如果有广告配置）
    if (self.canShowAd) {
        // 距离确认按钮15，渐变#87FBFF-#E8FCC5，如果剩余次数为0则颜色#EAEDE4且不可点击
        BOOL isEnabled = self.leftCount > 0;
        UIColor *startColor = isEnabled ? HEX_COLOR(0x87FBFF) : HEX_COLOR(0xEAEDE4);
        UIColor *endColor = isEnabled ? HEX_COLOR(0xE8FCC5) : HEX_COLOR(0xEAEDE4);
        
        // 分两行显示：第一行 "Watch ads and get coins for free"，第二行 "(3 times)"
        NSString *buttonTitle = [NSString stringWithFormat:LocalString(@"watch_ads_and_get_coins_for_free") ?: @"Watch ads and get coins\nfor free(%ld times)", (long)self.leftCount];
        
        self.watchAdButton = [GradientButton buttonWithTitle:buttonTitle
                                                   startColor:startColor
                                                     endColor:endColor];
        self.watchAdButton.cornerRadius = 20;
        self.watchAdButton.buttonHeight = 50;
        [self.watchAdButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
        self.watchAdButton.titleLabel.font = FONT(17);
        self.watchAdButton.titleLabel.numberOfLines = 0;
        self.watchAdButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.watchAdButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.watchAdButton.enabled = isEnabled;
        [self.watchAdButton addTarget:self action:@selector(watchAdButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.containerView addSubview:self.watchAdButton];
        
        [self.watchAdButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.containerView).offset(15);
            make.right.equalTo(self.containerView).offset(-15);
            make.top.equalTo(self.confirmButton.mas_bottom).offset(15);
            make.height.mas_equalTo(50);
        }];
    }
}

#pragma mark - Actions

- (void)cancelButtonTapped {
    [self dismiss];
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (void)confirmButtonTapped {
    [self dismiss];
    if (self.confirmBlock) {
        self.confirmBlock();
    }
}

- (void)watchAdButtonTapped {
    if (self.watchAdButton.enabled && self.watchAdBlock) {
        [self dismiss];
        self.watchAdBlock();
    }
}

- (void)dismiss {
    [self removeFromSuperview];
}

@end

