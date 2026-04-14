//
//  UploadHistoryManager.m
//  Bunnyx
//
//  上传历史记录管理器（仿照安卓 UploadHistoryManager）
//

#import "UploadHistoryManager.h"
#import "BunnyxMacros.h"

static NSString *const kUploadHistoryCacheKey = @"BunnyxUploadHistoryCache";
static NSInteger const kMaxHistoryCount = 3; // 最多保存3条历史记录

@implementation UploadHistoryItem

- (instancetype)initWithImageUri:(NSString *)imageUri 
                  awsRelativePath:(NSString *)awsRelativePath 
                      awsFullPath:(NSString *)awsFullPath {
    self = [super init];
    if (self) {
        _imageUri = imageUri;
        _awsRelativePath = awsRelativePath;
        _awsFullPath = awsFullPath;
        _uploadTime = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (instancetype)init {
    return [self initWithImageUri:@"" awsRelativePath:@"" awsFullPath:@""];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _imageUri = [coder decodeObjectForKey:@"imageUri"] ?: @"";
        _awsRelativePath = [coder decodeObjectForKey:@"awsRelativePath"] ?: @"";
        _awsFullPath = [coder decodeObjectForKey:@"awsFullPath"] ?: @"";
        _uploadTime = [coder decodeDoubleForKey:@"uploadTime"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.imageUri forKey:@"imageUri"];
    [coder encodeObject:self.awsRelativePath forKey:@"awsRelativePath"];
    [coder encodeObject:self.awsFullPath forKey:@"awsFullPath"];
    [coder encodeDouble:self.uploadTime forKey:@"uploadTime"];
}

@end

@implementation UploadHistoryManager

+ (instancetype)sharedManager {
    static UploadHistoryManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UploadHistoryManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化
    }
    return self;
}

#pragma mark - Public Methods

- (void)addUploadHistory:(NSString *)imageUri 
          awsRelativePath:(NSString *)awsRelativePath 
              awsFullPath:(NSString *)awsFullPath {
    if (!imageUri || imageUri.length == 0 || 
        !awsRelativePath || awsRelativePath.length == 0 || 
        !awsFullPath || awsFullPath.length == 0) {
        return;
    }
    
    NSMutableArray<UploadHistoryItem *> *historyList = [[self getUploadHistoryList] mutableCopy];
    
    // 检查是否已存在相同的记录（根据Uri判断）
    for (NSInteger i = historyList.count - 1; i >= 0; i--) {
        if ([imageUri isEqualToString:historyList[i].imageUri]) {
            [historyList removeObjectAtIndex:i];
        }
    }
    
    // 添加新记录到列表开头
    UploadHistoryItem *newItem = [[UploadHistoryItem alloc] initWithImageUri:imageUri 
                                                              awsRelativePath:awsRelativePath 
                                                                  awsFullPath:awsFullPath];
    [historyList insertObject:newItem atIndex:0];
    
    // 保持最多3条记录
    if (historyList.count > kMaxHistoryCount) {
        historyList = [[historyList subarrayWithRange:NSMakeRange(0, kMaxHistoryCount)] mutableCopy];
    }
    
    // 保存到本地
    [self saveHistoryList:historyList];
}

- (void)removeUploadHistory:(NSString *)imageUri {
    if (!imageUri || imageUri.length == 0) {
        return;
    }
    
    NSMutableArray<UploadHistoryItem *> *historyList = [[self getUploadHistoryList] mutableCopy];
    
    for (NSInteger i = historyList.count - 1; i >= 0; i--) {
        if ([imageUri isEqualToString:historyList[i].imageUri]) {
            [historyList removeObjectAtIndex:i];
            break;
        }
    }
    
    [self saveHistoryList:historyList];
}

- (NSArray<UploadHistoryItem *> *)getUploadHistoryList {
    NSData *historyData = [[NSUserDefaults standardUserDefaults] objectForKey:kUploadHistoryCacheKey];
    if (!historyData) {
        return @[];
    }
    
    NSError *error = nil;
    NSArray *historyArray = [NSKeyedUnarchiver unarchiveObjectWithData:historyData];
    if (!historyArray || ![historyArray isKindOfClass:[NSArray class]]) {
        return @[];
    }
    
    // 转换为UploadHistoryItem数组
    NSMutableArray<UploadHistoryItem *> *result = [NSMutableArray array];
    for (id obj in historyArray) {
        if ([obj isKindOfClass:[UploadHistoryItem class]]) {
            [result addObject:obj];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            // 兼容旧格式（字典）
            NSDictionary *dict = (NSDictionary *)obj;
            UploadHistoryItem *item = [[UploadHistoryItem alloc] init];
            item.imageUri = dict[@"imageUri"] ?: @"";
            item.awsRelativePath = dict[@"awsRelativePath"] ?: @"";
            item.awsFullPath = dict[@"awsFullPath"] ?: @"";
            item.uploadTime = [dict[@"uploadTime"] doubleValue];
            [result addObject:item];
        }
    }
    
    return result;
}

- (UploadHistoryItem *)getLatestHistoryItem {
    NSArray<UploadHistoryItem *> *historyList = [self getUploadHistoryList];
    if (historyList.count == 0) {
        return nil;
    }
    // 由于addUploadHistory将新记录添加到列表开头，所以第一个就是最新的
    return historyList.firstObject;
}

- (BOOL)hasHistory {
    return [self getUploadHistoryList].count > 0;
}

- (void)clearAllHistory {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUploadHistoryCacheKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Private Methods

- (void)saveHistoryList:(NSArray<UploadHistoryItem *> *)historyList {
    if (!historyList) {
        return;
    }
    
    // 确保UploadHistoryItem支持NSCoding
    NSData *historyData = [NSKeyedArchiver archivedDataWithRootObject:historyList];
    [[NSUserDefaults standardUserDefaults] setObject:historyData forKey:kUploadHistoryCacheKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BUNNYX_LOG(@"保存历史记录成功，数量: %lu", (unsigned long)historyList.count);
}

@end

