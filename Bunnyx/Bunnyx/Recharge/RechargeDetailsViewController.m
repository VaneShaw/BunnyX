//
//  RechargeDetailsViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "RechargeDetailsViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <DZNEmptyDataSet/DZNEmptyDataSet-umbrella.h>
#import "MJRefreshHelper.h"
#import "LanguageManager.h"

@interface RechargeRecordModel : NSObject

// UserBudget 模型字段
@property (nonatomic, assign) NSInteger budgetNum; // 收支金额(金币数量)
@property (nonatomic, assign) NSInteger budgetType; // 收支类型(1支出2收入)
@property (nonatomic, assign) NSTimeInterval addTime; // 时间戳
@property (nonatomic, copy) NSString *budgetCode; // 收支代号
@property (nonatomic, copy) NSString *state; // 状态
@property (nonatomic, copy) NSString *remarks; // 备注

// 兼容旧字段（用于显示）
@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, assign) CGFloat amount;
@property (nonatomic, assign) NSInteger coins;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *createTime;
@property (nonatomic, copy) NSString *paymentMethod;

+ (NSArray<RechargeRecordModel *> *)modelsFromResponse:(NSArray *)array;

@end

@implementation RechargeRecordModel

// 辅助方法：安全地从字典中获取字符串值，处理NSNull情况
+ (NSString *)safeStringFromDict:(NSDictionary *)dict forKey:(NSString *)key {
    id value = dict[key];
    if (value == nil || value == [NSNull null]) {
        return @"";
    }
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return @"";
}

+ (NSArray<RechargeRecordModel *> *)modelsFromResponse:(NSArray *)array {
    NSMutableArray *models = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            RechargeRecordModel *model = [[RechargeRecordModel alloc] init];
            
            // UserBudget 字段映射
            model.budgetNum = [dict[@"budgetNum"] integerValue];
            model.budgetType = [dict[@"budgetType"] integerValue];
            model.budgetCode = [self safeStringFromDict:dict forKey:@"budgetCode"];
            model.state = [self safeStringFromDict:dict forKey:@"state"];
            model.remarks = [self safeStringFromDict:dict forKey:@"remarks"];
            
            // 时间戳处理（addTime 是时间戳）
            id addTimeValue = dict[@"addTime"];
            if (addTimeValue && addTimeValue != [NSNull null]) {
                if ([addTimeValue isKindOfClass:[NSNumber class]]) {
                    model.addTime = [addTimeValue doubleValue];
                } else if ([addTimeValue isKindOfClass:[NSString class]]) {
                    model.addTime = [addTimeValue doubleValue];
                }
            }
            
            // 兼容旧字段
            model.orderId = [self safeStringFromDict:dict forKey:@"orderId"];
            if (model.orderId.length == 0) {
                model.orderId = [self safeStringFromDict:dict forKey:@"order_id"];
            }
            model.amount = [dict[@"amount"] floatValue];
            model.coins = model.budgetNum > 0 ? model.budgetNum : ([dict[@"coins"] integerValue] ?: [dict[@"buyNum"] integerValue] ?: 0);
            
            // 安全处理status字段
            NSString *stateValue = model.state.length > 0 ? model.state : [self safeStringFromDict:dict forKey:@"status"];
            model.status = stateValue;
            
            model.paymentMethod = [self safeStringFromDict:dict forKey:@"paymentMethod"];
            if (model.paymentMethod.length == 0) {
                model.paymentMethod = [self safeStringFromDict:dict forKey:@"payment_method"];
            }
            
            // 时间格式化处理（使用 addTime 时间戳）
            if (model.addTime > 0) {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:model.addTime / 1000.0]; // 时间戳可能是毫秒
                if (model.addTime < 10000000000) {
                    // 秒级时间戳
                    date = [NSDate dateWithTimeIntervalSince1970:model.addTime];
                }
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                model.createTime = [formatter stringFromDate:date];
            } else {
                // 兼容旧格式
                NSString *timeStr = [self safeStringFromDict:dict forKey:@"createTime"];
                if (timeStr.length == 0) {
                    timeStr = [self safeStringFromDict:dict forKey:@"create_time"];
                }
                if (timeStr.length == 0) {
                    timeStr = [self safeStringFromDict:dict forKey:@"createdAt"];
                }
                if (timeStr.length > 0) {
                    if ([timeStr containsString:@"."] || [timeStr integerValue] > 1000000000) {
                        NSTimeInterval timestamp = [timeStr doubleValue];
                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                        model.createTime = [formatter stringFromDate:date];
                    } else {
                        model.createTime = timeStr;
                    }
                } else {
                    model.createTime = @"";
                }
            }
            
            [models addObject:model];
        }
    }
    return models;
}

@end

@interface RechargeDetailsViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<RechargeRecordModel *> *records;
@property (nonatomic, strong) UILabel *titleLabel;

// 分页相关（使用index和count）
@property (nonatomic, assign) NSInteger index; // 分页起始位置，从0开始
@property (nonatomic, assign) NSInteger count; // 每页条数，10
@property (nonatomic, assign) BOOL hasMoreData;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation RechargeDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化数据（使用index和count）
    self.records = [NSMutableArray array];
    self.index = 0;
    self.count = 10; // 每页10条
    self.hasMoreData = YES;
    self.isLoading = NO;
    
    [self setupUI];
    [self setupRefresh];
    [self addObservers];
    
    // 初始加载数据
    [self loadRechargeHistory:YES];
}

- (void)dealloc {
    [self removeObservers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 页面显示时刷新数据
    if (self.records.count > 0) {
        [self refreshData];
    }
}

- (void)setupUI {
    // 设置标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"Details");
    self.titleLabel.font = BOLD_FONT(FONT_SIZE_20);
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.customBackButton.mas_right).offset(15);
        make.centerY.equalTo(self.customBackButton);
    }];
    
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    // 支持自动高度计算
    self.tableView.estimatedRowHeight = 90;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.customBackButton.mas_bottom).offset(30); // marginTop 30dp
        make.left.right.bottom.equalTo(self.view);
    }];
    
    // 注册cell
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"RechargeRecordCell"];
}

- (void)setupRefresh {
    __weak typeof(self) weakSelf = self;
    
    // 下拉刷新（使用国际化封装）
    MJRefreshNormalHeader *header = [MJRefreshHelper headerWithRefreshingBlock:^{
        [weakSelf loadRechargeHistory:YES];
    }];
    // 设置刷新状态下的文字颜色
    header.stateLabel.textColor = [UIColor whiteColor];
    header.lastUpdatedTimeLabel.textColor = [UIColor whiteColor];
    header.automaticallyChangeAlpha = YES;
    self.tableView.mj_header = header;
    
    // 上拉加载更多（使用国际化封装）
    MJRefreshAutoNormalFooter *footer = [MJRefreshHelper footerWithRefreshingBlock:^{
        [weakSelf loadRechargeHistory:NO];
    }];
    footer.stateLabel.textColor = [UIColor whiteColor];
    self.tableView.mj_footer = footer;
    self.tableView.mj_footer.hidden = YES;
}

- (void)loadRechargeHistory:(BOOL)isRefresh {
    if (self.isLoading) return;
    
    self.isLoading = YES;
    if (isRefresh) {
        self.index = 0; // 刷新时重置index为0
        self.hasMoreData = YES;
    }
    
    // 分页参数（index和count）
    NSDictionary *parameters = @{
        @"index": @(self.index),
        @"count": @(self.count)
    };
    
    // 只在首次加载时显示HUD，刷新时使用MJRefresh
    if (isRefresh && self.records.count == 0) {
        [SVProgressHUD showWithStatus:LocalString(@"加载中")];
    }
    
    // 使用钱包明细列表接口（user/getUserBudgetList），POST请求
    [[NetworkManager sharedManager] POST:BUNNYX_API_USER_BUDGET_LIST
                               parameters:parameters
                                  success:^(id responseObject) {
        self.isLoading = NO;
        [SVProgressHUD dismiss];
        [self endRefreshing];
        
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        // 处理返回数据格式 { "code": 0, "data": [...], "promptType": "..." }
        NSArray *dataArray = dict[@"data"];
        
        if (dataArray && [dataArray isKindOfClass:[NSArray class]]) {
            NSArray<RechargeRecordModel *> *newRecords = [RechargeRecordModel modelsFromResponse:dataArray];
            
            if (isRefresh) {
                [self.records removeAllObjects];
            }
            
            if (newRecords.count > 0) {
                [self.records addObjectsFromArray:newRecords];
                
                // 通过返回数据数量判断是否有更多数据
                self.hasMoreData = newRecords.count >= self.count;
                if (self.hasMoreData) {
                    // 每次增加count
                    self.index += self.count;
                }
            } else {
                self.hasMoreData = NO;
            }
        } else {
            if (isRefresh) {
                [self.records removeAllObjects];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        
        // 控制footer显示
        if (self.records.count == 0) {
            self.tableView.mj_footer.hidden = YES;
        } else {
            self.tableView.mj_footer.hidden = NO;
            if (!self.hasMoreData) {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
        }
    });
}

- (void)refreshData {
    // 刷新数据方法
    [self.tableView.mj_header beginRefreshing];
}

#pragma mark - 语言切换通知

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange:)
                                                 name:[LanguageManager languageDidChangeNotification]
                                               object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)languageDidChange:(NSNotification *)notification {
    // 语言切换后更新 MJRefresh 文案
    dispatch_async(dispatch_get_main_queue(), ^{
        [MJRefreshHelper updateLocalizationForScrollView:self.tableView];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.records.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RechargeRecordCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RechargeRecordCell"];
    }
    
    // 清除旧内容
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    
    RechargeRecordModel *record = self.records[indexPath.row];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    // 创建cell内容视图（按安卓布局：圆角15dp，paddingHorizontal 16dp，paddingVertical 16dp，marginBottom 16dp）
    UIView *containerView = [[UIView alloc] init];
    containerView.layer.cornerRadius = 15; // 圆角15dp（与安卓一致）
    [cell.contentView addSubview:containerView];
    
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(cell.contentView).insets(UIEdgeInsetsMake(0, 16, 0, 16)); // paddingHorizontal 16dp（与安卓一致）
        make.top.equalTo(cell.contentView);
        make.bottom.equalTo(cell.contentView).offset(-10); // marginBottom 16dp（与安卓一致）
    }];
    containerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.03]; // #0DFFFFFF 对应白色3%透明度
    
    // 第一行：标题（左）+ 金额（右）
    UIView *firstRowView = [[UIView alloc] init];
    [containerView addSubview:firstRowView];
    
    [firstRowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(containerView).insets(UIEdgeInsetsMake(0, 16, 0, 16)); // paddingHorizontal 16dp
        make.top.equalTo(containerView).offset(20); // paddingTop 16dp
    }];
    
    // 标题（左对齐，15sp bold，白色）
    NSString *title = record.budgetCode.length > 0 ? record.budgetCode : (record.remarks.length > 0 ? record.remarks : @"");
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = BOLD_FONT(15.0); // 15sp bold（与安卓一致）
    titleLabel.textColor = [UIColor whiteColor];
    [firstRowView addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(firstRowView);
        make.centerY.equalTo(firstRowView);
    }];
    
    // 金额（右对齐，15sp bold，根据budgetType显示颜色）
    NSInteger coins = record.coins > 0 ? record.coins : record.budgetNum;
    NSString *coinsText = @"";
    UIColor *coinsColor = HEX_COLOR(0x0AE971); // 默认绿色（收入）
    NSString *coinsUnit = LocalString(@"Coins");
    if (record.budgetType == 1) {
        // 支出
        coinsText = [NSString stringWithFormat:@"-%ld %@", (long)coins, coinsUnit];
        coinsColor = HEX_COLOR(0xB93218); // 红色（与安卓一致）
    } else {
        // 收入
        coinsText = [NSString stringWithFormat:@"+%ld %@", (long)coins, coinsUnit];
        coinsColor = HEX_COLOR(0x0AE971); // 绿色（与安卓一致）
    }
    
    UILabel *coinsLabel = [[UILabel alloc] init];
    coinsLabel.text = coinsText;
    coinsLabel.font = BOLD_FONT(15.0); // 15sp bold（与安卓一致）
    coinsLabel.textColor = coinsColor;
    coinsLabel.textAlignment = NSTextAlignmentRight;
    [firstRowView addSubview:coinsLabel];
    
    [coinsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(firstRowView);
        make.centerY.equalTo(firstRowView);
        make.left.greaterThanOrEqualTo(titleLabel.mas_right).offset(10); // 确保标题和金额不重叠
    }];
    
    // 第二行：时间（左对齐，12sp，black9 #999999）
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.text = record.createTime ?: @"";
    timeLabel.font = FONT(FONT_SIZE_12); // 12sp（与安卓一致）
    timeLabel.textColor = HEX_COLOR(0x999999); // black9（与安卓一致）
    [containerView addSubview:timeLabel];
    
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(16); // paddingLeft 16dp
        make.top.equalTo(titleLabel.mas_bottom).offset(12); // marginTop 6dp（与安卓一致）
        make.bottom.equalTo(containerView).offset(-16); // paddingBottom 16dp
    }];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 按安卓布局计算：paddingTop 16dp + 第一行高度（约20dp）+ marginTop 6dp + 时间行高度（约16dp）+ paddingBottom 16dp + marginBottom 16dp ≈ 90dp
    // 实际使用自动计算，这里给一个估算值
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90; // 估算高度
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = LocalString(@"暂无充值记录");
    NSDictionary *attributes = @{
        NSFontAttributeName: FONT(FONT_SIZE_16),
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

#pragma mark - DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}

@end

