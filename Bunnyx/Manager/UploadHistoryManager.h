//
//  UploadHistoryManager.h
//  Bunnyx
//
//  上传历史记录管理器（仿照安卓 UploadHistoryManager）
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 上传历史记录数据模型
@interface UploadHistoryItem : NSObject <NSCoding>

@property (nonatomic, strong) NSString *imageUri;          // 图片Uri或本地路径
@property (nonatomic, strong) NSString *awsRelativePath;   // AWS相对路径
@property (nonatomic, strong) NSString *awsFullPath;        // AWS完整路径
@property (nonatomic, assign) NSTimeInterval uploadTime;    // 上传时间戳

- (instancetype)initWithImageUri:(NSString *)imageUri 
                  awsRelativePath:(NSString *)awsRelativePath 
                      awsFullPath:(NSString *)awsFullPath;

@end

/// 上传历史记录管理器
/// 用于管理用户上传图片的历史记录缓存（本地存储，最多3条）
@interface UploadHistoryManager : NSObject

+ (instancetype)sharedManager;

/// 添加新的上传记录
/// @param imageUri 图片Uri或本地路径
/// @param awsRelativePath AWS相对路径
/// @param awsFullPath AWS完整路径
- (void)addUploadHistory:(NSString *)imageUri 
          awsRelativePath:(NSString *)awsRelativePath 
              awsFullPath:(NSString *)awsFullPath;

/// 删除指定的上传记录
/// @param imageUri 要删除的图片Uri
- (void)removeUploadHistory:(NSString *)imageUri;

/// 获取上传历史记录列表
- (NSArray<UploadHistoryItem *> *)getUploadHistoryList;

/// 获取最新的历史记录
- (UploadHistoryItem * _Nullable)getLatestHistoryItem;

/// 检查是否有历史记录
- (BOOL)hasHistory;

/// 清空所有历史记录
- (void)clearAllHistory;

@end

NS_ASSUME_NONNULL_END

