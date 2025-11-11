//
//  GenerateListViewController.h
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 通知名称：生成详情页删除成功（对应安卓的ActivityResultLauncher）
extern NSString *const kGenerateDetailDeletedNotification;
extern NSString *const kGenerateDetailDeletedCreateIdKey;

@interface GenerateListViewController : UIViewController

/// 刷新数据
- (void)refreshData;

/// 表格视图（用于嵌套滚动）
@property (nonatomic, strong, readonly) UITableView *tableView;

/// 根据createId删除item（对应安卓的adapter.removeByCreateId）
- (NSInteger)removeByCreateId:(NSString *)createId;

@end

NS_ASSUME_NONNULL_END

