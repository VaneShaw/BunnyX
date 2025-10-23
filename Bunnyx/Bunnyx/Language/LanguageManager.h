//
//  LanguageManager.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import <Foundation/Foundation.h>
#import "BunnyxMacros.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 支持的语言类型
 */
typedef NS_ENUM(NSInteger, LanguageType) {
    LanguageTypeChinese = 0,    // 中文
    LanguageTypeEnglish = 1     // 英文
};

/**
 * 语言管理器
 * 负责应用的语言切换和本地化字符串管理
 */
@interface LanguageManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

/// 当前语言类型
@property (nonatomic, assign, readonly) LanguageType currentLanguage;

/// 当前语言代码 (zh-Hans, en)
@property (nonatomic, copy, readonly) NSString *currentLanguageCode;

/// 当前语言名称
@property (nonatomic, copy, readonly) NSString *currentLanguageName;

/// 是否支持RTL (从右到左)
@property (nonatomic, assign, readonly) BOOL isRTL;

#pragma mark - 语言切换

/**
 * 设置应用语言
 * @param language 语言类型
 */
- (void)setLanguage:(LanguageType)language;

/**
 * 设置应用语言（通过语言代码）
 * @param languageCode 语言代码 (zh-Hans, en)
 */
- (void)setLanguageWithCode:(NSString *)languageCode;

/**
 * 获取本地化字符串
 * @param key 中文key
 * @return 本地化字符串，如果没有找到则返回中文key
 */
- (NSString *)localizedStringForKey:(NSString *)key;

/**
 * 获取本地化字符串（带默认值）
 * @param key 中文key
 * @param defaultValue 默认值
 * @return 本地化字符串
 */
- (NSString *)localizedStringForKey:(NSString *)key defaultValue:(NSString *)defaultValue;

#pragma mark - 语言信息

/**
 * 获取所有支持的语言
 * @return 支持的语言数组
 */
- (NSArray<NSDictionary *> *)supportedLanguages;

/**
 * 获取语言显示名称
 * @param language 语言类型
 * @return 语言显示名称
 */
- (NSString *)displayNameForLanguage:(LanguageType)language;

/**
 * 检查是否支持指定语言
 * @param languageCode 语言代码
 * @return 是否支持
 */
- (BOOL)isLanguageSupported:(NSString *)languageCode;

#pragma mark - 系统语言

/**
 * 获取系统语言
 * @return 系统语言类型
 */
- (LanguageType)systemLanguage;

/**
 * 使用系统语言
 */
- (void)useSystemLanguage;

#pragma mark - 通知

/**
 * 语言切换通知名称
 */
+ (NSString *)languageDidChangeNotification;

@end

NS_ASSUME_NONNULL_END
