//
//  AccountLoginViewController.m
//  Bunnyx
//
//  Created by fengwenxiao on 2024/11/30.
//

#import "AccountLoginViewController.h"
#import "MainTabBarController.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "BunnyxMacros.h"
#import "DeviceIdentifierManager.h"
#import "UserManager.h"
#import "UserInfoManager.h"
#import "BrowserViewController.h"
#import "AppConfigManager.h"
#import "LanguageManager.h"
#import "AdMobManager.h"

@interface AccountLoginViewController ()

@property (nonatomic, assign) BOOL isAgreedToTerms; // 是否同意用户协议和隐私政策

@property (nonatomic, strong) UIView *accountContainer;
@property (nonatomic, strong) UILabel *accountLabel;
@property (nonatomic, strong) UITextField *accountTextField;
@property (nonatomic, strong) UIView *passwordContainer;
@property (nonatomic, strong) UILabel *passwordLabel;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *agreementCheckbox;
@property (nonatomic, strong) UILabel *agreementLabel;
@property (nonatomic, strong) UITapGestureRecognizer *agreementTapGesture; // 协议文字点击手势

@end

@implementation AccountLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 默认勾选协议
    self.isAgreedToTerms = YES;
    [self setupUI];
    
    // 加载上次登录的账号
    [self loadLastLoginAccount];
    
    // 添加语言切换通知监听
    [self addObservers];
}

- (void)dealloc {
    [self removeObservers];
}

- (void)loadLastLoginAccount {
    // 从本地读取上次登录的账号
    NSString *lastAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"BunnyxLastLoginAccount"];
    if (lastAccount && lastAccount.length > 0) {
        self.accountTextField.text = lastAccount;
    }
}

- (void)saveLastLoginAccount {
    // 保存登录成功的账号
    NSString *account = self.accountTextField.text;
    if (account && account.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:account forKey:@"BunnyxLastLoginAccount"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setupUI {

    // 设置账号输入区域
    [self setupAccountInput];
    
    // 设置密码输入区域
    [self setupPasswordInput];
    
    // 设置登录按钮
    [self setupLoginButton];
    
    // 设置用户协议
    [self setupAgreement];
    
    // 设置约束
    [self setupConstraints];
}

- (void)setupAccountInput {
    // 账号容器
    self.accountContainer = [[UIView alloc] init];
    self.accountContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.accountContainer];
    
    // 账号标签
    self.accountLabel = [[UILabel alloc] init];
    self.accountLabel.text = LocalString(@"Account");
    self.accountLabel.textColor = [UIColor whiteColor];
    self.accountLabel.font = [UIFont systemFontOfSize:14];
    [self.accountContainer addSubview:self.accountLabel];
    
    // 账号图标
    UIImageView *accountIcon = [[UIImageView alloc] init];
    accountIcon.image = [UIImage imageNamed:@"icon_login_account_account"];
    accountIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.accountContainer addSubview:accountIcon];
    
    // 账号输入框
    self.accountTextField = [[UITextField alloc] init];
    self.accountTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.accountTextField.layer.cornerRadius = 8;
    self.accountTextField.layer.borderWidth = 0; // 去掉边框
    self.accountTextField.textColor = [UIColor whiteColor];
    self.accountTextField.font = [UIFont systemFontOfSize:16];
    self.accountTextField.placeholder =  LocalString(@"Please enter your account");
    
    // 添加清除按钮
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearButton setImage:[UIImage imageNamed:@"icon_login_account_delete"] forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearAccountText:) forControlEvents:UIControlEventTouchUpInside];
    
    // 创建容器视图来控制尺寸，右边留12像素间距
    UIView *rightViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 34, 22)];
    rightViewContainer.backgroundColor = [UIColor clearColor];
    [rightViewContainer addSubview:clearButton];
    clearButton.frame = CGRectMake(0, 0, 22, 22);
    
    self.accountTextField.rightView = rightViewContainer;
    self.accountTextField.rightViewMode = UITextFieldViewModeAlways;
    
    // 添加左边距
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    self.accountTextField.leftView = leftPaddingView;
    self.accountTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [self.accountContainer addSubview:self.accountTextField];
    
    // 设置约束
    [accountIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.accountContainer);
        make.centerY.equalTo(self.accountLabel);
        make.width.height.mas_equalTo(16);
    }];
    
    [self.accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(accountIcon.mas_right).offset(8);
        make.top.equalTo(self.accountContainer);
    }];
    
    [self.accountTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.accountContainer);
        make.top.equalTo(self.accountLabel.mas_bottom).offset(8);
        make.height.mas_equalTo(44);
    }];
}

- (void)setupPasswordInput {
    // 密码容器
    self.passwordContainer = [[UIView alloc] init];
    self.passwordContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.passwordContainer];
    
    // 密码标签
    self.passwordLabel = [[UILabel alloc] init];
    self.passwordLabel.text = LocalString(@"Password") ;
    self.passwordLabel.textColor = [UIColor whiteColor];
    self.passwordLabel.font = [UIFont systemFontOfSize:14];
    [self.passwordContainer addSubview:self.passwordLabel];
    
    // 密码图标
    UIImageView *passwordIcon = [[UIImageView alloc] init];
    passwordIcon.image = [UIImage imageNamed:@"icon_login_account_account(1)"];
    passwordIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.passwordContainer addSubview:passwordIcon];
    
    // 密码输入框
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.passwordTextField.layer.cornerRadius = 8;
    self.passwordTextField.layer.borderWidth = 0; // 去掉边框
    self.passwordTextField.textColor = [UIColor whiteColor];
    self.passwordTextField.font = [UIFont systemFontOfSize:16];
    self.passwordTextField.placeholder = LocalString(@"Please enter your password");
    self.passwordTextField.secureTextEntry = YES;
    
//    // 设置占位符颜色
//    self.passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Please enter your password" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.6]}];
    
    // 添加左边距
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    self.passwordTextField.leftView = leftPaddingView;
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [self.passwordContainer addSubview:self.passwordTextField];
    
    // 设置约束
    [passwordIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.passwordContainer);
        make.centerY.equalTo(self.passwordLabel);
        make.width.height.mas_equalTo(16);
    }];
    
    [self.passwordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(passwordIcon.mas_right).offset(8);
        make.top.equalTo(self.passwordContainer);
    }];
    
    [self.passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.passwordContainer);
        make.top.equalTo(self.passwordLabel.mas_bottom).offset(8);
        make.height.mas_equalTo(44);
    }];
}

- (void)setupLoginButton {
    self.loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.loginButton setTitle:LocalString(@"Login") forState:UIControlStateNormal];
    // 按钮标题颜色使用#333333
    [self.loginButton setTitleColor:[UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1.0] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    
    // 设置渐变背景
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0].CGColor,
                            (__bridge id)[UIColor colorWithRed:0.0 green:0.6 blue:0.8 alpha:1.0].CGColor];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    gradientLayer.cornerRadius = 10;
    
    // 将渐变层插入到最底层，避免遮挡文字
    [self.loginButton.layer insertSublayer:gradientLayer atIndex:0];
    
    self.loginButton.layer.cornerRadius = 10;
    self.loginButton.layer.masksToBounds = YES;
    [self.loginButton addTarget:self action:@selector(loginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // 根据协议勾选状态设置按钮可用性
    [self updateLoginButtonState];
    
    [self.view addSubview:self.loginButton];
}

- (void)updateLoginButtonState {
    // 未勾选协议时禁用登录按钮
    self.loginButton.enabled = self.isAgreedToTerms;
    self.loginButton.alpha = self.isAgreedToTerms ? 1.0 : 0.5;
}

- (void)setupAgreement {
    // 复选框18dp x 18dp，文字12sp，复选框和文字间距8dp
    self.agreementCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.agreementCheckbox setImage:[UIImage imageNamed:@"icon_login_bottom_box_default"] forState:UIControlStateNormal];
    [self.agreementCheckbox setImage:[UIImage imageNamed:@"icon_login_bottom_box_selected"] forState:UIControlStateSelected];
    // 默认勾选
    self.agreementCheckbox.selected = YES;
    [self.agreementCheckbox addTarget:self action:@selector(agreementCheckboxTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.agreementCheckbox];
    
    // 协议文字分为多个部分，支持点击
    self.agreementLabel = [[UILabel alloc] init];
    self.agreementLabel.textColor = HEX_COLOR(0x999999); // #999999
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
    
    // 设置整体样式（#999999）
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

- (void)setupConstraints {

    [self.accountContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.top.equalTo(self.customBackButton.mas_bottom).offset(60);
        make.height.offset(100);
    }];
    
    [self.passwordContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.top.equalTo(self.accountContainer.mas_bottom).offset(30);
        make.height.offset(100);
    }];
    
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.top.equalTo(self.passwordContainer.mas_bottom).offset(40);
        make.height.mas_equalTo(50);
    }];
    
    // 协议复选框（18dp x 18dp，底部间距20dp，左侧padding 20dp，顶部间距14dp）
    [self.agreementCheckbox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 更新渐变层的frame
    for (CALayer *layer in self.loginButton.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.loginButton.bounds;
        }
    }
}

#pragma mark - Button Actions

- (void)clearAccountText:(UIButton *)sender {
    self.accountTextField.text = @"";
}

- (void)loginButtonTapped:(UIButton *)sender {
    NSLog(@"登录按钮被点击");
    
    // 简单的验证
    if (self.accountTextField.text.length == 0) {
        [self showAlert:LocalString(@"请输入账号")];
        return;
    }
    
    if (self.passwordTextField.text.length == 0) {
        [self showAlert:LocalString(@"请输入密码")];
        return;
    }
    
    // 执行登录逻辑
    [self performLogin];
}

- (void)agreementCheckboxTapped:(UIButton *)sender {
    // 切换复选框状态
    self.isAgreedToTerms = !self.isAgreedToTerms;
    sender.selected = self.isAgreedToTerms;
    // 更新登录按钮状态
    [self updateLoginButtonState];
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
    // 语言切换后更新协议文字
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupAgreementText];
    });
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
        NSLog(@"[AccountLoginViewController] 用户协议链接暂不可用");
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
        NSLog(@"[AccountLoginViewController] 隐私政策链接暂不可用");
        [SVProgressHUD showErrorWithStatus:LocalString(@"隐私政策链接暂不可用")];
    }
}

- (void)performLogin {
    NSLog(@"开始执行登录");
    
    // 显示加载状态 - 暂时使用简单的日志
    NSLog(@"显示登录加载状态");
    // dispatch_async(dispatch_get_main_queue(), ^{
         [SVProgressHUD showWithStatus:LocalString(@"登录中...")];
    // });
    
    NSMutableDictionary * param = [NSMutableDictionary dictionary];
    
    [param setObject:self.accountTextField.text forKey:@"username"];
    [param setObject:self.passwordTextField.text forKey:@"password"];
    
    NSLog(@"登录参数: %@", param);
    NSLog(@"登录URL: %@", BUNNYX_API_USER_LOGIN_ACCOUNT);
    
    [[NetworkManager sharedManager]POST:BUNNYX_API_USER_LOGIN_ACCOUNT parameters:param success:^(id  _Nonnull responseObject) {
        NSLog(@"登录成功: %@", responseObject);
        
        // 打印登录接口返回的token信息
        NSDictionary *data = responseObject[@"data"];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            NSString *accessToken = data[@"access_token"];
            NSString *refreshToken = data[@"refresh_token"];
            NSString *tokenType = data[@"token_type"];
            NSNumber *expiresIn = data[@"expires_in"];
            
            NSLog(@"[AccountLogin] ========== 登录接口返回的Token信息 ==========");
            NSLog(@"[AccountLogin] access_token: %@", accessToken ?: @"(空)");
            NSLog(@"[AccountLogin] refresh_token: %@", refreshToken ?: @"(空)");
            NSLog(@"[AccountLogin] token_type: %@", tokenType ?: @"(空)");
            NSLog(@"[AccountLogin] expires_in: %@ 秒", expiresIn ?: @"(空)");
            NSLog(@"[AccountLogin] ============================================");
        }
        
        // 处理登录成功后的逻辑
        [self handleLoginSuccess:responseObject];
        
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"登录失败: %@", error);
        // dispatch_async(dispatch_get_main_queue(), ^{
        //     [SVProgressHUD dismiss];
        // });
        // 错误信息会通过NetworkManager自动显示Toast
    }];
    
}

- (void)handleLoginSuccess:(NSDictionary *)responseObject {
    NSLog(@"处理登录成功响应: %@", responseObject);
    
    // 提取token信息
    NSDictionary *data = responseObject[@"data"];
    if (data && [data isKindOfClass:[NSDictionary class]]) {
        NSString *accessToken = data[@"access_token"];
        NSString *refreshToken = data[@"refresh_token"];
        NSString *tokenType = data[@"token_type"];
        NSNumber *expiresIn = data[@"expires_in"];
        
        if (accessToken && accessToken.length > 0 && refreshToken && refreshToken.length > 0) {
            // 保存token信息
            [[UserManager sharedManager] saveUserTokensWithAccessToken:accessToken
                                                           refreshToken:refreshToken
                                                              tokenType:tokenType
                                                              expiresIn:expiresIn];
            
            // 设置网络管理器的Bearer认证
            [[NetworkManager sharedManager] setBearerAuthWithToken:accessToken];
            
            // 保存用户信息
            [[UserManager sharedManager] saveUserInfo:data];
            
            // 保存登录成功的账号
            [self saveLastLoginAccount];
            
            NSLog(@"Token保存成功: %@ %@", tokenType, accessToken);
            
            // 获取用户详细信息
            [self fetchUserInfoAfterLogin];
        } else {
            NSLog(@"登录响应中未找到完整的token信息");
            [SVProgressHUD showErrorWithStatus:LocalString(@"登录响应格式错误")];
        }
    } else {
        NSLog(@"登录响应数据格式错误");
        [SVProgressHUD showErrorWithStatus:LocalString(@"登录响应格式错误")];
    }
}

- (void)fetchUserInfoAfterLogin {
    NSLog(@"登录成功后获取用户详细信息");
    
    [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
        NSLog(@"获取用户详细信息成功: %@", userInfo.nickname);
        
        // 隐藏加载状态
        [SVProgressHUD dismiss];
        
        // 跳转到主界面
        [self transitionToMainInterface];
        
    } failure:^(NSError *error) {
        NSLog(@"获取用户详细信息失败: %@", error);
        
        // 即使获取用户信息失败，也继续跳转到主界面
        [self transitionToMainInterface];
    }];
}

- (void)transitionToMainInterface {
    // 创建主界面
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

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"提示") 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LocalString(@"确定") style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLoadingAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
