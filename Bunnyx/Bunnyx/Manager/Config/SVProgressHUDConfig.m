//
//  SVProgressHUDConfig.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "SVProgressHUDConfig.h"
#import "SVProgressHUDResourceLoader.h"
#import <SVProgressHUD/SVProgressHUD.h>

@implementation SVProgressHUDConfig

+ (void)configureSVProgressHUD {
    // 配置SVProgressHUD的基本设置
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD setMinimumDismissTimeInterval:1.0];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeFlat];
    [SVProgressHUD setRingThickness:2.0];
    [SVProgressHUD setRingRadius:18.0];
    [SVProgressHUD setRingNoTextRadius:24.0];
    
    // 设置字体
    [SVProgressHUD setFont:[UIFont systemFontOfSize:16]];
    
    // 设置颜色
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    [SVProgressHUD setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
    
    // 测试资源包加载
    NSBundle *bundle = [SVProgressHUD imageBundle];
    if (bundle) {
        NSLog(@"SVProgressHUD 资源包: %@", bundle);
        
        // 测试图片加载
        UIImage *successImage = [SVProgressHUDResourceLoader imageNamed:@"success"];
        UIImage *errorImage = [SVProgressHUDResourceLoader imageNamed:@"error"];
        UIImage *infoImage = [SVProgressHUDResourceLoader imageNamed:@"info"];
        
        NSLog(@"成功图片: %@", successImage ? @"✅" : @"❌");
        NSLog(@"错误图片: %@", errorImage ? @"✅" : @"❌");
        NSLog(@"信息图片: %@", infoImage ? @"✅" : @"❌");
    } else {
        NSLog(@"⚠️ SVProgressHUD 资源包未找到，将使用默认样式");
    }
    
    NSLog(@"SVProgressHUD 配置完成");
}

+ (void)testSVProgressHUD {
    // 测试SVProgressHUD是否能正常工作
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"测试中..."];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            NSLog(@"SVProgressHUD 测试完成");
        });
    });
}

@end
