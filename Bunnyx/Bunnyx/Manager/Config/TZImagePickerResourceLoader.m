//
//  TZImagePickerResourceLoader.m
//  Bunnyx
//

#import "TZImagePickerResourceLoader.h"
#import <objc/runtime.h>

@implementation TZImagePickerResourceLoader

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clazz = NSClassFromString(@"TZImagePickerController");
        SEL originalSel = NSSelectorFromString(@"tz_imagePickerBundle");
        SEL swizzledSel = @selector(swizzled_tz_imagePickerBundle);
        
        Method originalMethod = class_getClassMethod(clazz, originalSel);
        Method swizzledMethod = class_getClassMethod(self, swizzledSel);
        if (clazz && originalMethod && swizzledMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
            NSLog(@"✅ 已替换 TZImagePickerController tz_imagePickerBundle 方法");
        } else {
            // 某些版本方法名不同，尝试 bundle 方法名回退
            originalSel = NSSelectorFromString(@"bundle");
            originalMethod = class_getClassMethod(clazz, originalSel);
            if (clazz && originalMethod && swizzledMethod) {
                method_exchangeImplementations(originalMethod, swizzledMethod);
                NSLog(@"✅ 已替换 TZImagePickerController bundle 方法");
            } else {
                NSLog(@"⚠️ 未找到 TZImagePickerController 资源bundle方法，跳过Swizzle");
            }
        }
    });
}

+ (NSBundle *)swizzled_tz_imagePickerBundle {
    // 优先：从类获取
    Class tzClass = NSClassFromString(@"TZImagePickerController");
    NSBundle *bundle = [NSBundle bundleForClass:tzClass];
    NSURL *url = [bundle URLForResource:@"TZImagePickerController" withExtension:@"bundle"];
    if (url) {
        NSBundle *res = [NSBundle bundleWithURL:url];
        if (res) return res;
    }
    
    // 次选：主包
    bundle = [NSBundle mainBundle];
    url = [bundle URLForResource:@"TZImagePickerController" withExtension:@"bundle"];
    if (url) {
        NSBundle *res = [NSBundle bundleWithURL:url];
        if (res) return res;
    }
    
    // 回退：路径查找（Pods场景）
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TZImagePickerController" ofType:@"bundle"];
    if (path) {
        NSBundle *res = [NSBundle bundleWithPath:path];
        if (res) return res;
    }
    
    // 最后回退主bundle，避免 nil 导致崩溃
    NSLog(@"⚠️ 未找到 TZImagePickerController.bundle，回退主Bundle");
    return [NSBundle mainBundle];
}

@end


