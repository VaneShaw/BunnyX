//
//  SignSuccessDialog.m
//  Bunnyx
//
//  签到成功弹窗（SignSuccessDialog）
//

#import "SignSuccessDialog.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "GradientButton.h"
#import "AdMobManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "UserInfoManager.h"

@interface SignSuccessDialog ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *coinImageView;
@property (nonatomic, strong) UILabel *rewardLabel;
@property (nonatomic, strong) GradientButton *okButton;
@property (nonatomic, strong) GradientButton *watchAdButton;

@property (nonatomic, assign) NSInteger reward;
@property (nonatomic, strong) NSString *customTitle; // 自定义标题
@property (nonatomic, assign) BOOL showWatchAdButton; // 是否显示看广告按钮（只有签到成功时显示）
@property (nonatomic, assign) BOOL isHidden; // 是否被隐藏（用于开屏广告显示时）

// 静态变量：保存所有显示的弹窗实例
+ (NSMutableArray<SignSuccessDialog *> *)allDialogs;

@end

static NSMutableArray<SignSuccessDialog *> *s_allDialogs = nil;

@implementation SignSuccessDialog

+ (NSMutableArray<SignSuccessDialog *> *)allDialogs {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_allDialogs = [NSMutableArray array];
    });
    return s_allDialogs;
}

+ (void)showWithReward:(NSInteger)reward {
    SignSuccessDialog *dialog = [[SignSuccessDialog alloc] init];
    dialog.reward = reward;
    dialog.customTitle = nil;
    dialog.showWatchAdButton = YES; // 签到成功时显示看广告按钮
    [[self allDialogs] addObject:dialog];
    [dialog setupUI];
}

+ (void)showWithReward:(NSInteger)reward title:(NSString *)title {
    SignSuccessDialog *dialog = [[SignSuccessDialog alloc] init];
    dialog.reward = reward;
    dialog.customTitle = title;
    dialog.showWatchAdButton = NO; // 获得奖励成功时不显示看广告按钮
    [[self allDialogs] addObject:dialog];
    [dialog setupUI];
}

+ (void)dismissAll {
    NSArray<SignSuccessDialog *> *dialogs = [[self allDialogs] copy];
    for (SignSuccessDialog *dialog in dialogs) {
        [dialog dismiss];
    }
}

+ (void)hideAll {
    NSArray<SignSuccessDialog *> *dialogs = [[self allDialogs] copy];
    for (SignSuccessDialog *dialog in dialogs) {
        if (!dialog.isHidden) {
            dialog.hidden = YES;
            dialog.isHidden = YES;
        }
    }
}

+ (void)showAllHidden {
    NSArray<SignSuccessDialog *> *dialogs = [[self allDialogs] copy];
    for (SignSuccessDialog *dialog in dialogs) {
        if (dialog.isHidden) {
            dialog.hidden = NO;
            dialog.isHidden = NO;
        }
    }
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
    
    // 内容容器（marginHorizontal 20dp）
    self.containerView = [[UIView alloc] init];
    [self addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.offset(290);
        make.height.offset(335);
    }];
    
    // 背景图片（根据是否有看广告按钮选择不同的背景图）
    self.backgroundImageView = [[UIImageView alloc] init];
    NSString *backgroundImageName = self.showWatchAdButton ? @"bg_sign_success_topup_2" : @"bg_sign_success_topup";
    self.backgroundImageView.image = [UIImage imageNamed:backgroundImageName];
    self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    self.backgroundImageView.clipsToBounds = YES;
    self.backgroundImageView.layer.cornerRadius = 20;
    self.backgroundImageView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner; // 底部圆角
    [self.containerView addSubview:self.backgroundImageView];
    
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    
    // 标题（23sp bold，黑色#333333，marginTop 100dp）
    self.titleLabel = [[UILabel alloc] init];
    if (self.customTitle) {
        self.titleLabel.text = self.customTitle;
    } else {
        self.titleLabel.text = LocalString(@"sign_success_title") ?: @"签到成功";
    }
    self.titleLabel.textColor = HEX_COLOR(0x333333); // @color/black3
    self.titleLabel.font = BOLD_FONT(23); // 23sp bold
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(100);
    }];
    
    // 金币图标（icon_mine_recharge_list_coin_default，50dp × 50dp，marginTop 14dp）
    self.coinImageView = [[UIImageView alloc] init];
    self.coinImageView.image = [UIImage imageNamed:@"icon_mine_coin_default"];
    self.coinImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.containerView addSubview:self.coinImageView];
    
    [self.coinImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView);
        make.width.height.mas_equalTo(55);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(14);
    }];
    
    // 奖励文本（22sp bold，颜色#0AE971，marginTop 6dp）
    self.rewardLabel = [[UILabel alloc] init];
    self.rewardLabel.text = [NSString stringWithFormat:@"+%ld", (long)self.reward];
    self.rewardLabel.textColor = HEX_COLOR(0x0AE971); // #0AE971
    self.rewardLabel.font = BOLD_FONT(22); // 22sp bold
    self.rewardLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.rewardLabel];
    
    [self.rewardLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.coinImageView.mas_bottom).offset(6);
    }];
    
    // OK按钮（渐变背景#0AEA6F到#1CB3C1，圆角20dp，高度48dp，marginHorizontal 16dp，marginTop 16dp）
    self.okButton = [GradientButton buttonWithTitle:LocalString(@"sign_ok") ?: @"OK"
                                           startColor:HEX_COLOR(0x0AEA6F) // #0AEA6F
                                             endColor:HEX_COLOR(0x1CB3C1)]; // #1CB3C1
    self.okButton.cornerRadius = 20; // 20dp
    self.okButton.buttonHeight = 48; // 48dp
    [self.okButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal]; // @color/black3
    self.okButton.titleLabel.font = BOLD_FONT(16); // 16sp bold
    [self.okButton addTarget:self action:@selector(okButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.okButton];
    
    [self.okButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.top.equalTo(self.rewardLabel.mas_bottom).offset(16);
        make.height.mas_equalTo(44);
    }];
    
    // 看广告按钮（只有签到成功时显示）
    if (self.showWatchAdButton) {
        AdMobConfigModel *adConfig = [[AdMobManager sharedManager] getConfigForPlacement:AdMobPlacementSignIn adType:AdMobTypeRewarded];
        if (adConfig && !BUNNYX_IS_EMPTY_STRING(adConfig.adUnitId)) {
            // 使用渐变按钮，渐变色 #87FBFF 到 #E8FCC5
            self.watchAdButton = [GradientButton buttonWithTitle:LocalString(@"watch_ads_for_more_coins") ?: @"Watch ads for more coins"
                                                       startColor:HEX_COLOR(0x87FBFF) // #87FBFF
                                                         endColor:HEX_COLOR(0xE8FCC5)]; // #E8FCC5
            self.watchAdButton.cornerRadius = 20;
            self.watchAdButton.buttonHeight = 44;
            [self.watchAdButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
            self.watchAdButton.titleLabel.font = FONT(14);
            [self.watchAdButton addTarget:self action:@selector(watchAdButtonTapped) forControlEvents:UIControlEventTouchUpInside];
            [self.containerView addSubview:self.watchAdButton];
            
            [self.watchAdButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.containerView).offset(16);
                make.right.equalTo(self.containerView).offset(-16);
                make.top.equalTo(self.okButton.mas_bottom).offset(12);
                make.height.mas_equalTo(48);
            }];
        }
    }
    
    // 更新容器高度以适应新按钮
    if (self.watchAdButton) {
        [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.offset(335 + 56); // 增加高度以容纳看广告按钮
        }];
    }
}

#pragma mark - Actions

- (void)okButtonTapped {
    [self dismiss];
}

- (void)watchAdButtonTapped {
    // 点击看广告按钮时，先隐藏当前弹窗
    self.hidden = YES;
    self.isHidden = YES;
    
    // 展示激励广告
    [[AdMobManager sharedManager] showRewardedAdForPlacement:AdMobPlacementSignIn
                                                      success:^(NSInteger coins) {
        // 奖励发放成功，更新用户信息并显示新弹窗（显示获得金币弹窗）
        [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
            // 先关闭当前弹窗
            [self dismiss];
            // 显示获得金币弹窗
            [SignSuccessDialog showWithReward:coins title:LocalString(@"get_coins_success_title") ?: @"Get Coins successfully"];
        } failure:nil];
    } failure:^(NSError *error) {
        BUNNYX_LOG(@"展示激励广告失败: %@", error.localizedDescription);
        // 广告展示失败，重新显示弹窗
        self.hidden = NO;
        self.isHidden = NO;
    }];
}

- (void)dismiss {
    [self removeFromSuperview];
    [[[self class] allDialogs] removeObject:self];
}

@end

