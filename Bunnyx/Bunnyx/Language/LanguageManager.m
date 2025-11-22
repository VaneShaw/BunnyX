//
//  LanguageManager.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "LanguageManager.h"
#import "LocalizationFileManager.h"
#import <UIKit/UIKit.h>
#import "MainTabBarController.h"
#import "NetworkManager.h"
#import "AppConfigManager.h"

// 通知名称
NSString * const LanguageDidChangeNotification = @"LanguageDidChangeNotification";

// 用户偏好设置key
static NSString * const kLanguageKey = @"BunnyxLanguage";

@interface LanguageManager ()

@property (nonatomic, assign) LanguageType currentLanguage;
@property (nonatomic, copy) NSString *currentLanguageCode;
@property (nonatomic, copy) NSString *currentLanguageName;
@property (nonatomic, assign) BOOL isRTL;

@end

@implementation LanguageManager

#pragma mark - 单例

+ (instancetype)sharedManager {
    static LanguageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LanguageManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupManager];
    }
    return self;
}

- (void)setupManager {
    // 从用户偏好设置中读取语言设置
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 检查用户是否在语言设置页面手动设置过语言
    if ([defaults objectForKey:kLanguageKey] != nil) {
        // 如果存在保存的语言设置，使用用户设置的语言
        NSInteger savedLanguage = [defaults integerForKey:kLanguageKey];
        if (savedLanguage == LanguageTypeChinese || savedLanguage == LanguageTypeEnglish) {
            [self setLanguage:(LanguageType)savedLanguage];
            return;
        }
    }
    
    // 如果没有保存的语言设置，根据系统语言自动判断
    [self useSystemLanguageWithoutSaving];
}

#pragma mark - 语言切换

- (void)setLanguage:(LanguageType)language {
    if (_currentLanguage == language) {
        return;
    }
    
    _currentLanguage = language;
    
    // 更新语言代码和名称
    switch (language) {
        case LanguageTypeChinese:
            _currentLanguageCode = @"zh-Hans";
            _currentLanguageName = @"中文";
            _isRTL = NO;
            break;
        case LanguageTypeEnglish:
            _currentLanguageCode = @"en";
            _currentLanguageName = @"English";
            _isRTL = NO;
            break;
    }
    
    // 保存到用户偏好设置
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:language forKey:kLanguageKey];
    // 按系统做法，写入 AppleLanguages 以让 NSLocalizedString 读取对应 .lproj
    if (_currentLanguageCode.length > 0) {
        [defaults setObject:@[_currentLanguageCode] forKey:@"AppleLanguages"];
    }
    [defaults synchronize];
    
    // 发送语言切换通知
    [[NSNotificationCenter defaultCenter] postNotificationName:LanguageDidChangeNotification object:nil];
    
    // 延迟更新网络请求头中的 Accept-Language，避免初始化顺序问题
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            NetworkManager *networkManager = [NetworkManager sharedManager];
            if (networkManager && [networkManager respondsToSelector:@selector(updateCommonHeaders)]) {
                [networkManager updateCommonHeaders];
            }
        } @catch (NSException *exception) {
            BUNNYX_ERROR(@"更新请求头失败: %@", exception);
        }
    });
    
    BUNNYX_LOG(@"语言已切换到: %@", _currentLanguageName);
    
    // 切换语言后重新获取配置，强制刷新以获取对应语言的配置
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            AppConfigManager *configManager = [AppConfigManager sharedManager];
            if (configManager) {
                [configManager getAppConfigWithForceRefresh:YES success:^(AppConfigModel *configModel) {
                    BUNNYX_LOG(@"语言切换后配置获取成功");
                } failure:^(NSError *error) {
                    BUNNYX_ERROR(@"语言切换后配置获取失败: %@", error.localizedDescription);
                }];
            }
        } @catch (NSException *exception) {
            BUNNYX_ERROR(@"调用配置获取失败: %@", exception);
        }
    });
    
    // 立即重建根界面，使文案生效（无需逐控件 setTitle）
    [self rebuildRootInterface];
}

- (void)setLanguageWithCode:(NSString *)languageCode {
    LanguageType language = LanguageTypeChinese; // 默认中文
    
    if ([languageCode hasPrefix:@"en"]) {
        language = LanguageTypeEnglish;
    } else if ([languageCode hasPrefix:@"zh"]) {
        language = LanguageTypeChinese;
    }
    
    [self setLanguage:language];
}

- (NSString *)localizedStringForKey:(NSString *)key {
    return [self localizedStringForKey:key defaultValue:key];
}

- (NSString *)localizedStringForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    if (BUNNYX_IS_EMPTY_STRING(key)) {
        return defaultValue ?: @"";
    }
    
    // 获取当前语言的本地化字符串
    NSString *localizedString = [self getLocalizedStringForKey:key language:_currentLanguage];
    
    if (localizedString && localizedString.length > 0) {
        return localizedString;
    }
    
    // 如果没有找到，返回默认值（中文key）
    return defaultValue ?: key;
}

#pragma mark - 语言信息

- (NSArray<NSDictionary *> *)supportedLanguages {
    return @[
        @{
            @"type": @(LanguageTypeChinese),
            @"code": @"zh-Hans",
            @"name": @"中文",
            @"displayName": @"中文"
        },
        @{
            @"type": @(LanguageTypeEnglish),
            @"code": @"en",
            @"name": @"English",
            @"displayName": @"English"
        }
    ];
}

- (NSString *)displayNameForLanguage:(LanguageType)language {
    switch (language) {
        case LanguageTypeChinese:
            return @"中文";
        case LanguageTypeEnglish:
            return @"English";
        default:
            return @"中文";
    }
}

- (BOOL)isLanguageSupported:(NSString *)languageCode {
    if (BUNNYX_IS_EMPTY_STRING(languageCode)) {
        return NO;
    }
    
    return [languageCode hasPrefix:@"zh"] || [languageCode hasPrefix:@"en"];
}

#pragma mark - 系统语言

- (LanguageType)systemLanguage {
    NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSString *preferredLanguage = languages.firstObject;
    
    if ([preferredLanguage hasPrefix:@"zh"]) {
        // 系统语言为中文，返回中文
        return LanguageTypeChinese;
    }
    
    // 系统语言不是中文的，都默认返回英文
    return LanguageTypeEnglish;
}

- (void)useSystemLanguage {
    LanguageType systemLanguage = [self systemLanguage];
    [self setLanguage:systemLanguage];
}

/// 使用系统语言但不保存到用户偏好设置（用于首次启动时的自动判断）
- (void)useSystemLanguageWithoutSaving {
    LanguageType systemLanguage = [self systemLanguage];
    
    // 直接设置语言属性，不保存到 NSUserDefaults
    _currentLanguage = systemLanguage;
    
    // 更新语言代码和名称
    switch (systemLanguage) {
        case LanguageTypeChinese:
            _currentLanguageCode = @"zh-Hans";
            _currentLanguageName = @"中文";
            _isRTL = NO;
            break;
        case LanguageTypeEnglish:
            _currentLanguageCode = @"en";
            _currentLanguageName = @"English";
            _isRTL = NO;
            break;
    }
    
    // 按系统做法，写入 AppleLanguages 以让 NSLocalizedString 读取对应 .lproj
    if (_currentLanguageCode.length > 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@[_currentLanguageCode] forKey:@"AppleLanguages"];
        [defaults synchronize];
    }
    
    BUNNYX_LOG(@"根据系统语言自动设置为: %@", _currentLanguageName);
}

#pragma mark - 通知

+ (NSString *)languageDidChangeNotification {
    return LanguageDidChangeNotification;
}

#pragma mark - 私有方法

- (NSString *)getLocalizedStringForKey:(NSString *)key language:(LanguageType)language {
    // 首先尝试从缓存获取
    LocalizationFileManager *fileManager = [LocalizationFileManager sharedManager];
    NSDictionary *cachedTranslations = [fileManager getCachedTranslationsForLanguage:language];
    
    if (cachedTranslations && cachedTranslations[key]) {
        return cachedTranslations[key];
    }
    
    // 如果缓存中没有，从文件加载
    NSDictionary *fileTranslations = [fileManager loadTranslationsFromFileForLanguage:language];
    if (fileTranslations && fileTranslations[key]) {
        // 缓存翻译数据
        [fileManager cacheTranslations:fileTranslations forLanguage:language];
        return fileTranslations[key];
    }
    
    // 如果找不到翻译，直接返回 key 本身
    return key;
}

- (NSDictionary *)getTranslationsForLanguage:(LanguageType)language {
    // 这里返回对应语言的翻译字典
    // 实际项目中应该从本地化文件或服务器加载
    
    switch (language) {
        case LanguageTypeChinese:
            return [self getChineseTranslations];
        case LanguageTypeEnglish:
            return [self getEnglishTranslations];
        default:
            return [self getChineseTranslations];
    }
}

#pragma mark - UI重建
- (void)rebuildRootInterface {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *targetWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *ws = (UIWindowScene *)scene;
                    targetWindow = ws.windows.firstObject;
                    break;
                }
            }
        } else {
            targetWindow = [UIApplication sharedApplication].keyWindow;
        }
        if (!targetWindow) { return; }
        MainTabBarController *root = [[MainTabBarController alloc] init];
        targetWindow.rootViewController = root;
        [targetWindow makeKeyAndVisible];
        CATransition *fade = [CATransition animation];
        fade.type = kCATransitionFade;
        fade.duration = 0.2;
        [targetWindow.layer addAnimation:fade forKey:@"bx.lang.fade"];
    });
}

- (NSDictionary *)getChineseTranslations {
    // 中文翻译（key就是中文本身）
    return @{
        @"例子": @"例子",
        @"你好": @"你好",
        @"世界": @"世界",
        @"欢迎": @"欢迎",
        @"设置": @"设置",
        @"关于": @"关于",
        @"帮助": @"帮助",
        @"退出": @"退出",
        @"确定": @"确定",
        @"取消": @"取消",
        @"保存": @"保存",
        @"删除": @"删除",
        @"编辑": @"编辑",
        @"添加": @"添加",
        @"搜索": @"搜索",
        @"登录": @"登录",
        @"注册": @"注册",
        @"密码": @"密码",
        @"用户名": @"用户名",
        @"邮箱": @"邮箱",
        @"电话": @"电话",
        @"地址": @"地址",
        @"时间": @"时间",
        @"日期": @"日期",
        @"成功": @"成功",
        @"失败": @"失败",
        @"错误": @"错误",
        @"警告": @"警告",
        @"信息": @"信息",
        @"加载中": @"加载中",
        @"请稍候": @"请稍候",
        @"网络错误": @"网络错误",
        @"服务器错误": @"服务器错误",
        @"数据错误": @"数据错误",
        @"权限不足": @"权限不足",
        @"操作成功": @"操作成功",
        @"操作失败": @"操作失败"
    };
}

- (NSDictionary *)getEnglishTranslations {
    // 英文翻译
    return @{
        @"例子": @"Example",
        @"你好": @"Hello",
        @"世界": @"World",
        @"欢迎": @"Welcome",
        @"设置": @"Settings",
        @"关于": @"About",
        @"帮助": @"Help",
        @"退出": @"Exit",
        @"确定": @"OK",
        @"取消": @"Cancel",
        @"保存": @"Save",
        @"删除": @"Delete",
        @"编辑": @"Edit",
        @"添加": @"Add",
        @"搜索": @"Search",
        @"登录": @"Login",
        @"注册": @"Register",
        @"密码": @"Password",
        @"用户名": @"Username",
        @"邮箱": @"Email",
        @"电话": @"Phone",
        @"地址": @"Address",
        @"时间": @"Time",
        @"日期": @"Date",
        @"成功": @"Success",
        @"失败": @"Failure",
        @"错误": @"Error",
        @"警告": @"Warning",
        @"信息": @"Information",
        @"加载中": @"Loading",
        @"请稍候": @"Please wait",
        @"网络错误": @"Network Error",
        @"服务器错误": @"Server Error",
        @"数据错误": @"Data Error",
        @"权限不足": @"Insufficient Permission",
        @"操作成功": @"Operation Successful",
        @"操作失败": @"Operation Failed"
    };
}

@end
