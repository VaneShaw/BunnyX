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
#import <MJRefresh/MJRefresh.h>
#import <SDWebImage/SDWebImage.h>
#import <SVProgressHUD/SVProgressHUD.h>

static NSString * const kMaterialCellId = @"kMaterialCellId";

@interface MaterialListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MaterialCollectionViewCellDelegate>

@property (nonatomic, assign) NSInteger typeId;
@property (nonatomic, strong) UICollectionView *collectionView;
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
    [self setupRefresh];
    [self.collectionView.mj_header beginRefreshing];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    // 对齐安卓：间距16dp（对应iOS的16pt）
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
    // 对齐安卓：禁用默认动画，减少闪烁（setItemAnimator(null)）
    // iOS中通过禁用UIView动画来达到类似效果
    [_collectionView registerClass:[MaterialCollectionViewCell class] forCellWithReuseIdentifier:kMaterialCellId];
    [self.view addSubview:_collectionView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
}

- (void)setupRefresh {
    __weak typeof(self) weakSelf = self;
    self.collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        __strong typeof(weakSelf) self = weakSelf; if (!self) return; 
        self.index = 0; 
        [self fetchListIsLoadMore:NO];
    }];
    self.collectionView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
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
        // 对齐安卓：禁用动画，减少闪烁
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
    
    // 对齐安卓：按顺序加载图片，避免动效混乱
    // 直接配置，SDWebImage会自动处理加载顺序和缓存
    MaterialItemModel *model = self.items[indexPath.item];
    [cell configureWithModel:model];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = collectionView.bounds.size.width;
    UIEdgeInsets inset = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).sectionInset;
    CGFloat spacing = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).minimumInteritemSpacing;
    // 对齐安卓：GridSpacingItemDecoration with includeEdge=true
    // 可用宽度 = 总宽度 - 左边缘 - 右边缘 - 中间间距
    // 由于sectionInset已经设置了左右各16pt，minimumInteritemSpacing为16pt
    CGFloat available = width - inset.left - inset.right - spacing;
    CGFloat itemW = floor(available / 2.0);
    // 对齐安卓：固定高度220dp（对应iOS的220pt）
    CGFloat itemH = 220.0;
    return CGSizeMake(itemW, itemH);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 防重复点击（对齐安卓：600ms防重复点击）
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970] * 1000;
    if (now - self.lastItemClickTime < 600) {
        return;
    }
    self.lastItemClickTime = now;
    self.lastClickIndex = indexPath.item;
    
    MaterialItemModel *model = self.items[indexPath.item];
    
    // 预加载图片（对齐安卓：点击后预加载详情页需要的大图）
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
    // 切换点赞状态（对齐安卓：点击点赞区域切换状态）
    BOOL newFavoriteState = !model.isFavorite;
    
    // 调用点赞接口（对齐安卓：FavoriteMaterialApi）
    NSDictionary *params = @{
        @"materialId": @(model.materialId),
        @"add": @(newFavoriteState)
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_MATERIAL_FAVORITE_ADD parameters:params success:^(id  _Nonnull responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 点赞成功，更新本地数据（对齐安卓：更新model状态和数量）
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
        [SVProgressHUD showErrorWithStatus:LocalString(@"操作失败")];
    }];
}

#pragma mark - Public Methods

- (void)refreshData {
    // 刷新数据（对齐安卓：refreshData方法）
    [self.collectionView.mj_header beginRefreshing];
}

@end


