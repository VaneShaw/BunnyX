//
//  RechargeViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "RechargeViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "RechargeItemModel.h"
#import "UserInfoManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "GradientButton.h"

@interface RechargeViewController ()

// 标题栏
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *detailsButton;

// 当前余额
@property (nonatomic, strong) UIView *balanceView;
@property (nonatomic, strong) UIImageView *coinIconView;
@property (nonatomic, strong) UILabel *balanceLabel;

// 充值套餐网格
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *packagesContainerView;
@property (nonatomic, strong) NSMutableArray<UIView *> *packageViews;

// 购买按钮
@property (nonatomic, strong) GradientButton *buyButton;

// 数据
@property (nonatomic, strong) NSArray<RechargeItemModel *> *rechargeList;
@property (nonatomic, strong) RechargeItemModel *selectedItem;

@end

@implementation RechargeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BUNNYX_LOG(@"RechargeViewController viewDidLoad");
    
    // 设置UI
    [self setupUI];
    
    // 加载充值列表
    [self loadRechargeList];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 更新余额显示
    [self updateBalance];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 设置背景渐变
    [self setupGradientBackground];
    
    // 设置标题栏
    [self setupTitleBar];
    
    // 设置余额显示
    [self setupBalanceView];
    
    // 先设置购买按钮（用于约束参考）
    [self setupBuyButton];
    
    // 设置充值套餐容器（在购买按钮之后，可以依赖购买按钮的约束）
    [self setupPackagesContainer];
}

- (void)setupGradientBackground {
    // 创建渐变层
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    
    // 深绿到黑色的渐变
    UIColor *darkGreen = [UIColor colorWithRed:0.1 green:0.2 blue:0.1 alpha:1.0];
    UIColor *black = [UIColor blackColor];
    
    gradientLayer.colors = @[(__bridge id)darkGreen.CGColor, (__bridge id)black.CGColor];
    gradientLayer.startPoint = CGPointMake(0.5, 0);
    gradientLayer.endPoint = CGPointMake(0.5, 1);
    
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 更新渐变层frame
    if (self.view.layer.sublayers.count > 0) {
        CAGradientLayer *gradientLayer = (CAGradientLayer *)self.view.layer.sublayers[0];
        if ([gradientLayer isKindOfClass:[CAGradientLayer class]]) {
            gradientLayer.frame = self.view.bounds;
        }
    }
}

- (void)setupTitleBar {
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"Coins");
    self.titleLabel.font = BOLD_FONT(FONT_SIZE_20);
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.customBackButton.mas_right).offset(MARGIN_15);
        make.centerY.equalTo(self.customBackButton);
    }];
    
    // Details按钮
    self.detailsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.detailsButton setTitle:LocalString(@"Details") forState:UIControlStateNormal];
    [self.detailsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.detailsButton.titleLabel.font = FONT(FONT_SIZE_16);
    
    [self.detailsButton addTarget:self action:@selector(detailsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.detailsButton];
    
    [self.detailsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-MARGIN_20);
        make.centerY.equalTo(self.customBackButton);
        make.height.mas_equalTo(30);
    }];
}

- (void)setupBalanceView {
    self.balanceView = [[UIView alloc] init];
    [self.view addSubview:self.balanceView];
    
    [self.balanceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.customBackButton.mas_bottom).offset(MARGIN_30);
        make.centerX.equalTo(self.view);
        make.height.offset(200);
    }];
    
    // 硬币图标
    self.coinIconView = [[UIImageView alloc] init];
    self.coinIconView.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    self.coinIconView.layer.cornerRadius = 25;
    self.coinIconView.layer.masksToBounds = YES;
    
    // 创建内部黑色圆形
    UIView *innerCircle = [[UIView alloc] init];
    innerCircle.backgroundColor = [UIColor blackColor];
    innerCircle.layer.cornerRadius = 15;
    innerCircle.layer.masksToBounds = YES;
    [self.coinIconView addSubview:innerCircle];
    
    [innerCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.coinIconView);
        make.width.height.mas_equalTo(30);
    }];
    
    [self.balanceView addSubview:self.coinIconView];
    
    [self.coinIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.balanceView);
        make.centerY.equalTo(self.balanceView);
        make.width.height.mas_equalTo(50);
    }];
    
    // Coins标签
    UILabel *coinsTitleLabel = [[UILabel alloc] init];
    coinsTitleLabel.text = [NSString stringWithFormat:@"%@:", LocalString(@"Coins")];
    coinsTitleLabel.font = FONT(FONT_SIZE_16);
    coinsTitleLabel.textColor = [UIColor whiteColor];
    [self.balanceView addSubview:coinsTitleLabel];
    
    [coinsTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.coinIconView.mas_right).offset(MARGIN_15);
        make.centerY.equalTo(self.balanceView);
    }];
    
    // 余额数字
    self.balanceLabel = [[UILabel alloc] init];
    self.balanceLabel.text = @"0";
    self.balanceLabel.font = BOLD_FONT(FONT_SIZE_32);
    self.balanceLabel.textColor = [UIColor whiteColor];
    [self.balanceView addSubview:self.balanceLabel];
    
    [self.balanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(coinsTitleLabel.mas_right).offset(MARGIN_10);
        make.centerY.equalTo(self.balanceView);
        make.right.equalTo(self.balanceView);
    }];
}

- (void)setupPackagesContainer {
    self.packageViews = [NSMutableArray array];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.balanceView.mas_bottom).offset(MARGIN_30);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.buyButton.mas_top).offset(-MARGIN_20);
    }];
    
    self.packagesContainerView = [[UIView alloc] init];
    self.packagesContainerView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.packagesContainerView];
    
    [self.packagesContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
        make.height.greaterThanOrEqualTo(@(100)); // 初始最小高度
    }];
}

- (void)setupBuyButton {
   
    // 使用GradientButton便利构造方法
    self.buyButton = [GradientButton buttonWithTitle:LocalString(@"Buy")];
                                         
    [self.buyButton addTarget:self action:@selector(buyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buyButton];
    
    [self.buyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, MARGIN_20, 0, MARGIN_20));
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-MARGIN_20);
        make.height.mas_equalTo(50);
    }];
}

#pragma mark - Data Loading

- (void)loadRechargeList {
    // iOS平台使用applePay
    NSString *paymentCode = @"applePay";
    
    BUNNYX_LOG(@"开始加载充值列表，paymentCode: %@", paymentCode);
    [SVProgressHUD showWithStatus:LocalString(@"加载中")];
    
    NSDictionary *parameters = @{
        @"paymentCode": paymentCode
    };
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_PAY_RECHARGE_LIST
                               parameters:parameters
                                  success:^(id responseObject) {
        [SVProgressHUD dismiss];
        
        BUNNYX_LOG(@"充值列表请求成功，响应: %@", responseObject);
        
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSArray *dataArray = dict[@"data"];
        
        if (dataArray && [dataArray isKindOfClass:[NSArray class]]) {
            self.rechargeList = [RechargeItemModel modelsFromResponse:dataArray];
            BUNNYX_LOG(@"解析充值列表成功，共 %ld 个套餐", (long)self.rechargeList.count);
            
            // 主线程更新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePackagesUI];
            });
        } else {
            BUNNYX_ERROR(@"充值列表数据格式错误，data不是数组类型");
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:LocalString(@"数据加载失败")];
            });
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        BUNNYX_ERROR(@"加载充值列表失败: %@", error.localizedDescription);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:LocalString(@"网络错误")];
        });
    }];
}

- (void)updatePackagesUI {
    BUNNYX_LOG(@"开始更新充值套餐UI，套餐数量: %ld", (long)self.rechargeList.count);
    
    // 清除旧的套餐视图
    for (UIView *view in self.packageViews) {
        [view removeFromSuperview];
    }
    [self.packageViews removeAllObjects];
    
    if (self.rechargeList.count == 0) {
        BUNNYX_ERROR(@"充值列表为空，无法显示套餐");
        return;
    }
    
    // 计算布局参数
    CGFloat screenWidth = SCREEN_WIDTH;
    CGFloat margin = MARGIN_15;
    CGFloat itemSpacing = MARGIN_15;
    NSInteger itemsPerRow = 3;
    CGFloat itemWidth = (screenWidth - margin * 2 - itemSpacing * (itemsPerRow - 1)) / itemsPerRow;
    CGFloat itemHeight = 120;
    
    BUNNYX_LOG(@"布局参数 - 屏幕宽度: %.1f, 每个卡片宽度: %.1f, 高度: %.1f", screenWidth, itemWidth, itemHeight);
    
    // 创建套餐卡片
    for (NSInteger i = 0; i < self.rechargeList.count; i++) {
        RechargeItemModel *item = self.rechargeList[i];
        
        NSInteger row = i / itemsPerRow;
        NSInteger col = i % itemsPerRow;
        
        UIView *packageView = [self createPackageViewWithItem:item];
        [self.packagesContainerView addSubview:packageView];
        [self.packageViews addObject:packageView];
        
        [packageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.packagesContainerView).offset(margin + col * (itemWidth + itemSpacing));
            make.top.equalTo(self.packagesContainerView).offset(MARGIN_20 + row * (itemHeight + MARGIN_15));
            make.width.mas_equalTo(itemWidth);
            make.height.mas_equalTo(itemHeight);
        }];
        
        // 添加点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(packageTapped:)];
        [packageView addGestureRecognizer:tapGesture];
        packageView.tag = i;
        packageView.userInteractionEnabled = YES;
        
        BUNNYX_LOG(@"创建套餐卡片 %ld - 金币: %ld, 价格: %.2f, 位置: 行%ld 列%ld", (long)i, (long)item.buyNum, item.payMoney, (long)row, (long)col);
    }
    
    // 更新容器高度
    NSInteger totalRows = (self.rechargeList.count + itemsPerRow - 1) / itemsPerRow;
    CGFloat containerHeight = MARGIN_20 * 2 + totalRows * itemHeight + (totalRows - 1) * MARGIN_15;
    
    [self.packagesContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(containerHeight);
    }];
    
    // 强制更新布局
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    BUNNYX_LOG(@"套餐UI更新完成，容器高度: %.1f", containerHeight);
}

- (UIView *)createPackageViewWithItem:(RechargeItemModel *)item {
    UIView *packageView = [[UIView alloc] init];
    packageView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    packageView.layer.cornerRadius = CORNER_RADIUS_12;
    packageView.layer.masksToBounds = YES;
    packageView.layer.borderWidth = 1;
    packageView.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1.0].CGColor;
    
    // 折扣标签（如果有）- 粉色标签在左上角
    if (item.discountRemark && item.discountRemark.length > 0) {
        UIView *discountBadge = [[UIView alloc] init];
        discountBadge.backgroundColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0];
        discountBadge.layer.cornerRadius = 6;
        discountBadge.layer.masksToBounds = YES;
        [packageView addSubview:discountBadge];
        
        UILabel *discountLabel = [[UILabel alloc] init];
        discountLabel.text = item.discountRemark;
        discountLabel.font = BOLD_FONT(FONT_SIZE_10);
        discountLabel.textColor = [UIColor whiteColor];
        discountLabel.textAlignment = NSTextAlignmentCenter;
        [discountBadge addSubview:discountLabel];
        
        [discountBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(packageView).offset(6);
            make.left.equalTo(packageView).offset(6);
        }];
        
        [discountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(discountBadge).insets(UIEdgeInsetsMake(3, 8, 3, 8));
        }];
    }
    
    // 星星图标 - 居中偏上
    UIImageView *coinIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"star.fill"]];
    coinIcon.tintColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    [packageView addSubview:coinIcon];
    
    [coinIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(packageView);
        make.top.equalTo(packageView).offset(MARGIN_20);
        make.width.height.mas_equalTo(28);
    }];
    
    // 金币数量 - 在星星下方，绿色大字体
    UILabel *coinsLabel = [[UILabel alloc] init];
    coinsLabel.text = [NSString stringWithFormat:@"%ld", (long)item.buyNum];
    coinsLabel.font = BOLD_FONT(FONT_SIZE_20);
    coinsLabel.textColor = [UIColor colorWithRed:0.0 green:0.85 blue:0.35 alpha:1.0];
    coinsLabel.textAlignment = NSTextAlignmentCenter;
    [packageView addSubview:coinsLabel];
    
    [coinsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(packageView);
        make.top.equalTo(coinIcon.mas_bottom).offset(MARGIN_10);
        make.left.right.equalTo(packageView).insets(UIEdgeInsetsMake(0, MARGIN_5, 0, MARGIN_5));
    }];
    
    // 价格 - 在底部，白色字体
    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.text = [NSString stringWithFormat:@"$ %.2f", item.payMoney];
    priceLabel.font = FONT(FONT_SIZE_14);
    priceLabel.textColor = [UIColor whiteColor];
    priceLabel.textAlignment = NSTextAlignmentCenter;
    [packageView addSubview:priceLabel];
    
    [priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(packageView);
        make.bottom.equalTo(packageView).offset(-MARGIN_15);
        make.left.right.equalTo(packageView).insets(UIEdgeInsetsMake(0, MARGIN_5, 0, MARGIN_5));
    }];
    
    return packageView;
}

#pragma mark - Update UI

- (void)updateBalance {
    UserInfoManager *userManager = [UserInfoManager sharedManager];
    NSNumber *coins = [userManager getSurplusMxdDiamond];
    NSInteger coinsValue = coins ? [coins integerValue] : 0;
    self.balanceLabel.text = [NSString stringWithFormat:@"%ld", (long)coinsValue];
}

- (void)updateSelectedPackage {
    // 更新所有套餐视图的选中状态
    for (NSInteger i = 0; i < self.packageViews.count; i++) {
        UIView *packageView = self.packageViews[i];
        
        // 恢复默认样式
        packageView.layer.borderWidth = 0;
        packageView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        
        // 如果被选中，添加边框和背景
        if (i < self.rechargeList.count) {
            RechargeItemModel *item = self.rechargeList[i];
            if (item == self.selectedItem) {
                packageView.layer.borderWidth = 2;
                packageView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.3 alpha:1.0].CGColor;
                packageView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
            }
        }
    }
}

#pragma mark - Actions

- (void)detailsButtonTapped:(UIButton *)sender {
    BUNNYX_LOG(@"Details按钮被点击");
    // TODO: 跳转到充值详情页面
}

- (void)packageTapped:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    if (index >= 0 && index < self.rechargeList.count) {
        self.selectedItem = self.rechargeList[index];
        [self updateSelectedPackage];
        BUNNYX_LOG(@"选中充值套餐: %ld coins, $%.2f", (long)self.selectedItem.buyNum, self.selectedItem.payMoney);
    }
}

- (void)buyButtonTapped:(UIButton *)sender {
    if (!self.selectedItem) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"请选择充值套餐")];
        return;
    }
    
    BUNNYX_LOG(@"购买按钮被点击，选中套餐ID: %ld", (long)self.selectedItem.rechargeId);
    // TODO: 实现支付逻辑
    // 1. 调用充值API获取productId和订单号
    // 2. 调用Apple Pay或Google Pay进行支付
}

@end

