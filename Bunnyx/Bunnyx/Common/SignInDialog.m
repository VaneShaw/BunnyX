//
//  SignInDialog.m
//  Bunnyx
//
//  签到弹窗（SignInDialog）
//

#import "SignInDialog.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "GradientButton.h"
#import "NetworkManager.h"
#import "SignDayCell.h"
#import "SignRewardCell.h"
#import "SignSuccessDialog.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "BunnyxNetworkMacros.h"

@interface SignInDialog () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *daysContainerView;
@property (nonatomic, strong) UICollectionView *daysCollectionView;
@property (nonatomic, strong) UILabel *daysDescLabel;
@property (nonatomic, strong) UIView *rewardsContainerView;
@property (nonatomic, strong) UICollectionView *rewardsCollectionView;
@property (nonatomic, strong) GradientButton *signButton;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) SignInData *signData;
@property (nonatomic, strong) NSArray<NSDictionary *> *daysData;
@property (nonatomic, strong) NSArray<NSDictionary *> *rewardsData;

@end

@implementation SignInData

@end

@implementation SignInDialog

+ (void)show {
    // 先请求签到数据，然后显示弹窗）
    [self requestSignDataAndShow];
}

+ (void)showWithData:(SignInData *)data {
    SignInDialog *dialog = [[SignInDialog alloc] init];
    dialog.signData = data;
    [dialog setupUI];
    [dialog loadData];
}

+ (void)requestSignDataAndShow {
    // 请求签到数据（GetUserSignListApi）
    // 拼上baseUrl）
    NSString *url = [NSString stringWithFormat:@"%@/user/task/getUserSignList", BUNNYX_API_BASE_URL];
    [[NetworkManager sharedManager] GET:url
                             parameters:nil
                                success:^(id responseObject) {
        // 解析响应（GetUserSignListApi.Bean）
        // if (result == null || result.getData() == null) { return; }
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            return;
        }
        NSDictionary *response = (NSDictionary *)responseObject;
        NSInteger code = [response[@"code"] integerValue];
        
        // 只有code == 0时才处理
        if (code == 0) {
            NSDictionary *dataDict = response[@"data"];
            // if (result.getData() == null) { return; }
            if (!dataDict) {
                return;
            }
            
            // 构建SignInData）
            SignInData *signData = [[SignInData alloc] init];
            signData.consecutiveDay = [dataDict[@"consecutiveDay"] integerValue];
            signData.signIn = [dataDict[@"signIn"] boolValue];
            signData.result = dataDict[@"result"] ?: @[];
            signData.signRewards = dataDict[@"signRewards"] ?: @[];
            
            // 如果当天未签到，显示签到弹窗（!data.isSignIn()）
            if (!signData.signIn) {
                [self showWithData:signData];
            }
        }
    }
                                failure:^(NSError *error) {
        BUNNYX_ERROR(@"获取签到数据失败: %@", error);
        // 请求失败时不显示弹窗（安卓的HttpCallback只有onSucceed，失败时不会调用，所以不会显示弹窗）
        // 不显示弹窗，直接返回
    }];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.daysData = @[];
        self.rewardsData = @[];
    }
    return self;
}

- (void)setupUI {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.frame = window.bounds;
    [window addSubview:self];
    
    // 背景遮罩（paddingBottom 35dp）
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:self.backgroundView];
    
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [self.backgroundView addGestureRecognizer:tap];
    
    // 内容容器（marginHorizontal 20dp，marginBottom 5dp，居中显示，不占满全屏）
    self.containerView = [[UIView alloc] init];
    [self addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.offset(335);
        make.height.offset(445);
    }];
    
    // 背景图片（bg_sign_topup，在containerView内部，不占满全屏）
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.image = [UIImage imageNamed:@"bg_sign_topup"];
    self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    self.backgroundImageView.clipsToBounds = YES;
    // 设置圆角（确保四个角都有圆角）
    self.backgroundImageView.layer.cornerRadius = 20; // 圆角20dp
    self.backgroundImageView.layer.masksToBounds = YES;
    [self.containerView addSubview:self.backgroundImageView];
    
    // 背景图约束到containerView，但需要等spacerBottom创建后再设置底部约束
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.containerView);
        // 底部约束在spacerBottom创建后设置
    }];
    
    // 创建辅助视图用于百分比定位（Guideline）
    UIView *sideStartGuide = [[UIView alloc] init];
    sideStartGuide.backgroundColor = [UIColor clearColor];
    [self.containerView addSubview:sideStartGuide];
    
    UIView *sideEndGuide = [[UIView alloc] init];
    sideEndGuide.backgroundColor = [UIColor clearColor];
    [self.containerView addSubview:sideEndGuide];

    [sideStartGuide mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView);
        make.width.equalTo(self.containerView).multipliedBy(0.06); // 6%
        make.top.bottom.equalTo(self.containerView);
    }];
    
    [sideEndGuide mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.containerView);
        make.width.equalTo(self.containerView).multipliedBy(0.06); // 6%
        make.top.bottom.equalTo(self.containerView);
    }];

    // 标题（23sp bold，黑色#333333，24%位置）
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"sign_title") ?: @"每日签到";
    self.titleLabel.textColor = HEX_COLOR(0x333333); // @color/black3
    self.titleLabel.font = BOLD_FONT(23); // 23sp bold
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sideStartGuide.mas_right);
        make.right.equalTo(sideEndGuide.mas_left);
        make.top.offset(100);
        make.height.offset(22);
    }];
    
    // 副标题（14sp，黑色#333333，marginTop 6dp）
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = LocalString(@"sign_subtitle") ?: @"VIP会员可获得双倍奖励";
    self.subtitleLabel.textColor = HEX_COLOR(0x333333); // @color/black3
    self.subtitleLabel.font = FONT(14); // 14sp
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.subtitleLabel];
    
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(11);
        make.height.offset(15);
    }];
    
    // 天列表容器（13% 黑 + 圆角13dp，padding 5dp，38%位置）
    self.daysContainerView = [[UIView alloc] init];
    self.daysContainerView.backgroundColor = RGBA(0, 0, 0, 0.13); // #21000000
    self.daysContainerView.layer.cornerRadius = 13; // 13dp
    self.daysContainerView.layer.masksToBounds = YES;
    [self.containerView addSubview:self.daysContainerView];
    
    [self.daysContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sideStartGuide.mas_right);
        make.right.equalTo(sideEndGuide.mas_left);
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(8);
        make.height.mas_equalTo(75); // 临时高度，后续根据内容调整
    }];
    
    // 天列表CollectionView（横向滚动，LinearLayoutManager.HORIZONTAL）
    UICollectionViewFlowLayout *daysLayout = [[UICollectionViewFlowLayout alloc] init];
    daysLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal; // 横向滚动
    daysLayout.minimumInteritemSpacing = 6;
    daysLayout.minimumLineSpacing = 6;
    daysLayout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    
    self.daysCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:daysLayout];
    self.daysCollectionView.backgroundColor = [UIColor clearColor];
    self.daysCollectionView.dataSource = self;
    self.daysCollectionView.delegate = self;
    self.daysCollectionView.showsHorizontalScrollIndicator = NO; // overScrollMode="never"
    self.daysCollectionView.alwaysBounceHorizontal = YES; // 允许横向滚动
    [self.daysCollectionView registerClass:[SignDayCell class] forCellWithReuseIdentifier:@"SignDayCell"];
    [self.daysContainerView addSubview:self.daysCollectionView];
    
    [self.daysCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.daysContainerView);
    }];
    
    // 天数描述（14sp，黑色#333333，50%位置，marginTop 10dp）
    self.daysDescLabel = [[UILabel alloc] init];
    self.daysDescLabel.text = LocalString(@"sign_days_desc") ?: @"已连续签到 1 天\n持续签到奖励更多金币";
    self.daysDescLabel.textColor = HEX_COLOR(0x333333); // @color/black3
    self.daysDescLabel.font = FONT(14); // 14sp
    self.daysDescLabel.textAlignment = NSTextAlignmentCenter;
    self.daysDescLabel.numberOfLines = 2;
    [self.containerView addSubview:self.daysDescLabel];
    
    [self.daysDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sideStartGuide.mas_right);
        make.right.equalTo(sideEndGuide.mas_left);
        make.top.equalTo(self.daysContainerView.mas_bottom).offset(10);\
        make.height.offset(36);
    }];
    
    // 奖励列表容器（同样样式，62%位置）
    self.rewardsContainerView = [[UIView alloc] init];
    self.rewardsContainerView.backgroundColor = RGBA(0, 0, 0, 0.13); // #21000000
    self.rewardsContainerView.layer.cornerRadius = 13; // 13dp
    self.rewardsContainerView.layer.masksToBounds = YES;
    [self.containerView addSubview:self.rewardsContainerView];
    
    [self.rewardsContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sideStartGuide.mas_right);
        make.right.equalTo(sideEndGuide.mas_left);
        make.top.equalTo(self.daysDescLabel.mas_bottom).offset(8);
        make.height.mas_equalTo(80); // 临时高度，后续根据内容调整
    }];
    
    // 奖励列表CollectionView（横向滚动，LinearLayoutManager.HORIZONTAL）
    UICollectionViewFlowLayout *rewardsLayout = [[UICollectionViewFlowLayout alloc] init];
    rewardsLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal; // 横向滚动
    rewardsLayout.minimumInteritemSpacing = 6;
    rewardsLayout.minimumLineSpacing = 6;
    rewardsLayout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    
    self.rewardsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:rewardsLayout];
    self.rewardsCollectionView.backgroundColor = [UIColor clearColor];
    self.rewardsCollectionView.dataSource = self;
    self.rewardsCollectionView.delegate = self;
    self.rewardsCollectionView.showsHorizontalScrollIndicator = NO; // overScrollMode="never"
    self.rewardsCollectionView.alwaysBounceHorizontal = YES; // 允许横向滚动
    [self.rewardsCollectionView registerClass:[SignRewardCell class] forCellWithReuseIdentifier:@"SignRewardCell"];
    [self.rewardsContainerView addSubview:self.rewardsCollectionView];
    
    [self.rewardsCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.rewardsContainerView);
    }];
    
    // 签到按钮（渐变背景#0AEA6F到#1CB3C1，圆角20dp，高度48dp，80%位置）
    self.signButton = [GradientButton buttonWithTitle:LocalString(@"sign_button") ?: @"签到"
                                            startColor:HEX_COLOR(0x0AEA6F) // #0AEA6F
                                              endColor:HEX_COLOR(0x1CB3C1)]; // #1CB3C1
    self.signButton.cornerRadius = 20; // 20dp
    self.signButton.buttonHeight = 48; // 48dp
    [self.signButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal]; // @color/black3
    self.signButton.titleLabel.font = FONT(16); // 16sp
    [self.signButton addTarget:self action:@selector(signButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.signButton];
    
    [self.signButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sideStartGuide.mas_right);
        make.right.equalTo(sideEndGuide.mas_left);
        make.top.equalTo(self.rewardsContainerView.mas_bottom).offset(16);
        make.height.mas_equalTo(48);
    }];
    
    // 背景底部占位视图（spacer_bottom，高度20dp）
    UIView *spacerBottom = [[UIView alloc] init];
    spacerBottom.backgroundColor = [UIColor clearColor];
    [self.containerView addSubview:spacerBottom];
    
    [spacerBottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sideStartGuide.mas_right);
        make.right.equalTo(sideEndGuide.mas_left);
        make.top.equalTo(self.signButton.mas_bottom);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.containerView);
    }];
    
    // 设置背景图的底部约束（背景图约束到spacer_bottom）
    [self.backgroundImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(spacerBottom.mas_bottom);
    }];
    
    // 外部关闭按钮（icon_home_pop_up_close_default，marginBottom -35dp，底部居中）
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setImage:[UIImage imageNamed:@"icon_home_pop_up_close_default"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.containerView.mas_bottom).offset(60);
        make.centerX.equalTo(self.containerView);
        make.width.height.offset(30);
    }];
}

- (void)loadData {
    if (self.signData) {
        [self updateUIWithData:self.signData];
    } else {
        // 如果没有数据，使用默认占位数据）
        [self setupDefaultData];
    }
}

- (void)setupDefaultData {
    // 默认填充占位项，保证首屏至少 4 个）
    NSMutableArray *days = [NSMutableArray array];
    [days addObject:@{@"coinText": @"+2", @"dateText": @"24/10"}];
    [days addObject:@{@"coinText": @"+2", @"dateText": @"25/10"}];
    [days addObject:@{@"coinText": @"+2", @"dateText": @"26/10"}];
    [days addObject:@{@"coinText": @"+2", @"dateText": @"27/10"}];
    self.daysData = days;
    
    NSMutableArray *rewards = [NSMutableArray array];
    [rewards addObject:@{@"coinText": @"+10", @"daysText": LocalString(@"sign_7_days") ?: @"7 Days"}];
    [rewards addObject:@{@"coinText": @"+30", @"daysText": LocalString(@"sign_30_days") ?: @"30 Days"}];
    [rewards addObject:@{@"coinText": @"+200", @"daysText": LocalString(@"sign_90_days") ?: @"90 Days"}];
    [rewards addObject:@{@"coinText": @"+120", @"daysText": LocalString(@"sign_120_days") ?: @"120 Days"}];
    self.rewardsData = rewards;
    
    [self.daysCollectionView reloadData];
    [self.rewardsCollectionView reloadData];
}

- (void)updateUIWithData:(SignInData *)data {
    // 顶部描述（对齐安卓：无论consecutiveDay是否大于0都显示格式化文案）
    NSString *desc = [NSString stringWithFormat:LocalString(@"sign_days_desc") ?: @"已连续签到 %d 天\n持续签到奖励更多金币", (int)data.consecutiveDay];
    self.daysDescLabel.text = desc;
    
    // 上方天列表）
    NSMutableArray *days = [NSMutableArray array];
    if (data.result && data.result.count > 0) {
        for (NSDictionary *item in data.result) {
            NSInteger signDate = [item[@"signDate"] integerValue];
            NSInteger rewardNum = [item[@"rewardNum"] integerValue];
            NSString *md = [self formatMonthDay:signDate];
            [days addObject:@{@"coinText": [NSString stringWithFormat:@"+%ld", (long)rewardNum], @"dateText": md}];
        }
    }
    if (days.count > 0) {
        self.daysData = days;
        [self.daysCollectionView reloadData];
    }
    
    // 下方奖励列表）
    NSMutableArray *rewards = [NSMutableArray array];
    if (data.signRewards && data.signRewards.count > 0) {
        for (NSDictionary *sr in data.signRewards) {
            NSInteger needDay = [sr[@"needDay"] integerValue];
            NSInteger rewardNum = [sr[@"rewardNum"] integerValue];
            NSString *daysText = [NSString stringWithFormat:LocalString(@"sign_days_format") ?: @"%d Days", (int)needDay];
            [rewards addObject:@{@"coinText": [NSString stringWithFormat:@"+%ld", (long)rewardNum], @"daysText": daysText}];
        }
    }
    if (rewards.count > 0) {
        self.rewardsData = rewards;
        [self.rewardsCollectionView reloadData];
    }
}

- (NSString *)formatMonthDay:(NSInteger)yyyymmdd {
    // yyyymmdd -> MM/dd）
    NSInteger month = (yyyymmdd / 100) % 100;
    NSInteger day = yyyymmdd % 100;
    return [NSString stringWithFormat:@"%ld/%02ld", (long)month, (long)day];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.daysCollectionView) {
        return self.daysData.count;
    } else if (collectionView == self.rewardsCollectionView) {
        return self.rewardsData.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.daysCollectionView) {
        SignDayCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SignDayCell" forIndexPath:indexPath];
        NSDictionary *item = self.daysData[indexPath.item];
        [cell configureWithCoinText:item[@"coinText"] dateText:item[@"dateText"]];
        return cell;
    } else if (collectionView == self.rewardsCollectionView) {
        SignRewardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SignRewardCell" forIndexPath:indexPath];
        NSDictionary *item = self.rewardsData[indexPath.item];
        [cell configureWithCoinText:item[@"coinText"] daysText:item[@"daysText"]];
        return cell;
    }
    return [[UICollectionViewCell alloc] init];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    // 在cell即将显示时，确保渐变层frame正确（避免首次显示时背景色不显示）
    if ([cell isKindOfClass:[SignDayCell class]]) {
        SignDayCell *signDayCell = (SignDayCell *)cell;
        // 强制触发layout，确保渐变层frame正确
        [signDayCell setNeedsLayout];
        [signDayCell layoutIfNeeded];
    } else if ([cell isKindOfClass:[SignRewardCell class]]) {
        SignRewardCell *signRewardCell = (SignRewardCell *)cell;
        // 强制触发layout，确保渐变层frame正确
        [signRewardCell setNeedsLayout];
        [signRewardCell layoutIfNeeded];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // item使用wrap_content，宽度根据内容自适应
    // 两个collectionView的cell应该使用相同的宽度计算方式，确保宽度一致
    
    // 统一的宽度计算函数（两个item布局结构相同）
    CGFloat (^calculateCellWidth)(NSString *, NSString *) = ^(NSString *coinText, NSString *bottomText) {
        // 计算文本宽度（18sp bold金币文本 + 11sp底部文本）
        UIFont *coinFont = BOLD_FONT(18);
        UIFont *bottomFont = FONT(11);
        
        // 金币文本宽度（包含图标16 + 间距5 + 文本）
        CGFloat coinIconWidth = 16;
        CGFloat coinSpacing = 5;
        CGSize coinSize = [coinText sizeWithAttributes:@{NSFontAttributeName: coinFont}];
        CGFloat coinTextWidth = coinIconWidth + coinSpacing + coinSize.width;
        
        // 底部文本宽度（日期或天数）
        CGSize bottomSize = [bottomText sizeWithAttributes:@{NSFontAttributeName: bottomFont}];
        CGFloat bottomTextWidth = bottomSize.width;
        
        // 取两者较大值，加上padding（外层padding 6dp，内层padding 8dp）
        CGFloat contentWidth = MAX(coinTextWidth, bottomTextWidth);
        CGFloat cellWidth = 6 * 2 + 8 * 2 + contentWidth; // padding 6*2 + container padding 8*2 + 内容
        
        // 确保最小宽度（wrap_content但要有合理的最小值）
        return MAX(cellWidth, 70);
    };
    
    CGFloat cellWidth = 0;
    CGFloat cellHeight = 0;
    
    if (collectionView == self.daysCollectionView) {
        // 天列表cell：根据内容计算宽度
        NSDictionary *item = self.daysData[indexPath.item];
        NSString *coinText = item[@"coinText"] ?: @"+0";
        NSString *dateText = item[@"dateText"] ?: @"";
        
        cellWidth = calculateCellWidth(coinText, dateText);
        // 高度：padding(6*2) + container padding(8*2) + marginTop(3) + 金币文本高度(18) + marginTop(3) + 日期文本高度(11) + 底部margin(3)
        cellHeight = 6 * 2 + 8 * 2 + 3 + 18 + 3 + 11 + 3;
    } else if (collectionView == self.rewardsCollectionView) {
        // 奖励列表cell：使用相同的宽度计算方式
        NSDictionary *item = self.rewardsData[indexPath.item];
        NSString *coinText = item[@"coinText"] ?: @"+0";
        NSString *daysText = item[@"daysText"] ?: @"";
        
        cellWidth = calculateCellWidth(coinText, daysText);
        // 高度：padding(6*2) + container padding(8*2) + marginTop(3) + 金币文本高度(18) + marginTop(6) + 天数文本高度(11)
        cellHeight = 6 * 2 + 8 * 2 + 3 + 18 + 6 + 11;
    }
    
    // 确保最小高度
    cellHeight = MAX(cellHeight, 70);
    
    return CGSizeMake(cellWidth, cellHeight);
}

#pragma mark - Actions

- (void)signButtonTapped {
    // 调用签到接口）
    [self performSignIn];
}

- (void)performSignIn {
    // 调用签到接口（user/task/everyday/signIn）
    // 注意：签到状态由接口返回决定，不在这里改变）
    BUNNYX_LOG(@"执行签到");
    
    // 显示加载提示
    [SVProgressHUD showWithStatus:LocalString(@"signing") ?: @"签到中..."];
    
    // 调用签到接口（拼上baseUrl）
    NSString *url = [NSString stringWithFormat:@"%@/user/task/everyday/signIn", BUNNYX_API_BASE_URL];
    [[NetworkManager sharedManager] POST:url
                               parameters:nil
                                  success:^(id responseObject) {
        [SVProgressHUD dismiss];
        
        // 解析响应（EverydaySignInApi.Bean）
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            
            if (code == 0) {
                // 签到成功（成功后关闭弹窗并显示成功弹窗，不改变当前弹窗状态）
                NSDictionary *data = response[@"data"];
                if (data && data[@"signReward"]) {
                    NSInteger reward = [data[@"signReward"] integerValue];
                    // 先关闭当前弹窗，再显示成功弹窗）
                    [self dismiss];
                    [SignSuccessDialog showWithReward:reward];
                } else {
                    // 没有奖励信息，也显示成功
                    [self dismiss];
                    [SignSuccessDialog showWithReward:0];
                }
            } else {
                // 签到失败（失败时不关闭弹窗，只显示错误提示）
                NSString *message = response[@"message"] ?: (LocalString(@"sign_failed") ?: @"签到失败");
                [SVProgressHUD showErrorWithStatus:message];
            }
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"sign_failed") ?: @"签到失败"];
        }
    }
                                  failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        BUNNYX_ERROR(@"签到失败: %@", error);
        // 失败时不关闭弹窗，只显示错误提示）
        [SVProgressHUD showErrorWithStatus:LocalString(@"network_error") ?: @"网络错误"];
    }];
}

- (void)dismiss {
    [self removeFromSuperview];
}

@end

