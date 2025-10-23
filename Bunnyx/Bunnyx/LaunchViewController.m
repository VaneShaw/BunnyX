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
    // 使用系统的LaunchImage作为背景
    UIImage *launchImage = [UIImage imageNamed:@"LaunchImage"];
    if (launchImage) {
        // 如果找到LaunchImage，直接设置为背景
        self.view.backgroundColor = [UIColor colorWithPatternImage:launchImage];
        self.logoImageView = [[UIImageView alloc]init];
        [self.view addSubview:self.logoImageView];
        [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.view);
            make.width.height.offset(175);
        }];
        self.logoImageView.image = [UIImage imageNamed:@"launch_logo"];
    } else {
        // 如果没有LaunchImage，使用默认背景色
        self.view.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0];
    }
    
    [self setupConstraints];
}

- (void)setupConstraints {

}

- (void)startLaunchAnimation {
    // 设置初始状态
    self.logoImageView.alpha = 0;
    self.logoImageView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.appNameLabel.alpha = 0;
    self.appNameLabel.transform = CGAffineTransformMakeTranslation(0, 30);
    
    // 执行动画
    [UIView animateWithDuration:1.0 delay:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // Logo动画
        self.logoImageView.alpha = 1.0;
        self.logoImageView.transform = CGAffineTransformIdentity;
        
        // 应用名称动画
        self.appNameLabel.alpha = 1.0;
        self.appNameLabel.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        // 动画完成后，延迟跳转到主界面
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self transitionToMainInterface];
        });
    }];
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
