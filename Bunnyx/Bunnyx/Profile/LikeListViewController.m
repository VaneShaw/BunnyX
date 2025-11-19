//
//  LikeListViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import "LikeListViewController.h"
#import <Masonry/Masonry.h>
#import "MaterialItemModel.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "BunnyxMacros.h"
#import "MaterialCollectionViewCell.h"
#import "MaterialDetailViewController.h"
#import <MJRefresh/MJRefresh.h>
#import <JXPagingView/JXPagerView.h>
#import <SDWebImage/SDWebImage.h>

static NSString *const kLikeCellId = @"LikeListCell";

@interface LikeListViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, JXPagerViewListViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) NSMutableArray<MaterialItemModel *> *dataList;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasMoreData;
@property (nonatomic, copy) void(^listViewDidScrollCallback)(UIScrollView *scrollView);
@property (nonatomic, assign) NSTimeInterval lastItemClickTime; // 防重复点击
@property (nonatomic, assign) NSInteger lastClickIndex; // 最后点击的位置

@end

@implementation LikeListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.dataList = [NSMutableArray array];
    self.currentPage = 1;
    self.isLoading = NO;
    self.hasMoreData = YES;
    self.lastItemClickTime = 0;
    self.lastClickIndex = -1;
    
    [self setupUI];
    [self setupRefresh];
}

- (void)setupUI {
    self.view.backgroundColor = HEX_COLOR(0x0A1C1B);
    // 网格布局
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 12;
    layout.minimumInteritemSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(12, MARGIN_20, 12, MARGIN_20);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    // 设置 alwaysBounceVertical 为 YES，确保即使内容不够时也能触发下拉刷新
    self.collectionView.alwaysBounceVertical = YES;
    // 设置 contentInsetAdjustmentBehavior，确保在嵌套滚动中刷新能正常工作
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.collectionView registerClass:[MaterialCollectionViewCell class] forCellWithReuseIdentifier:kLikeCellId];
    [self.view addSubview:self.collectionView];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 空状态视图（layout_empty）
    self.emptyView = [[UIView alloc] init];
    self.emptyView.hidden = YES;
    self.emptyView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.emptyView];
    
    [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.offset(350);
    }];
    
    // 空状态图标（icon_mine_default_image，80dp x 80dp）
    UIImageView *emptyIcon = [[UIImageView alloc] init];
    emptyIcon.image = [UIImage imageNamed:@"icon_mine_default_image"];
    emptyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.emptyView addSubview:emptyIcon];
    
    [emptyIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.emptyView);
        make.width.height.mas_equalTo(80);
    }];
}

- (void)setupRefresh {
    __weak typeof(self) weakSelf = self;
    
    // 下拉刷新
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadData:YES];
    }];
    // 设置刷新状态下的文字颜色
    header.stateLabel.textColor = [UIColor whiteColor];
    header.lastUpdatedTimeLabel.textColor = [UIColor whiteColor];
    // 设置自动透明度
    header.automaticallyChangeAlpha = YES;
    // 设置忽略滚动视图的 contentInset，确保在嵌套滚动中能正常工作
    header.ignoredScrollViewContentInsetTop = 0;
    self.collectionView.mj_header = header;
    
    // 上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [weakSelf loadData:NO];
    }];
    // 设置加载状态下的文字颜色
    footer.stateLabel.textColor = [UIColor whiteColor];
    // 设置没有更多数据时的提示
    [footer setTitle:LocalString(@"没有更多数据了") forState:MJRefreshStateNoMoreData];
    self.collectionView.mj_footer = footer;
    self.collectionView.mj_footer.hidden = YES;
}

- (void)loadData:(BOOL)isRefresh {
    if (self.isLoading) return;
    
    self.isLoading = YES;
    if (isRefresh) {
        self.currentPage = 1;
        self.hasMoreData = YES;
    }
    
    NSDictionary *params = @{
        @"page": @(self.currentPage),
        @"pageSize": @(20)
    };
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_GET_FAVORITE_MATERIAL_LIST
                              parameters:params
                                 success:^(id responseObject) {
        self.isLoading = NO;
        [self endRefreshing];
        
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSArray *data = dict[@"data"];
        if (data && [data isKindOfClass:[NSArray class]]) {
            NSArray *models = [MaterialItemModel modelsFromResponse:data];
            if (isRefresh) {
                [self.dataList removeAllObjects];
            }
            if (models.count > 0) {
                [self.dataList addObjectsFromArray:models];
                self.currentPage++;
                self.hasMoreData = models.count >= 20;
            } else {
                self.hasMoreData = NO;
            }
        } else {
            if (isRefresh) {
                [self.dataList removeAllObjects];
            }
            self.hasMoreData = NO;
        }
        
        [self updateUI];
    } failure:^(NSError *error) {
        self.isLoading = NO;
        [self endRefreshing];
        self.hasMoreData = NO;
        [self updateUI];
    }];
}

- (void)endRefreshing {
    [self.collectionView.mj_header endRefreshing];
    if (self.hasMoreData) {
        [self.collectionView.mj_footer endRefreshing];
    } else {
        [self.collectionView.mj_footer endRefreshingWithNoMoreData];
    }
}

- (void)updateUI {
    [self.collectionView reloadData];
    
    if (self.dataList.count == 0) {
        self.collectionView.hidden = YES;
        self.emptyView.hidden = NO;
        self.collectionView.mj_footer.hidden = YES;
    } else {
        self.collectionView.hidden = NO;
        self.emptyView.hidden = YES;
        if (self.hasMoreData) {
            self.collectionView.mj_footer.hidden = NO;
            [self.collectionView.mj_footer resetNoMoreData];
        } else {
            self.collectionView.mj_footer.hidden = NO;
        }
    }
}

- (void)refreshData {
    [self.collectionView.mj_header beginRefreshing];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MaterialCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kLikeCellId forIndexPath:indexPath];
    MaterialItemModel *model = self.dataList[indexPath.item];
    [cell configureWithModel:model];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (SCREEN_WIDTH - MARGIN_20 * 2 - 12) / 2.0;
    return CGSizeMake(width, width * 1.2);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self handleCellSelectionAtIndexPath:indexPath];
}

- (void)handleCellSelectionAtIndexPath:(NSIndexPath *)indexPath {
    // 防重复点击（600ms防重复点击）
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970] * 1000;
    if (now - self.lastItemClickTime < 600) {
        return;
    }
    self.lastItemClickTime = now;
    self.lastClickIndex = indexPath.item;
    
    if (indexPath.item >= 0 && indexPath.item < self.dataList.count) {
        MaterialItemModel *model = self.dataList[indexPath.item];
        
        // 预加载图片（点击后预加载详情页需要的大图）
        if (model.materialUrl && model.materialUrl.length > 0) {
            NSURL *url = [NSURL URLWithString:model.materialUrl];
            [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[url]];
        }
        
        // 跳转到素材详情页（MaterialDetailActivity）
        MaterialDetailViewController *detailVC = [[MaterialDetailViewController alloc] initWithMaterialId:model.materialId];
        detailVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 通知JXPagerView滚动事件，用于嵌套滚动联动
    if (self.listViewDidScrollCallback) {
        self.listViewDidScrollCallback(scrollView);
    }
}

#pragma mark - JXPagerViewListViewDelegate

- (UIView *)listView {
    return self.view;
}

- (UIScrollView *)listScrollView {
    return self.collectionView;
}

- (void)listViewDidScrollCallback:(void (^)(UIScrollView *))callback {
    self.listViewDidScrollCallback = callback;
}

#pragma mark - JXPagerViewListViewDelegate Optional Methods

- (void)listScrollViewWillResetContentOffset {
    // 当主滚动视图滚动到顶部时，会调用此方法重置子列表的contentOffset
    // 在 JXPagerView 嵌套滚动中，当主滚动视图的 header 还没有消失时，
    // 子列表的 contentOffset 会被重置，此时下拉刷新才能正常工作
    // 确保 collectionView 的 contentOffset 为 0，这样下拉刷新才能正常触发
    if (self.collectionView.contentOffset.y < 0) {
        self.collectionView.contentOffset = CGPointZero;
    }
}

- (void)listDidAppear {
    // 列表已经出现时，如果数据为空，自动加载数据
    if (self.dataList.count == 0 && !self.isLoading) {
        [self loadData:YES];
    }
}

@end
