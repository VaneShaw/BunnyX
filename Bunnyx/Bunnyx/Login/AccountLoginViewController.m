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

@interface AccountLoginViewController ()


@property (nonatomic, strong) UIView *accountContainer;
@property (nonatomic, strong) UILabel *accountLabel;
@property (nonatomic, strong) UITextField *accountTextField;
@property (nonatomic, strong) UIView *passwordContainer;
@property (nonatomic, strong) UILabel *passwordLabel;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *agreementCheckbox;
@property (nonatomic, strong) UILabel *agreementLabel;

@end

@implementation AccountLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
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
    self.accountLabel.text = @"Account";
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
    self.accountTextField.layer.borderWidth = 1;
    self.accountTextField.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
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
    self.passwordTextField.layer.borderWidth = 1;
    self.passwordTextField.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
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
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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
    [self.view addSubview:self.loginButton];
}

- (void)setupAgreement {
    self.agreementCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.agreementCheckbox setImage:[UIImage imageNamed:@"icon_login_bottom_box_checked"] forState:UIControlStateNormal];
    self.agreementCheckbox.selected = YES;
    [self.agreementCheckbox addTarget:self action:@selector(agreementCheckboxTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.agreementCheckbox];
    
    self.agreementLabel = [[UILabel alloc] init];
    self.agreementLabel.text = @"If you login, it means you agree to the User Agreement and Privacy Policy";
    self.agreementLabel.textColor = [UIColor lightGrayColor];
    self.agreementLabel.font = [UIFont systemFontOfSize:12];
    self.agreementLabel.numberOfLines = 0;
    self.agreementLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.agreementLabel];
    
    // 设置协议文本中的链接样式
    [self setupAgreementText];
}

- (void)setupAgreementText {
    NSString *fullText = @"If you login, it means you agree to the User Agreement and Privacy Policy";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:fullText];
    
    // 设置整体样式
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, fullText.length)];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, fullText.length)];
    
    // 设置"User Agreement"为绿色并添加点击链接
    NSRange userAgreementRange = [fullText rangeOfString:@"User Agreement"];
    if (userAgreementRange.location != NSNotFound) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0] range:userAgreementRange];
        [attributedString addAttribute:NSLinkAttributeName value:@"userAgreement://" range:userAgreementRange];
    }
    
    // 设置"Privacy Policy"为绿色并添加点击链接
    NSRange privacyPolicyRange = [fullText rangeOfString:@"Privacy Policy"];
    if (privacyPolicyRange.location != NSNotFound) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0] range:privacyPolicyRange];
        [attributedString addAttribute:NSLinkAttributeName value:@"privacyPolicy://" range:privacyPolicyRange];
    }
    
    self.agreementLabel.attributedText = attributedString;
    
    // 启用用户交互
    self.agreementLabel.userInteractionEnabled = YES;
    
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(agreementLabelTapped:)];
    [self.agreementLabel addGestureRecognizer:tapGesture];
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
    
    [self.agreementCheckbox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(40);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-30);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.agreementLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.agreementCheckbox.mas_right).offset(10);
        make.right.equalTo(self.view).offset(-40);
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
        [self showAlert:@"请输入账号"];
        return;
    }
    
    if (self.passwordTextField.text.length == 0) {
        [self showAlert:@"请输入密码"];
        return;
    }
    
    if (!self.agreementCheckbox.selected) {
        [self showAlert:@"请同意用户协议和隐私政策"];
        return;
    }
    
    // 执行登录逻辑
    [self performLogin];
}

- (void)agreementCheckboxTapped:(UIButton *)sender {
    sender.selected = !sender.selected;
    UIImage *image = sender.selected ? [UIImage imageNamed:@"icon_login_bottom_box_checked"] : [UIImage imageNamed:@"icon_login_bottom_box_default"];
    [sender setImage:image forState:UIControlStateNormal];
    NSLog(@"协议复选框被点击，选中状态: %@", sender.selected ? @"是" : @"否");
}

- (void)agreementLabelTapped:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.agreementLabel];
    
    // 获取文本的边界框
    NSString *fullText = self.agreementLabel.text;
    NSRange userAgreementRange = [fullText rangeOfString:@"User Agreement"];
    NSRange privacyPolicyRange = [fullText rangeOfString:@"Privacy Policy"];
    
    // 计算文本的字体和大小
    UIFont *font = self.agreementLabel.font;
    CGSize textSize = [fullText sizeWithAttributes:@{NSFontAttributeName: font}];
    
    // 计算每个字符的宽度
    CGFloat charWidth = textSize.width / fullText.length;
    
    // 计算点击位置对应的字符索引
    NSUInteger characterIndex = (NSUInteger)(location.x / charWidth);
    
    // 检查点击位置是否在链接范围内
    if (NSLocationInRange(characterIndex, userAgreementRange)) {
        [self showUserAgreement];
    } else if (NSLocationInRange(characterIndex, privacyPolicyRange)) {
        [self showPrivacyPolicy];
    }
}

- (void)showUserAgreement {
    NSLog(@"显示用户协议");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"用户协议" 
                                                                   message:@"这里是用户协议的内容..." 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showPrivacyPolicy {
    NSLog(@"显示隐私政策");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"隐私政策" 
                                                                   message:@"这里是隐私政策的内容..." 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performLogin {
    NSLog(@"开始执行登录");
    
    // 显示加载状态 - 暂时使用简单的日志
    NSLog(@"显示登录加载状态");
    // dispatch_async(dispatch_get_main_queue(), ^{
         [SVProgressHUD showWithStatus:@"登录中..."];
    // });
    
    NSMutableDictionary * param = [NSMutableDictionary dictionary];
    
    [param setObject:self.accountTextField.text forKey:@"username"];
    [param setObject:self.passwordTextField.text forKey:@"password"];
    
    NSLog(@"登录参数: %@", param);
    NSLog(@"登录URL: %@", BUNNYX_API_USER_LOGIN_ACCOUNT);
    
    [[NetworkManager sharedManager]POST:BUNNYX_API_USER_LOGIN_ACCOUNT parameters:param success:^(id  _Nonnull responseObject) {
        NSLog(@"登录成功: %@", responseObject);
        // dispatch_async(dispatch_get_main_queue(), ^{
             [SVProgressHUD dismiss];
        // });
        // 登录成功，跳转到主界面
        [self transitionToMainInterface];
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"登录失败: %@", error);
        // dispatch_async(dispatch_get_main_queue(), ^{
        //     [SVProgressHUD dismiss];
        // });
        // 错误信息会通过NetworkManager自动显示Toast
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
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
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
