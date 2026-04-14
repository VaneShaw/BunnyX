//
//  MJRefreshHelper.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "MJRefreshHelper.h"
#import "BunnyxMacros.h"
#import "LanguageManager.h"

@implementation MJRefreshHelper

+ (MJRefreshNormalHeader *)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock {
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:refreshingBlock];
    [self configureHeaderLocalization:header];
    return header;
}

+ (MJRefreshAutoNormalFooter *)footerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock {
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:refreshingBlock];
    [self configureFooterLocalization:footer];
    return footer;
}

+ (void)configureHeaderLocalization:(MJRefreshNormalHeader *)header {
    if (!header) return;
    
    // 设置下拉刷新状态的国际化文案
    [header setTitle:LocalString(@"下拉可以刷新") forState:MJRefreshStateIdle];
    [header setTitle:LocalString(@"释放立即刷新") forState:MJRefreshStatePulling];
    [header setTitle:LocalString(@"正在刷新...") forState:MJRefreshStateRefreshing];
}

+ (void)configureFooterLocalization:(MJRefreshAutoNormalFooter *)footer {
    if (!footer) return;
    
    // 设置上拉加载状态的国际化文案
    [footer setTitle:LocalString(@"上拉可以加载") forState:MJRefreshStateIdle];
    [footer setTitle:LocalString(@"释放立即加载") forState:MJRefreshStatePulling];
    [footer setTitle:LocalString(@"正在加载...") forState:MJRefreshStateRefreshing];
    [footer setTitle:LocalString(@"没有更多数据了") forState:MJRefreshStateNoMoreData];
}

+ (void)updateLocalizationForScrollView:(UIScrollView *)scrollView {
    if (!scrollView) return;
    
    // 更新 Header
    if (scrollView.mj_header && [scrollView.mj_header isKindOfClass:[MJRefreshNormalHeader class]]) {
        [self configureHeaderLocalization:(MJRefreshNormalHeader *)scrollView.mj_header];
    }
    
    // 更新 Footer
    if (scrollView.mj_footer && [scrollView.mj_footer isKindOfClass:[MJRefreshAutoNormalFooter class]]) {
        [self configureFooterLocalization:(MJRefreshAutoNormalFooter *)scrollView.mj_footer];
    }
}

@end

