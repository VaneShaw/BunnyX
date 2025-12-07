//
//  SceneDelegate.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "SceneDelegate.h"
#import "MainTabBarController.h"
#import "LaunchViewController.h"
#import "UserManager.h"
#import "NetworkManager.h"
#import "UserInfoManager.h"
#import "AppConfigManager.h"
#import "PaymentExceptionHandler.h"
#import "SubscriptionViewController.h"
#import "AdjustManager.h"
#import <AdjustSdk/Adjust.h>
#import "AdMobManager.h"

@interface SceneDelegate ()

@property (nonatomic, assign) BOOL hasScheduledNavigation;

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
    
    // 重置订阅弹窗会话标记（每次app启动时重置）
    [SubscriptionViewController resetSessionDialogFlag];
    
    // 初始化支付异常处理（处理未完成的交易）
    [[PaymentExceptionHandler sharedHandler] initialize];
    
    // 初始化 Adjust SDK 和 Facebook SDK（如果还没初始化）
    // 注意：打开事件（eventName=open）会在 AdjustManager 初始化完成后自动通过 /server/addAdjustEvent 接口上报
    if (![[AdjustManager sharedManager] isInitialized]) {
        UIApplication *application = [UIApplication sharedApplication];
        [[AdjustManager sharedManager] initializeWithApplication:application];
    }
    
    // 创建窗口并设置启动页
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
        
        // 先显示启动页
        [self showLaunchScreen];
        
        // 显示窗口
        [self.window makeKeyAndVisible];
        
        // 启动页请求应用配置，控制跳转时机
        [self loadAppConfigAndNavigate];
    }
}

- (void)showLaunchScreen {
    NSLog(@"[SceneDelegate] 显示启动页");
    // 创建启动页控制器
    LaunchViewController *launchViewController = [[LaunchViewController alloc] init];
    
    // 设置启动页图片（您需要将图片添加到Assets.xcassets中）
    UIImage *backgroundImage = [UIImage imageNamed:@"launch_background"];
    UIImage *logoImage = [UIImage imageNamed:@"launch_logo"];
    
    NSLog(@"[SceneDelegate] 背景图片加载状态: %@", backgroundImage ? @"成功" : @"失败");
    NSLog(@"[SceneDelegate] Logo图片加载状态: %@", logoImage ? @"成功" : @"失败");
    
    if (backgroundImage) {
        [launchViewController setBackgroundImage:backgroundImage];
    }
    if (logoImage) {
        [launchViewController setLogoImage:logoImage];
    }
    
    self.window.rootViewController = launchViewController;
    NSLog(@"[SceneDelegate] 启动页设置完成");
}

- (void)checkUserLoginStatusAndNavigate {
    NSLog(@"[SceneDelegate] 检查用户登录状态");
    BOOL isLoggedIn = [[UserManager sharedManager] isUserLoggedIn];
    NSLog(@"[SceneDelegate] 用户登录状态: %@", isLoggedIn ? @"已登录" : @"未登录");
    
    if (isLoggedIn) {
        // 已登录，跳转到主页
        NSLog(@"[SceneDelegate] 跳转到主页");
        [self navigateToMainInterface];
    } else {
        // 未登录，跳转到登录页
        NSLog(@"[SceneDelegate] 跳转到登录页");
        [self navigateToLoginPage];
    }
}

- (void)navigateToMainInterface {
    // 创建主界面
    MainTabBarController *mainTabBarController = [[MainTabBarController alloc] init];
    self.window.rootViewController = mainTabBarController;
    
    // 设置用户认证
    [self setupUserAuthentication];
    
    // 展示开屏广告（登录后）
    [self showSplashAdIfNeeded];
}

- (void)showSplashAdIfNeeded {
    // 延迟一点展示，确保界面已经显示
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AdMobManager sharedManager] showSplashAdWithSuccess:^{
            BUNNYX_LOG(@"开屏广告展示完成");
        } failure:^(NSError *error) {
            BUNNYX_LOG(@"开屏广告展示失败或未配置: %@", error.localizedDescription);
        }];
    });
}

- (void)setupUserAuthentication {
    // 已登录用户，设置认证
    NSString *accessToken = [[UserManager sharedManager] getAccessToken];
    if (accessToken) {
        // 检查token是否过期
        if ([[UserManager sharedManager] isTokenExpired]) {
            NSLog(@"[SceneDelegate] Token已过期，尝试刷新");
            [self refreshTokenIfNeeded];
        } else {
            // 设置Bearer认证
            [[NetworkManager sharedManager] setBearerAuthWithToken:accessToken];
            NSLog(@"[SceneDelegate] 自动设置Bearer认证成功");
            
            // 检查并恢复未完成的订单（与安卓版本保持一致）
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[PaymentExceptionHandler sharedHandler] checkAndRecoverPendingOrder];
            });
            
            // 刷新用户信息
            [self refreshUserInfoIfNeeded];
        }
    } else {
        NSLog(@"[SceneDelegate] 访问token不存在，清除登录状态");
        [[UserManager sharedManager] logout];
    }
}

- (void)refreshTokenIfNeeded {
    [[UserManager sharedManager] refreshTokenWithSuccess:^{
        NSLog(@"[SceneDelegate] Token刷新成功");
        // 刷新用户信息
        [self refreshUserInfoIfNeeded];
    } failure:^(NSError *error) {
        NSLog(@"[SceneDelegate] Token刷新失败: %@", error);
        // Token刷新失败，清除登录状态并跳转到登录页
        [[UserManager sharedManager] logout];
        [self navigateToLoginPage];
    }];
}

- (void)navigateToLoginPage {
    // 创建登录页面
    Class loginClass = NSClassFromString(@"LoginViewController");
    if (loginClass) {
        UIViewController *loginViewController = [[loginClass alloc] init];
        self.window.rootViewController = loginViewController;
    } else {
        // 如果没有找到LoginViewController，显示启动页
        [self showLaunchScreen];
    }
}

- (void)refreshUserInfoIfNeeded {
    // 检查本地是否有用户信息，如果没有则刷新
    UserInfoModel *userInfo = [[UserInfoManager sharedManager] getCurrentUserInfo];
    if (!userInfo) {
        NSLog(@"[SceneDelegate] 本地无用户信息，开始刷新");
        [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
            NSLog(@"[SceneDelegate] 刷新用户信息成功: %@", userInfo.nickname);
        } failure:^(NSError *error) {
            NSLog(@"[SceneDelegate] 刷新用户信息失败: %@", error);
        }];
    } else {
        NSLog(@"[SceneDelegate] 本地已有用户信息: %@", userInfo.nickname);
    }
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    
    // Adjust SDK 需要在场景激活时调用（对应 Android 的 onResume）
    [Adjust trackSubsessionStart];
    
    // 延迟请求 IDFA 授权（确保 UI 完全准备好后再请求，ATT 弹窗需要在可见界面时显示）
    // 只在首次激活时请求，避免重复请求
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 如果还没有获取到 IDFA，尝试再次请求授权
            AdjustManager *adjustManager = [AdjustManager sharedManager];
            if ([adjustManager isInitialized] && ![adjustManager getIDFA]) {
                // 请求授权（如果状态是 NotDetermined 会弹窗）
                [adjustManager requestIDFAAuthorizationIfNeeded];
            }
        });
    });
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}

- (void)loadAppConfigAndNavigate {
    __weak typeof(self) weakSelf = self;
    [[AppConfigManager sharedManager] getAppConfigWithForceRefresh:YES success:^(AppConfigModel *configModel) {
        // 初始化AdMob SDK（如果还没初始化）
        [weakSelf initializeAdMobIfNeeded];
        [weakSelf scheduleNavigationAfterDelay:1.0];
    } failure:^(NSError *error) {
        // 即使获取配置失败，也初始化AdMob
        [self initializeAdMobIfNeeded];
        [weakSelf scheduleNavigationAfterDelay:1.5];
    }];
}

- (void)initializeAdMobIfNeeded {
    // 直接使用本地配置的AdMob应用ID
    NSString *admobAppId = BUNNYX_ADMOB_APP_ID;
    if (!BUNNYX_IS_EMPTY_STRING(admobAppId)) {
        // 初始化AdMob SDK
        [[AdMobManager sharedManager] initializeWithAppId:admobAppId];
        
        // 加载广告配置
        [[AdMobManager sharedManager] loadAdConfigWithSuccess:^(NSArray<AdMobConfigModel *> *configs) {
            BUNNYX_LOG(@"AdMob配置加载成功，共%lu个配置", (unsigned long)configs.count);
        } failure:^(NSError *error) {
            BUNNYX_ERROR(@"AdMob配置加载失败: %@", error.localizedDescription);
        }];
    } else {
        BUNNYX_LOG(@"未配置AdMob App ID，跳过初始化");
    }
}

- (void)scheduleNavigationAfterDelay:(NSTimeInterval)delay {
    if (self.hasScheduledNavigation) {
        return;
    }
    self.hasScheduledNavigation = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self checkUserLoginStatusAndNavigate];
    });
}

@end
