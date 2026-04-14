//
//  MJRefreshHelper.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <Foundation/Foundation.h>
#import <MJRefresh/MJRefresh.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * MJRefresh 国际化封装类
 * 自动设置所有刷新和加载状态的国际化文案
 */
@interface MJRefreshHelper : NSObject

/**
 * 创建已国际化的下拉刷新 Header
 * @param refreshingBlock 刷新回调
 * @return 已配置国际化的 MJRefreshNormalHeader
 */
+ (MJRefreshNormalHeader *)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock;

/**
 * 创建已国际化的上拉加载 Footer
 * @param refreshingBlock 加载回调
 * @return 已配置国际化的 MJRefreshAutoNormalFooter
 */
+ (MJRefreshAutoNormalFooter *)footerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock;

/**
 * 配置 Header 的国际化文案
 * @param header MJRefreshHeader 实例
 */
+ (void)configureHeaderLocalization:(MJRefreshNormalHeader *)header;

/**
 * 配置 Footer 的国际化文案
 * @param footer MJRefreshFooter 实例
 */
+ (void)configureFooterLocalization:(MJRefreshAutoNormalFooter *)footer;

/**
 * 更新 ScrollView 的 Header 和 Footer 国际化文案（用于语言切换时调用）
 * @param scrollView 包含 mj_header 或 mj_footer 的 ScrollView
 */
+ (void)updateLocalizationForScrollView:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END

