//
//  LaunchViewController.m
//  Bunnyx
//
//  Created by fengwenxiao on 2024/11/30.
//

#import "LaunchViewController.h"
#import "LoginViewController.h"
#import <Masonry/Masonry.h>
#import "AdMobManager.h"
#import "BunnyxMacros.h"

@interface LaunchViewController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *appNameLabel;
@property (nonatomic, copy) LaunchViewControllerCompletionBlock completionBlock;
@property (nonatomic, assign) BOOL hasCompleted; // 是否已经完成（防止重复调用）
@property (nonatomic, strong) NSTimer *timeoutTimer; // 10秒超时定时器
@property (nonatomic, assign) NSDate *startTime; // 开始时间，用于计算是否超时

@end

@implementation LaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self startLaunchAnimation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 在视图显示后开始加载和展示开屏广告
    [self startSplashAdFlow];
}

- (void)dealloc {
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    // 清理完成回调，避免循环引用
    // 使用实例变量直接访问，避免属性访问器可能的问题
    _completionBlock = nil;
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

#pragma mark - 开屏广告逻辑

- (void)setCompletionBlock:(LaunchViewControllerCompletionBlock)completionBlock {
    // 使用实例变量直接赋值，避免属性访问器可能的问题
    // 手动 copy block 到堆上，确保 block 的生命周期正确
    _completionBlock = completionBlock ? [completionBlock copy] : nil;
}

- (void)startSplashAdFlow {
    NSLog(@"[LaunchViewController] 开始开屏广告流程");
    
    // 重置状态
    self.hasCompleted = NO;
    self.startTime = [NSDate date];
    
    // 启动10秒超时定时器
    [self startTimeoutTimer];
    
    // 先确保广告配置已加载，然后再检查是否有开屏广告配置
    [self ensureAdConfigLoadedAndShowAd];
}

- (void)ensureAdConfigLoadedAndShowAd {
    // 先检查当前是否已有配置
    AdMobConfigModel *config = [[AdMobManager sharedManager] getConfigForPlacement:AdMobPlacementSplash adType:AdMobTypeSplash];
    
    // 如果已有配置，直接展示广告
    if (config && !BUNNYX_IS_EMPTY_STRING(config.adUnitId)) {
        NSLog(@"[LaunchViewController] 已有开屏广告配置，开始展示广告");
        [self showSplashAd];
        return;
    }
    
    // 如果没有配置，先从接口获取广告配置
    NSLog(@"[LaunchViewController] 没有开屏广告配置，先从接口获取广告配置");
    __weak typeof(self) weakSelf = self;
    [[AdMobManager sharedManager] loadAdConfigWithSuccess:^(NSArray<AdMobConfigModel *> *configs) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.hasCompleted) {
            return;
        }
        
        NSLog(@"[LaunchViewController] 广告配置加载成功，共%lu个配置", (unsigned long)configs.count);
        
        // 配置加载完成后，再次检查是否有开屏广告配置
        AdMobConfigModel *splashConfig = [[AdMobManager sharedManager] getConfigForPlacement:AdMobPlacementSplash adType:AdMobTypeSplash];
        if (splashConfig && !BUNNYX_IS_EMPTY_STRING(splashConfig.adUnitId)) {
            NSLog(@"[LaunchViewController] 获取到开屏广告配置，开始展示广告");
            [strongSelf showSplashAd];
        } else {
            NSLog(@"[LaunchViewController] 接口返回的配置中没有开屏广告配置，直接进入app");
            // 没有开屏广告配置，直接完成
            [strongSelf completeLaunchFlow];
        }
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.hasCompleted) {
            return;
        }
        
        NSLog(@"[LaunchViewController] 获取广告配置失败: %@，直接进入app", error.localizedDescription);
        // 获取配置失败，直接完成
        [strongSelf completeLaunchFlow];
    }];
}

- (void)showSplashAd {
    // 使用AdMobManager的showSplashAdWithSuccess:failure:方法
    // 这个方法会自动检查是否有可用广告，如果没有则加载，加载完成后立即展示
    NSLog(@"[LaunchViewController] 开始加载和展示开屏广告");
    __weak typeof(self) weakSelf = self;
    [[AdMobManager sharedManager] showSplashAdWithSuccess:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            NSLog(@"[LaunchViewController] 开屏广告展示完成");
            [strongSelf completeLaunchFlow];
        }
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            NSLog(@"[LaunchViewController] 开屏广告展示失败或未配置: %@", error.localizedDescription);
            // 广告加载失败或展示失败，直接完成
            [strongSelf completeLaunchFlow];
        }
    }];
}

- (void)startTimeoutTimer {
    // 取消之前的定时器
    [self.timeoutTimer invalidate];
    
    // 创建10秒超时定时器
    __weak typeof(self) weakSelf = self;
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && !strongSelf.hasCompleted) {
            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:strongSelf.startTime];
            NSLog(@"[LaunchViewController] 10秒超时（已过去%.2f秒），广告未加载完成并开始播放，直接进入app", elapsed);
            // 10秒超时，无论广告状态如何，直接完成
            [strongSelf completeLaunchFlow];
        }
    }];
}

- (void)completeLaunchFlow {
    if (self.hasCompleted) {
        return;
    }
    
    self.hasCompleted = YES;
    
    // 取消超时定时器
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    
    NSLog(@"[LaunchViewController] 开屏页流程完成，执行后续逻辑");
    
    // 执行完成回调，执行后立即清空避免循环引用
    // 使用实例变量直接访问，避免属性访问器可能的问题
    LaunchViewControllerCompletionBlock completionBlock = _completionBlock;
    _completionBlock = nil; // 先清空，避免在执行回调时被重复调用
    
    if (completionBlock) {
        completionBlock();
    }
}

@end
