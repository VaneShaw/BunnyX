//
//  AppDelegate.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "AppDelegate.h"
#import "MainTabBarController.h"
#import "LaunchViewController.h"
#import "Manager/Config/AppConfigManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[AppConfigManager sharedManager]getAppConfigWithSuccess:^(AppConfigModel * _Nonnull configModel) {
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    // 只在iOS 12及以下版本中设置启动页
    if (@available(iOS 13.0, *)) {
        // iOS 13+ 由 SceneDelegate 处理
        return YES;
    } else {
        // iOS 12 及以下版本
        LaunchViewController *launchViewController = [[LaunchViewController alloc] init];
        
        // 设置启动页图片（您需要将图片添加到Assets.xcassets中）
        UIImage *backgroundImage = [UIImage imageNamed:@"launch_background"];
        UIImage *logoImage = [UIImage imageNamed:@"launch_logo"];
        
        if (backgroundImage) {
            [launchViewController setBackgroundImage:backgroundImage];
        }
        if (logoImage) {
            [launchViewController setLogoImage:logoImage];
        }
        
        // 设置根视图控制器为启动页
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.window.rootViewController = launchViewController;
        [self.window makeKeyAndVisible];
    
    }
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
