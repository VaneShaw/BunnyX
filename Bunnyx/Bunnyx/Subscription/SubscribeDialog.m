//
//  SubscribeDialog.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "SubscribeDialog.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "AppConfigManager.h"
#import "LanguageManager.h"
#import "UserInfoManager.h"
#import "UserInfoModel.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <StoreKit/StoreKit.h>

@interface SubscribeDialog () <ApplePayManagerDelegate>

@property (nonatomic, strong) SKPaymentTransaction *currentTransaction;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *dialogView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *countdownContainer;
@property (nonatomic, strong) UILabel *hourTensLabel;
@property (nonatomic, strong) UILabel *hourOnesLabel;
@property (nonatomic, strong) UILabel *minuteTensLabel;
@property (nonatomic, strong) UILabel *minuteOnesLabel;
@property (nonatomic, strong) UILabel *secondTensLabel;
@property (nonatomic, strong) UILabel *secondOnesLabel;
@property (nonatomic, strong) UIView *priceCardView;
@property (nonatomic, strong) UILabel *priceMainLabel;
@property (nonatomic, strong) UILabel *priceSubLabel;
@property (nonatomic, strong) UILabel *typeTitleLabel;
@property (nonatomic, strong) UILabel *typeSubLabel;
@property (nonatomic, strong) UILabel *bottomDescLabel;
@property (nonatomic, strong) UIButton *subscribeButton;
@property (nonatomic, strong) UIButton *thinkAboutItButton;

@property (nonatomic, assign) NSInteger remainingSeconds;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, copy) NSString *payMoney;
@property (nonatomic, copy) NSString *originalPrice;
@property (nonatomic, copy) NSString *typeRemark;
@property (nonatomic, assign) BOOL firstBuy;
@property (nonatomic, assign) NSInteger rechargeId;
@property (nonatomic, strong) ApplePayManager *applePayManager;
@property (nonatomic, copy) OnSubscribeListener onSubscribeListener;
@property (nonatomic, copy) NSString *currentServerOrderSn;

@end

@implementation SubscribeDialog

static const NSInteger COUNTDOWN_DURATION = 5400; // 1小时30分钟 = 5400秒

+ (void)showWithPayMoney:(NSString *)payMoney
           originalPrice:(NSString *)originalPrice
              typeRemark:(NSString *)typeRemark
                firstBuy:(BOOL)firstBuy
              rechargeId:(NSInteger)rechargeId
         applePayManager:(ApplePayManager *)applePayManager
             onSubscribe:(OnSubscribeListener)onSubscribe {
    
    SubscribeDialog *dialog = [[SubscribeDialog alloc] init];
    dialog.payMoney = payMoney;
    dialog.originalPrice = originalPrice;
    dialog.typeRemark = typeRemark;
    dialog.firstBuy = firstBuy;
    dialog.rechargeId = rechargeId;
    dialog.applePayManager = applePayManager;
    dialog.onSubscribeListener = onSubscribe;
    
    [dialog setupUI];
    [dialog show];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.remainingSeconds = COUNTDOWN_DURATION;
    }
    return self;
}

- (void)setupUI {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        return;
    }
    self.frame = window.bounds;
    [window addSubview:self];
    [window bringSubviewToFront:self];
    
    // 背景遮罩
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:self.backgroundView];
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [self.backgroundView addGestureRecognizer:tap];
    
    // 对话框
    self.dialogView = [[UIView alloc] init];
    self.dialogView.backgroundColor = [UIColor clearColor];
    self.dialogView.layer.cornerRadius = 20;
    self.dialogView.layer.masksToBounds = YES;
    // 背景图片（如果有）
    UIImage *bgImage = [UIImage imageNamed:@"bg_subscribe_topup"];
    if (bgImage) {
        self.backgroundImageView = [[UIImageView alloc] initWithImage:bgImage];
        self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
        self.backgroundImageView.clipsToBounds = YES;
        [self.dialogView addSubview:self.backgroundImageView];
        [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.dialogView);
        }];
    }
    [self addSubview:self.dialogView];
    [self.dialogView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.left.right.equalTo(self).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(500);
    }];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"限时优惠");
    self.titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    self.titleLabel.font = BOLD_FONT(23);
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.dialogView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.dialogView).offset(20);
        make.centerX.equalTo(self.dialogView);
    }];
    
    // 倒计时
    [self setupCountdown];
    
    // 价格卡片
    [self setupPriceCard];
    
    // 底部描述
    [self setupBottomDesc];
    
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
        (id)[UIColor colorWithRed:0.04 green:0.92 blue:0.44 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.11 green:0.70 blue:0.76 alpha:1.0].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 0);
    gradient.cornerRadius = 12;
    [self.subscribeButton.layer insertSublayer:gradient atIndex:0];
    [self.subscribeButton addTarget:self action:@selector(subscribeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.dialogView addSubview:self.subscribeButton];
    [self.subscribeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomDescLabel.mas_bottom).offset(20);
        make.left.right.equalTo(self.dialogView).insets(UIEdgeInsetsMake(0, 24, 0, 24));
        make.height.mas_equalTo(48);
    }];
    
    // 再想想按钮
    self.thinkAboutItButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.thinkAboutItButton setTitle:LocalString(@"我再想想") forState:UIControlStateNormal];
    [self.thinkAboutItButton setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
    self.thinkAboutItButton.titleLabel.font = FONT(17);
    [self.thinkAboutItButton addTarget:self action:@selector(thinkAboutItTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.dialogView addSubview:self.thinkAboutItButton];
    [self.thinkAboutItButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subscribeButton.mas_bottom).offset(16);
        make.centerX.equalTo(self.dialogView);
        make.bottom.equalTo(self.dialogView).offset(-16);
    }];
    
    // 更新价格和类型
    [self updatePriceAndType];
    [self updateFirstBuyDisplay];
}

- (void)setupCountdown {
    self.countdownContainer = [[UIView alloc] init];
    [self.dialogView addSubview:self.countdownContainer];
    [self.countdownContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
        make.centerX.equalTo(self.dialogView);
        make.height.mas_equalTo(45);
    }];
    
    // 小时十位
    self.hourTensLabel = [self createCountdownLabel];
    [self.countdownContainer addSubview:self.hourTensLabel];
    
    // 小时个位
    self.hourOnesLabel = [self createCountdownLabel];
    [self.countdownContainer addSubview:self.hourOnesLabel];
    
    // 冒号1
    UILabel *colon1 = [[UILabel alloc] init];
    colon1.text = @":";
    colon1.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    colon1.font = BOLD_FONT(30);
    [self.countdownContainer addSubview:colon1];
    
    // 分钟十位
    self.minuteTensLabel = [self createCountdownLabel];
    [self.countdownContainer addSubview:self.minuteTensLabel];
    
    // 分钟个位
    self.minuteOnesLabel = [self createCountdownLabel];
    [self.countdownContainer addSubview:self.minuteOnesLabel];
    
    // 冒号2
    UILabel *colon2 = [[UILabel alloc] init];
    colon2.text = @":";
    colon2.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    colon2.font = BOLD_FONT(30);
    [self.countdownContainer addSubview:colon2];
    
    // 秒十位
    self.secondTensLabel = [self createCountdownLabel];
    [self.countdownContainer addSubview:self.secondTensLabel];
    
    // 秒个位
    self.secondOnesLabel = [self createCountdownLabel];
    [self.countdownContainer addSubview:self.secondOnesLabel];
    
    // 布局
    [self.hourTensLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(self.countdownContainer);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(45);
    }];
    
    [self.hourOnesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.hourTensLabel.mas_right).offset(4);
        make.centerY.equalTo(self.countdownContainer);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(45);
    }];
    
    [colon1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.hourOnesLabel.mas_right).offset(5);
        make.centerY.equalTo(self.countdownContainer);
    }];
    
    [self.minuteTensLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(colon1.mas_right).offset(5);
        make.centerY.equalTo(self.countdownContainer);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(45);
    }];
    
    [self.minuteOnesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.minuteTensLabel.mas_right).offset(4);
        make.centerY.equalTo(self.countdownContainer);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(45);
    }];
    
    [colon2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.minuteOnesLabel.mas_right).offset(5);
        make.centerY.equalTo(self.countdownContainer);
    }];
    
    [self.secondTensLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(colon2.mas_right).offset(5);
        make.centerY.equalTo(self.countdownContainer);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(45);
    }];
    
    [self.secondOnesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.secondTensLabel.mas_right).offset(4);
        make.centerY.equalTo(self.countdownContainer);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(45);
        make.right.equalTo(self.countdownContainer);
    }];
}

- (UILabel *)createCountdownLabel {
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.13 alpha:1.0]; // #FFF621
    label.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    label.font = BOLD_FONT(30);
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 10;
    label.layer.masksToBounds = YES;
    label.text = @"0";
    return label;
}

- (void)setupPriceCard {
    self.priceCardView = [[UIView alloc] init];
    // 渐变背景
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.96 green:1.0 blue:0.80 alpha:1.0].CGColor, // #F4FFCB
        (id)[UIColor colorWithRed:0.74 green:1.0 blue:0.89 alpha:1.0].CGColor  // #BDFFE2
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 0);
    gradient.cornerRadius = 12;
    [self.priceCardView.layer insertSublayer:gradient atIndex:0];
    self.priceCardView.layer.cornerRadius = 12;
    self.priceCardView.layer.masksToBounds = YES;
    [self.dialogView addSubview:self.priceCardView];
    [self.priceCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.countdownContainer.mas_bottom).offset(24);
        make.left.right.equalTo(self.dialogView).insets(UIEdgeInsetsMake(0, 24, 0, 24));
        make.height.mas_equalTo(80);
    }];
    
    // 价格主标签
    UIView *priceContainer = [[UIView alloc] init];
    [self.priceCardView addSubview:priceContainer];
    
    UILabel *priceSymbol = [[UILabel alloc] init];
    priceSymbol.text = @"$";
    priceSymbol.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    priceSymbol.font = BOLD_FONT(20);
    [priceContainer addSubview:priceSymbol];
    
    self.priceMainLabel = [[UILabel alloc] init];
    self.priceMainLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    self.priceMainLabel.font = BOLD_FONT(26);
    [priceContainer addSubview:self.priceMainLabel];
    
    self.priceSubLabel = [[UILabel alloc] init];
    self.priceSubLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.priceSubLabel.font = FONT(14);
    [priceContainer addSubview:self.priceSubLabel];
    
    [priceSymbol mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(priceContainer);
    }];
    
    [self.priceMainLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(priceSymbol.mas_right).offset(2);
        make.top.equalTo(priceContainer);
    }];
    
    [self.priceSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(priceContainer);
        make.top.equalTo(self.priceMainLabel.mas_bottom).offset(4);
    }];
    
    [priceContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.priceCardView).offset(16);
        make.centerY.equalTo(self.priceCardView);
    }];
    
    // 类型标签
    UIView *typeContainer = [[UIView alloc] init];
    [self.priceCardView addSubview:typeContainer];
    
    self.typeTitleLabel = [[UILabel alloc] init];
    self.typeTitleLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    self.typeTitleLabel.font = BOLD_FONT(26);
    [typeContainer addSubview:self.typeTitleLabel];
    
    self.typeSubLabel = [[UILabel alloc] init];
    self.typeSubLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.typeSubLabel.font = FONT(14);
    [typeContainer addSubview:self.typeSubLabel];
    
    [self.typeTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(typeContainer);
    }];
    
    [self.typeSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.typeTitleLabel.mas_bottom).offset(4);
        make.right.equalTo(typeContainer);
    }];
    
    [typeContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.priceCardView).offset(-16);
        make.centerY.equalTo(self.priceCardView);
    }];
}

- (void)setupBottomDesc {
    self.bottomDescLabel = [[UILabel alloc] init];
    self.bottomDescLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.bottomDescLabel.font = FONT(11);
    self.bottomDescLabel.numberOfLines = 0;
    self.bottomDescLabel.textAlignment = NSTextAlignmentCenter;
    [self.dialogView addSubview:self.bottomDescLabel];
    [self.bottomDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.priceCardView.mas_bottom).offset(20);
        make.left.right.equalTo(self.dialogView).insets(UIEdgeInsetsMake(0, 24, 0, 24));
    }];
    
    [self applyBottomDescText:LocalString(@"订阅提示默认")];
    // 加载VIP折扣提示
    [self loadVipDiscountTips];
}

- (void)loadVipDiscountTips {
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    if (config && config.vipDiscountTips && config.vipDiscountTips.length > 0) {
        // 解析JSON
        NSData *jsonData = [config.vipDiscountTips dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSError *error = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            if (!error && [dict isKindOfClass:[NSDictionary class]]) {
                NSString *langCode = [[LanguageManager sharedManager] currentLanguageCode];
                NSString *text = nil;
                if (dict[langCode]) {
                    text = dict[langCode];
                } else if ([langCode hasPrefix:@"zh"] && dict[@"zh_CN"]) {
                    text = dict[@"zh_CN"];
                } else if (dict[@"en_US"]) {
                    text = dict[@"en_US"];
                }
                if (text) {
                    [self applyBottomDescText:text];
                    return;
                }
            }
        }
    }
    // 默认文案
    [self applyBottomDescText:LocalString(@"订阅提示默认")];
}

- (void)applyBottomDescText:(NSString *)text {
    if (!self.bottomDescLabel) {
        return;
    }
    NSString *displayText = (text.length > 0) ? text : LocalString(@"订阅提示默认");
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    style.lineSpacing = 4.0;
    NSDictionary *attributes = @{
        NSFontAttributeName: self.bottomDescLabel.font ?: FONT(11),
        NSForegroundColorAttributeName: self.bottomDescLabel.textColor ?: [UIColor colorWithWhite:0.6 alpha:1.0],
        NSParagraphStyleAttributeName: style
    };
    self.bottomDescLabel.attributedText = [[NSAttributedString alloc] initWithString:displayText attributes:attributes];
}

- (void)updatePriceAndType {
    if (self.payMoney) {
        self.priceMainLabel.text = self.payMoney;
    }
    if (self.originalPrice) {
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"$%@", self.originalPrice]];
        [attrStr addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, attrStr.length)];
        self.priceSubLabel.attributedText = attrStr;
    }
    if (self.typeRemark) {
        self.typeSubLabel.text = self.typeRemark;
    }
}

- (void)updateFirstBuyDisplay {
    if (self.firstBuy) {
        self.typeTitleLabel.text = LocalString(@"首年");
        self.typeTitleLabel.hidden = NO;
    } else {
        self.typeTitleLabel.hidden = YES;
    }
}

- (void)show {
    self.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
    [self startCountdown];
}

- (void)dismiss {
    [self stopCountdown];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)startCountdown {
    self.remainingSeconds = COUNTDOWN_DURATION;
    [self updateCountdownDisplay];
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdownTick) userInfo:nil repeats:YES];
}

- (void)stopCountdown {
    if (self.countdownTimer) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
    }
}

- (void)countdownTick {
    if (self.remainingSeconds > 0) {
        self.remainingSeconds--;
        [self updateCountdownDisplay];
    } else {
        [self stopCountdown];
        [self dismiss];
    }
}

- (void)updateCountdownDisplay {
    NSInteger hours = self.remainingSeconds / 3600;
    NSInteger minutes = (self.remainingSeconds % 3600) / 60;
    NSInteger seconds = self.remainingSeconds % 60;
    
    self.hourTensLabel.text = [NSString stringWithFormat:@"%ld", hours / 10];
    self.hourOnesLabel.text = [NSString stringWithFormat:@"%ld", hours % 10];
    self.minuteTensLabel.text = [NSString stringWithFormat:@"%ld", minutes / 10];
    self.minuteOnesLabel.text = [NSString stringWithFormat:@"%ld", minutes % 10];
    self.secondTensLabel.text = [NSString stringWithFormat:@"%ld", seconds / 10];
    self.secondOnesLabel.text = [NSString stringWithFormat:@"%ld", seconds % 10];
}

- (void)subscribeButtonTapped:(UIButton *)sender {
    if (!self.applePayManager || self.rechargeId <= 0) {
        if (self.onSubscribeListener) {
            self.onSubscribeListener();
        }
        return;
    }
    [self createVipOrderAndPay];
}

- (void)thinkAboutItTapped:(UIButton *)sender {
    [self dismiss];
}

- (void)createVipOrderAndPay {
    NSDictionary *params = @{ @"rechargeId": @(self.rechargeId) };
    [SVProgressHUD show];
    [[NetworkManager sharedManager] POST:BUNNYX_API_PAY_BUY_VIP
                              parameters:params
                                 success:^(id responseObject) {
        [SVProgressHUD dismiss];
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code != 0) {
            NSString *msg = responseObject[@"message"] ?: LocalString(@"订阅失败");
            [SVProgressHUD showErrorWithStatus:msg];
            return;
        }
        
        NSDictionary *data = responseObject[@"data"];
        if (data) {
            NSString *productId = data[@"product_id"];
            NSString *orderSn = data[@"order_sn"];
            if (productId && productId.length > 0 && orderSn && orderSn.length > 0) {
                self.currentServerOrderSn = orderSn;
                NSString *timestamp = [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
                [self startPurchase:productId orderId:orderSn timestamp:timestamp];
            } else {
                [SVProgressHUD showErrorWithStatus:LocalString(@"订阅失败")];
            }
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"订阅失败")];
    }];
}

- (void)startPurchase:(NSString *)productId orderId:(NSString *)orderId timestamp:(NSString *)timestamp {
    // 设置代理
    self.applePayManager.delegate = self;
    [self.applePayManager purchaseProductWithId:productId orderId:orderId timestamp:timestamp];
}

#pragma mark - ApplePayManagerDelegate

- (void)applePayManager:(ApplePayManager *)manager didPurchaseSuccessWithTransaction:(SKPaymentTransaction *)transaction productId:(NSString *)productId {
    self.currentTransaction = transaction;
    [self verifyPayment:transaction];
}

- (void)applePayManager:(ApplePayManager *)manager didPurchaseFailWithError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: LocalString(@"订阅失败")];
}

- (void)verifyPayment:(SKPaymentTransaction *)transaction {
    if (!transaction) return;
    
    // 获取收据
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    
    if (!receiptData) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"订阅失败")];
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
            // 验证通过，完成交易
            [self.applePayManager finishTransaction:transaction];
            [SVProgressHUD showSuccessWithStatus:LocalString(@"订阅成功")];
            [self dismiss];
            // 刷新用户信息
            [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
                // 刷新完成
            } failure:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"订阅失败")];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"订阅失败")];
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 更新渐变层frame
    for (CALayer *layer in self.subscribeButton.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.subscribeButton.bounds;
        }
    }
    for (CALayer *layer in self.priceCardView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.priceCardView.bounds;
        }
    }
}

- (void)dealloc {
    [self stopCountdown];
}

@end

