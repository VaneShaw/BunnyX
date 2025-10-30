//
//  MaterialListViewController.m
//  Bunnyx
//

#import "MaterialListViewController.h"
#import "MaterialCollectionViewCell.h"
#import "MaterialItemModel.h"
#import "NetworkManager.h"
#import "BunnyxMacros.h"
#import <MJRefresh/MJRefresh.h>

static NSString * const kMaterialCellId = @"kMaterialCellId";

@interface MaterialListViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) NSInteger typeId;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<MaterialItemModel *> *items;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL isLoading;

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
    layout.minimumLineSpacing = 8;
    layout.minimumInteritemSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(8, 12, 8, 12);
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
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
        [self.collectionView reloadData];
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
    [cell configureWithModel:self.items[indexPath.item]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = collectionView.bounds.size.width;
    UIEdgeInsets inset = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).sectionInset;
    CGFloat spacing = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).minimumInteritemSpacing;
    CGFloat available = width - inset.left - inset.right - spacing;
    CGFloat itemW = floor(available / 2.0);
    CGFloat itemH = itemW * 1.3; // 略高一些
    return CGSizeMake(itemW, itemH);
}

@end


