//
//  MaterialListViewController.m
//  Bunnyx
//

#import "MaterialListViewController.h"
#import "MaterialCollectionViewCell.h"
#import "MaterialItemModel.h"
#import "MaterialDetailViewController.h"
#import "NetworkManager.h"
#import "BunnyxMacros.h"
#import "BunnyxNetworkMacros.h"
#import "MJRefreshHelper.h"
#import "LanguageManager.h"
#import <SDWebImage/SDWebImage.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <Masonry/Masonry.h>

static NSString * const kMaterialCellId = @"kMaterialCellId";

@interface MaterialListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MaterialCollectionViewCellDelegate>

@property (nonatomic, assign) NSInteger typeId;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *emptyView; // 空状态视图（layout_empty）
@property (nonatomic, strong) NSMutableArray<MaterialItemModel *> *items;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) NSTimeInterval lastItemClickTime; // 防重复点击
@property (nonatomic, assign) NSInteger lastClickIndex; // 最后点击的位置

@end

@implementation MaterialListViewController

- (instancetype)initWithMaterialType:(NSInteger)typeId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _typeId = typeId;
        _items = [NSMutableArray array];
        _index = 0;
        _count = 20;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self setupCollectionView];
    [self setupEmptyView];
    [self setupRefresh];
    [self setupNotifications];
    [self.collectionView.mj_header beginRefreshing];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    // 间距16dp（对应iOS的16pt）
    // GridSpacingItemDecoration(2, 16, true) 表示：
    // - 行间距：16dp（对应minimumLineSpacing）
    // - 列间距：16dp（对应minimumInteritemSpacing）
    // - 边缘间距：16dp（对应sectionInset）
    layout.minimumLineSpacing = 16.0;
    layout.minimumInteritemSpacing = 16.0;
    layout.sectionInset = UIEdgeInsetsMake(16.0, 16.0, 16.0, 16.0);
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    // 禁用默认动画，减少闪烁（setItemAnimator(null)）
    // iOS中通过禁用UIView动画来达到类似效果
    [_collectionView registerClass:[MaterialCollectionViewCell class] forCellWithReuseIdentifier:kMaterialCellId];
    [self.view addSubview:_collectionView];
}

- (void)setupEmptyView {
    // layout_empty，使用icon_mine_default_image
    self.emptyView = [[UIView alloc] init];
    self.emptyView.backgroundColor = [UIColor clearColor];
    self.emptyView.hidden = YES;
    [self.view addSubview:self.emptyView];
    [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    UIImageView *emptyIcon = [[UIImageView alloc] init];
    emptyIcon.image = [UIImage imageNamed:@"icon_mine_default_image"];
    emptyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.emptyView addSubview:emptyIcon];
    [emptyIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.emptyView);
        make.width.height.mas_equalTo(80);
    }];
}

- (void)setupNotifications {
    // 监听详情页返回后的收藏状态更新通知（ActivityResultLauncher）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMaterialDetailFavoriteChanged:)
                                                 name:@"MaterialDetailFavoriteChangedNotification"
                                               object:nil];
    // 监听素材被举报/屏蔽的通知（material_reported）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMaterialReported:)
                                                 name:@"MaterialReportedNotification"
                                               object:nil];
    // 监听语言切换通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange:)
                                                 name:[LanguageManager languageDidChangeNotification]
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleMaterialDetailFavoriteChanged:(NSNotification *)notification {
    // 精确更新对应item的收藏状态，避免整体刷新
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    NSInteger materialId = [userInfo[@"materialId"] integerValue];
    BOOL isFavorite = [userInfo[@"isFavorite"] boolValue];
    NSInteger likeCount = [userInfo[@"likeCount"] integerValue];
    
    // 查找对应的item并更新
    for (NSInteger i = 0; i < self.items.count; i++) {
        MaterialItemModel *item = self.items[i];
        if (item && item.materialId == materialId) {
            item.isFavorite = isFavorite;
            if (likeCount >= 0) {
                item.favoriteQty = @(likeCount);
            }
            // 只更新对应的cell，不整体刷新
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            break;
        }
    }
}

- (void)handleMaterialReported:(NSNotification *)notification {
    // 从列表中移除被举报/屏蔽的item（对应material_reported）
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    NSInteger materialId = [userInfo[@"materialId"] integerValue];
    
    // 查找对应的item并移除
    for (NSInteger i = 0; i < self.items.count; i++) {
        MaterialItemModel *item = self.items[i];
        if (item && item.materialId == materialId) {
            [self.items removeObjectAtIndex:i];
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            
            // 如果删除后列表为空，显示空状态
            if (self.items.count == 0) {
                self.emptyView.hidden = NO;
                self.collectionView.hidden = YES;
            }
            break;
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
}

- (void)setupRefresh {
    __weak typeof(self) weakSelf = self;
    // 下拉刷新（使用国际化封装）
    self.collectionView.mj_header = [MJRefreshHelper headerWithRefreshingBlock:^{
        __strong typeof(weakSelf) self = weakSelf; if (!self) return; 
        self.index = 0; 
        [self fetchListIsLoadMore:NO];
    }];
    // 上拉加载（使用国际化封装）
    self.collectionView.mj_footer = [MJRefreshHelper footerWithRefreshingBlock:^{
        __strong typeof(weakSelf) self = weakSelf; if (!self) return; 
        [self fetchListIsLoadMore:YES];
    }];
}

- (void)endRefreshing {
    [self.collectionView.mj_header endRefreshing];
    [self.collectionView.mj_footer endRefreshing];
}

- (void)fetchListIsLoadMore:(BOOL)isLoadMore {
    if (self.isLoading) { return; }
    self.isLoading = YES;
    if (!isLoadMore) {
        self.index = 0;
    }
    NSDictionary *params = @{ @"index": @(self.index),
                              @"count": @(self.count),
                              @"materialType": @(self.typeId) };
    [[NetworkManager sharedManager] GET:BUNNYX_API_MATERIAL_LIST parameters:params success:^(id  _Nonnull responseObject) {
        self.isLoading = NO;
        [self endRefreshing];
        NSArray *data = responseObject[@"data"];
        NSArray *models = [MaterialItemModel modelsFromResponse:data];
        if (isLoadMore) {
            [self.items addObjectsFromArray:models];
        } else {
            [self.items removeAllObjects];
            [self.items addObjectsFromArray:models];
        }
        self.index += models.count;
        if (models.count < self.count) {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.collectionView.mj_footer resetNoMoreData];
        }
        
        // 根据数据是否为空显示/隐藏空状态
        if (self.items.count > 0) {
            self.emptyView.hidden = YES;
            self.collectionView.hidden = NO;
        } else {
            self.emptyView.hidden = NO;
            self.collectionView.hidden = YES;
        }
        
        // 禁用动画，减少闪烁
        [UIView performWithoutAnimation:^{
            [self.collectionView reloadData];
        }];
    } failure:^(NSError * _Nonnull error) {
        self.isLoading = NO;
        [self endRefreshing];
    }];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MaterialCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kMaterialCellId forIndexPath:indexPath];
    cell.delegate = self;
    
    // 按顺序加载图片，避免动效混乱
    // 直接配置，SDWebImage会自动处理加载顺序和缓存
    MaterialItemModel *model = self.items[indexPath.item];
    [cell configureWithModel:model];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = collectionView.bounds.size.width;
    UIEdgeInsets inset = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).sectionInset;
    CGFloat spacing = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).minimumInteritemSpacing;
    // GridSpacingItemDecoration with includeEdge=true
    // 可用宽度 = 总宽度 - 左边缘 - 右边缘 - 中间间距
    // 由于sectionInset已经设置了左右各16pt，minimumInteritemSpacing为16pt
    CGFloat available = width - inset.left - inset.right - spacing;
    CGFloat itemW = floor(available / 2.0);
    // 固定高度220dp（对应iOS的220pt）
    CGFloat itemH = 220.0;
    return CGSizeMake(itemW, itemH);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 防重复点击（600ms防重复点击）
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970] * 1000;
    if (now - self.lastItemClickTime < 600) {
        return;
    }
    self.lastItemClickTime = now;
    self.lastClickIndex = indexPath.item;
    
    MaterialItemModel *model = self.items[indexPath.item];
    
    // 预加载图片（点击后预加载详情页需要的大图）
    if (model.materialUrl && model.materialUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:model.materialUrl];
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[url]];
    }
    
    MaterialDetailViewController *detailVC = [[MaterialDetailViewController alloc] initWithMaterialId:model.materialId];
    detailVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - MaterialCollectionViewCellDelegate

- (void)materialCollectionViewCell:(MaterialCollectionViewCell *)cell didTapLikeWithModel:(MaterialItemModel *)model {
    // 切换点赞状态（点击点赞区域切换状态）
    BOOL newFavoriteState = !model.isFavorite;
    
    // 调用点赞接口（FavoriteMaterialApi）
    NSDictionary *params = @{
        @"materialId": @(model.materialId),
        @"add": @(newFavoriteState)
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_MATERIAL_FAVORITE_ADD parameters:params success:^(id  _Nonnull responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 点赞成功，更新本地数据（更新model状态和数量）
            model.isFavorite = newFavoriteState;
            
            // 更新点赞数量
            NSInteger currentCount = model.favoriteQty ? [model.favoriteQty integerValue] : 0;
            if (newFavoriteState) {
                model.favoriteQty = @(currentCount + 1);
            } else {
                model.favoriteQty = @(MAX(0, currentCount - 1));
            }
            
            // 刷新对应位置的cell
            NSInteger index = [self.items indexOfObject:model];
            if (index != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }
        }
    } failure:^(NSError * _Nonnull error) {
        // 错误提示由 NetworkManager 自动显示
    }];
}

- (void)languageDidChange:(NSNotification *)notification {
    // 语言切换后更新 MJRefresh 文案
    dispatch_async(dispatch_get_main_queue(), ^{
        [MJRefreshHelper updateLocalizationForScrollView:self.collectionView];
    });
}

#pragma mark - Public Methods

- (void)refreshData {
    // 刷新数据（refreshData方法）
    [self.collectionView.mj_header beginRefreshing];
}

@end


