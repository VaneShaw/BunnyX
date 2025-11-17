//
//  SignSuccessDialog.m
//  Bunnyx
//
//  签到成功弹窗（对齐安卓SignSuccessDialog）
//

#import "SignSuccessDialog.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "GradientButton.h"

@interface SignSuccessDialog ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *coinImageView;
@property (nonatomic, strong) UILabel *rewardLabel;
@property (nonatomic, strong) GradientButton *okButton;

@property (nonatomic, assign) NSInteger reward;

@end

@implementation SignSuccessDialog

+ (void)showWithReward:(NSInteger)reward {
    SignSuccessDialog *dialog = [[SignSuccessDialog alloc] init];
    dialog.reward = reward;
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
    
    // 内容容器（对齐安卓：marginHorizontal 20dp）
    self.containerView = [[UIView alloc] init];
    [self addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.offset(290);
        make.height.offset(335);
    }];
    
    // 背景图片（对齐安卓：bg_sign_success_topup，圆角20dp底部）
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.image = [UIImage imageNamed:@"bg_sign_success_topup"];
    self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    self.backgroundImageView.clipsToBounds = YES;
    self.backgroundImageView.layer.cornerRadius = 20;
    self.backgroundImageView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner; // 底部圆角
    [self.containerView addSubview:self.backgroundImageView];
    
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    
    // 标题（对齐安卓：23sp bold，黑色#333333，marginTop 100dp）
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"sign_success_title") ?: @"签到成功";
    self.titleLabel.textColor = HEX_COLOR(0x333333); // 对齐安卓：@color/black3
    self.titleLabel.font = BOLD_FONT(23); // 对齐安卓：23sp bold
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(100);
    }];
    
    // 金币图标（对齐安卓：icon_mine_recharge_list_coin_default，50dp × 50dp，marginTop 14dp）
    self.coinImageView = [[UIImageView alloc] init];
    self.coinImageView.image = [UIImage imageNamed:@"icon_mine_coin_default"];
    self.coinImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.containerView addSubview:self.coinImageView];
    
    [self.coinImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView);
        make.width.height.mas_equalTo(55);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
    }];
    
    // 奖励文本（对齐安卓：22sp bold，颜色#0AE971，marginTop 6dp）
    self.rewardLabel = [[UILabel alloc] init];
    self.rewardLabel.text = [NSString stringWithFormat:@"+%ld", (long)self.reward];
    self.rewardLabel.textColor = HEX_COLOR(0x0AE971); // 对齐安卓：#0AE971
    self.rewardLabel.font = BOLD_FONT(22); // 对齐安卓：22sp bold
    self.rewardLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.rewardLabel];
    
    [self.rewardLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.coinImageView.mas_bottom).offset(6);
    }];
    
    // OK按钮（对齐安卓：渐变背景#0AEA6F到#1CB3C1，圆角20dp，高度48dp，marginHorizontal 16dp，marginTop 16dp）
    self.okButton = [GradientButton buttonWithTitle:LocalString(@"sign_ok") ?: @"OK"
                                           startColor:HEX_COLOR(0x0AEA6F) // 对齐安卓：#0AEA6F
                                             endColor:HEX_COLOR(0x1CB3C1)]; // 对齐安卓：#1CB3C1
    self.okButton.cornerRadius = 20; // 对齐安卓：20dp
    self.okButton.buttonHeight = 48; // 对齐安卓：48dp
    [self.okButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal]; // 对齐安卓：@color/black3
    self.okButton.titleLabel.font = BOLD_FONT(16); // 对齐安卓：16sp bold
    [self.okButton addTarget:self action:@selector(okButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.okButton];
    
    [self.okButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.top.equalTo(self.rewardLabel.mas_bottom).offset(16);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.containerView).offset(-20);
    }];
}

#pragma mark - Actions

- (void)okButtonTapped {
    [self dismiss];
}

- (void)dismiss {
    [self removeFromSuperview];
}

@end

