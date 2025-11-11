//
//  LikeListViewController.h
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LikeListViewController;

/// 滚动代理协议（用于嵌套滚动）
@protocol LikeListViewControllerScrollDelegate <NSObject>
- (void)likeListViewController:(LikeListViewController *)controller didScrollToOffset:(CGFloat)offset;
@end

@interface LikeListViewController : UIViewController

/// 刷新数据
- (void)refreshData;

/// 集合视图（用于嵌套滚动）
@property (nonatomic, strong, readonly) UICollectionView *collectionView;

/// 滚动代理（用于嵌套滚动）
@property (nonatomic, weak) id<LikeListViewControllerScrollDelegate> scrollDelegate;

/// 处理cell点击事件（用于delegate转发）
- (void)handleCellSelectionAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END

