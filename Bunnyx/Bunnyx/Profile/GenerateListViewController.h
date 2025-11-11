//
//  GenerateListViewController.h
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GenerateListViewController : UIViewController

/// 刷新数据
- (void)refreshData;

/// 表格视图（用于嵌套滚动）
@property (nonatomic, strong, readonly) UITableView *tableView;

@end

NS_ASSUME_NONNULL_END

