//
//  LocalizationFileManager.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "LocalizationFileManager.h"
#import "NetworkManager.h"

@interface LocalizationFileManager ()

@property (nonatomic, strong) NSMutableDictionary *translationCache;
@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation LocalizationFileManager

#pragma mark - 单例

+ (instancetype)sharedManager {
    static LocalizationFileManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LocalizationFileManager alloc] init];
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
    self.translationCache = [NSMutableDictionary dictionary];
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [self createLocalizationFiles];
}

#pragma mark - 文件加载

- (NSDictionary *)loadTranslationsFromFileForLanguage:(LanguageType)language {
    // 直接从 .strings 文件加载翻译
    return [self getDefaultTranslationsForLanguage:language];
}

- (void)loadTranslationsFromServerForLanguage:(LanguageType)language
                                   completion:(void(^)(NSDictionary *translations, NSError *error))completion {
    
    NSString *languageCode = [self getLanguageCodeForLanguage:language];
    NSString *url = [NSString stringWithFormat:@"%@/localization/%@", BUNNYX_API_BASE_URL, languageCode];
    
    BUNNYX_LOG(@"从服务器加载翻译: %@", url);
    
    [[NetworkManager sharedManager] GET:url
                             parameters:nil
                                success:^(id responseObject) {
        NSDictionary *translations = responseObject;
        if (translations && [translations isKindOfClass:[NSDictionary class]]) {
            // 缓存翻译数据
            [self cacheTranslations:translations forLanguage:language];
            
            // 更新本地文件
            [self updateLocalizationFile:translations forLanguage:language];
            
            if (completion) {
                completion(translations, nil);
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"LocalizationFileManager" 
                                                 code:-1 
                                             userInfo:@{NSLocalizedDescriptionKey: @"服务器返回数据格式错误"}];
            if (completion) {
                completion(nil, error);
            }
        }
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"从服务器加载翻译失败: %@", error.localizedDescription);
        
        // 如果服务器加载失败，尝试从本地文件加载
        NSDictionary *localTranslations = [self loadTranslationsFromFileForLanguage:language];
        if (completion) {
            completion(localTranslations, error);
        }
    }];
}

#pragma mark - 缓存管理

- (void)cacheTranslations:(NSDictionary *)translations forLanguage:(LanguageType)language {
    NSString *key = [NSString stringWithFormat:@"translations_%ld", (long)language];
    [self.translationCache setObject:translations forKey:key];
    
    // 保存到用户偏好设置
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:translations];
    [self.userDefaults setObject:data forKey:key];
    [self.userDefaults synchronize];
    
    BUNNYX_LOG(@"翻译数据已缓存: %@", [self getLanguageNameForLanguage:language]);
}

- (NSDictionary *)getCachedTranslationsForLanguage:(LanguageType)language {
    NSString *key = [NSString stringWithFormat:@"translations_%ld", (long)language];
    
    // 先从内存缓存获取
    NSDictionary *cachedTranslations = self.translationCache[key];
    if (cachedTranslations) {
        return cachedTranslations;
    }
    
    // 从用户偏好设置获取
    NSData *data = [self.userDefaults objectForKey:key];
    if (data) {
        NSDictionary *translations = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (translations) {
            [self.translationCache setObject:translations forKey:key];
            return translations;
        }
    }
    
    return nil;
}

- (void)clearTranslationCache {
    [self.translationCache removeAllObjects];
    
    // 清除用户偏好设置中的缓存
    NSArray *keys = @[@"translations_0", @"translations_1"];
    for (NSString *key in keys) {
        [self.userDefaults removeObjectForKey:key];
    }
    [self.userDefaults synchronize];
    
    BUNNYX_LOG(@"翻译缓存已清除");
}

#pragma mark - 文件管理

- (void)createLocalizationFiles {
    // 不再需要创建本地化文件，直接使用 .strings 文件
    BUNNYX_LOG(@"使用 .strings 文件进行本地化");
}

- (void)updateLocalizationFile:(NSDictionary *)translations forLanguage:(LanguageType)language {
    // 不再需要更新本地化文件，直接使用 .strings 文件
    BUNNYX_LOG(@"使用 .strings 文件，无需更新本地化文件");
}

#pragma mark - 私有方法

// 这些方法不再需要，因为直接使用 .strings 文件

- (NSString *)getLanguageCodeForLanguage:(LanguageType)language {
    switch (language) {
        case LanguageTypeChinese:
            return @"zh-Hans";
        case LanguageTypeEnglish:
            return @"en";
        default:
            return @"zh-Hans";
    }
}

- (NSString *)getLanguageNameForLanguage:(LanguageType)language {
    switch (language) {
        case LanguageTypeChinese:
            return @"中文";
        case LanguageTypeEnglish:
            return @"English";
        default:
            return @"中文";
    }
}

- (NSDictionary *)getDefaultTranslationsForLanguage:(LanguageType)language {
    // 从 .strings 文件加载翻译
    NSString *languageCode = [self getLanguageCodeForLanguage:language];
    NSString *path = [[NSBundle mainBundle] pathForResource:languageCode ofType:@"lproj"];
    if (!path) {
        // Fallback to main bundle if lproj not found
        path = [[NSBundle mainBundle] bundlePath];
    }
    
    NSBundle *languageBundle = [NSBundle bundleWithPath:path];
    if (!languageBundle) {
        BUNNYX_ERROR(@"无法找到语言包: %@", languageCode);
        return [self getEmptyTranslations];
    }
    
    // 加载 Localizable.strings 文件
    NSString *stringsPath = [languageBundle pathForResource:@"Localizable" ofType:@"strings"];
    if (!stringsPath) {
        BUNNYX_ERROR(@"无法找到 Localizable.strings 文件: %@", languageCode);
        return [self getEmptyTranslations];
    }
    
    NSDictionary *translations = [NSDictionary dictionaryWithContentsOfFile:stringsPath];
    if (translations && translations.count > 0) {
        BUNNYX_LOG(@"成功从 .strings 文件加载翻译: %@ (%ld 条)", languageCode, (long)translations.count);
        return translations;
    } else {
        BUNNYX_ERROR(@"从 .strings 文件加载翻译失败: %@", languageCode);
        return [self getEmptyTranslations];
    }
}

- (NSDictionary *)getEmptyTranslations {
    // 返回空字典，让 LanguageManager 直接使用 key 作为显示内容
    return @{};
}

// 这些硬编码的翻译方法不再需要，因为直接使用 .strings 文件

@end
