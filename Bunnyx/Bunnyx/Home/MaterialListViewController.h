//
//  MaterialListViewController.h
//  Bunnyx
//

#import <UIKit/UIKit.h>

@interface MaterialListViewController : UIViewController

// 指定类型初始化
- (instancetype)initWithMaterialType:(NSInteger)typeId;

// 刷新数据（对齐安卓：refreshData方法）
- (void)refreshData;

@end


