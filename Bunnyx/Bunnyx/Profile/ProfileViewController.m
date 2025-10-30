//
//  ProfileViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "ProfileViewController.h"
#import <Masonry/Masonry.h>
#import "LanguageManager.h"
#import "SettingsViewController.h"

@interface ProfileViewController ()

// Header区域
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *userIDLabel;
@property (nonatomic, strong) UIButton *supportButton;
@property (nonatomic, strong) UIButton *settingsButton;

// 订阅卡片
@property (nonatomic, strong) UIView *subscriptionCardView;
@property (nonatomic, strong) CAGradientLayer *cardGradientLayer;
@property (nonatomic, strong) UILabel *proLogoLabel;
@property (nonatomic, strong) UIView *proBadgeView;
@property (nonatomic, strong) UILabel *proBadgeLabel;
@property (nonatomic, strong) UIButton *subscribeButton;
@property (nonatomic, strong) CAGradientLayer *buttonGradientLayer;

// Coins部分
@property (nonatomic, strong) UIView *coinsView;
@property (nonatomic, strong) UIImageView *coinIconView;
@property (nonatomic, strong) UILabel *coinsLabel;
@property (nonatomic, strong) UIImageView *arrowIconView;

// 导航标签
@property (nonatomic, strong) UIView *tabView;
@property (nonatomic, strong) UIButton *generateTabButton;
@property (nonatomic, strong) UIButton *likeTabButton;
@property (nonatomic, strong) UIView *tabIndicatorView;

// 内容区域
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *emptyStateIconView;

// 背景渐变层
@property (nonatomic, strong) CAGradientLayer *backgroundGradientLayer;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置深色渐变背景
    [self setupGradientBackground];
    
    // 使用宏定义记录日志
    BUNNYX_LOG(@"ProfileViewController viewDidLoad");
    
    // 设置UI
    [self setupHeaderView];
    [self setupSubscriptionCard];
    [self setupCoinsView];
    [self setupTabView];
    [self setupContentView];
}

#pragma mark - 背景设置

- (void)setupGradientBackground {
    // 创建渐变层
    self.backgroundGradientLayer = [CAGradientLayer layer];
    self.backgroundGradientLayer.frame = self.view.bounds;
    
    // 深绿到黑色的渐变
    UIColor *darkGreen = [UIColor colorWithRed:0.1 green:0.2 blue:0.1 alpha:1.0];
    UIColor *black = [UIColor blackColor];
    
    self.backgroundGradientLayer.colors = @[(__bridge id)darkGreen.CGColor, (__bridge id)black.CGColor];
    self.backgroundGradientLayer.startPoint = CGPointMake(0.5, 0);
    self.backgroundGradientLayer.endPoint = CGPointMake(0.5, 1);
    
    [self.view.layer insertSublayer:self.backgroundGradientLayer atIndex:0];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 更新所有渐变层frame
    if (self.backgroundGradientLayer) {
        self.backgroundGradientLayer.frame = self.view.bounds;
    }
    if (self.cardGradientLayer) {
        self.cardGradientLayer.frame = self.subscriptionCardView.bounds;
    }
    if (self.buttonGradientLayer) {
        self.buttonGradientLayer.frame = self.subscribeButton.bounds;
    }
}

#pragma mark - Header区域

- (void)setupHeaderView {
    // Header容器
    self.headerView = [[UIView alloc] init];
    [self.view addSubview:self.headerView];
    
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(MARGIN_20);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, MARGIN_20, 0, MARGIN_20));
        make.height.mas_equalTo(60);
    }];
    
    // 头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.image = [UIImage imageNamed:@"icon_login_account_back"]; // 使用默认头像，可以替换
    self.avatarImageView.layer.cornerRadius = 25;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.borderWidth = 2;
    self.avatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.avatarImageView.backgroundColor = [UIColor lightGrayColor];
    [self.headerView addSubview:self.avatarImageView];
    
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.headerView);
        make.centerY.equalTo(self.headerView);
        make.width.height.mas_equalTo(50);
    }];
    
    // 用户名
    self.usernameLabel = [[UILabel alloc] init];
    self.usernameLabel.text = @"fdsw4r";
    self.usernameLabel.font = BOLD_FONT(FONT_SIZE_18);
    self.usernameLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.usernameLabel];
    
    [self.usernameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(MARGIN_15);
        make.top.equalTo(self.headerView).offset(8);
        make.right.equalTo(self.view.mas_right).offset(-MARGIN_20);
    }];
    
    // 用户ID
    self.userIDLabel = [[UILabel alloc] init];
    self.userIDLabel.text = [NSString stringWithFormat:@"%@:388886", LocalString(@"ID")];
    self.userIDLabel.font = FONT(FONT_SIZE_14);
    self.userIDLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    [self.headerView addSubview:self.userIDLabel];
    
    [self.userIDLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.usernameLabel);
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(4);
    }];
    
    // 设置按钮（先创建，因为supportButton需要引用它）
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.settingsButton setImage:[UIImage systemImageNamed:@"gearshape"] forState:UIControlStateNormal];
    [self.settingsButton setTintColor:[UIColor whiteColor]];
    [self.settingsButton addTarget:self action:@selector(settingsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.settingsButton];
    
    [self.settingsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.headerView);
        make.centerY.equalTo(self.headerView);
        make.width.height.mas_equalTo(30);
    }];
    
    // 支持按钮（耳机图标）
    self.supportButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.supportButton setImage:[UIImage systemImageNamed:@"headphones"] forState:UIControlStateNormal];
    [self.supportButton setTintColor:[UIColor whiteColor]];
    [self.supportButton addTarget:self action:@selector(supportButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.supportButton];
    
    [self.supportButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.settingsButton.mas_left).offset(-MARGIN_15);
        make.centerY.equalTo(self.headerView);
        make.width.height.mas_equalTo(30);
    }];
}

#pragma mark - 订阅卡片

- (void)setupSubscriptionCard {
    self.subscriptionCardView = [[UIView alloc] init];
    self.subscriptionCardView.layer.cornerRadius = CORNER_RADIUS_16;
    self.subscriptionCardView.layer.masksToBounds = YES;
    
    [self.view addSubview:self.subscriptionCardView];
    
    [self.subscriptionCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(MARGIN_20);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, MARGIN_20, 0, MARGIN_20));
        make.height.mas_equalTo(140);
    }];
    
    // 订阅卡片渐变背景
    self.cardGradientLayer = [CAGradientLayer layer];
    UIColor *cardDarkGreen = [UIColor colorWithRed:0.05 green:0.15 blue:0.05 alpha:1.0];
    UIColor *cardBlack = [UIColor blackColor];
    self.cardGradientLayer.colors = @[(__bridge id)cardDarkGreen.CGColor, (__bridge id)cardBlack.CGColor];
    self.cardGradientLayer.cornerRadius = CORNER_RADIUS_16;
    [self.subscriptionCardView.layer insertSublayer:self.cardGradientLayer atIndex:0];
    
    // BunnyX PRO Logo
    UIView *logoContainer = [[UIView alloc] init];
    [self.subscriptionCardView addSubview:logoContainer];
    
    [logoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.subscriptionCardView);
        make.top.equalTo(self.subscriptionCardView).offset(MARGIN_20);
    }];
    
    self.proLogoLabel = [[UILabel alloc] init];
    self.proLogoLabel.text = @"BunnyX";
    self.proLogoLabel.font = BOLD_FONT(FONT_SIZE_24);
    self.proLogoLabel.textColor = [UIColor whiteColor];
    [logoContainer addSubview:self.proLogoLabel];
    
    [self.proLogoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(logoContainer);
        make.top.bottom.equalTo(logoContainer);
    }];
    
    // PRO标签
    self.proBadgeView = [[UIView alloc] init];
    self.proBadgeView.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.2 alpha:1.0];
    self.proBadgeView.layer.cornerRadius = 8;
    self.proBadgeView.layer.masksToBounds = YES;
    [logoContainer addSubview:self.proBadgeView];
    
    [self.proBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.proLogoLabel.mas_right).offset(MARGIN_10);
        make.centerY.equalTo(self.proLogoLabel);
        make.height.mas_equalTo(20);
        make.right.equalTo(logoContainer);
    }];
    
    self.proBadgeLabel = [[UILabel alloc] init];
    self.proBadgeLabel.text = @"PRO";
    self.proBadgeLabel.font = BOLD_FONT(FONT_SIZE_12);
    self.proBadgeLabel.textColor = [UIColor whiteColor];
    self.proBadgeLabel.textAlignment = NSTextAlignmentCenter;
    [self.proBadgeView addSubview:self.proBadgeLabel];
    
    [self.proBadgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.proBadgeView).insets(UIEdgeInsetsMake(0, 8, 0, 8));
        make.top.bottom.equalTo(self.proBadgeView).insets(UIEdgeInsetsMake(2, 0, 2, 0));
    }];
    
    // 订阅按钮
    self.subscribeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.subscribeButton setTitle:LocalString(@"订阅") forState:UIControlStateNormal];
    [self.subscribeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.subscribeButton.titleLabel.font = BOLD_FONT(FONT_SIZE_16);
    self.subscribeButton.layer.cornerRadius = 20;
    self.subscribeButton.layer.masksToBounds = YES;
    
    [self.subscribeButton addTarget:self action:@selector(subscribeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.subscriptionCardView addSubview:self.subscribeButton];
    
    [self.subscribeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.subscriptionCardView);
        make.top.equalTo(logoContainer.mas_bottom).offset(MARGIN_20);
        make.width.mas_equalTo(140);
        make.height.mas_equalTo(40);
    }];
    
    // 订阅按钮渐变背景
    self.buttonGradientLayer = [CAGradientLayer layer];
    UIColor *pink = [UIColor colorWithRed:1.0 green:0.4 blue:0.5 alpha:1.0];
    UIColor *orange = [UIColor colorWithRed:1.0 green:0.6 blue:0.3 alpha:1.0];
    self.buttonGradientLayer.colors = @[(__bridge id)pink.CGColor, (__bridge id)orange.CGColor];
    self.buttonGradientLayer.cornerRadius = 20;
    [self.subscribeButton.layer insertSublayer:self.buttonGradientLayer atIndex:0];
}

#pragma mark - Coins部分

- (void)setupCoinsView {
    self.coinsView = [[UIView alloc] init];
    self.coinsView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1.0];
    self.coinsView.layer.cornerRadius = CORNER_RADIUS_12;
    self.coinsView.layer.masksToBounds = YES;
    [self.view addSubview:self.coinsView];
    
    [self.coinsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subscriptionCardView.mas_bottom).offset(MARGIN_20);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, MARGIN_20, 0, MARGIN_20));
        make.height.mas_equalTo(60);
    }];
    
    // 硬币图标
    self.coinIconView = [[UIImageView alloc] init];
    self.coinIconView.backgroundColor = [UIColor colorWithRed:0.1 green:0.2 blue:0.1 alpha:1.0];
    self.coinIconView.layer.cornerRadius = 20;
    self.coinIconView.layer.masksToBounds = YES;
    self.coinIconView.layer.borderWidth = 2;
    self.coinIconView.layer.borderColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0].CGColor;
    
    // 创建钻石图标（使用系统图标或自定义）
    UIImageView *diamondIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"diamond"]];
    diamondIcon.tintColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [self.coinIconView addSubview:diamondIcon];
    
    [self.coinsView addSubview:self.coinIconView];
    
    [self.coinIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.coinsView).offset(MARGIN_15);
        make.centerY.equalTo(self.coinsView);
        make.width.height.mas_equalTo(40);
    }];
    
    [diamondIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.coinIconView);
        make.width.height.mas_equalTo(24);
    }];
    
    // 硬币数量
    self.coinsLabel = [[UILabel alloc] init];
    self.coinsLabel.text = @"88 Coins";
    self.coinsLabel.font = BOLD_FONT(FONT_SIZE_16);
    self.coinsLabel.textColor = [UIColor whiteColor];
    [self.coinsView addSubview:self.coinsLabel];
    
    [self.coinsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.coinIconView.mas_right).offset(MARGIN_15);
        make.centerY.equalTo(self.coinsView);
    }];
    
    // 箭头图标
    self.arrowIconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    self.arrowIconView.tintColor = [UIColor whiteColor];
    [self.coinsView addSubview:self.arrowIconView];
    
    [self.arrowIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.coinsView).offset(-MARGIN_15);
        make.centerY.equalTo(self.coinsView);
        make.width.height.mas_equalTo(20);
    }];
}

#pragma mark - 导航标签

- (void)setupTabView {
    self.tabView = [[UIView alloc] init];
    [self.view addSubview:self.tabView];
    
    [self.tabView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.coinsView.mas_bottom).offset(MARGIN_20);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
    
    // Generate标签
    self.generateTabButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.generateTabButton setTitle:LocalString(@"生成") forState:UIControlStateNormal];
    [self.generateTabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.generateTabButton.titleLabel.font = BOLD_FONT(FONT_SIZE_16);
    [self.generateTabButton addTarget:self action:@selector(generateTabTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabView addSubview:self.generateTabButton];
    
    [self.generateTabButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tabView).offset(SCREEN_WIDTH / 2 - 60);
        make.centerY.equalTo(self.tabView);
    }];
    
    // Like标签
    self.likeTabButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.likeTabButton setTitle:LocalString(@"点赞") forState:UIControlStateNormal];
    [self.likeTabButton setTitleColor:[UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
    self.likeTabButton.titleLabel.font = FONT(FONT_SIZE_16);
    [self.likeTabButton addTarget:self action:@selector(likeTabTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabView addSubview:self.likeTabButton];
    
    [self.likeTabButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.generateTabButton.mas_right).offset(MARGIN_30);
        make.centerY.equalTo(self.tabView);
    }];
    
    // 下划线指示器（Generate标签下）
    self.tabIndicatorView = [[UIView alloc] init];
    self.tabIndicatorView.backgroundColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.3 alpha:1.0];
    self.tabIndicatorView.layer.cornerRadius = 1.5;
    [self.tabView addSubview:self.tabIndicatorView];
    
    [self.tabIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.tabView);
        make.centerX.equalTo(self.generateTabButton);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(3);
    }];
}

#pragma mark - 内容区域

- (void)setupContentView {
    self.contentView = [[UIView alloc] init];
    [self.view addSubview:self.contentView];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tabView.mas_bottom).offset(MARGIN_20);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    // 空状态图标（文件夹和星星）
    UIView *emptyStateContainer = [[UIView alloc] init];
    [self.contentView addSubview:emptyStateContainer];
    
    [emptyStateContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self.contentView);
    }];
    
    // 文件夹图标
    self.emptyStateIconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"folder.fill"]];
    self.emptyStateIconView.tintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [emptyStateContainer addSubview:self.emptyStateIconView];
    
    [self.emptyStateIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(emptyStateContainer);
        make.width.height.mas_equalTo(80);
    }];
    
    // 星星图标（在文件夹中心）
    UIImageView *starIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"star.fill"]];
    starIcon.tintColor = [UIColor whiteColor];
    [emptyStateContainer addSubview:starIcon];
    
    [starIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.emptyStateIconView);
        make.width.height.mas_equalTo(30);
    }];
    
    // 装饰星星（文件夹周围）
    UIImageView *sparkle1 = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"sparkle"]];
    sparkle1.tintColor = [UIColor whiteColor];
    [emptyStateContainer addSubview:sparkle1];
    
    [sparkle1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.emptyStateIconView).offset(-10);
        make.right.equalTo(self.emptyStateIconView).offset(10);
        make.width.height.mas_equalTo(20);
    }];
    
    UIImageView *sparkle2 = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"sparkle"]];
    sparkle2.tintColor = [UIColor whiteColor];
    [emptyStateContainer addSubview:sparkle2];
    
    [sparkle2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.emptyStateIconView).offset(10);
        make.left.equalTo(self.emptyStateIconView).offset(-10);
        make.width.height.mas_equalTo(20);
    }];
}

#pragma mark - 按钮事件

- (void)supportButtonTapped:(UIButton *)sender {
    BUNNYX_LOG(@"支持按钮被点击");
    // TODO: 实现支持功能
}

- (void)settingsButtonTapped:(UIButton *)sender {
    BUNNYX_LOG(@"设置按钮被点击");
    SettingsViewController *vc = [[SettingsViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)subscribeButtonTapped:(UIButton *)sender {
    BUNNYX_LOG(@"订阅按钮被点击");
    // TODO: 实现订阅功能
}

- (void)generateTabTapped:(UIButton *)sender {
    BUNNYX_LOG(@"生成标签被点击");
    [self switchToTab:sender];
}

- (void)likeTabTapped:(UIButton *)sender {
    BUNNYX_LOG(@"点赞标签被点击");
    [self switchToTab:sender];
}

- (void)switchToTab:(UIButton *)selectedButton {
    // 更新按钮样式
    BOOL isGenerate = (selectedButton == self.generateTabButton);
    
    // Generate按钮
    [self.generateTabButton setTitleColor:isGenerate ? [UIColor whiteColor] : [UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
    self.generateTabButton.titleLabel.font = isGenerate ? BOLD_FONT(FONT_SIZE_16) : FONT(FONT_SIZE_16);
    
    // Like按钮
    [self.likeTabButton setTitleColor:!isGenerate ? [UIColor whiteColor] : [UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
    self.likeTabButton.titleLabel.font = !isGenerate ? BOLD_FONT(FONT_SIZE_16) : FONT(FONT_SIZE_16);
    
    // 移动下划线指示器
    [self.tabIndicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.tabView);
        make.centerX.equalTo(selectedButton);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(3);
    }];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

// 不再在此监听语言切换，文案通过 LocalString 宏从系统 .strings 获取

@end
