//
//  LocalizationFileManager.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import <Foundation/Foundation.h>
#import "LanguageManager.h"
#import "BunnyxMacros.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 本地化文件管理器
 * 负责从本地文件或服务器加载翻译数据
 */
@interface LocalizationFileManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

#pragma mark - 文件加载

/**
 * 从本地文件加载翻译数据
 * @param language 语言类型
 * @return 翻译字典
 */
- (NSDictionary *)loadTranslationsFromFileForLanguage:(LanguageType)language;

/**
 * 从服务器加载翻译数据
 * @param language 语言类型
 * @param completion 完成回调
 */
- (void)loadTranslationsFromServerForLanguage:(LanguageType)language
                                   completion:(void(^)(NSDictionary *translations, NSError *error))completion;

#pragma mark - 缓存管理

/**
 * 缓存翻译数据
 * @param translations 翻译字典
 * @param language 语言类型
 */
- (void)cacheTranslations:(NSDictionary *)translations forLanguage:(LanguageType)language;

/**
 * 获取缓存的翻译数据
 * @param language 语言类型
 * @return 缓存的翻译字典
 */
- (NSDictionary *)getCachedTranslationsForLanguage:(LanguageType)language;

/**
 * 清除翻译缓存
 */
- (void)clearTranslationCache;

#pragma mark - 文件管理

/**
 * 创建本地化文件
 */
- (void)createLocalizationFiles;

/**
 * 更新本地化文件
 * @param translations 翻译字典
 * @param language 语言类型
 */
- (void)updateLocalizationFile:(NSDictionary *)translations forLanguage:(LanguageType)language;

@end

NS_ASSUME_NONNULL_END
