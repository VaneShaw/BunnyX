//
//  LaunchViewController.m
//  Bunnyx
//
//  Created by fengwenxiao on 2024/11/30.
//

#import "LaunchViewController.h"
#import "LoginViewController.h"
#import <Masonry/Masonry.h>

@interface LaunchViewController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *appNameLabel;

@end

@implementation LaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self startLaunchAnimation];
}

- (void)setupUI {
    // 设置背景图片，与LaunchScreen.storyboard保持一致
    if (!self.backgroundImageView) {
        self.backgroundImageView = [[UIImageView alloc] init];
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.backgroundImageView.clipsToBounds = YES;
        [self.view addSubview:self.backgroundImageView];
        [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    
    // 优先使用传入的背景图片，否则使用默认的launch_background
    UIImage *backgroundImage = self.backgroundImageView.image;
    if (!backgroundImage) {
        backgroundImage = [UIImage imageNamed:@"launch_background"];
    }
    if (backgroundImage) {
        self.backgroundImageView.image = backgroundImage;
    } else {
        // 如果都没有，使用默认背景色
        self.view.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0];
    }
    
    // 设置Logo，与LaunchScreen.storyboard保持一致
    if (!self.logoImageView) {
        self.logoImageView = [[UIImageView alloc] init];
        self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:self.logoImageView];
        [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.view);
            make.width.height.offset(175);
        }];
    }
    
    // 优先使用传入的Logo图片，否则使用默认的launch_logo
    UIImage *logoImage = self.logoImageView.image;
    if (!logoImage) {
        logoImage = [UIImage imageNamed:@"launch_logo"];
    }
    if (logoImage) {
        self.logoImageView.image = logoImage;
    }
    
    [self setupConstraints];
}

- (void)setupConstraints {

}

- (void)startLaunchAnimation {
    // Logo直接以正常大小显示，不进行放大动画
    if (self.logoImageView) {
        self.logoImageView.alpha = 1.0;
        self.logoImageView.transform = CGAffineTransformIdentity; // 直接设置为正常大小，不进行缩放动画
    }
    
    // 应用名称也直接显示，不进行动画
    if (self.appNameLabel) {
        self.appNameLabel.alpha = 1.0;
        self.appNameLabel.transform = CGAffineTransformIdentity; // 直接设置为正常状态，不进行动画
    }
    
    // 动画完成，不自动跳转，等待外部控制
    NSLog(@"[LaunchViewController] 启动动画完成");
}

- (void)transitionToMainInterface {
    // 创建登录页面
    LoginViewController *loginViewController = [[LoginViewController alloc] init];
    
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
            window.rootViewController = loginViewController;
        } completion:nil];
    } else {
        // 如果没有找到window，直接设置
        [UIApplication sharedApplication].delegate.window.rootViewController = loginViewController;
    }
}

#pragma mark - 设置图片资源

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    if (backgroundImage) {
        NSLog(@"设置背景图片: %@", backgroundImage);
        self.backgroundImageView.image = backgroundImage;
        NSLog(@"背景图片视图frame: %@", NSStringFromCGRect(self.backgroundImageView.frame));
    } else {
        NSLog(@"背景图片为nil");
    }
}

- (void)setLogoImage:(UIImage *)logoImage {
    if (logoImage) {
        self.logoImageView.image = logoImage;
    }
}

@end
