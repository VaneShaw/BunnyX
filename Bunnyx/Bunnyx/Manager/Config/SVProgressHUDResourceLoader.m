//
//  SVProgressHUDResourceLoader.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "SVProgressHUDResourceLoader.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <objc/runtime.h>

@implementation SVProgressHUDResourceLoader

+ (void)load {
    // 使用 Method Swizzling 替换 SVProgressHUD 的 imageBundle 方法
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class svProgressHUDClass = NSClassFromString(@"SVProgressHUD");
        if (svProgressHUDClass) {
            Method originalMethod = class_getClassMethod(svProgressHUDClass, @selector(imageBundle));
            Method swizzledMethod = class_getClassMethod([self class], @selector(swizzled_imageBundle));
            
            if (originalMethod && swizzledMethod) {
                method_exchangeImplementations(originalMethod, swizzledMethod);
                NSLog(@"✅ 成功替换 SVProgressHUD imageBundle 方法");
            } else {
                NSLog(@"❌ 无法找到 SVProgressHUD imageBundle 方法");
            }
        }
    });
}

+ (NSBundle *)swizzled_imageBundle {
    // 完全替换原始实现，避免调用原始的 imageBundle 方法
    NSBundle *bundle = nil;
    
    // 方式1: 从 SVProgressHUD 类获取
    bundle = [NSBundle bundleForClass:[SVProgressHUD class]];
    NSURL *url = [bundle URLForResource:@"SVProgressHUD" withExtension:@"bundle"];
    if (url) {
        NSBundle *resourceBundle = [NSBundle bundleWithURL:url];
        if (resourceBundle) {
            NSLog(@"✅ 成功从 SVProgressHUD 类获取资源包");
            return resourceBundle;
        }
    }
    
    // 方式2: 从主包获取
    bundle = [NSBundle mainBundle];
    url = [bundle URLForResource:@"SVProgressHUD" withExtension:@"bundle"];
    if (url) {
        NSBundle *resourceBundle = [NSBundle bundleWithURL:url];
        if (resourceBundle) {
            NSLog(@"✅ 成功从主包获取资源包");
            return resourceBundle;
        }
    }
    
    // 方式3: 使用文件系统路径
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"SVProgressHUD" ofType:@"bundle"];
    if (bundlePath) {
        bundle = [NSBundle bundleWithPath:bundlePath];
        if (bundle) {
            NSLog(@"✅ 成功从文件系统路径获取资源包");
            return bundle;
        }
    }
    
    // 方式4: 尝试从 Pods 目录获取
    NSString *podsPath = [[NSBundle mainBundle] pathForResource:@"SVProgressHUD" ofType:@"bundle" inDirectory:@"Pods/SVProgressHUD/SVProgressHUD"];
    if (podsPath) {
        bundle = [NSBundle bundleWithPath:podsPath];
        if (bundle) {
            NSLog(@"✅ 成功从 Pods 目录获取资源包");
            return bundle;
        }
    }
    
    // 方式5: 直接返回主包，避免 nil URL 问题
    NSLog(@"⚠️ 无法找到 SVProgressHUD.bundle，返回主包");
    return [NSBundle mainBundle];
}


+ (UIImage *)imageNamed:(NSString *)name {
    NSBundle *bundle = [self swizzled_imageBundle];
    UIImage *image = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
    
    if (!image) {
        // 如果从资源包获取失败，尝试从主包获取
        image = [UIImage imageNamed:name];
        if (image) {
            NSLog(@"⚠️ 从主包获取图片: %@", name);
        } else {
            NSLog(@"❌ 无法获取图片: %@", name);
        }
    } else {
        NSLog(@"✅ 成功获取图片: %@", name);
    }
    
    return image;
}

@end
