//
//  AppDelegate.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "AppDelegate.h"
#import "MainTabBarController.h"
#import "LaunchViewController.h"
#import "Manager/Config/SVProgressHUDConfig.h"
#import "PaymentExceptionHandler.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImageWebPCoder/SDWebImageWebPCoder.h>
#import <SDWebImage/SDWebImage.h>
#import "FirebaseCore.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // 注册WebP解码器（支持webp格式图片）
    SDImageWebPCoder *webPCoder = [SDImageWebPCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:webPCoder];
    
    // 配置SDWebImage缓存策略，防止内存和CPU过载导致闪退
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    // 设置内存缓存限制：50MB（根据设备内存动态调整，避免内存溢出）
    // 对于大量WebP图片，需要限制内存缓存，防止内存爆满
    imageCache.config.maxMemoryCost = 50 * 1024 * 1024; // 50MB
    // 设置内存缓存图片数量限制：100张（防止图片数量过多）
    imageCache.config.maxMemoryCount = 100;
    // 设置磁盘缓存限制：200MB
    imageCache.config.maxDiskAge = 7 * 24 * 60 * 60; // 7天
    imageCache.config.maxDiskSize = 200 * 1024 * 1024; // 200MB
    // 设置下载器最大并发数，避免同时解码过多WebP导致CPU过载
    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
    downloader.config.maxConcurrentDownloads = 5; // 限制并发下载数为3，减少CPU压力
    
    // 配置SVProgressHUD
    [SVProgressHUDConfig configureSVProgressHUD];
    
    // 初始化支付异常处理（处理未完成的交易）
    // 注意：iOS 13+ 在 SceneDelegate 中也会初始化，但这里初始化不会重复（单例模式）
    [[PaymentExceptionHandler sharedHandler] initialize];
    
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
    
    [FIRApp configure];
    
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
