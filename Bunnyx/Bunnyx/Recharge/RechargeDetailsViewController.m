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
#import <MJRefresh/MJRefresh.h>

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
    
    // 初始加载数据
    [self loadRechargeHistory:YES];
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
    self.titleLabel.text = LocalString(@"Recharge Details") ?: @"Recharge Details";
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
    
    // 下拉刷新
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadRechargeHistory:YES];
    }];
    // 设置刷新状态下的文字颜色
    header.stateLabel.textColor = [UIColor whiteColor];
    header.lastUpdatedTimeLabel.textColor = [UIColor whiteColor];
    header.automaticallyChangeAlpha = YES;
    self.tableView.mj_header = header;
    
    // 上拉加载更多
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [weakSelf loadRechargeHistory:NO];
    }];
    footer.stateLabel.textColor = [UIColor whiteColor];
    [footer setTitle:LocalString(@"没有更多数据了") forState:MJRefreshStateNoMoreData];
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
        [SVProgressHUD dismiss];
        [self endRefreshing];
        self.hasMoreData = NO;
        
        // 错误处理
        if (isRefresh && self.records.count == 0) {
            // 首次加载失败，显示错误提示
            [SVProgressHUD showErrorWithStatus:LocalString(@"加载失败")];
        }
        
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
    
    // 创建cell内容视图
    UIView *containerView = [[UIView alloc] init];
    containerView.layer.cornerRadius = 12; // 圆角12dp
    [cell.contentView addSubview:containerView];
    
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(cell.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20)); // paddingHorizontal 20dp
        make.top.bottom.equalTo(cell.contentView).insets(UIEdgeInsetsMake(0, 0, 15, 0)); // marginBottom 15dp
        make.height.mas_equalTo(80); // itemHeight 80dp
    }];
    containerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.03];
    
    // 金币图标（icon_mine_coin_default）
    UIImageView *coinIcon = [[UIImageView alloc] init];
    coinIcon.image = [UIImage imageNamed:@"icon_mine_coin_default"];
    coinIcon.contentMode = UIViewContentModeScaleAspectFit;
    [containerView addSubview:coinIcon];
    
    [coinIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(20); // marginLeft 20dp
        make.centerY.equalTo(containerView);
        make.width.height.mas_equalTo(40); // 40dp × 40dp
    }];
    
    // 金币数量（绿色，20sp bold）
    // 根据budgetType显示：1支出2收入，收入显示+，支出显示-
    NSInteger coins = record.coins > 0 ? record.coins : record.budgetNum;
    NSString *coinsText = @"";
    if (record.budgetType == 2) {
        // 收入
        coinsText = [NSString stringWithFormat:@"+%ld", (long)coins];
    } else if (record.budgetType == 1) {
        // 支出
        coinsText = [NSString stringWithFormat:@"-%ld", (long)coins];
    } else {
        // 默认显示+
        coinsText = [NSString stringWithFormat:@"+%ld", (long)coins];
    }
    
    UILabel *coinsLabel = [[UILabel alloc] init];
    coinsLabel.text = coinsText;
    coinsLabel.font = BOLD_FONT(FONT_SIZE_20);
    coinsLabel.textColor = HEX_COLOR(0x0AE971); // #0AE971
    [containerView addSubview:coinsLabel];
    
    [coinsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(coinIcon.mas_right).offset(15); // 间距15dp
        make.top.equalTo(containerView).offset(15); // marginTop 15dp
    }];
    
    // 时间（白色，14sp）
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.text = record.createTime ?: @"";
    timeLabel.font = FONT(FONT_SIZE_14);
    timeLabel.textColor = [UIColor whiteColor];
    [containerView addSubview:timeLabel];
    
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(coinsLabel);
        make.top.equalTo(coinsLabel.mas_bottom).offset(8); // 间距8dp
    }];
    
    // 金额（白色，16sp，右对齐）
    UILabel *amountLabel = [[UILabel alloc] init];
    amountLabel.text = [NSString stringWithFormat:@"$%.2f", record.amount];
    amountLabel.font = FONT(FONT_SIZE_16);
    amountLabel.textColor = [UIColor whiteColor];
    amountLabel.textAlignment = NSTextAlignmentRight;
    [containerView addSubview:amountLabel];
    
    [amountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(containerView).offset(-20); // marginRight 20dp
        make.centerY.equalTo(containerView);
    }];
    
    // 状态标签（根据state显示不同文字和颜色）
    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.font = FONT(FONT_SIZE_12);
    
    NSString *state = record.state.length > 0 ? record.state : record.status;
    if (state && state.length > 0) {
        NSString *statusText = @"";
        UIColor *statusColor = [UIColor whiteColor];
        
        // 状态映射
        if ([state isEqualToString:@"success"] || [state isEqualToString:@"completed"] || [state isEqualToString:@"成功"]) {
            statusText = LocalString(@"成功") ?: @"Success";
            statusColor = HEX_COLOR(0x0AE971); // 成功：绿色
        } else if ([state isEqualToString:@"pending"] || [state isEqualToString:@"processing"] || [state isEqualToString:@"处理中"]) {
            statusText = LocalString(@"处理中") ?: @"Processing";
            statusColor = [UIColor yellowColor]; // 待处理：黄色
        } else if ([state isEqualToString:@"failed"] || [state isEqualToString:@"failure"] || [state isEqualToString:@"失败"]) {
            statusText = LocalString(@"失败") ?: @"Failed";
            statusColor = [UIColor redColor]; // 失败：红色
        } else {
            statusText = state;
            statusColor = [UIColor whiteColor];
        }
        
        statusLabel.text = statusText;
        statusLabel.textColor = statusColor;
        [containerView addSubview:statusLabel];
        
        [statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(containerView).offset(-20);
            make.bottom.equalTo(containerView).offset(-15);
        }];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 95; // 80dp + 15dp marginBottom
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = LocalString(@"暂无充值记录") ?: @"No Recharge Records";
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

