//
//  BunnyxMacros.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import <UIKit/UIKit.h>
#import "BunnyxNetworkMacros.h"

#ifndef BunnyxMacros_h
#define BunnyxMacros_h

// MARK: - 屏幕尺寸相关宏
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_BOUNDS [UIScreen mainScreen].bounds

// MARK: - 设备判断宏
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE_X (IS_IPHONE && SCREEN_HEIGHT >= 812.0)
#define IS_IPHONE_XS (IS_IPHONE && SCREEN_HEIGHT == 812.0)
#define IS_IPHONE_XR (IS_IPHONE && SCREEN_HEIGHT == 896.0)
#define IS_IPHONE_XS_MAX (IS_IPHONE && SCREEN_HEIGHT == 896.0)

// MARK: - 安全区域相关宏
#define SAFE_AREA_TOP (IS_IPHONE_X ? 44.0 : 20.0)
#define SAFE_AREA_BOTTOM (IS_IPHONE_X ? 34.0 : 0.0)
#define STATUS_BAR_HEIGHT (IS_IPHONE_X ? 44.0 : 20.0)
#define NAVIGATION_BAR_HEIGHT 44.0
#define TAB_BAR_HEIGHT (IS_IPHONE_X ? 83.0 : 49.0)

// MARK: - 颜色相关宏
#define RGB(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define RGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define HEX_COLOR(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:1.0]

// MARK: - 常用颜色
#define BUNNYX_MAIN_COLOR HEX_COLOR(0x007AFF)
#define BUNNYX_BACKGROUND_COLOR HEX_COLOR(0xF5F5F5)
#define BUNNYX_TEXT_COLOR HEX_COLOR(0x333333)
#define BUNNYX_LIGHT_TEXT_COLOR HEX_COLOR(0x999999)
#define BUNNYX_LINE_COLOR HEX_COLOR(0xE5E5E5)

// MARK: - 字体相关宏
#define FONT(size) [UIFont systemFontOfSize:size]
#define BOLD_FONT(size) [UIFont boldSystemFontOfSize:size]
#define MEDIUM_FONT(size) [UIFont systemFontOfSize:size weight:UIFontWeightMedium]

// MARK: - 国际化相关宏
#define LocalString(key) [[LanguageManager sharedManager] localizedStringForKey:key]
#define LocalStringWithDefault(key, defaultValue) [[LanguageManager sharedManager] localizedStringForKey:key defaultValue:defaultValue]

// MARK: - 常用字体大小
#define FONT_SIZE_10 10.0
#define FONT_SIZE_12 12.0
#define FONT_SIZE_14 14.0
#define FONT_SIZE_16 16.0
#define FONT_SIZE_18 18.0
#define FONT_SIZE_20 20.0
#define FONT_SIZE_24 24.0

// MARK: - 间距相关宏
#define MARGIN_5 5.0
#define MARGIN_10 10.0
#define MARGIN_15 15.0
#define MARGIN_20 20.0
#define MARGIN_30 30.0

// MARK: - 圆角相关宏
#define CORNER_RADIUS_4 4.0
#define CORNER_RADIUS_8 8.0
#define CORNER_RADIUS_12 12.0
#define CORNER_RADIUS_16 16.0

// MARK: - 弱引用宏
#define WEAK_SELF __weak typeof(self) weakSelf = self
#define STRONG_SELF __strong typeof(weakSelf) strongSelf = weakSelf

// MARK: - 单例宏
#define SINGLETON_INTERFACE(className) \
+ (instancetype)shared##className;

#define SINGLETON_IMPLEMENTATION(className) \
+ (instancetype)shared##className { \
    static className *instance = nil; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        instance = [[className alloc] init]; \
    }); \
    return instance; \
}

// MARK: - 日志宏
#ifdef DEBUG
#define BUNNYX_LOG(fmt, ...) NSLog((@"[Bunnyx] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define BUNNYX_ERROR(fmt, ...) NSLog((@"[Bunnyx ERROR] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define BUNNYX_LOG(fmt, ...)
#define BUNNYX_ERROR(fmt, ...)
#endif

// MARK: - 通知相关宏
#define BUNNYX_NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#define BUNNYX_POST_NOTIFICATION(name, object, userInfo) [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userInfo]
#define BUNNYX_ADD_OBSERVER(observer, selector, name, object) [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:name object:object]
#define BUNNYX_REMOVE_OBSERVER(observer) [[NSNotificationCenter defaultCenter] removeObserver:observer]

// MARK: - 用户偏好设置宏
#define BUNNYX_USER_DEFAULTS [NSUserDefaults standardUserDefaults]
#define BUNNYX_SET_OBJECT(key, object) [[NSUserDefaults standardUserDefaults] setObject:object forKey:key]
#define BUNNYX_GET_OBJECT(key) [[NSUserDefaults standardUserDefaults] objectForKey:key]
#define BUNNYX_SET_BOOL(key, value) [[NSUserDefaults standardUserDefaults] setBool:value forKey:key]
#define BUNNYX_GET_BOOL(key) [[NSUserDefaults standardUserDefaults] boolForKey:key]

// MARK: - 文件路径宏
#define BUNNYX_DOCUMENTS_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
#define BUNNYX_CACHES_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]
#define BUNNYX_TEMP_PATH NSTemporaryDirectory()

// MARK: - 版本相关宏
#define BUNNYX_APP_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#define BUNNYX_APP_BUILD [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]
#define BUNNYX_SYSTEM_VERSION [[UIDevice currentDevice] systemVersion]

// MARK: - 线程相关宏
#define BUNNYX_MAIN_QUEUE dispatch_get_main_queue()
#define BUNNYX_BACKGROUND_QUEUE dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define BUNNYX_ASYNC_MAIN(block) dispatch_async(dispatch_get_main_queue(), block)
#define BUNNYX_ASYNC_BACKGROUND(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)

// MARK: - 动画相关宏
#define BUNNYX_ANIMATION_DURATION 0.3
#define BUNNYX_ANIMATION_OPTIONS UIViewAnimationOptionCurveEaseInOut

// MARK: - 网络相关宏
#define BUNNYX_NETWORK_TIMEOUT 30.0
// BUNNYX_REQUEST_TIMEOUT 已在 BunnyxNetworkMacros.h 中定义

// MARK: - 分页相关宏
#define BUNNYX_PAGE_SIZE 20
#define BUNNYX_DEFAULT_PAGE 1

// MARK: - 字符串相关宏
#define BUNNYX_IS_EMPTY_STRING(str) (!str || [str isKindOfClass:[NSNull class]] || [str length] == 0)
#define BUNNYX_SAFE_STRING(str) (str ? str : @"")

// MARK: - 数组相关宏
#define BUNNYX_IS_EMPTY_ARRAY(arr) (!arr || [arr isKindOfClass:[NSNull class]] || [arr count] == 0)
#define BUNNYX_SAFE_ARRAY(arr) (arr ? arr : @[])

// MARK: - 字典相关宏
#define BUNNYX_IS_EMPTY_DICTIONARY(dict) (!dict || [dict isKindOfClass:[NSNull class]] || [dict count] == 0)
#define BUNNYX_SAFE_DICTIONARY(dict) (dict ? dict : @{})

#endif /* BunnyxMacros_h */
