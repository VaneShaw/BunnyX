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

@interface MainTabBarController ()

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置TabBar外观
    [self setupTabBarAppearance];
    
    // 创建视图控制器
    [self setupViewControllers];
}

- (void)setupTabBarAppearance {
    // 设置TabBar背景色
    self.tabBar.backgroundColor = [UIColor systemBackgroundColor];
    
    // 设置选中和未选中的颜色
    self.tabBar.tintColor = [UIColor systemGreenColor];
    self.tabBar.unselectedItemTintColor = [UIColor systemGrayColor];
    
    // 设置TabBar样式
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor systemBackgroundColor];
        
        // 设置选中状态的颜色
        appearance.stackedLayoutAppearance.selected.iconColor = [UIColor systemGreenColor];
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor systemGreenColor]};
        
        // 设置未选中状态的颜色
        appearance.stackedLayoutAppearance.normal.iconColor = [UIColor systemGrayColor];
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor systemGrayColor]};
        
        self.tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            self.tabBar.scrollEdgeAppearance = appearance;
        }
    }
}

- (void)setupViewControllers {
    // 创建首页控制器
    HomeViewController *homeVC = [[HomeViewController alloc] init];
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeVC];
    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"首页" image:[UIImage systemImageNamed:@"house"] selectedImage:[UIImage systemImageNamed:@"house.fill"]];
    
    // 创建热门控制器
    HotViewController *hotVC = [[HotViewController alloc] init];
    UINavigationController *hotNav = [[UINavigationController alloc] initWithRootViewController:hotVC];
    hotNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"热门" image:[UIImage systemImageNamed:@"flame"] selectedImage:[UIImage systemImageNamed:@"flame.fill"]];
    
    // 创建订阅控制器
    SubscriptionViewController *subscriptionVC = [[SubscriptionViewController alloc] init];
    UINavigationController *subscriptionNav = [[UINavigationController alloc] initWithRootViewController:subscriptionVC];
    subscriptionNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"订阅" image:[UIImage systemImageNamed:@"list.bullet"] selectedImage:[UIImage systemImageNamed:@"list.bullet"]];
    
    // 创建我的控制器
    ProfileViewController *profileVC = [[ProfileViewController alloc] init];
    UINavigationController *profileNav = [[UINavigationController alloc] initWithRootViewController:profileVC];
    profileNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"我的" image:[UIImage systemImageNamed:@"person"] selectedImage:[UIImage systemImageNamed:@"person.fill"]];
    
    // 设置视图控制器数组
    self.viewControllers = @[homeNav, hotNav, subscriptionNav, profileNav];
    
    // 默认选中首页
    self.selectedIndex = 0;
}

@end
