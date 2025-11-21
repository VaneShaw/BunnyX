//
//  MainTabBarController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "MainTabBarController.h"
#import "HomeViewController.h"
#import "HotViewController.h"
#import "SubscriptionViewController.h"
#import "ProfileViewController.h"
#import "VersionUpdateDialog.h"
#import "SignInDialog.h"
#import "AppConfigManager.h"
#import "AppConfigModel.h"
#import "NewAppInfo.h"
#import "BunnyxMacros.h"

@interface MainTabBarController ()

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置TabBar外观
    [self setupTabBarAppearance];
    
    // 创建视图控制器
    [self setupViewControllers];
    
    // 检查版本更新和签到弹窗（checkVersionUpdateAndMaybeShowSign）
    [self checkVersionUpdateAndMaybeShowSign];
}

- (void)setupTabBarAppearance {
    // 设置TabBar背景色为黑色
    self.tabBar.backgroundColor = [UIColor blackColor];
    
    // 设置选中和未选中的文字颜色（图标使用原始图片，不需要设置tintColor）
    self.tabBar.tintColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.3 alpha:1.0]; // 绿色（用于文字）
    self.tabBar.unselectedItemTintColor = [UIColor colorWithWhite:0.6 alpha:1.0]; // 浅灰色（用于文字）
    
    // 设置TabBar样式
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor blackColor];
        
        // 设置选中状态的文字颜色（图标使用原始图片，不设置iconColor）
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor colorWithRed:0.0 green:0.7 blue:0.3 alpha:1.0]};
        
        // 设置未选中状态的文字颜色（图标使用原始图片，不设置iconColor）
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.6 alpha:1.0]};
        
        self.tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            self.tabBar.scrollEdgeAppearance = appearance;
        }
    }
}

- (void)setupViewControllers {
    // 创建首页控制器并包裹导航
    HomeViewController *homeVC = [[HomeViewController alloc] init];
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeVC];
    [homeNav setNavigationBarHidden:YES animated:NO];
    // 设置图片为原始渲染模式，保留原始颜色和图案，并调整大小
    UIImage *homeDefaultImage = [[UIImage imageNamed:@"tabbar_home_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *homeSelectedImage = [[UIImage imageNamed:@"tabbar_home_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:LocalString(@"首页") image:[self resizeTabBarImage:homeDefaultImage] selectedImage:[self resizeTabBarImage:homeSelectedImage]];
    
    // 创建热门控制器并包裹导航
    HotViewController *hotVC = [[HotViewController alloc] init];
    UINavigationController *hotNav = [[UINavigationController alloc] initWithRootViewController:hotVC];
    [hotNav setNavigationBarHidden:YES animated:NO];
    UIImage *hotDefaultImage = [[UIImage imageNamed:@"tabbar_hot_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *hotSelectedImage = [[UIImage imageNamed:@"tabbar_hot_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    hotNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:LocalString(@"热门") image:[self resizeTabBarImage:hotDefaultImage] selectedImage:[self resizeTabBarImage:hotSelectedImage]];
    
    // 创建订阅控制器并包裹导航
    SubscriptionViewController *subscriptionVC = [[SubscriptionViewController alloc] init];
    UINavigationController *subNav = [[UINavigationController alloc] initWithRootViewController:subscriptionVC];
    [subNav setNavigationBarHidden:YES animated:NO];
    UIImage *subDefaultImage = [[UIImage imageNamed:@"tabbar_Subscribe_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *subSelectedImage = [[UIImage imageNamed:@"tabbar_Subscribe_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    subNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:LocalString(@"订阅") image:[self resizeTabBarImage:subDefaultImage] selectedImage:[self resizeTabBarImage:subSelectedImage]];
    
    // 创建我的控制器并包裹导航
    ProfileViewController *profileVC = [[ProfileViewController alloc] init];
    UINavigationController *profileNav = [[UINavigationController alloc] initWithRootViewController:profileVC];
    [profileNav setNavigationBarHidden:YES animated:NO];
    UIImage *mineDefaultImage = [[UIImage imageNamed:@"tabbar_mine_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *mineSelectedImage = [[UIImage imageNamed:@"tabbar_mine_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    profileNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:LocalString(@"我的") image:[self resizeTabBarImage:mineDefaultImage] selectedImage:[self resizeTabBarImage:mineSelectedImage]];
    
    // 设置视图控制器数组
    self.viewControllers = @[homeNav, hotNav, subNav, profileNav];
    
    // 默认选中首页
    self.selectedIndex = 0;
}

/// 调整TabBar图标大小（UITabBarItem推荐大小：25x25pt @1x，50x50pt @2x，75x75pt @3x）
- (UIImage *)resizeTabBarImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    
    // UITabBarItem图标推荐大小：25x25pt
    CGFloat targetSize = 25.0;
    CGFloat scale = [UIScreen mainScreen].scale;
    
    // UIImage的size属性已经是逻辑大小（points），不需要除以scale
    // 如果图片已经是指定大小，直接返回（允许1pt的误差）
    if (fabs(image.size.width - targetSize) < 1.0 && fabs(image.size.height - targetSize) < 1.0) {
        return image;
    }
    
    // 调整图片大小，保持原始scale
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(targetSize, targetSize), NO, scale);
    [image drawInRect:CGRectMake(0, 0, targetSize, targetSize)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 保持原始渲染模式
    return [resizedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - 版本更新和签到弹窗

/**
 * 检查版本更新信息，如果有版本更新则先显示版本更新弹窗，关闭后再显示签到弹窗
 * 如果没有版本更新，直接显示签到弹窗
 * 确保版本更新弹窗始终在最上层（checkVersionUpdateAndMaybeShowSign）
 */
- (void)checkVersionUpdateAndMaybeShowSign {
    // 获取应用配置（AppConfigManager.getInstance().getAppConfig()）
    AppConfigModel *config = [[AppConfigManager sharedManager] getCachedConfig];
    
    // 检查是否有版本更新信息（config.getNew_app_info() != null）
    // 只要 new_app_info 不为 null 就显示版本更新弹窗，不进行版本比较
    NewAppInfo *appInfo = config.latestAppInfo;
    if (config != nil && appInfo != nil) {
        // 有版本更新信息，构建VersionUpdateInfo（GetAppConfigApi.NewAppInfo）
        VersionUpdateInfo *versionInfo = [[VersionUpdateInfo alloc] init];
        versionInfo.forceType = appInfo.forceType; // forceType
        versionInfo.appVersion = appInfo.appVersion ?: @""; // appVersion
        versionInfo.updateMsg = appInfo.updateMsg ?: @""; // updateMsg
        versionInfo.appUrl = appInfo.appUrl ?: @""; // appUrl
        versionInfo.appCode = appInfo.appCode ?: @"ios"; // appCode
        versionInfo.appSize = appInfo.appSize ?: @""; // appSize
        
        // 先显示版本更新弹窗，等关闭后再显示签到弹窗（VersionUpdateDialog.showWithListener）
        [VersionUpdateDialog showWithAppInfo:versionInfo onDismiss:^{
            // 版本更新弹窗关闭后，显示签到弹窗）
            [self requestSignInfoAndMaybeShow];
        }];
        return;
    }
    
    // 没有版本更新，直接显示签到弹窗）
    [self requestSignInfoAndMaybeShow];
}

/**
 * 请求签到信息并可能显示签到弹窗（requestSignInfoAndMaybeShow）
 */
- (void)requestSignInfoAndMaybeShow {
    // 调用SignInDialog.show，内部会请求数据并判断是否显示）
    [SignInDialog show];
}

@end
