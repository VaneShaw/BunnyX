//
//  SubscriptionViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "SubscriptionViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "VipListDataModel.h"
#import "VipItemModel.h"
#import "SubscribeVipCell.h"
#import "UserInfoManager.h"
#import "AppConfigManager.h"
#import "PaymentOrderCacheManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "SubscribeDialog.h"
#import "ApplePayManager.h"
#import "BrowserViewController.h"
#import "LanguageManager.h"
#import <StoreKit/StoreKit.h>

@interface SubscriptionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SubscribeVipCellDelegate, ApplePayManagerDelegate>

// UI组件
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *privilegeContainerView;
@property (nonatomic, strong) UILabel *privilege1Label;
@property (nonatomic, strong) UILabel *privilege2Label;
@property (nonatomic, strong) UILabel *privilege3Label;
@property (nonatomic, strong) UILabel *privilege4Label;
@property (nonatomic, strong) UILabel *privilege5Label;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *subscribeButton;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIView *linksContainerView;
@property (nonatomic, strong) UIButton *privacyPolicyButton;
@property (nonatomic, strong) UIButton *userAgreementButton;
@property (nonatomic, strong) UIButton *subscriptionAgreementButton;

// 数据
@property (nonatomic, strong) VipListDataModel *vipData;
@property (nonatomic, strong) NSArray<VipItemModel *> *vipItems;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) ApplePayManager *applePayManager;
@property (nonatomic, copy) NSString *currentServerOrderSn;
@property (nonatomic, assign) NSInteger currentRechargeId;

// 弹窗标记（本次app启动是否已弹过）
@property (nonatomic, assign) BOOL hasShownDialogThisSession;

@end

@implementation SubscriptionViewController

+ (void)resetSessionDialogFlag {
    // 在AppDelegate启动时调用此方法重置标记
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SubscribeHasShownDialogThisSession"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.selectedIndex = 0;
    self.hasShownDialogThisSession = [[NSUserDefaults standardUserDefaults] boolForKey:@"SubscribeHasShownDialogThisSession"];
    
    [self setupUI];
    [self setupApplePay];
    [self loadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.showBackButton = NO;
}

- (void)setupUI {
    // ScrollView
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // ContentView
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"订阅标题");
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = BOLD_FONT(28);
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(STATUS_BAR_HEIGHT+NAVIGATION_BAR_HEIGHT);
        make.left.equalTo(self.contentView).offset(20);
        make.height.mas_equalTo(40);
    }];
    
    // 特权容器
    self.privilegeContainerView = [[UIView alloc] init];
    self.privilegeContainerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05];
    self.privilegeContainerView.layer.cornerRadius = 15;
    self.privilegeContainerView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.privilegeContainerView];
    [self.privilegeContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(30);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    
    // 特权项
    [self setupPrivilegeItems];
    
    // CollectionView
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[SubscribeVipCell class] forCellWithReuseIdentifier:@"SubscribeVipCell"];
    [self.contentView addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.privilegeContainerView.mas_bottom).offset(16);
        make.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(200);
    }];
    
    // 订阅按钮
    self.subscribeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.subscribeButton setTitle:LocalString(@"订阅按钮") forState:UIControlStateNormal];
    [self.subscribeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.subscribeButton.titleLabel.font = BOLD_FONT(16);
    self.subscribeButton.layer.cornerRadius = 12;
    self.subscribeButton.layer.masksToBounds = YES;
    // 渐变背景
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.04 green:0.92 blue:0.44 alpha:1.0].CGColor, // #0AEA6F
        (id)[UIColor colorWithRed:0.11 green:0.70 blue:0.76 alpha:1.0].CGColor  // #1CB3C1
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 0);
    gradient.cornerRadius = 12;
    [self.subscribeButton.layer insertSublayer:gradient atIndex:0];
    [self.subscribeButton addTarget:self action:@selector(subscribeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.subscribeButton];
    [self.subscribeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.collectionView.mas_bottom).offset(30);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(48);
    }];
    
    // 提示文字
    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.text = LocalString(@"订阅提示默认");
    self.tipsLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.tipsLabel.font = FONT(11);
    self.tipsLabel.numberOfLines = 0;
    self.tipsLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.tipsLabel];
    [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subscribeButton.mas_bottom).offset(20);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    
    // 底部链接
    [self setupBottomLinks];
    
    // 设置contentView底部约束
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.linksContainerView.mas_bottom).offset(20);
    }];
}

- (void)setupPrivilegeItems {
    NSArray *privilegeTexts = @[
        LocalString(@"免费金币"),  // 会动态更新
        LocalString(@"快速生成"),
        LocalString(@"解锁高级模型"),
        LocalString(@"高质量生成"),
        LocalString(@"双倍签到奖励")
    ];
    
    NSArray *labels = @[
        self.privilege1Label = [[UILabel alloc] init],
        self.privilege2Label = [[UILabel alloc] init],
        self.privilege3Label = [[UILabel alloc] init],
        self.privilege4Label = [[UILabel alloc] init],
        self.privilege5Label = [[UILabel alloc] init]
    ];
    
    UIImage *iconImage = [UIImage imageNamed:@"tabbar_subscribe_right"];
    if (!iconImage) {
        // 如果没有图片，使用系统图标
        iconImage = [UIImage systemImageNamed:@"checkmark.circle.fill"];
    }
    
    UIView *lastView = nil;
    for (NSInteger i = 0; i < labels.count; i++) {
        UILabel *label = labels[i];
        label.text = privilegeTexts[i];
        label.textColor = [UIColor whiteColor];
        label.font = FONT(15);
        
        UIImageView *iconView = [[UIImageView alloc] initWithImage:iconImage];
        iconView.tintColor = [UIColor whiteColor];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        
        UIView *itemView = [[UIView alloc] init];
        [itemView addSubview:iconView];
        [itemView addSubview:label];
        [self.privilegeContainerView addSubview:itemView];
        
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(itemView).offset(16);
            make.centerY.equalTo(itemView);
            make.width.height.mas_equalTo(20);
        }];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconView.mas_right).offset(12);
            make.right.equalTo(itemView).offset(-16);
            make.top.bottom.equalTo(itemView).insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
        
        [itemView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.privilegeContainerView);
            if (lastView) {
                make.top.equalTo(lastView.mas_bottom);
            } else {
                make.top.equalTo(self.privilegeContainerView).offset(16);
            }
            make.height.mas_equalTo(30);
            if (i == labels.count - 1) {
                make.bottom.equalTo(self.privilegeContainerView).offset(-16);
            }
        }];
        
        lastView = itemView;
    }
}

- (void)setupBottomLinks {
    self.linksContainerView = [[UIView alloc] init];
    [self.contentView addSubview:self.linksContainerView];
    [self.linksContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipsLabel.mas_bottom).offset(20);
        make.centerX.equalTo(self.contentView);
        make.height.mas_equalTo(20);
    }];
    
    self.privacyPolicyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.privacyPolicyButton setTitle:LocalString(@"隐私政策") forState:UIControlStateNormal];
    [self.privacyPolicyButton setTitleColor:[UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
    self.privacyPolicyButton.titleLabel.font = FONT(12);
    [self.privacyPolicyButton addTarget:self action:@selector(privacyPolicyTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.linksContainerView addSubview:self.privacyPolicyButton];
    
    UIView *separator1 = [[UIView alloc] init];
    separator1.backgroundColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    [self.linksContainerView addSubview:separator1];
    
    self.userAgreementButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.userAgreementButton setTitle:LocalString(@"用户协议") forState:UIControlStateNormal];
    [self.userAgreementButton setTitleColor:[UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
    self.userAgreementButton.titleLabel.font = FONT(12);
    [self.userAgreementButton addTarget:self action:@selector(userAgreementTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.linksContainerView addSubview:self.userAgreementButton];
    
    UIView *separator2 = [[UIView alloc] init];
    separator2.backgroundColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    [self.linksContainerView addSubview:separator2];
    
    self.subscriptionAgreementButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.subscriptionAgreementButton setTitle:LocalString(@"订阅协议") forState:UIControlStateNormal];
    [self.subscriptionAgreementButton setTitleColor:[UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
    self.subscriptionAgreementButton.titleLabel.font = FONT(11);
    [self.subscriptionAgreementButton addTarget:self action:@selector(subscriptionAgreementTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.linksContainerView addSubview:self.subscriptionAgreementButton];
    
    [self.privacyPolicyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(self.linksContainerView);
    }];
    
    [separator1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.privacyPolicyButton.mas_right).offset(6);
        make.centerY.equalTo(self.linksContainerView);
        make.width.mas_equalTo(1);
        make.height.mas_equalTo(12);
    }];
    
    [self.userAgreementButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(separator1.mas_right).offset(6);
        make.centerY.equalTo(self.linksContainerView);
    }];
    
    [separator2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.userAgreementButton.mas_right).offset(6);
        make.centerY.equalTo(self.linksContainerView);
        make.width.mas_equalTo(1);
        make.height.mas_equalTo(12);
    }];
    
    [self.subscriptionAgreementButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(separator2.mas_right).offset(6);
        make.right.centerY.equalTo(self.linksContainerView);
    }];
}

- (void)setupApplePay {
    self.applePayManager = [ApplePayManager sharedManager];
    [self.applePayManager initializeWithDelegate:self];
}

- (void)loadData {
    [self loadSubscribeTips];
    [self loadVipList];
}

- (void)loadSubscribeTips {
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    if ([self updateSubscribeTipsWithConfig:config]) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [[AppConfigManager sharedManager] getAppConfigWithSuccess:^(AppConfigModel *configModel) {
        if (![weakSelf updateSubscribeTipsWithConfig:configModel]) {
            [weakSelf setDefaultSubscribeTips];
        }
    } failure:^(NSError *error) {
        [weakSelf setDefaultSubscribeTips];
    }];
}

- (BOOL)updateSubscribeTipsWithConfig:(AppConfigModel *)config {
    if (config && config.subscribeVipTips && config.subscribeVipTips.length > 0) {
        self.tipsLabel.text = config.subscribeVipTips;
        return YES;
    }
    return NO;
}

- (void)setDefaultSubscribeTips {
    self.tipsLabel.text = LocalString(@"订阅提示默认");
}

- (void)loadVipList {
    NSDictionary *params = @{ @"paymentCode": @"applePay" };
    [[NetworkManager sharedManager] GET:BUNNYX_API_PAY_VIP_LIST
                              parameters:params
                                 success:^(id responseObject) {
        NSDictionary *data = responseObject[@"data"];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            self.vipData = [VipListDataModel modelFromResponse:data];
            if (self.vipData && self.vipData.list) {
                self.vipItems = self.vipData.list;
                [self.collectionView reloadData];
                // 首次加载时，自动设置第一个item的值到privilege1
                if (self.vipItems.count > 0) {
                    [self updatePrivilege1Text:self.vipItems[0]];
                }
            }
            // 检查是否需要弹出限时优惠弹窗
            [self checkAndShowFirstBuyDialog];
        }
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"加载VIP列表失败: %@", error);
    }];
}

- (void)checkAndShowFirstBuyDialog {
    // 如果本次app启动已经弹过弹窗，不再弹出
    if (self.hasShownDialogThisSession) {
        return;
    }
    
    // 检查用户是否是VIP，如果是VIP就不弹窗
    if ([[UserInfoManager sharedManager] isVip]) {
        return;
    }
    
    // 检查是否是首次进入且firstBuy为true
    if (self.vipData && self.vipData.firstBuy && self.vipItems.count > 0) {
        // 优先选择Year套餐
        VipItemModel *selectedItem = nil;
        for (VipItemModel *item in self.vipItems) {
            if (item.typeRemark && [item.typeRemark isEqualToString:@"Year"]) {
                selectedItem = item;
                break;
            }
        }
        if (!selectedItem) {
            selectedItem = self.vipItems[0];
        }
        
        // 弹出限时优惠弹窗
        [SubscribeDialog showWithPayMoney:[NSString stringWithFormat:@"%.2f", selectedItem.payMoney]
                            originalPrice:selectedItem.originalPrice ? [NSString stringWithFormat:@"%.2f", [selectedItem.originalPrice doubleValue]] : nil
                                typeRemark:selectedItem.typeRemark
                                 firstBuy:self.vipData.firstBuy
                               rechargeId:selectedItem.rechargeId
                        applePayManager:self.applePayManager
                        onSubscribe:^{
            // 已在弹窗内处理支付流程
        }];
        
        // 标记本次app启动已弹过弹窗
        self.hasShownDialogThisSession = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SubscribeHasShownDialogThisSession"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)updatePrivilege1Text:(VipItemModel *)item {
    if (!item || !self.privilege1Label) {
        return;
    }
    NSInteger give = item.giveMxdNum;
    NSString *typeRemark = item.typeRemark ?: @"";
    self.privilege1Label.text = [NSString stringWithFormat:LocalString(@"每%@免费%ld金币"), typeRemark, (long)give];
}

#pragma mark - Actions

- (void)subscribeButtonTapped:(UIButton *)sender {
    VipItemModel *selected = nil;
    if (self.selectedIndex >= 0 && self.selectedIndex < self.vipItems.count) {
        selected = self.vipItems[self.selectedIndex];
    } else if (self.vipItems.count > 0) {
        selected = self.vipItems[0];
    }
    
    if (!selected) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"请选择订阅套餐")];
        return;
    }
    
    // 直接调起支付流程
    [self startDirectPayment:selected];
}

- (void)startDirectPayment:(VipItemModel *)selectedItem {
    if (!self.applePayManager) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"支付服务未初始化")];
        return;
    }
    
    // 创建VIP订单
    NSDictionary *params = @{ @"rechargeId": @(selectedItem.rechargeId) };
    [SVProgressHUD show];
    [[NetworkManager sharedManager] POST:BUNNYX_API_PAY_BUY_VIP
                              parameters:params
                                 success:^(id responseObject) {
        [SVProgressHUD dismiss];
        // NetworkManager已经在基类中处理了code != 0的情况并显示错误信息，这里不需要重复处理
        NSDictionary *data = responseObject[@"data"];
        if (data) {
            NSString *productId = data[@"product_id"];
            NSString *orderSn = data[@"order_sn"];
            if (productId && productId.length > 0 && orderSn && orderSn.length > 0) {
                self.currentServerOrderSn = orderSn;
                self.currentRechargeId = selectedItem.rechargeId;
                NSString *timestamp = [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
                // 调起Apple支付
                [self launchApplePayment:productId orderId:orderSn timestamp:timestamp rechargeId:selectedItem.rechargeId];
            } else {
                [SVProgressHUD showErrorWithStatus:LocalString(@"订阅失败")];
            }
        }
    } failure:^(NSError *error) {
        // NetworkManager已经在基类中自动显示错误信息，这里不需要重复显示
    }];
}

- (void)launchApplePayment:(NSString *)productId orderId:(NSString *)orderId timestamp:(NSString *)timestamp rechargeId:(NSInteger)rechargeId {
    [self.applePayManager purchaseProductWithId:productId orderId:orderId timestamp:timestamp];
}

- (void)privacyPolicyTapped:(UIButton *)sender {
    [self openBrowserWithConfigKey:@"privacy_policy_url"];
}

- (void)userAgreementTapped:(UIButton *)sender {
    [self openBrowserWithConfigKey:@"user_agreement_url"];
}

- (void)subscriptionAgreementTapped:(UIButton *)sender {
    [self openBrowserWithConfigKey:@"purchase_agreement_url"];
}

- (void)openBrowserWithConfigKey:(NSString *)configKey {
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    NSString *url = nil;
    
    // 根据configKey获取对应的URL
    if ([configKey isEqualToString:@"privacy_policy_url"]) {
        url = config.privacyPolicyUrl;
    } else if ([configKey isEqualToString:@"user_agreement_url"]) {
        url = config.userAgreementUrl;
    } else if ([configKey isEqualToString:@"purchase_agreement_url"]) {
        url = config.purchaseAgreementUrl;
    }
    
    if (url && url.length > 0) {
        BrowserViewController *browser = [[BrowserViewController alloc] initWithURL:url];
        browser.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:browser animated:YES];
    } else {
        [SVProgressHUD showErrorWithStatus:LocalString(@"链接获取失败")];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.vipItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SubscribeVipCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SubscribeVipCell" forIndexPath:indexPath];
    VipItemModel *item = self.vipItems[indexPath.item];
    [cell configureWithVipItem:item selected:(indexPath.item == self.selectedIndex)];
    cell.delegate = self;
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (self.view.bounds.size.width - 40 - 10) / 2.0;
    return CGSizeMake(width, 120);
}

#pragma mark - SubscribeVipCellDelegate

- (void)subscribeVipCell:(SubscribeVipCell *)cell didSelectItem:(VipItemModel *)item {
    NSInteger index = [self.vipItems indexOfObject:item];
    if (index != NSNotFound) {
        self.selectedIndex = index;
        [self.collectionView reloadData];
        // 更新权益1文本
        [self updatePrivilege1Text:item];
    }
}

#pragma mark - ApplePayManagerDelegate

- (void)applePayManager:(ApplePayManager *)manager didPurchaseSuccessWithTransaction:(SKPaymentTransaction *)transaction productId:(NSString *)productId {
    // ApplePayManager 已经在内部验证了收据，这里只需要完成交易和刷新用户信息
    // 完成交易（消耗型商品需要调用此方法）
    [self.applePayManager finishTransaction:transaction];
    
    // 显示成功提示
    [SVProgressHUD showSuccessWithStatus:LocalString(@"订阅成功")];
    
    // 刷新用户信息
    [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
        // 刷新完成
    } failure:nil];
    
    // 清除缓存的订单信息（如果存在）
    if (transaction.transactionIdentifier) {
        [[PaymentOrderCacheManager sharedManager] clearPendingOrderForTransactionId:transaction.transactionIdentifier];
    }
}

- (void)applePayManager:(ApplePayManager *)manager didPurchaseFailWithError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: LocalString(@"订阅失败")];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 更新订阅按钮渐变层frame
    for (CALayer *layer in self.subscribeButton.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.subscribeButton.bounds;
        }
    }
}

@end
