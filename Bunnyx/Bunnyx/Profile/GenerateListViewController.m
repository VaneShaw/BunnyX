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

static NSString *const kGenerateCellId = @"GenerateListCell";

@interface GenerateListViewController () <UITableViewDataSource, UITableViewDelegate, JXPagerViewListViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) NSMutableArray<CreateTaskModel *> *dataList;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasMoreData;
@property (nonatomic, copy) void(^listViewDidScrollCallback)(UIScrollView *scrollView);

@end

@implementation GenerateListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.dataList = [NSMutableArray array];
    self.currentPage = 1;
    self.isLoading = NO;
    self.hasMoreData = YES;
    
    [self setupUI];
    [self setupRefresh];
    // 不在 viewDidLoad 中直接加载数据，等列表出现时再加载（listDidAppear）
}

- (void)setupUI {
    // 表格视图
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 120;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    // 设置 alwaysBounceVertical 为 YES，确保即使内容不够时也能触发下拉刷新
    self.tableView.alwaysBounceVertical = YES;
    // 设置 contentInsetAdjustmentBehavior，确保在嵌套滚动中刷新能正常工作
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.tableView registerClass:[GenerateListCell class] forCellReuseIdentifier:kGenerateCellId];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 空状态视图
    self.emptyView = [[UIView alloc] init];
    self.emptyView.hidden = YES;
    [self.view addSubview:self.emptyView];
    
    [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.height.mas_equalTo(100);
    }];
    
    // 空状态图标（文件夹+星星）
    UIImageView *folderIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"folder.fill"]];
    folderIcon.tintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [self.emptyView addSubview:folderIcon];
    
    [folderIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.emptyView);
        make.centerY.equalTo(self.emptyView).offset(-10);
        make.width.height.mas_equalTo(60);
    }];
    
    UIImageView *starIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"star.fill"]];
    starIcon.tintColor = [UIColor whiteColor];
    [self.emptyView addSubview:starIcon];
    
    [starIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(folderIcon);
        make.width.height.mas_equalTo(24);
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
    
    // 如果状态是排队中(1)或生成中(2)，不允许点击
    if (model.status == 1 || model.status == 2) {
        return;
    }
    
    // TODO: 跳转到详情页
    BUNNYX_LOG(@"点击生成任务: %@", model.createId);
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
    if (self.tableView.contentOffset.y < 0) {
        self.tableView.contentOffset = CGPointZero;
    }
}

- (void)listDidAppear {
    // 列表已经出现时，如果数据为空，自动加载数据
    if (self.dataList.count == 0 && !self.isLoading) {
        [self loadData:YES];
    }
}

@end
