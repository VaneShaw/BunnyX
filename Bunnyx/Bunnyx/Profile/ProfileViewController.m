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
#import "UserInfoManager.h"
#import "UserInfoModel.h"
#import "BunnyxMacros.h"
#import <SDWebImage/SDWebImage.h>
#import "RechargeViewController.h"
#import "SubscriptionViewController.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import <JXPagingView/JXPagerListRefreshView.h>
#import "GenerateListViewController.h"
#import "LikeListViewController.h"
#import "GradientButton.h"
#import "ContactUsViewController.h"

// MARK: - ProfileViewController
@interface ProfileViewController () <JXPagerViewDelegate, JXPagerMainTableViewGestureDelegate>

// 顶部区域
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *serviceImageView;
@property (nonatomic, strong) UIImageView *settingsImageView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UILabel *userIdLabel;
@property (nonatomic, strong) UIView *vipContainerView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) GradientButton *subscribeButton;
@property (nonatomic, strong) UIView *coinContainerView;
@property (nonatomic, strong) UIImageView *coinIconImageView;
@property (nonatomic, strong) UILabel *coinsLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

// Tab区域
@property (nonatomic, strong) UIView *tabContainerView;
@property (nonatomic, strong) UIButton *generateTabButton;
@property (nonatomic, strong) UIButton *likeTabButton;
@property (nonatomic, strong) UIView *tabIndicatorView;

// JXPagerView (使用 JXPagerListRefreshView 支持子列表下拉刷新)
@property (nonatomic, strong) JXPagerListRefreshView *pagerView;
@property (nonatomic, strong) GenerateListViewController *generateListVC;
@property (nonatomic, strong) LikeListViewController *likeListVC;
@property (nonatomic, assign) NSInteger currentTabIndex;
@property (nonatomic, assign) BOOL isProgrammaticScroll; // 标记是否为程序化滚动

// 数据
@property (nonatomic, strong) UserInfoModel *userInfo;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.11 blue:0.11 alpha:1.0]; // #0A1C1B
    
    self.currentTabIndex = 0;
    
    [self setupUI];
    [self setupJXPagerView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 每次进入页面都刷新用户信息
    [self refreshUserInfo];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 创建顶部区域
    [self setupHeaderView];
    
    // 创建Tab区域
    [self setupTabView];
}

- (void)setupHeaderView {
    // 顶部容器视图
    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.headerView];
    
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.left.right.equalTo(self.view);
    }];
    
    // 顶部按钮容器
    UIView *topButtonContainer = [[UIView alloc] init];
    [self.headerView addSubview:topButtonContainer];
    
    [topButtonContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.headerView);
        make.height.mas_equalTo(STATUS_BAR_HEIGHT+NAVIGATION_BAR_HEIGHT);
    }];
    
    // 设置按钮
    self.settingsImageView = [[UIImageView alloc] init];
    self.settingsImageView.image = [UIImage imageNamed:@"icon_mine_set_default"];
    self.settingsImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *settingsTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSettingsClick)];
    [self.settingsImageView addGestureRecognizer:settingsTap];
    [topButtonContainer addSubview:self.settingsImageView];
    
    [self.settingsImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(topButtonContainer).offset(-16);
        make.width.height.mas_equalTo(22);
        make.top.offset(70);
    }];
    
    // 服务按钮
    self.serviceImageView = [[UIImageView alloc] init];
    self.serviceImageView.image = [UIImage imageNamed:@"icon_mine_service_default"];
    self.serviceImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *serviceTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onServiceClick)];
    [self.serviceImageView addGestureRecognizer:serviceTap];
    [topButtonContainer addSubview:self.serviceImageView];
    
    [self.serviceImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.settingsImageView.mas_left).offset(-8);
        make.centerY.equalTo(self.settingsImageView.mas_centerY);
        make.width.height.offset(25);
    }];
    
    // 用户信息区域
    UIView *userInfoContainer = [[UIView alloc] init];
    [self.headerView addSubview:userInfoContainer];
    
    [userInfoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topButtonContainer.mas_bottom).offset(10);
        make.left.right.equalTo(self.headerView);
        make.height.offset(75);
    }];
    
    // 头像
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.image = [UIImage imageNamed:@"icon_mine_default_image"];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.layer.cornerRadius = 37.5;
    self.avatarImageView.layer.masksToBounds = YES;
    [userInfoContainer addSubview:self.avatarImageView];
    
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(userInfoContainer).offset(16);
        make.top.equalTo(userInfoContainer);
        make.width.height.mas_equalTo(75);
    }];
    
    // 昵称
    self.nicknameLabel = [[UILabel alloc] init];
    self.nicknameLabel.text = LocalString(@"生成");
    self.nicknameLabel.textColor = [UIColor whiteColor];
    self.nicknameLabel.font = FONT(FONT_SIZE_18);
    [userInfoContainer addSubview:self.nicknameLabel];
    
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(10);
        make.top.equalTo(self.avatarImageView).offset(16);
        make.right.lessThanOrEqualTo(userInfoContainer).offset(-16);
    }];
    
    // ID
    self.userIdLabel = [[UILabel alloc] init];
    self.userIdLabel.text = [NSString stringWithFormat:LocalString(@"ID:%@"), @""];
    self.userIdLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]; // #999999
    self.userIdLabel.font = FONT(13);
    [userInfoContainer addSubview:self.userIdLabel];
    
    [self.userIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nicknameLabel);
        make.top.equalTo(self.nicknameLabel.mas_bottom).offset(5);
        make.right.lessThanOrEqualTo(userInfoContainer).offset(-16);
    }];
    
    // 会员状态区域
    self.vipContainerView = [[UIView alloc] init];
    // 设置背景图片
    UIImage *vipBgImage = [UIImage imageNamed:@"bg_mine_pro"];
    if (vipBgImage) {
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:vipBgImage];
//        bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.vipContainerView insertSubview:bgImageView atIndex:0];
        [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.vipContainerView);
        }];
    }
    [self.headerView addSubview:self.vipContainerView];
    
    [self.vipContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(userInfoContainer.mas_bottom).offset(10);
        make.left.right.equalTo(self.headerView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        make.height.offset(113);
    }];
    
    // Logo
    self.logoImageView = [[UIImageView alloc] init];
    self.logoImageView.image = [UIImage imageNamed:@"icon_mine_logo"];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.vipContainerView addSubview:self.logoImageView];
    
    [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vipContainerView).offset(24);
        make.centerX.equalTo(self.vipContainerView);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(22);
    }];
    
    // 订阅按钮（对齐安卓：bg_mine_subscribe_button - 渐变背景 #F76E8C -> #FABDA9，圆角50dp）
    // 使用GradientButton实现渐变效果
    self.subscribeButton = [GradientButton buttonWithTitle:LocalString(@"订阅")
                                                  startColor:HEX_COLOR(0xF76E8C)  // #F76E8C
                                                    endColor:HEX_COLOR(0xFABDA9)]; // #FABDA9
    
    // 设置文字样式（对应安卓：textColor="#333333", textSize="17sp", textStyle="bold"）
    [self.subscribeButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
    self.subscribeButton.titleLabel.font = BOLD_FONT(17);
    
    // 设置圆角（对应安卓：corners android:radius="50dp"）
    self.subscribeButton.layer.cornerRadius = 20;
    self.subscribeButton.layer.masksToBounds = YES;
    // 注意按钮高度：paddingTop 15 + paddingBottom 14 = 29，加上文字高度约17，总高度约46
    // 但安卓是wrap_content，所以不设置固定高度，让按钮根据内容自适应
    // 如果需要固定高度，可以设置：self.subscribeButton.buttonHeight = 46;
    
    [self.subscribeButton addTarget:self action:@selector(onSubscribeClick) forControlEvents:UIControlEventTouchUpInside];
    [self.vipContainerView addSubview:self.subscribeButton];
    
    [self.subscribeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(15);
        make.centerX.equalTo(self.vipContainerView);
        make.bottom.equalTo(self.vipContainerView).offset(-13);
        make.height.offset(40);
        make.width.offset(150);
    }];
    
    // 金币区域
    self.coinContainerView = [[UIView alloc] init];
    self.coinContainerView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    self.coinContainerView.layer.cornerRadius = 12;
    self.coinContainerView.layer.masksToBounds = YES;
    // 设置背景图片
    UIImage *coinBgImage = [UIImage imageNamed:@"bg_mine_coin"];
    if (coinBgImage) {
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:coinBgImage];
        bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        bgImageView.clipsToBounds = YES;
        bgImageView.layer.cornerRadius = 12;
        [self.coinContainerView insertSubview:bgImageView atIndex:0];
        [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.coinContainerView);
        }];
    }
    self.coinContainerView.userInteractionEnabled = YES;
    UITapGestureRecognizer *coinTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCoinsClick)];
    [self.coinContainerView addGestureRecognizer:coinTap];
    [self.headerView addSubview:self.coinContainerView];
    
    [self.coinContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vipContainerView.mas_bottom).offset(10);
        make.left.right.equalTo(self.headerView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        make.bottom.equalTo(self.headerView).offset(0);
        make.height.mas_equalTo(56);
    }];
    
    // 金币图标
    self.coinIconImageView = [[UIImageView alloc] init];
    self.coinIconImageView.image = [UIImage imageNamed:@"icon_mine_coin_default"];
    self.coinIconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.coinContainerView addSubview:self.coinIconImageView];
    
    [self.coinIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.coinContainerView).offset(16);
        make.centerY.equalTo(self.coinContainerView);
        make.width.height.mas_equalTo(24);
    }];
    
    // 金币数量
    self.coinsLabel = [[UILabel alloc] init];
    self.coinsLabel.text = [NSString stringWithFormat:LocalString(@"%d Coins"), 0];
    self.coinsLabel.textColor = [UIColor whiteColor];
    self.coinsLabel.font = FONT(17);
    [self.coinContainerView addSubview:self.coinsLabel];
    
    [self.coinsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.coinIconImageView.mas_right).offset(12);
        make.centerY.equalTo(self.coinContainerView);
    }];
    
    // 箭头
    self.arrowImageView = [[UIImageView alloc] init];
    self.arrowImageView.image = [UIImage imageNamed:@"icon_mine_enter_default"];
    self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.coinContainerView addSubview:self.arrowImageView];
    
    [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.coinContainerView).offset(-16);
        make.centerY.equalTo(self.coinContainerView);
        make.width.height.mas_equalTo(24);
    }];
}

- (void)setupTabView {
    self.tabContainerView = [[UIView alloc] init];
    self.tabContainerView.backgroundColor = [UIColor clearColor];
    // 注意：Tab区域不直接添加到view，而是作为pinSectionHeader
    
    // 生成Tab
    self.generateTabButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.generateTabButton setTitle:LocalString(@"生成") forState:UIControlStateNormal];
    [self.generateTabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.generateTabButton.titleLabel.font = FONT(20);
    [self.generateTabButton addTarget:self action:@selector(onGenerateTabClick) forControlEvents:UIControlEventTouchUpInside];
    [self.tabContainerView addSubview:self.generateTabButton];
    
    // 点赞Tab
    self.likeTabButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.likeTabButton setTitle:LocalString(@"点赞") forState:UIControlStateNormal];
    [self.likeTabButton setTitleColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0] forState:UIControlStateNormal];
    self.likeTabButton.titleLabel.font = FONT(17);
    [self.likeTabButton addTarget:self action:@selector(onLikeTabClick) forControlEvents:UIControlEventTouchUpInside];
    [self.tabContainerView addSubview:self.likeTabButton];
    
    // Tab指示器
    self.tabIndicatorView = [[UIView alloc] init];
    self.tabIndicatorView.backgroundColor = [UIColor whiteColor];
    self.tabIndicatorView.layer.cornerRadius = 2;
    [self.tabContainerView addSubview:self.tabIndicatorView];
    
    // 布局Tab按钮（居中，间距固定）
    // Tab区域总宽度250，两个按钮居中，间距125
    [self.generateTabButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.tabContainerView).offset(-62.5);
        make.bottom.equalTo(self.tabContainerView).offset(-20);
    }];
    
    [self.likeTabButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.tabContainerView).offset(62.5);
        make.top.equalTo(self.generateTabButton);
    }];
    
    // 指示器初始位置（在生成Tab下方）
    [self.tabIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.generateTabButton);
        make.bottom.equalTo(self.tabContainerView).offset(-8);
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(4);
    }];
}

- (void)setupJXPagerView {
    // 创建列表视图控制器
    self.generateListVC = [[GenerateListViewController alloc] init];
    self.likeListVC = [[LikeListViewController alloc] init];
    
    // 创建JXPagerListRefreshView（支持子列表下拉刷新）
    self.pagerView = [[JXPagerListRefreshView alloc] initWithDelegate:self];
    self.pagerView.mainTableView.gestureDelegate = self;
    self.pagerView.mainTableView.backgroundColor = [UIColor clearColor];
    // 设置 contentInsetAdjustmentBehavior，确保在嵌套滚动中刷新能正常工作
    if (@available(iOS 11.0, *)) {
        self.pagerView.mainTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.pagerView];
    
    [self.pagerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    // 监听列表容器的滚动，同步Tab状态
    __weak typeof(self) weakSelf = self;
    [self.pagerView.listContainerView.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"] && object == self.pagerView.listContainerView.scrollView) {
        // 如果是程序化滚动，跳过 KVO 更新，避免循环
        if (self.isProgrammaticScroll) {
            return;
        }
        CGFloat offsetX = self.pagerView.listContainerView.scrollView.contentOffset.x;
        NSInteger newIndex = (NSInteger)(offsetX / SCREEN_WIDTH + 0.5);
        if (newIndex >= 0 && newIndex < 2 && newIndex != self.currentTabIndex) {
            self.currentTabIndex = newIndex;
            [self updateTabState];
        }
    }
}

- (void)dealloc {
    @try {
        [self.pagerView.listContainerView.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    } @catch (NSException *exception) {
        // 忽略移除观察者时的异常
    }
}

#pragma mark - JXPagerViewDelegate

- (NSUInteger)tableHeaderViewHeightInPagerView:(JXPagerView *)pagerView {
    // 计算headerView的高度（不包括Tab区域）
    // 顶部按钮区域: 44
    // 用户信息区域: 75 (头像高度) + 16 (顶部间距)
    // 会员状态区域: 24 + 22 + 15 + 44 + 13 = 118 (估算)
    // 金币区域: 56
    // 总间距: 20 + 16 + 24 + 24 + 24 = 108
    // 总计: 44 + 91 + 118 + 56 + 108 = 417
    return 360;
}

- (UIView *)tableHeaderViewInPagerView:(JXPagerView *)pagerView {
    return self.headerView;
}

- (NSUInteger)heightForPinSectionHeaderInPagerView:(JXPagerView *)pagerView {
    // Tab区域高度 + 上下间距
    return 84; // 44 (Tab高度) + 20 (上方间距)
}

- (UIView *)viewForPinSectionHeaderInPagerView:(JXPagerView *)pagerView {
    // Tab区域会由JXPagerView管理，不需要手动添加到view
    return self.tabContainerView;
}

- (NSInteger)numberOfListsInPagerView:(JXPagerView *)pagerView {
    return 2;
}

- (id<JXPagerViewListViewDelegate>)pagerView:(JXPagerView *)pagerView initListAtIndex:(NSInteger)index {
    if (index == 0) {
        return (id<JXPagerViewListViewDelegate>)self.generateListVC;
    } else {
        return (id<JXPagerViewListViewDelegate>)self.likeListVC;
    }
}

#pragma mark - JXPagerMainTableViewGestureDelegate

- (BOOL)mainTableViewGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Tab Actions

- (void)onGenerateTabClick {
    if (self.currentTabIndex == 0) return;
    
    // 先触发初始化，确保视图控制器被加载
    [self.pagerView.listContainerView didClickSelectedItemAtIndex:0];
    // 标记为程序化滚动，避免 KVO 循环
    self.isProgrammaticScroll = YES;
    // 更新状态
    self.currentTabIndex = 0;
    [self updateTabState];
    // 滚动到对应位置
    [self.pagerView.listContainerView.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    // 滚动完成后重置标志
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isProgrammaticScroll = NO;
    });
}

- (void)onLikeTabClick {
    if (self.currentTabIndex == 1) return;
    
    // 先触发初始化，确保视图控制器被加载
    [self.pagerView.listContainerView didClickSelectedItemAtIndex:1];
    // 标记为程序化滚动，避免 KVO 循环
    self.isProgrammaticScroll = YES;
    // 更新状态
    self.currentTabIndex = 1;
    [self updateTabState];
    // 滚动到对应位置
    [self.pagerView.listContainerView.scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:YES];
    // 滚动完成后重置标志
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isProgrammaticScroll = NO;
    });
}

- (void)updateTabState {
    if (self.currentTabIndex == 0) {
        // 生成Tab选中
        [self.generateTabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.generateTabButton.titleLabel.font = FONT(20);
        [self.likeTabButton setTitleColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0] forState:UIControlStateNormal];
        self.likeTabButton.titleLabel.font = FONT(17);
        
        [self.tabIndicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.generateTabButton);
            make.bottom.equalTo(self.tabContainerView).offset(-8);
            make.width.mas_equalTo(20);
            make.height.mas_equalTo(4);
        }];
    } else {
        // 点赞Tab选中
        [self.likeTabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.likeTabButton.titleLabel.font = FONT(20);
        [self.generateTabButton setTitleColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0] forState:UIControlStateNormal];
        self.generateTabButton.titleLabel.font = FONT(17);
        
        [self.tabIndicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.likeTabButton);
            make.bottom.equalTo(self.tabContainerView).offset(-8);
            make.width.mas_equalTo(20);
            make.height.mas_equalTo(4);
        }];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.tabContainerView layoutIfNeeded];
    }];
}

#pragma mark - Button Actions

- (void)onServiceClick {
    // 跳转到联系客服页面
    ContactUsViewController *contactUsVC = [[ContactUsViewController alloc] init];
    [self.navigationController pushViewController:contactUsVC animated:YES];
}

- (void)onSettingsClick {
    SettingsViewController *settingsVC = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsVC animated:YES];
}

- (void)onSubscribeClick {
    // 跳转到订阅页面（第三个tab）
    // 通过MainTabBarController切换
    UITabBarController *tabBarController = self.tabBarController;
    if (tabBarController && tabBarController.viewControllers.count > 2) {
        tabBarController.selectedIndex = 2;
    }
}

- (void)onCoinsClick {
    RechargeViewController *rechargeVC = [[RechargeViewController alloc] init];
    [self.navigationController pushViewController:rechargeVC animated:YES];
}

#pragma mark - Data Loading

- (void)refreshUserInfo {
    [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
        self.userInfo = userInfo;
        [self updateUserInfoUI];
    } failure:^(NSError *error) {
        BUNNYX_LOG(@"刷新用户信息失败: %@", error);
    }];
}

- (void)updateUserInfoUI {
    if (!self.userInfo) {
        // 没有用户信息时的默认显示
        self.avatarImageView.image = [UIImage imageNamed:@"icon_mine_default_image"];
        self.nicknameLabel.text = LocalString(@"生成");
        self.userIdLabel.text = [NSString stringWithFormat:LocalString(@"ID:%@"), @""];
        self.coinsLabel.text = [NSString stringWithFormat:LocalString(@"%d Coins"), 0];
        [self.subscribeButton setTitle:LocalString(@"订阅") forState:UIControlStateNormal];
        return;
    }
    
    // 设置头像
    NSString *avatar = [self.userInfo.avatar stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (avatar && avatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:avatar]
                                 placeholderImage:[UIImage imageNamed:@"icon_mine_default_image"]
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (error) {
                self.avatarImageView.image = [UIImage imageNamed:@"icon_mine_default_image"];
            }
        }];
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"icon_mine_default_image"];
    }
    
    // 设置昵称
    NSString *nickname = [self.userInfo.nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (nickname && nickname.length > 0) {
        self.nicknameLabel.text = nickname;
    } else {
        self.nicknameLabel.text = LocalString(@"生成");
    }
    
    // 设置用户ID
    NSString *account = [self.userInfo.account stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (account && account.length > 0) {
        self.userIdLabel.text = [NSString stringWithFormat:LocalString(@"ID:%@"), account];
    } else {
        self.userIdLabel.text = [NSString stringWithFormat:LocalString(@"ID:%@"), @""];
    }
    
    // 设置金币数量
    NSNumber *coins = self.userInfo.surplusMxdDiamond;
    long coinsValue = coins ? [coins longValue] : 0;
    self.coinsLabel.text = [NSString stringWithFormat:LocalString(@"%d Coins"), (int)coinsValue];
    
    // 设置会员状态
    [self updateVipStatus];
}

- (void)updateVipStatus {
    if (!self.userInfo) {
        // 恢复订阅按钮样式（渐变背景）
        [self.subscribeButton setTitle:LocalString(@"订阅") forState:UIControlStateNormal];
        [self.subscribeButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
        self.subscribeButton.titleLabel.font = BOLD_FONT(17);
        // 恢复渐变背景
        self.subscribeButton.gradientStartColor = HEX_COLOR(0xF76E8C);
        self.subscribeButton.gradientEndColor = HEX_COLOR(0xFABDA9);
        self.subscribeButton.layer.cornerRadius = 20;
        return;
    }
    
    BOOL isVip = self.userInfo.isVip;
    NSNumber *vipEndTime = self.userInfo.vipEndTime;
    
    if (isVip && vipEndTime && [vipEndTime longValue] > 0) {
        // 是会员，显示有效期
        NSString *formattedDate = [self formatVipEndTime:[vipEndTime longValue]];
        NSString *title = [NSString stringWithFormat:LocalString(@"有效期至: %@"), formattedDate];
        [self.subscribeButton setTitle:title forState:UIControlStateNormal];
        [self.subscribeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.subscribeButton.titleLabel.font = FONT(14);
        // 设置VIP背景（使用透明渐变，让背景图片显示）
        self.subscribeButton.gradientStartColor = [UIColor clearColor];
        self.subscribeButton.gradientEndColor = [UIColor clearColor];
        // 设置VIP背景图片
        UIImage *vipBgImage = [UIImage imageNamed:@"bg_vip_button"];
        if (vipBgImage) {
            [self.subscribeButton setBackgroundImage:vipBgImage forState:UIControlStateNormal];
        }
    } else {
        // 不是会员，显示订阅按钮（渐变背景）
        [self.subscribeButton setTitle:LocalString(@"订阅") forState:UIControlStateNormal];
        [self.subscribeButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
        self.subscribeButton.titleLabel.font = BOLD_FONT(17);
        // 恢复渐变背景
        self.subscribeButton.gradientStartColor = HEX_COLOR(0xF76E8C);
        self.subscribeButton.gradientEndColor = HEX_COLOR(0xFABDA9);
        self.subscribeButton.cornerRadius = 20;
        [self.subscribeButton setBackgroundImage:nil forState:UIControlStateNormal];
    }
}

- (NSString *)formatVipEndTime:(long)vipEndYmd {
    // 后端返回形如 20261029（yyyyMMdd）
    int year = (int)(vipEndYmd / 10000);
    int month = (int)((vipEndYmd % 10000) / 100);
    int day = (int)(vipEndYmd % 100);
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [calendar dateFromComponents:components];
    
    if (date) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
        formatter.locale = [NSLocale currentLocale];
        return [formatter stringFromDate:date];
    } else {
        // 兜底处理
        NSString *raw = [NSString stringWithFormat:@"%ld", vipEndYmd];
        if (raw.length == 8) {
            NSString *y = [raw substringWithRange:NSMakeRange(0, 4)];
            NSString *m = [raw substringWithRange:NSMakeRange(4, 2)];
            NSString *d = [raw substringWithRange:NSMakeRange(6, 2)];
            return [NSString stringWithFormat:@"%@-%@-%@", y, m, d];
        }
        return raw;
    }
}

@end
