　//
//  GenerateListViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import "GenerateListViewController.h"
#import <Masonry/Masonry.h>
#import "CreateTaskModel.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "BunnyxMacros.h"
#import <MJRefresh/MJRefresh.h>
#import <JXPagingView/JXPagerView.h>
#import "GenerateListCell.h" // 导入以使用 GenerateListCell
#import <SDWebImage/SDWebImage.h>
#import <QuartzCore/QuartzCore.h> // 用于CACurrentMediaTime()
#import "MaterialDetailViewController.h"

static NSString *const kGenerateCellId = @"GenerateListCell";

// 通知名称：生成详情页删除成功
NSString *const kGenerateDetailDeletedNotification = @"GenerateDetailDeletedNotification";
NSString *const kGenerateDetailDeletedCreateIdKey = @"createId";

@interface GenerateListViewController () <UITableViewDataSource, UITableViewDelegate, JXPagerViewListViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) NSMutableArray<CreateTaskModel *> *dataList;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasMoreData;
@property (nonatomic, copy) void(^listViewDidScrollCallback)(UIScrollView *scrollView);
@property (nonatomic, assign) NSTimeInterval lastClickTime; // 防重复点击（600ms间隔）
@property (nonatomic, assign) NSInteger lastClickIndex; // 最后点击的索引

@end

@implementation GenerateListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.dataList = [NSMutableArray array];
    self.currentPage = 1;
    self.isLoading = NO;
    self.hasMoreData = YES;
    self.lastClickTime = 0;
    self.lastClickIndex = -1;
    
    [self setupUI];
    [self setupRefresh];
    [self setupNotifications];
    // 不在 viewDidLoad 中直接加载数据，等列表出现时再加载（listDidAppear）
}

- (void)setupNotifications {
    // 监听生成详情页删除成功的通知（对应安卓的ActivityResultLauncher）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleGenerateDetailDeleted:)
                                                 name:kGenerateDetailDeletedNotification
                                               object:nil];
}

- (void)handleGenerateDetailDeleted:(NSNotification *)notification {
    // 对应安卓的detailLauncher回调
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    NSString *createId = userInfo[kGenerateDetailDeletedCreateIdKey];
    if (createId && createId.length > 0) {
        NSInteger removedPosition = [self removeByCreateId:createId];
        if (removedPosition >= 0 && self.dataList.count == 0) {
            // 列表为空，显示空状态（已在removeByCreateId中调用updateUI）
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
    // 设置背景色（对应安卓的 #0A1C1B）
    self.view.backgroundColor = HEX_COLOR(0x0A1C1B);
    
    // 表格视图
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 300; // 根据安卓布局估算：16+15+15+220+12+24+16 = 约300
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    // 设置 alwaysBounceVertical 为 YES，确保即使内容不够时也能触发下拉刷新
    self.tableView.alwaysBounceVertical = YES;
    // 设置 contentInsetAdjustmentBehavior，确保在嵌套滚动中刷新能正常工作
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    // 设置paddingTop和paddingBottom为8dp（对应安卓的paddingTop="8dp" paddingBottom="8dp"）
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 8, 0);
    [self.tableView registerClass:[GenerateListCell class] forCellReuseIdentifier:kGenerateCellId];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 空状态视图（对应安卓的layout_empty）
    self.emptyView = [[UIView alloc] init];
    self.emptyView.hidden = YES;
    self.emptyView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.emptyView];
    
    [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.offset(350);
    }];
    
    // 空状态图标（对应安卓的icon_mine_default_image，80dp x 80dp）
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
    self.tableView.mj_header = header;
    
    // 上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [weakSelf loadData:NO];
    }];
    // 设置加载状态下的文字颜色
    footer.stateLabel.textColor = [UIColor whiteColor];
    // 设置没有更多数据时的提示
    [footer setTitle:LocalString(@"没有更多数据了") forState:MJRefreshStateNoMoreData];
    self.tableView.mj_footer = footer;
    self.tableView.mj_footer.hidden = YES;
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
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_GET_CREATE_LIST
                              parameters:params
                                 success:^(id responseObject) {
        self.isLoading = NO;
        [self endRefreshing];
        
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSArray *data = dict[@"data"];
        if (data && [data isKindOfClass:[NSArray class]]) {
            NSArray *models = [CreateTaskModel modelsFromResponse:data];
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
    [self.tableView.mj_header endRefreshing];
    if (self.hasMoreData) {
        [self.tableView.mj_footer endRefreshing];
    } else {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    }
}

- (void)updateUI {
    [self.tableView reloadData];
    
    if (self.dataList.count == 0) {
        self.tableView.hidden = YES;
        self.emptyView.hidden = NO;
        self.tableView.mj_footer.hidden = YES;
    } else {
        self.tableView.hidden = NO;
        self.emptyView.hidden = YES;
        if (self.hasMoreData) {
            self.tableView.mj_footer.hidden = NO;
            [self.tableView.mj_footer resetNoMoreData];
        } else {
            self.tableView.mj_footer.hidden = NO;
        }
    }
}

- (void)refreshData {
    [self.tableView.mj_header beginRefreshing];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GenerateListCell *cell = [tableView dequeueReusableCellWithIdentifier:kGenerateCellId forIndexPath:indexPath];
    CreateTaskModel *model = self.dataList[indexPath.row];
    [cell configureWithModel:model];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CreateTaskModel *model = self.dataList[indexPath.row];
    if (!model) {
        return;
    }
    
    // 防重复点击（600ms间隔，对应安卓的SystemClock.elapsedRealtime()）
    NSTimeInterval now = CACurrentMediaTime() * 1000; // 转换为毫秒
    if (now - self.lastClickTime < 600) {
        return;
    }
    self.lastClickTime = now;
    self.lastClickIndex = indexPath.row;
    
    // 检查状态，status为1（排队中）或2（生成中）时不可点击，4、5（生成失败）也不可点击
    if (model.status == 1 || model.status == 2 || model.status == 4 || model.status == 5) {
        // 不执行任何操作，也不显示提示
        return;
    }
    
    // 预加载生成详情需要的大图（videoUrl 优先，其次 imageUrl）
    NSString *preloadUrl = nil;
    if (model.videoUrl && model.videoUrl.length > 0) {
        preloadUrl = model.videoUrl;
    } else if (model.imageUrl && model.imageUrl.length > 0) {
        preloadUrl = model.imageUrl;
    }
    if (preloadUrl && preloadUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:preloadUrl];
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[url]];
    }
    
    // 跳转到详情页
    [self navigateToDetailWithCreateTask:model];
}

- (void)navigateToDetailWithCreateTask:(CreateTaskModel *)createTask {
    // 对应安卓的VideoDetailActivity.startForGenerate(context, createTask)
    // 需要传递：
    // 1. createTask (CreateTaskModel)
    // 2. pageType (PAGE_TYPE_GENERATE = 1)
    // 3. materialId (createTask.materialId)
    
    // 使用MaterialDetailViewController，传递pageType参数（对齐安卓）
    if (createTask.materialId > 0) {
        MaterialDetailViewController *vc = [[MaterialDetailViewController alloc] initWithMaterialId:createTask.materialId 
                                                                                            pageType:MaterialDetailPageTypeGenerate];
        vc.hidesBottomBarWhenPushed = YES;
        
        // 使用block回调来处理详情页返回后的删除操作
        // 注意：需要在MaterialDetailViewController中添加回调支持
        // 暂时先跳转，删除功能通过通知或其他方式实现
        
        [self.navigationController pushViewController:vc animated:YES];
        BUNNYX_LOG(@"跳转到详情页，createId: %@, materialId: %ld", createTask.createId, (long)createTask.materialId);
    } else {
        BUNNYX_LOG(@"无法跳转，materialId无效: %ld", (long)createTask.materialId);
    }
}

/// 根据createId删除item（对应安卓的adapter.removeByCreateId）
- (NSInteger)removeByCreateId:(NSString *)createId {
    if (!createId || createId.length == 0) {
        return -1;
    }
    
    for (NSInteger i = 0; i < self.dataList.count; i++) {
        CreateTaskModel *task = self.dataList[i];
        if (task && [task.createId isEqualToString:createId]) {
            [self.dataList removeObjectAtIndex:i];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            
            // 如果删除后列表为空，显示空状态
            if (self.dataList.count == 0) {
                [self updateUI];
            }
            
            return i;
        }
    }
    
    return -1;
}

#pragma mark - JXPagerViewListViewDelegate

- (UIView *)listView {
    return self.view;
}

- (UIScrollView *)listScrollView {
    return self.tableView;
}

- (void)listViewDidScrollCallback:(void (^)(UIScrollView *))callback {
    self.listViewDidScrollCallback = callback;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 通知JXPagerView滚动事件，用于嵌套滚动联动
    if (self.listViewDidScrollCallback) {
        self.listViewDidScrollCallback(scrollView);
    }
}

#pragma mark - JXPagerViewListViewDelegate Optional Methods

- (void)listScrollViewWillResetContentOffset {
    // 当主滚动视图滚动到顶部时，会调用此方法重置子列表的contentOffset
    // 在 JXPagerView 嵌套滚动中，当主滚动视图的 header 还没有消失时，
    // 子列表的 contentOffset 会被重置，此时下拉刷新才能正常工作
    // 确保 tableView 的 contentOffset 为 0，这样下拉刷新才能正常触发
}

- (void)listDidAppear {
    // 列表已经出现时，如果数据为空，自动加载数据
    if (self.dataList.count == 0 && !self.isLoading) {
        [self loadData:YES];
    }
}

@end
