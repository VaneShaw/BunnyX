//
//  LoginViewController.m
//  Bunnyx
//
//  Created by fengwenxiao on 2024/11/30.
//

#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "AccountLoginViewController.h"
#import "UserManager.h"
#import "UserInfoManager.h"
#import "AppConfigManager.h"
#import "DeviceIdentifierManager.h"
#import "NetworkManager.h"
#import "GradientButton.h"
#import "LanguageManager.h"
#import "BrowserViewController.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "AdMobManager.h"
#import <AuthenticationServices/AuthenticationServices.h>


@interface LoginViewController () <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) GradientButton *quickLoginButton; // 使用GradientButton类型
@property (nonatomic, strong) UIButton *appleLoginButton;
@property (nonatomic, strong) UIButton *accountLoginButton;
@property (nonatomic, strong) UIButton *agreementCheckbox;
@property (nonatomic, strong) UILabel *agreementLabel;
@property (nonatomic, assign) BOOL isAgreedToTerms; // 是否同意用户协议和隐私政策
@property (nonatomic, strong) UITapGestureRecognizer *agreementTapGesture; // 协议文字点击手势

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self addObservers];
}

- (void)dealloc {
    [self removeObservers];
}

- (void)setupUI {
    // 设置背景
    [self setupBackground];
    
    // 设置Logo和应用名称
    [self setupLogo];
    
    // 设置登录按钮
    [self setupLoginButtons];
    
    // 设置用户协议
    [self setupAgreement];
    
    // 设置约束
    [self setupConstraints];
}

- (void)setupBackground {
    self.view.backgroundColor = [UIColor blackColor];
    
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.image = [UIImage imageNamed:@"bg_login"];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];
}

- (void)setupLogo {
    // 200dp x 160dp
    self.logoImageView = [[UIImageView alloc] init];
    self.logoImageView.image = [UIImage imageNamed:@"icon_login_logo"];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.logoImageView];
}

- (void)setupLoginButtons {
    // 快速登录按钮（渐变背景 #0AEA6F -> #1CB3C1，圆角12dp，高度48dp）
    self.quickLoginButton = [GradientButton buttonWithTitle:LocalString(@"快速登录")
                                                   startColor:[UIColor colorWithRed:0x0A/255.0 green:0xEA/255.0 blue:0x6F/255.0 alpha:1.0]  // #0AEA6F
                                                     endColor:[UIColor colorWithRed:0x1C/255.0 green:0xB3/255.0 blue:0xC1/255.0 alpha:1.0]]; // #1CB3C1
    [self.quickLoginButton setTitleColor:[UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1.0] forState:UIControlStateNormal]; // #333333
    self.quickLoginButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.quickLoginButton.cornerRadius = 12.0; // 使用GradientButton的cornerRadius属性
    // buttonHeight已在约束中设置，不需要单独设置
    // 图标尺寸22dp，图标和文字间距12dp
    UIImageView *quickIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_login_quick"]];
    quickIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.quickLoginButton addSubview:quickIcon];
    [quickIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.quickLoginButton).offset(16); // paddingHorizontal 16dp
        make.centerY.equalTo(self.quickLoginButton);
        make.width.height.mas_equalTo(22);
    }];
    // 文字居中（gravity="center"）
    self.quickLoginButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.quickLoginButton addTarget:self action:@selector(quickLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.quickLoginButton];
    
    // Google登录按钮（背景色#1B2A3C，圆角12dp，高度48dp）
    self.appleLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.appleLoginButton setTitle:LocalString(@"使用 Apple 登录") forState:UIControlStateNormal];
    [self.appleLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appleLoginButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.appleLoginButton.backgroundColor = [UIColor colorWithRed:0x1B/255.0 green:0x2A/255.0 blue:0x3C/255.0 alpha:1.0]; // #1B2A3C
    self.appleLoginButton.layer.cornerRadius = 12.0;
    self.appleLoginButton.layer.masksToBounds = YES;
    // 图标尺寸22dp，图标和文字间距12dp
    UIImageView *googleIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_login_apple"]];
    googleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.appleLoginButton addSubview:googleIcon];
    [googleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.appleLoginButton).offset(16); // paddingHorizontal 16dp
        make.centerY.equalTo(self.appleLoginButton);
        make.width.height.mas_equalTo(22);
    }];
    // 文字居中（gravity="center"）
    self.appleLoginButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.appleLoginButton addTarget:self action:@selector(appleLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.appleLoginButton];
    
    // 账号登录按钮（背景色white，圆角12dp，高度48dp）
    self.accountLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.accountLoginButton setTitle:LocalString(@"账号密码登录") forState:UIControlStateNormal];
    [self.accountLoginButton setTitleColor:[UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1.0] forState:UIControlStateNormal]; // #333333
    self.accountLoginButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.accountLoginButton.backgroundColor = [UIColor whiteColor];
    self.accountLoginButton.layer.cornerRadius = 12.0;
    self.accountLoginButton.layer.masksToBounds = YES;
    // 图标尺寸20dp，图标和文字间距12dp
    UIImageView *accountIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_login_account"]];
    accountIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.accountLoginButton addSubview:accountIcon];
    [accountIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.accountLoginButton).offset(16); // paddingHorizontal 16dp
        make.centerY.equalTo(self.accountLoginButton);
        make.width.height.mas_equalTo(20);
    }];
    // 文字居中（gravity="center"）
    self.accountLoginButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.accountLoginButton addTarget:self action:@selector(accountLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.accountLoginButton];
}

- (void)setupAgreement {
    // 复选框18dp x 18dp，文字12sp，复选框和文字间距8dp
    self.agreementCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.agreementCheckbox setImage:[UIImage imageNamed:@"icon_login_bottom_box_default"] forState:UIControlStateNormal];
    [self.agreementCheckbox setImage:[UIImage imageNamed:@"icon_login_bottom_box_selected"] forState:UIControlStateSelected];
    [self.agreementCheckbox addTarget:self action:@selector(agreementCheckboxTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.agreementCheckbox];
    
    // 协议文字分为多个部分，支持点击
    self.agreementLabel = [[UILabel alloc] init];
    self.agreementLabel.textColor = [UIColor colorWithRed:0x99/255.0 green:0xFF/255.0 blue:0xFF/255.0 alpha:1.0]; // #99FFFFFF
    self.agreementLabel.font = [UIFont systemFontOfSize:12];
    self.agreementLabel.numberOfLines = 0; // 允许多行显示
    self.agreementLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.agreementLabel];
    
    // 设置协议文本中的链接样式
    [self setupAgreementText];
}

- (void)setupAgreementText {
    // 协议文字分为前缀、用户协议、和、隐私政策
    NSString *prefix = LocalString(@"如果你登录，即表示你同意用");
    NSString *userAgreement = LocalString(@"用户协议");
    NSString *and = LocalString(@"和");
    NSString *privacyPolicy = LocalString(@"隐私政策");
    
    // 在英文环境下，将 "User Agreement" 和 "Privacy Policy" 中的空格替换为 non-breaking space，防止单词被拆分
    LanguageManager *langManager = [LanguageManager sharedManager];
    if (langManager.currentLanguage == LanguageTypeEnglish) {
        // 使用 non-breaking space (U+00A0) 替换普通空格
        userAgreement = [userAgreement stringByReplacingOccurrencesOfString:@" " withString:@"\u00A0"];
        privacyPolicy = [privacyPolicy stringByReplacingOccurrencesOfString:@" " withString:@"\u00A0"];
    }
    
    NSString *fullText = [NSString stringWithFormat:@"%@%@%@%@", prefix, userAgreement, and, privacyPolicy];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:fullText];
    
    // 设置整体样式（#99FFFFFF）
    UIColor *tipsColor = HEX_COLOR(0x999999);
    [attributedString addAttribute:NSForegroundColorAttributeName value:tipsColor range:NSMakeRange(0, fullText.length)];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, fullText.length)];
    
    // 设置"用户协议"为链接颜色（#2BD7B4）
    NSRange userAgreementRange = [fullText rangeOfString:userAgreement];
    if (userAgreementRange.location != NSNotFound) {
        UIColor *linkColor = [UIColor colorWithRed:0x2B/255.0 green:0xD7/255.0 blue:0xB4/255.0 alpha:1.0]; // #2BD7B4
        [attributedString addAttribute:NSForegroundColorAttributeName value:linkColor range:userAgreementRange];
    }
    
    // 设置"隐私政策"为链接颜色（#2BD7B4）
    NSRange privacyPolicyRange = [fullText rangeOfString:privacyPolicy];
    if (privacyPolicyRange.location != NSNotFound) {
        UIColor *linkColor = [UIColor colorWithRed:0x2B/255.0 green:0xD7/255.0 blue:0xB4/255.0 alpha:1.0]; // #2BD7B4
        [attributedString addAttribute:NSForegroundColorAttributeName value:linkColor range:privacyPolicyRange];
    }
    
    self.agreementLabel.attributedText = attributedString;
    
    // 启用用户交互
    self.agreementLabel.userInteractionEnabled = YES;
    
    // 添加点击手势（只添加一次）
    if (!self.agreementTapGesture) {
        self.agreementTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(agreementLabelTapped:)];
        [self.agreementLabel addGestureRecognizer:self.agreementTapGesture];
    }
}

#pragma mark - 语言切换通知

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange:)
                                                 name:[LanguageManager languageDidChangeNotification]
                                               object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)languageDidChange:(NSNotification *)notification {
    // 语言切换后更新按钮文字
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateButtonTitles];
        [self setupAgreementText];
    });
}

- (void)updateButtonTitles {
    // 更新快速登录按钮
    if (self.quickLoginButton) {
        [self.quickLoginButton setTitle:LocalString(@"快速登录") forState:UIControlStateNormal];
    }
    
    // 更新Apple登录按钮
    if (self.appleLoginButton) {
        [self.appleLoginButton setTitle:LocalString(@"使用 Apple 登录") forState:UIControlStateNormal];
    }
    
    // 更新账号密码登录按钮
    if (self.accountLoginButton) {
        [self.accountLoginButton setTitle:LocalString(@"账号密码登录") forState:UIControlStateNormal];
    }
}

- (void)setupConstraints {
    // 背景图片铺满整个视图
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // Logo（200dp x 160dp，顶部间距80dp，水平居中）
    [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(80+STATUS_BAR_HEIGHT+NAVIGATION_BAR_HEIGHT);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(160);
    }];
    
    // 创建一个占位视图，模拟安卓的Space（layout_weight="1"），让按钮靠底部
    UIView *spacerView = [[UIView alloc] init];
    [self.view addSubview:spacerView];
    [spacerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoImageView.mas_bottom);
        make.left.right.equalTo(self.view);
    }];
    
    // 快速登录按钮（水平padding 20dp，高度48dp，圆角12dp，按钮间距12dp）
    [self.quickLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.top.equalTo(spacerView.mas_bottom);
        make.height.mas_equalTo(48);
    }];
    
    // 设置spacerView的底部约束，让它填充剩余空间
    [spacerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.quickLoginButton.mas_top);
    }];
    
    // Google登录按钮（间距12dp）
    [self.appleLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.quickLoginButton);
        make.top.equalTo(self.quickLoginButton.mas_bottom).offset(12);
        make.height.mas_equalTo(48);
    }];
    
    // 账号登录按钮（间距12dp）
    [self.accountLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.quickLoginButton);
        make.top.equalTo(self.appleLoginButton.mas_bottom).offset(12);
        make.height.mas_equalTo(48);
    }];
    
    // 协议复选框（18dp x 18dp，底部间距20dp，左侧padding 20dp，顶部间距14dp）
    [self.agreementCheckbox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.top.equalTo(self.accountLoginButton.mas_bottom).offset(14);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.width.height.mas_equalTo(18);
    }];
    
    // 协议文字（复选框和文字间距8dp，文字12sp）
    [self.agreementLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.agreementCheckbox.mas_right).offset(8);
        make.right.equalTo(self.view).offset(-20);
        make.centerY.equalTo(self.agreementCheckbox);
    }];
}

#pragma mark - Button Actions

- (void)quickLoginButtonTapped:(UIButton *)sender {
    // 检查是否同意协议
    if (!self.isAgreedToTerms) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"请先同意用户协议和隐私政策")];
        return;
    }
    [self performQuickLogin];
}

- (void)appleLoginButtonTapped:(UIButton *)sender {
    // 检查是否同意协议
    if (!self.isAgreedToTerms) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"请先同意用户协议和隐私政策")];
        return;
    }
    // 执行Apple登录（performGoogleLogin）
    [self performAppleLogin];
}

- (void)accountLoginButtonTapped:(UIButton *)sender {
    // 检查是否同意协议
    if (!self.isAgreedToTerms) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"请先同意用户协议和隐私政策")];
        return;
    }
    
    // 创建账号登录页面
    AccountLoginViewController *accountLoginVC = [[AccountLoginViewController alloc] init];
    
    // 使用导航控制器进行跳转
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:accountLoginVC];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)agreementCheckboxTapped:(UIButton *)sender {
    // 切换复选框状态
    self.isAgreedToTerms = !self.isAgreedToTerms;
    sender.selected = self.isAgreedToTerms;
    NSLog(@"协议复选框被点击，选中状态: %@", self.isAgreedToTerms ? @"是" : @"否");
}

- (void)agreementLabelTapped:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.agreementLabel];
    
    // 获取文本内容（使用国际化字符串）
    NSString *userAgreement = LocalString(@"用户协议");
    NSString *privacyPolicy = LocalString(@"隐私政策");
    NSString *fullText = self.agreementLabel.attributedText.string;
    
    if (!fullText || fullText.length == 0) {
        return;
    }
    
    // 在英文环境下，需要将原始字符串中的空格替换为 non-breaking space 来匹配显示文本
    LanguageManager *langManager = [LanguageManager sharedManager];
    if (langManager.currentLanguage == LanguageTypeEnglish) {
        userAgreement = [userAgreement stringByReplacingOccurrencesOfString:@" " withString:@"\u00A0"];
        privacyPolicy = [privacyPolicy stringByReplacingOccurrencesOfString:@" " withString:@"\u00A0"];
    }
    
    NSRange userAgreementRange = [fullText rangeOfString:userAgreement];
    NSRange privacyPolicyRange = [fullText rangeOfString:privacyPolicy];
    
    // 使用NSLayoutManager精确计算点击位置对应的字符索引（支持中英文混合）
    NSUInteger characterIndex = [self characterIndexAtPoint:location inLabel:self.agreementLabel];
    
    if (characterIndex == NSNotFound) {
        return;
    }
    
    // 检查点击位置是否在链接范围内
    if (userAgreementRange.location != NSNotFound && NSLocationInRange(characterIndex, userAgreementRange)) {
        [self showUserAgreement];
    } else if (privacyPolicyRange.location != NSNotFound && NSLocationInRange(characterIndex, privacyPolicyRange)) {
        [self showPrivacyPolicy];
    }
}

/// 精确计算点击位置对应的字符索引（支持中英文混合）
- (NSUInteger)characterIndexAtPoint:(CGPoint)point inLabel:(UILabel *)label {
    if (!label.attributedText || label.attributedText.length == 0) {
        return NSNotFound;
    }
    
    // 确保label已经完成布局
    if (CGRectIsEmpty(label.bounds)) {
        return NSNotFound;
    }
    
    // 创建NSTextStorage、NSLayoutManager和NSTextContainer
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:label.attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    
    // 配置textContainer，确保与label的布局完全匹配
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:label.bounds.size];
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = label.numberOfLines;
    textContainer.lineBreakMode = label.lineBreakMode;
    
    // 根据textAlignment调整textContainer的宽度
    if (label.textAlignment == NSTextAlignmentCenter || label.textAlignment == NSTextAlignmentRight) {
        // 对于居中和右对齐，需要计算实际文本宽度
        CGSize textSize = [label.attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, label.bounds.size.height)
                                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                               context:nil].size;
        if (textSize.width < label.bounds.size.width) {
            textContainer.size = CGSizeMake(textSize.width, label.bounds.size.height);
        }
    }
    
    [layoutManager addTextContainer:textContainer];
    
    // 强制布局计算
    [layoutManager ensureLayoutForTextContainer:textContainer];
    
    // 调整点击位置（考虑textAlignment）
    CGPoint adjustedPoint = point;
    if (label.textAlignment == NSTextAlignmentCenter) {
        // 居中对齐：需要调整点击位置的x坐标
        CGSize textSize = [label.attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, label.bounds.size.height)
                                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                               context:nil].size;
        if (textSize.width < label.bounds.size.width) {
            CGFloat offsetX = (label.bounds.size.width - textSize.width) / 2.0;
            adjustedPoint = CGPointMake(point.x - offsetX, point.y);
        }
    } else if (label.textAlignment == NSTextAlignmentRight) {
        // 右对齐：需要调整点击位置的x坐标
        CGSize textSize = [label.attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, label.bounds.size.height)
                                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                               context:nil].size;
        if (textSize.width < label.bounds.size.width) {
            CGFloat offsetX = label.bounds.size.width - textSize.width;
            adjustedPoint = CGPointMake(point.x - offsetX, point.y);
        }
    }
    
    // 计算字符索引
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:adjustedPoint
                                                        inTextContainer:textContainer
                               fractionOfDistanceBetweenInsertionPoints:NULL];
    
    // 边界检查
    if (characterIndex >= label.attributedText.length) {
        return NSNotFound;
    }
    
    return characterIndex;
}

- (void)showUserAgreement {
    // 从配置中获取用户协议URL并打开浏览器
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    if (config && config.userAgreementUrl && config.userAgreementUrl.length > 0) {
        BrowserViewController *browserVC = [[BrowserViewController alloc] initWithURL:config.userAgreementUrl];
        browserVC.title = LocalString(@"用户协议");
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:browserVC];
        navVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navVC animated:YES completion:nil];
    } else {
        NSLog(@"[LoginViewController] 用户协议链接暂不可用");
        [SVProgressHUD showErrorWithStatus:LocalString(@"用户协议链接暂不可用")];
    }
}

- (void)showPrivacyPolicy {
    // 从配置中获取隐私政策URL并打开浏览器
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    if (config && config.privacyPolicyUrl && config.privacyPolicyUrl.length > 0) {
        BrowserViewController *browserVC = [[BrowserViewController alloc] initWithURL:config.privacyPolicyUrl];
        browserVC.title = LocalString(@"隐私政策");
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:browserVC];
        navVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navVC animated:YES completion:nil];
    } else {
        NSLog(@"[LoginViewController] 隐私政策链接暂不可用");
        [SVProgressHUD showErrorWithStatus:LocalString(@"隐私政策链接暂不可用")];
    }
}

- (void)performQuickLogin {
    // 显示加载提示
    [SVProgressHUD showWithStatus:LocalString(@"加载中")];
    
    // 获取设备UUID（IMEI）
    NSString *imei = [[DeviceIdentifierManager sharedManager] getDeviceUUID];
    if (!imei || imei.length == 0) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"获取设备标识失败"];
        return;
    }
    
    NSLog(@"[LoginViewController] 设备IMEI: %@", imei);
    
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    if (config) {
        [self continueQuickLoginWithConfig:config imei:imei];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [[AppConfigManager sharedManager] getAppConfigWithSuccess:^(AppConfigModel *configModel) {
        [weakSelf continueQuickLoginWithConfig:configModel imei:imei];
    } failure:^(NSError *error) {
    
    }];
}

- (void)continueQuickLoginWithConfig:(AppConfigModel *)config imei:(NSString *)imei {
    if (!config) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"获取登录配置失败，请稍后重试"];
        return;
    }
    
    // 获取 login_imei_salt
    NSString *loginImeiSalt = config.loginImeiSalt;
    
    // 如果没有 login_imei_salt，尝试从缓存中的配置获取
    if (!loginImeiSalt || loginImeiSalt.length == 0) {
        AppConfigModel *cachedConfig = [[AppConfigManager sharedManager] getCachedConfig];
        if (cachedConfig) {
            loginImeiSalt = cachedConfig.loginImeiSalt;
        }
    }
    
    if (!loginImeiSalt || loginImeiSalt.length == 0) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"获取登录配置失败，请稍后重试"];
        return;
    }
    
    NSLog(@"[LoginViewController] login_imei_salt: %@", loginImeiSalt);
    
    // 生成签名：IMEI + login_imei_salt，然后进行 Base64 编码
    NSString *signatureString = [NSString stringWithFormat:@"%@%@", imei, loginImeiSalt];
    NSData *signatureData = [signatureString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *signature = [signatureData base64EncodedStringWithOptions:0];
    
    NSLog(@"[LoginViewController] 签名字符串: %@", signatureString);
    NSLog(@"[LoginViewController] Base64签名: %@", signature);
    
    // 调用快速登录接口
    [[UserManager sharedManager] quickLoginWithUsername:imei
                                              signature:signature
                                                success:^(NSDictionary *tokenInfo) {
        NSLog(@"[LoginViewController] 快速登录成功，token信息: %@", tokenInfo);
        
        // 打印快速登录接口返回的token信息
        NSString *accessToken = tokenInfo[@"access_token"];
        NSString *refreshToken = tokenInfo[@"refresh_token"];
        NSString *tokenType = tokenInfo[@"token_type"];
        NSNumber *expiresIn = tokenInfo[@"expires_in"];
        
        NSLog(@"[QuickLogin] ========== 快速登录接口返回的Token信息 ==========");
        NSLog(@"[QuickLogin] access_token: %@", accessToken ?: @"(空)");
        NSLog(@"[QuickLogin] refresh_token: %@", refreshToken ?: @"(空)");
        NSLog(@"[QuickLogin] token_type: %@", tokenType ?: @"(空)");
        NSLog(@"[QuickLogin] expires_in: %@ 秒", expiresIn ?: @"(空)");
        NSLog(@"[QuickLogin] ==============================================");
        
        if (accessToken && refreshToken) {
            [[UserManager sharedManager] saveUserTokensWithAccessToken:accessToken
                                                          refreshToken:refreshToken
                                                             tokenType:tokenType
                                                             expiresIn:expiresIn];
            
            // 设置网络管理器的Bearer认证
            [[NetworkManager sharedManager] setBearerAuthWithToken:accessToken];
            
            // 保存用户信息
            [[UserManager sharedManager] saveUserInfo:tokenInfo];
            
            // 获取用户详细信息
            [self fetchUserInfoAfterQuickLogin];
        } else {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:@"登录响应格式错误"];
        }
    } failure:^(NSError *error) {
        NSLog(@"[LoginViewController] 快速登录失败: %@", error);
    }];
}

- (void)fetchUserInfoAfterQuickLogin {
    // 请求用户信息
    [self requestUserInfo];
}

/**
 * 请求用户信息（requestUserInfo方法）
 */
- (void)requestUserInfo {
    [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
        NSLog(@"[LoginViewController] 获取用户详细信息成功: %@", userInfo.nickname);
        
        // 隐藏加载状态
        [SVProgressHUD dismiss];
        
        // 跳转到首页并关闭所有登录相关页面
        [self transitionToMainInterface];
        
    } failure:^(NSError *error) {
        NSLog(@"[LoginViewController] 获取用户详细信息失败: %@", error);
        
        // 即使获取用户信息失败，也跳转到首页
        [self transitionToMainInterface];
    }];
}

- (void)transitionToMainInterface {
    // 跳转到首页并关闭所有登录相关页面
    MainTabBarController *mainTabBarController = [[MainTabBarController alloc] init];
    
    // 设置根视图控制器
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    if (!window) {
        // 如果没有window，尝试从SceneDelegate获取
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        }
    }
    
    if (window) {
        // 淡入淡出动画
        [UIView transitionWithView:window duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            window.rootViewController = mainTabBarController;
        } completion:nil];
    } else {
        // 如果没有找到window，直接设置
        [UIApplication sharedApplication].delegate.window.rootViewController = mainTabBarController;
    }
    
    // 注意：开屏广告已在LaunchViewController中处理，登录后不再展示
}

#pragma mark - Apple Sign In（performGoogleLogin）

/**
 * 执行Apple登录（performGoogleLogin方法）
 */
- (void)performAppleLogin {
    if (@available(iOS 13.0, *)) {
        // 检查presentationAnchor是否可用
        ASPresentationAnchor anchor = [self presentationAnchorForAuthorizationController:nil];
        if (!anchor) {
            NSLog(@"[LoginViewController] 无法获取presentationAnchor，Apple登录失败");
            [SVProgressHUD showErrorWithStatus:LocalString(@"无法显示Apple登录界面，请稍后重试")];
            return;
        }
        
        ASAuthorizationAppleIDProvider *provider = [[ASAuthorizationAppleIDProvider alloc] init];
        ASAuthorizationAppleIDRequest *request = [provider createRequest];
        request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
        
        ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
        controller.delegate = self;
        controller.presentationContextProvider = self;
        
        NSLog(@"[LoginViewController] 开始执行Apple登录请求");
        [controller performRequests];
    } else {
        // iOS 13以下不支持Apple登录
        [SVProgressHUD showErrorWithStatus:LocalString(@"Apple登录需要iOS 13或更高版本")];
    }
}

#pragma mark - ASAuthorizationControllerDelegate

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization API_AVAILABLE(ios(13.0)) {
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
        ASAuthorizationAppleIDCredential *credential = (ASAuthorizationAppleIDCredential *)authorization.credential;
        
        // 获取用户信息
        NSString *userID = credential.user;
        
        // identityToken和authorizationCode是NSData类型，需要转换为base64编码的字符串
        NSString *identityToken = nil;
        if (credential.identityToken) {
            identityToken = [[NSString alloc] initWithData:credential.identityToken encoding:NSUTF8StringEncoding];
        }
        
        NSString *email = credential.email;
        NSString *fullName = nil;
        if (credential.fullName) {
            NSMutableString *nameComponents = [NSMutableString string];
            if (credential.fullName.givenName) {
                [nameComponents appendString:credential.fullName.givenName];
            }
            if (credential.fullName.familyName) {
                if (nameComponents.length > 0) {
                    [nameComponents appendString:@" "];
                }
                [nameComponents appendString:credential.fullName.familyName];
            }
            fullName = nameComponents.length > 0 ? nameComponents : nil;
        }
        
        NSLog(@"[LoginViewController] Apple登录成功 - userID: %@, email: %@, name: %@", userID, email, fullName);
        NSLog(@"[LoginViewController] identityToken存在: %@, authorizationCode存在: %@", 
              identityToken ? @"是" : @"否");
        
        // 优先使用identityToken，如果没有则使用authorizationCode
        NSString *appleToken = identityToken ;
        if (!appleToken || appleToken.length == 0) {
            NSLog(@"[LoginViewController] 警告：identityToken和authorizationCode都为空");
            [SVProgressHUD showErrorWithStatus:LocalString(@"无法获取Apple登录信息")];
            return;
        }
        
        // 处理Apple登录结果（handleGoogleLoginResult）
        [self handleAppleLoginResult:appleToken email:email name:fullName];
    } else {
        NSLog(@"[LoginViewController] 警告：授权凭证类型不正确");
        [SVProgressHUD showErrorWithStatus:LocalString(@"Apple登录凭证类型错误")];
    }
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error API_AVAILABLE(ios(13.0)) {
    NSLog(@"[LoginViewController] Apple登录失败: %@", error);
    NSLog(@"[LoginViewController] 错误域: %@, 错误代码: %ld, 错误描述: %@", error.domain, (long)error.code, error.localizedDescription);
    
    if (error.code == ASAuthorizationErrorCanceled) {
        NSLog(@"[LoginViewController] 用户取消Apple登录");
        // 用户取消不需要显示错误提示
    } else if (error.code == ASAuthorizationErrorUnknown) {
        // 错误代码 1000 - 未知错误
        NSLog(@"[LoginViewController] Apple登录未知错误，可能原因：");
        NSLog(@"  1. 设备不支持Apple登录");
        NSLog(@"  2. 未在Xcode中启用Sign in with Apple能力");
        NSLog(@"  3. 未在Apple Developer中配置App ID");
        NSLog(@"  4. 网络连接问题");
        NSLog(@"  5. presentationAnchor返回nil");
        [SVProgressHUD showErrorWithStatus:LocalString(@"Apple登录失败，请检查设备设置或稍后重试")];
    } else if (error.code == ASAuthorizationErrorInvalidResponse) {
        NSLog(@"[LoginViewController] Apple登录响应无效");
        [SVProgressHUD showErrorWithStatus:LocalString(@"Apple登录响应无效，请重试")];
    } else if (error.code == ASAuthorizationErrorNotHandled) {
        NSLog(@"[LoginViewController] Apple登录请求未处理");
        [SVProgressHUD showErrorWithStatus:LocalString(@"Apple登录请求未处理，请重试")];
    } else if (error.code == ASAuthorizationErrorFailed) {
        NSLog(@"[LoginViewController] Apple登录请求失败");
        [SVProgressHUD showErrorWithStatus:LocalString(@"Apple登录请求失败，请重试")];
    } else {
        // 显示原始错误信息
        NSString *errorMessage = error.localizedDescription ?: error.localizedFailureReason;
        if (errorMessage && errorMessage.length > 0) {
            [SVProgressHUD showErrorWithStatus:errorMessage];
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"Apple登录失败")];
        }
    }
}

#pragma mark - ASAuthorizationControllerPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller API_AVAILABLE(ios(13.0)) {
    // 优先使用当前视图的window
    UIWindow *window = self.view.window;
    if (window) {
        return window;
    }
    
    // 如果当前视图的window为nil，尝试从SceneDelegate获取
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if ([windowScene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *sceneWindow in windowScene.windows) {
                    if (sceneWindow.isKeyWindow) {
                        return sceneWindow;
                    }
                }
            }
        }
    }
    
    // 最后尝试从AppDelegate获取
    if ([UIApplication sharedApplication].delegate.window) {
        return [UIApplication sharedApplication].delegate.window;
    }
    
    // 如果都获取不到，返回应用的主窗口
    return [UIApplication sharedApplication].windows.firstObject;
}

/**
 * 处理Apple登录结果（handleGoogleLoginResult方法）
 */
- (void)handleAppleLoginResult:(NSString *)appleToken email:(NSString *)email name:(NSString *)name {
    if (!appleToken || appleToken.length == 0) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"无法获取Apple登录信息")];
        return;
    }
    
    // 显示加载提示
    [SVProgressHUD showWithStatus:LocalString(@"登录中")];
    
    // 调用Apple登录接口
    NSDictionary *params = @{
        @"code": appleToken ?: @""
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_USER_LOGIN_APPLE
                              parameters:params
                                 success:^(id responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 保存登录信息
            NSDictionary *data = responseObject[@"data"];
            if (data && [data isKindOfClass:[NSDictionary class]]) {
                NSString *accessToken = data[@"access_token"];
                NSString *refreshToken = data[@"refresh_token"];
                NSString *tokenType = data[@"token_type"] ?: @"Bearer";
                NSNumber *expiresIn = data[@"expires_in"];
                
                // 打印Apple登录接口返回的token信息
                NSLog(@"[AppleLogin] ========== Apple登录接口返回的Token信息 ==========");
                NSLog(@"[AppleLogin] access_token: %@", accessToken ?: @"(空)");
                NSLog(@"[AppleLogin] refresh_token: %@", refreshToken ?: @"(空)");
                NSLog(@"[AppleLogin] token_type: %@", tokenType ?: @"(空)");
                NSLog(@"[AppleLogin] expires_in: %@ 秒", expiresIn ?: @"(空)");
                NSLog(@"[AppleLogin] ==============================================");
                
                if (accessToken && refreshToken) {
                    [[UserManager sharedManager] saveUserTokensWithAccessToken:accessToken
                                                                  refreshToken:refreshToken
                                                                     tokenType:tokenType
                                                                     expiresIn:expiresIn];
                    
                    // 设置网络管理器的Bearer认证
                    [[NetworkManager sharedManager] setBearerAuthWithToken:accessToken];
                    
                    // 打印token存储位置信息
                    NSLog(@"[AppleLogin] ========== Token存储位置信息 ==========");
                    NSLog(@"[AppleLogin] Token存储位置: NSUserDefaults");
                    NSLog(@"[AppleLogin] access_token存储key: BunnyxAccessToken");
                    NSLog(@"[AppleLogin] refresh_token存储key: BunnyxRefreshToken");
                    NSLog(@"[AppleLogin] token_type存储key: BunnyxTokenType");
                    NSLog(@"[AppleLogin] 过期时间存储key: BunnyxTokenExpireTime");
                    NSLog(@"[AppleLogin] Token保存成功: %@ %@", tokenType, accessToken);
                    NSLog(@"[AppleLogin] ======================================");
                }
            }
            
            // 无论是否有token数据，只要code=0就继续请求用户信息
            [self requestUserInfo];
        } else {
            [SVProgressHUD dismiss];
            NSString *message = responseObject[@"message"];
            [SVProgressHUD showErrorWithStatus:message ?: LocalString(@"Apple登录失败")];
        }
    } failure:^(NSError *error) {
        NSLog(@"[LoginViewController] Apple登录接口请求失败: %@", error);
        // 错误提示由 NetworkManager 自动显示
    }];
}

@end
