//
//  RechargeViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "RechargeViewController.h"
#import "RechargeDetailsViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "RechargeItemModel.h"
#import "UserInfoManager.h"
#import "UserInfoModel.h"
#import "ApplePayManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "GradientButton.h"
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>

@interface RechargeViewController () <ApplePayManagerDelegate>

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

// 支付
@property (nonatomic, strong) ApplePayManager *applePayManager;
@property (nonatomic, copy) NSString *currentServerOrderSn;
@property (nonatomic, assign) NSInteger currentRechargeId;

@end

@implementation RechargeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BUNNYX_LOG(@"RechargeViewController viewDidLoad");
    
    // 设置UI
    [self setupUI];
    
    // 初始化支付能力
    [self setupApplePay];
    
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

- (void)setupApplePay {
    self.applePayManager = [ApplePayManager sharedManager];
    [self.applePayManager initializeWithDelegate:self];
}

- (void)setupGradientBackground {
    // 对齐安卓：使用背景图片（如果有）或黑色背景
    self.view.backgroundColor = [UIColor blackColor];
    
    // 如果有充值页面背景图，可以在这里添加
    // UIImage *bgImage = [UIImage imageNamed:@"bg_recharge"];
    // if (bgImage) {
    //     UIImageView *bgImageView = [[UIImageView alloc] initWithImage:bgImage];
    //     bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    //     [self.view insertSubview:bgImageView atIndex:0];
    //     [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    //         make.edges.equalTo(self.view);
    //     }];
    // }
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
    // 对齐安卓：余额显示区域
    self.balanceView = [[UIView alloc] init];
    [self.view addSubview:self.balanceView];
    
    [self.balanceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.customBackButton.mas_bottom).offset(30); // 对齐安卓：marginTop 30dp
        make.centerX.equalTo(self.view);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20)); // 对齐安卓：paddingHorizontal 20dp
        make.height.offset(75);
    }];
    
    // 金币图标（对齐安卓：icon_mine_coin_default，使用图片资源）
    self.coinIconView = [[UIImageView alloc] init];
    self.coinIconView.image = [UIImage imageNamed:@"icon_mine_coin_default"];
    self.coinIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.balanceView addSubview:self.coinIconView];
    
    // 余额数字（对齐安卓：字体32sp bold，颜色白色）
    self.balanceLabel = [[UILabel alloc] init];
    self.balanceLabel.text = @"0";
    self.balanceLabel.font = BOLD_FONT(FONT_SIZE_32);
    self.balanceLabel.textColor = [UIColor whiteColor];
    [self.balanceView addSubview:self.balanceLabel];
    
    [self.coinIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.balanceView.mas_centerX).offset(-40);
        make.top.equalTo(self.balanceView.mas_top);
        make.width.height.mas_equalTo(15); // 对齐安卓：50dp × 50dp
    }];
    
    // Coins标签（对齐安卓：文字颜色白色，字体16sp）
    UILabel *coinsTitleLabel = [[UILabel alloc] init];
    coinsTitleLabel.text = [NSString stringWithFormat:@"%@:", LocalString(@"Coins")];
    coinsTitleLabel.font = FONT(FONT_SIZE_16);
    coinsTitleLabel.textColor = [UIColor whiteColor];
    [self.balanceView addSubview:coinsTitleLabel];
    
    [coinsTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.coinIconView.mas_centerY);
        make.left.equalTo(self.coinIconView.mas_right).offset(4);
    }];
    
    [self.balanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.balanceView.mas_centerX);
        make.top.equalTo(coinsTitleLabel.mas_bottom).offset(17);
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
        make.top.equalTo(self.balanceView.mas_bottom).offset(30); // 对齐安卓：marginTop 30dp
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.buyButton.mas_top).offset(-20); // 对齐安卓：marginBottom 20dp
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
    
    if (!self.selectedItem) {
        self.selectedItem = self.rechargeList.firstObject;
    }
    
    // 对齐安卓：计算布局参数（paddingHorizontal 20dp，itemSpacing 15dp，3列）
    CGFloat screenWidth = SCREEN_WIDTH;
    CGFloat margin = 20; // 对齐安卓：paddingHorizontal 20dp
    CGFloat itemSpacing = 15; // 对齐安卓：itemSpacing 15dp
    NSInteger itemsPerRow = 3;
    CGFloat itemWidth = (screenWidth - margin * 2 - itemSpacing * (itemsPerRow - 1)) / itemsPerRow;
    CGFloat itemHeight = 120; // 对齐安卓：itemHeight 120dp
    
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
            make.top.equalTo(self.packagesContainerView).offset(20 + row * (itemHeight + 15)); // 对齐安卓：marginTop 20dp，rowSpacing 15dp
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
    
    // 更新容器高度（对齐安卓：marginTop 20dp，rowSpacing 15dp）
    NSInteger totalRows = (self.rechargeList.count + itemsPerRow - 1) / itemsPerRow;
    CGFloat containerHeight = 20 * 2 + totalRows * itemHeight + (totalRows - 1) * 15;
    
    [self.packagesContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(containerHeight);
    }];
    
    // 强制更新布局
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    // 更新选中状态，确保所有卡片初始状态正确（未选中，显示渐变背景）
    [self updateSelectedPackage];
    
    BUNNYX_LOG(@"套餐UI更新完成，容器高度: %.1f", containerHeight);
}

- (UIView *)createPackageViewWithItem:(RechargeItemModel *)item {
    // 对齐安卓：套餐卡片样式
    UIView *packageView = [[UIView alloc] init];
    packageView.layer.cornerRadius = 12; // 对齐安卓：圆角12dp
    packageView.layer.masksToBounds = YES;
    packageView.layer.borderWidth = 0; // 未选中时无边框
    
    // 未选中时添加渐变背景（从上到下：#1C3427到#091E1A）
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[
        (__bridge id)HEX_COLOR(0x1C3427).CGColor, // 顶部：#1C3427
        (__bridge id)HEX_COLOR(0x091E1A).CGColor   // 底部：#091E1A
    ];
    gradientLayer.startPoint = CGPointMake(0.5, 0);
    gradientLayer.endPoint = CGPointMake(0.5, 1);
    gradientLayer.cornerRadius = 12;
    [packageView.layer insertSublayer:gradientLayer atIndex:0];
    
    // 保存渐变层的引用，以便后续更新
    objc_setAssociatedObject(packageView, "gradientLayer", gradientLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 折扣标签（如果有）- 对齐安卓：粉色标签在左上角，圆角只设置左上和右下
    if (item.discountRemark && item.discountRemark.length > 0) {
        UIView *discountBadge = [[UIView alloc] init];
        discountBadge.backgroundColor = HEX_COLOR(0xFF6B9D); // 对齐安卓：粉色#FF6B9D
        [packageView addSubview:discountBadge];
        
        UILabel *discountLabel = [[UILabel alloc] init];
        discountLabel.text = item.discountRemark;
        discountLabel.font = BOLD_FONT(10); // 对齐安卓：10sp bold
        discountLabel.textColor = [UIColor whiteColor];
        discountLabel.textAlignment = NSTextAlignmentCenter;
        [discountBadge addSubview:discountLabel];
        
        [discountBadge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(packageView); // 对齐安卓：marginTop 0dp
            make.left.equalTo(packageView); // 对齐安卓：marginLeft 0dp
        }];
        
        [discountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(discountBadge).insets(UIEdgeInsetsMake(3, 8, 3, 8)); // 对齐安卓：padding
        }];
        
        // 使用UIBezierPath创建只有左上和右下圆角的mask
        // 需要在layout完成后设置，所以使用dispatch_async
        __weak UIView *weakBadge = discountBadge;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakBadge) {
                CGFloat cornerRadius = 12.0; // 对齐安卓：圆角6dp
                UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:weakBadge.bounds
                                                               byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomRight
                                                                     cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
                CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
                maskLayer.frame = weakBadge.bounds;
                maskLayer.path = maskPath.CGPath;
                weakBadge.layer.mask = maskLayer;
            }
        });
        
        // 保存badge引用以便在viewDidLayoutSubviews中更新mask
        objc_setAssociatedObject(discountBadge, "needsMaskUpdate", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    // 金币图标（对齐安卓：icon_mine_coin_default，居中偏上）
    UIImageView *coinIcon = [[UIImageView alloc] init];
    coinIcon.image = [UIImage imageNamed:@"icon_mine_coin_default"];
    coinIcon.contentMode = UIViewContentModeScaleAspectFit;
    [packageView addSubview:coinIcon];
    
    [coinIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(packageView);
        make.top.equalTo(packageView).offset(20); // 对齐安卓：marginTop 20dp
        make.width.height.mas_equalTo(28); // 对齐安卓：28dp × 28dp
    }];
    
    // 金币数量（对齐安卓：绿色大字体#0AE971，20sp bold，marginTop 10dp）
    UILabel *coinsLabel = [[UILabel alloc] init];
    coinsLabel.text = [NSString stringWithFormat:@"%ld", (long)item.buyNum];
    coinsLabel.font = BOLD_FONT(FONT_SIZE_20);
    coinsLabel.textColor = HEX_COLOR(0x0AE971); // 对齐安卓：#0AE971
    coinsLabel.textAlignment = NSTextAlignmentCenter;
    [packageView addSubview:coinsLabel];
    
    [coinsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(packageView);
        make.top.equalTo(coinIcon.mas_bottom).offset(10); // 对齐安卓：marginTop 10dp
        make.left.right.equalTo(packageView).insets(UIEdgeInsetsMake(0, 5, 0, 5));
    }];
    
    // 价格（对齐安卓：白色字体，14sp，marginBottom 15dp）
    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.text = [NSString stringWithFormat:@"$ %.2f", item.payMoney];
    priceLabel.font = FONT(FONT_SIZE_14);
    priceLabel.textColor = [UIColor whiteColor];
    priceLabel.textAlignment = NSTextAlignmentCenter;
    [packageView addSubview:priceLabel];
    
    [priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(packageView);
        make.bottom.equalTo(packageView).offset(-15); // 对齐安卓：marginBottom 15dp
        make.left.right.equalTo(packageView).insets(UIEdgeInsetsMake(0, 5, 0, 5));
    }];
    
    // 初始状态：未选中，显示渐变背景，无边框
    // 渐变层已在上面创建并添加到layer中
    
    return packageView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 更新所有套餐卡片的渐变层frame
    for (UIView *packageView in self.packageViews) {
        CAGradientLayer *gradientLayer = objc_getAssociatedObject(packageView, "gradientLayer");
        if (gradientLayer && [gradientLayer isKindOfClass:[CAGradientLayer class]]) {
            gradientLayer.frame = packageView.bounds;
        }
        
        // 更新折扣标签的圆角mask（只设置左上和右下）
        for (UIView *subview in packageView.subviews) {
            NSNumber *needsMaskUpdate = objc_getAssociatedObject(subview, "needsMaskUpdate");
            if (needsMaskUpdate && [needsMaskUpdate boolValue] && subview.bounds.size.width > 0 && subview.bounds.size.height > 0) {
                CGFloat cornerRadius = 12.0; // 对齐安卓：圆角6dp
                UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:subview.bounds
                                                               byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomRight
                                                                     cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
                CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
                maskLayer.frame = subview.bounds;
                maskLayer.path = maskPath.CGPath;
                subview.layer.mask = maskLayer;
            }
        }
    }
}

#pragma mark - Update UI

- (void)updateBalance {
    UserInfoManager *userManager = [UserInfoManager sharedManager];
    NSNumber *coins = [userManager getSurplusMxdDiamond];
    NSInteger coinsValue = coins ? [coins integerValue] : 0;
    self.balanceLabel.text = [NSString stringWithFormat:@"%ld", (long)coinsValue];
}

- (void)updateSelectedPackage {
    // 对齐安卓：更新所有套餐视图的选中状态
    for (NSInteger i = 0; i < self.packageViews.count; i++) {
        UIView *packageView = self.packageViews[i];
        CAGradientLayer *gradientLayer = objc_getAssociatedObject(packageView, "gradientLayer");
        
        // 确保渐变层始终显示并frame正确
        if (gradientLayer) {
            gradientLayer.hidden = NO;
            gradientLayer.frame = packageView.bounds;
        }
        packageView.backgroundColor = [UIColor clearColor]; // 清除纯色背景，使用渐变
        
        if (i < self.rechargeList.count) {
            RechargeItemModel *item = self.rechargeList[i];
            if (item == self.selectedItem) {
                // 选中状态：有边框，显示渐变背景
                packageView.layer.borderWidth = 2; // 对齐安卓：选中边框宽度2dp
                packageView.layer.borderColor = HEX_COLOR(0x0AE971).CGColor; // 对齐安卓：选中边框色#0AE971
            } else {
                // 未选中状态：无边框，显示渐变背景
                packageView.layer.borderWidth = 0; // 未选中时无边框
            }
        }
    }
}

#pragma mark - Actions

- (void)detailsButtonTapped:(UIButton *)sender {
    BUNNYX_LOG(@"Details按钮被点击");
    // 跳转到充值详情页面
    RechargeDetailsViewController *detailsVC = [[RechargeDetailsViewController alloc] init];
    [self.navigationController pushViewController:detailsVC animated:YES];
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
    [self startPurchaseWithItem:self.selectedItem];
}

#pragma mark - Purchase Flow

- (void)startPurchaseWithItem:(RechargeItemModel *)item {
    if (!self.applePayManager) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"支付服务未初始化")];
        return;
    }
    
    NSDictionary *params = @{ @"rechargeId": @(item.rechargeId) };
    [SVProgressHUD show];
    [[NetworkManager sharedManager] POST:BUNNYX_API_PAY_BUY_VIP
                              parameters:params
                                 success:^(id responseObject) {
        [SVProgressHUD dismiss];
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code != 0) {
            NSString *msg = responseObject[@"message"] ?: LocalString(@"充值失败");
            [SVProgressHUD showErrorWithStatus:msg];
            return;
        }
        
        NSDictionary *data = responseObject[@"data"];
        if (data) {
            NSString *productId = data[@"product_id"];
            NSString *orderSn = data[@"order_sn"];
            if (productId.length == 0 || orderSn.length == 0) {
                [SVProgressHUD showErrorWithStatus:LocalString(@"充值失败")];
                return;
            }
            self.currentServerOrderSn = orderSn;
            self.currentRechargeId = item.rechargeId;
            NSString *timestamp = [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
            [self launchApplePaymentWithProductId:productId orderId:orderSn timestamp:timestamp rechargeId:item.rechargeId];
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"充值失败")];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"充值失败")];
    }];
}

- (void)launchApplePaymentWithProductId:(NSString *)productId
                                 orderId:(NSString *)orderId
                               timestamp:(NSString *)timestamp
                              rechargeId:(NSInteger)rechargeId {
    [self.applePayManager purchaseProductWithId:productId orderId:orderId timestamp:timestamp];
}

- (void)verifyRechargePaymentWithTransaction:(SKPaymentTransaction *)transaction {
    if (!transaction) {
        return;
    }
    
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"充值失败")];
        return;
    }
    
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:0];
    NSDictionary *params = @{
        @"token": transaction.transactionIdentifier ?: @"",
        @"signture_data": @"",
        @"order_sn": self.currentServerOrderSn ?: @"",
        @"billingResponseCode": @(0),
        @"other_data": receiptString
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_PAY_APPLE_VERIFY
                              parameters:params
                                 success:^(id responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            [self.applePayManager finishTransaction:transaction];
            [SVProgressHUD showSuccessWithStatus:LocalString(@"充值成功")];
            [self refreshUserInfoAndBalance];
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"充值失败")];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"充值失败")];
    }];
}

- (void)refreshUserInfoAndBalance {
    [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateBalance];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateBalance];
        });
    }];
}

#pragma mark - ApplePayManagerDelegate

- (void)applePayManager:(ApplePayManager *)manager didPurchaseSuccessWithTransaction:(SKPaymentTransaction *)transaction productId:(NSString *)productId {
    [self verifyRechargePaymentWithTransaction:transaction];
}

- (void)applePayManager:(ApplePayManager *)manager didPurchaseFailWithError:(NSError *)error {
    NSString *message = error.localizedDescription.length > 0 ? error.localizedDescription : LocalString(@"充值失败");
    [SVProgressHUD showErrorWithStatus:message];
}

@end

