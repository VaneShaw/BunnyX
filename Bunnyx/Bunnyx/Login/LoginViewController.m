//
//  LoginViewController.m
//  Bunnyx
//
//  Created by fengwenxiao on 2024/11/30.
//

#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "AccountLoginViewController.h"
#import <Masonry/Masonry.h>


@interface LoginViewController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UIButton *quickLoginButton;
@property (nonatomic, strong) UIButton *appleLoginButton;
@property (nonatomic, strong) UIButton *accountLoginButton;
@property (nonatomic, strong) UIButton *agreementCheckbox;
@property (nonatomic, strong) UILabel *agreementLabel;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
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
    self.logoImageView = [[UIImageView alloc] init];
    self.logoImageView.image = [UIImage imageNamed:@"icon_login_logo"];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.logoImageView];
}

- (void)setupLoginButtons {
    // Quick Login 按钮
    self.quickLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.quickLoginButton setTitle:@"Quick Login" forState:UIControlStateNormal];
    [self.quickLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.quickLoginButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.quickLoginButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0];
    self.quickLoginButton.layer.cornerRadius = 25;
    [self.quickLoginButton setImage:[UIImage imageNamed:@"icon_login_quick"] forState:UIControlStateNormal];
    self.quickLoginButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 10);
    self.quickLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, -10);
    [self.quickLoginButton addTarget:self action:@selector(quickLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.quickLoginButton];
    
    // Apple/Google Login 按钮
    self.appleLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.appleLoginButton setTitle:@"Sign in with Apple/Google" forState:UIControlStateNormal];
    [self.appleLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appleLoginButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.appleLoginButton.backgroundColor = [UIColor blackColor];
    self.appleLoginButton.layer.cornerRadius = 25;
    self.appleLoginButton.layer.borderWidth = 1;
    self.appleLoginButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [self.appleLoginButton setImage:[UIImage imageNamed:@"icon_login_apple"] forState:UIControlStateNormal];
    self.appleLoginButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 10);
    self.appleLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, -10);
    [self.appleLoginButton addTarget:self action:@selector(appleLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.appleLoginButton];
    
    // Account Login 按钮
    self.accountLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.accountLoginButton setTitle:@"Sign in with Account" forState:UIControlStateNormal];
    [self.accountLoginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.accountLoginButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.accountLoginButton.backgroundColor = [UIColor whiteColor];
    self.accountLoginButton.layer.cornerRadius = 25;
    [self.accountLoginButton setImage:[UIImage imageNamed:@"icon_login_account"] forState:UIControlStateNormal];
    self.accountLoginButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 10);
    self.accountLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, -10);
    [self.accountLoginButton addTarget:self action:@selector(accountLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.accountLoginButton];
}

- (void)setupAgreement {
    self.agreementCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.agreementCheckbox setImage:[UIImage imageNamed:@"icon_login_bottom_box_default"] forState:UIControlStateNormal];
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
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(80);
        make.width.height.mas_equalTo(80);
    }];
    
    [self.quickLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.logoImageView.mas_bottom).offset(60);
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.height.mas_equalTo(50);
    }];
    
    [self.appleLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.quickLoginButton.mas_bottom).offset(15);
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.height.mas_equalTo(50);
    }];
    
    [self.accountLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.appleLoginButton.mas_bottom).offset(15);
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
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

#pragma mark - Button Actions

- (void)quickLoginButtonTapped:(UIButton *)sender {
    NSLog(@"Quick Login 按钮被点击");
    [self transitionToMainInterface];
}

- (void)appleLoginButtonTapped:(UIButton *)sender {
    NSLog(@"Apple/Google Login 按钮被点击");
    [self transitionToMainInterface];
}

- (void)accountLoginButtonTapped:(UIButton *)sender {
    NSLog(@"Account Login 按钮被点击");
    
    // 创建账号登录页面
    AccountLoginViewController *accountLoginVC = [[AccountLoginViewController alloc] init];
    
    // 使用导航控制器进行跳转
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:accountLoginVC];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)agreementCheckboxTapped:(UIButton *)sender {
    sender.selected = !sender.selected;
    // 这里可以添加选中状态的图片
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

@end
