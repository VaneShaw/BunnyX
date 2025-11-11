//
//  HomeViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "HomeViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import "MaterialTypeModel.h"
#import "MaterialListViewController.h"
#import "BunnyxMacros.h"
#import "HomeTabCell.h"

// 通知名称：刷新首页列表
extern NSString *const kRefreshMaterialListNotification;

@interface HomeViewController () <UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *tabCollectionView;
@property (nonatomic, strong) UIScrollView *pagesScrollView;
@property (nonatomic, strong) NSArray<MaterialTypeModel *> *types;
@property (nonatomic, strong) NSMutableArray<MaterialListViewController *> *pages;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) BOOL hasLoadedData; // 是否已经加载过数据（对齐安卓）

@end

@implementation HomeViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // 背景图
    [self setupBackgroundImage];
    self.pages = [NSMutableArray array];
    self.hasLoadedData = NO;
    [self setupTopTabs];
    [self setupPagesScrollView];
    [self setupEmptyLabel];
    [self fetchCategories];
    
    // 对齐安卓：监听刷新列表通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshMaterialListNotification:)
                                                 name:kRefreshMaterialListNotification
                                               object:nil];
}

- (void)dealloc {
    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleRefreshMaterialListNotification:(NSNotification *)notification {
    // 对齐安卓：收到刷新通知时，刷新所有MaterialListViewController
    [self refreshData];
}

- (void)setupBackgroundImage {
    if (!self.backgroundImageView) {
        self.backgroundImageView = [[UIImageView alloc] init];
        self.backgroundImageView.image = [UIImage imageNamed:@"bg_login_account"];
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.backgroundImageView.clipsToBounds = YES;
        [self.view addSubview:self.backgroundImageView];
        [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
}


// 顶部横向可滚动分类Tab（对齐安卓UI交互）
- (void)setupTopTabs {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(0, 12, 0, 12);
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [collectionView registerClass:[HomeTabCell class] forCellWithReuseIdentifier:@"HomeTabCell"];
    self.tabCollectionView = collectionView;
    [self.view addSubview:collectionView];
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
}

// 生成纯色图片用于Segment控制透明背景/分隔线
- (UIImage *)bx_imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// 横向分页容器
- (void)setupPagesScrollView {
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scroll.pagingEnabled = YES;
    scroll.showsHorizontalScrollIndicator = NO;
    scroll.delegate = self;
    scroll.backgroundColor = [UIColor clearColor];
    self.pagesScrollView = scroll;
    [self.view addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tabCollectionView.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self.view);
    }];
}

#pragma mark - Empty View

- (void)setupEmptyLabel {
    UILabel *label = [[UILabel alloc] init];
    label.text = LocalString(@"暂无数据");
    label.textColor = BUNNYX_LIGHT_TEXT_COLOR;
    label.font = FONT(14);
    label.textAlignment = NSTextAlignmentCenter;
    label.hidden = YES;
    self.emptyLabel = label;
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
}

#pragma mark - Networking

- (void)fetchCategories {
    // 只有在没有加载过数据时才加载（对齐安卓）
    if (self.hasLoadedData) {
        return;
    }
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_MATERIAL_TYPE_LIST parameters:nil success:^(id  _Nonnull responseObject) {
        NSArray *data = responseObject[@"data"];
        self.types = [MaterialTypeModel modelsFromResponse:data];
        self.hasLoadedData = YES;
        [self reloadTabsAndPages];
    } failure:^(NSError * _Nonnull error) {
        self.types = @[];
        self.hasLoadedData = YES; // 即使失败也标记为已加载，避免重复请求
        [self reloadTabsAndPages];
    }];
}

- (void)refreshData {
    // 刷新数据（对齐安卓：refreshData方法）
    // 如果已经有数据，直接通知所有MaterialListViewController刷新
    if (self.hasLoadedData && self.pages.count > 0) {
        for (MaterialListViewController *vc in self.pages) {
            if ([vc respondsToSelector:@selector(refreshData)]) {
                [vc refreshData];
            }
        }
    } else {
        // 如果没有数据，重新加载分类
        self.hasLoadedData = NO;
        [self fetchCategories];
    }
}

- (void)reloadTabsAndPages {
    [self.pages makeObjectsPerformSelector:@selector(removeFromParentViewController)];
    [self.pages removeAllObjects];
    self.currentIndex = 0;
    NSInteger idx = 0;
    for (MaterialTypeModel *t in self.types) {
        MaterialListViewController *vc = [[MaterialListViewController alloc] initWithMaterialType:t.typeId];
        [self addChildViewController:vc];
        [self.pages addObject:vc];
        idx++;
    }
    self.emptyLabel.hidden = (self.types.count > 0);
    [self.tabCollectionView reloadData];
    if (self.types.count > 0) {
        NSIndexPath *first = [NSIndexPath indexPathForItem:0 inSection:0];
        [self.tabCollectionView selectItemAtIndexPath:first animated:NO scrollPosition:UICollectionViewScrollPositionLeft];
        [self.tabCollectionView scrollToItemAtIndexPath:first atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    }
    [self layoutPages];
}

- (void)layoutPages {
    CGFloat width = self.pagesScrollView.bounds.size.width;
    CGFloat height = self.pagesScrollView.bounds.size.height;
    if (width <= 0 || height <= 0) { [self.view layoutIfNeeded]; width = self.pagesScrollView.bounds.size.width; height = self.pagesScrollView.bounds.size.height; }
    self.pagesScrollView.contentSize = CGSizeMake(width * self.pages.count, height);
    [self.pages enumerateObjectsUsingBlock:^(MaterialListViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *v = obj.view;
        v.frame = CGRectMake(width * idx, 0, width, height);
        if (!v.superview) {
            [self.pagesScrollView addSubview:v];
        }
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutPages];
}

#pragma mark - Tab Helpers

- (void)scrollTabsToVisibleIndex:(NSInteger)index {
    if (!self.tabCollectionView) { return; }
    if (index < 0 || index >= [self collectionView:self.tabCollectionView numberOfItemsInSection:0]) { return; }
    NSIndexPath *idxPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.tabCollectionView selectItemAtIndexPath:idxPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    [self.tabCollectionView scrollToItemAtIndexPath:idxPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.pagesScrollView) { return; }
    CGFloat width = MAX(scrollView.bounds.size.width, 1);
    NSInteger page = lround(scrollView.contentOffset.x / width);
    if (page >= 0 && page < (NSInteger)self.types.count && self.currentIndex != page) {
        self.currentIndex = page;
        [self scrollTabsToVisibleIndex:page];
        [self.tabCollectionView reloadData];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.pagesScrollView) { return; }
    CGFloat width = MAX(scrollView.bounds.size.width, 1);
    NSInteger page = lround(scrollView.contentOffset.x / width);
    if (page >= 0 && page < (NSInteger)self.types.count) {
        self.currentIndex = page;
        [self scrollTabsToVisibleIndex:page];
        [self.tabCollectionView reloadData];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.types.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeTabCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeTabCell" forIndexPath:indexPath];
    MaterialTypeModel *m = self.types[indexPath.item];
    BOOL selected = (indexPath.item == self.currentIndex);
    [cell configureWithTitle:[m displayName] selected:selected];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.currentIndex) { return; }
    self.currentIndex = indexPath.item;
    CGFloat width = self.pagesScrollView.bounds.size.width;
    CGPoint offset = CGPointMake(width * self.currentIndex, 0);
    [self.pagesScrollView setContentOffset:offset animated:YES];
    [self scrollTabsToVisibleIndex:self.currentIndex];
    [self.tabCollectionView reloadData];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    MaterialTypeModel *m = self.types[indexPath.item];
    NSString *title = [m displayName] ?: @"";
    // 对齐安卓：文字大小 20pt（选中和未选中一样）
    UIFont *font = [UIFont systemFontOfSize:20 weight:UIFontWeightRegular];
    CGSize textSize = [title sizeWithAttributes:@{NSFontAttributeName: font}];
    // 对齐安卓：左右 padding 各 25pt（paddingHorizontal="25dp"）
    CGFloat horizontalPadding = 25.0 * 2;
    // 对齐安卓：上下 padding 各 12pt（paddingVertical="12dp"）
    CGFloat verticalPadding = 12.0 * 2;
    CGFloat width = ceil(textSize.width) + horizontalPadding;
    CGFloat height = ceil(textSize.height) + verticalPadding;
    return CGSizeMake(width, MAX(44, height)); // 最小高度 44pt
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 8; // Adjust as needed
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 8; // Adjust as needed
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0); // Adjust as needed
}

@end
