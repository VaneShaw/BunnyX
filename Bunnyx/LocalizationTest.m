#import <Foundation/Foundation.h>
#import "LocalizationFileManager.h"
#import "LanguageManager.h"
#import "BunnyxMacros.h"

/**
 * 国际化功能测试
 * 用于验证 .strings 文件是否正确加载
 */
void testLocalizationFunctionality() {
    NSLog(@"=== 国际化功能测试开始 ===");
    
    // 测试中文翻译
    NSLog(@"\n--- 测试中文翻译 ---");
    [[LanguageManager sharedManager] setLanguage:LanguageTypeChinese];
    
    LocalizationFileManager *fileManager = [LocalizationFileManager sharedManager];
    NSDictionary *chineseTranslations = [fileManager loadTranslationsFromFileForLanguage:LanguageTypeChinese];
    
    NSLog(@"中文翻译数量: %ld", (long)chineseTranslations.count);
    NSLog(@"中文翻译示例:");
    NSLog(@"  '例子' -> '%@'", chineseTranslations[@"例子"]);
    NSLog(@"  '设置' -> '%@'", chineseTranslations[@"设置"]);
    NSLog(@"  '欢迎使用' -> '%@'", chineseTranslations[@"欢迎使用"]);
    
    // 测试英文翻译
    NSLog(@"\n--- 测试英文翻译 ---");
    [[LanguageManager sharedManager] setLanguage:LanguageTypeEnglish];
    
    NSDictionary *englishTranslations = [fileManager loadTranslationsFromFileForLanguage:LanguageTypeEnglish];
    
    NSLog(@"英文翻译数量: %ld", (long)englishTranslations.count);
    NSLog(@"英文翻译示例:");
    NSLog(@"  '例子' -> '%@'", englishTranslations[@"例子"]);
    NSLog(@"  '设置' -> '%@'", englishTranslations[@"设置"]);
    NSLog(@"  '欢迎使用' -> '%@'", englishTranslations[@"欢迎使用"]);
    
    // 测试宏功能
    NSLog(@"\n--- 测试宏功能 ---");
    NSLog(@"LocalString('例子'): %@", LocalString(@"例子"));
    NSLog(@"LocalString('设置'): %@", LocalString(@"设置"));
    NSLog(@"LocalString('欢迎使用'): %@", LocalString(@"欢迎使用"));
    
    NSLog(@"\n=== 国际化功能测试完成 ===");
}
