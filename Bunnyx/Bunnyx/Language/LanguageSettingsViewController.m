//
//  LanguageSettingsViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "LanguageSettingsViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"

// 声明通知名称
extern NSString * const LanguageDidChangeNotification;

@interface LanguageSettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *languages;
@property (nonatomic, assign) LanguageType currentLanguage;

@end

@implementation LanguageSettingsViewController

#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadData];
    [self addObservers];
}

- (void)dealloc {
    [self removeObservers];
}

#pragma mark - 初始化

- (void)setupUI {
    // 对齐安卓：background="#0A1C1B"
    self.view.backgroundColor = HEX_COLOR(0x0A1C1B);
    self.title = LocalString(@"语言设置");
    
    // 对齐安卓：使用和设置页面一样的TableView样式
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // 对齐安卓：使用CardView，不需要分隔线
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    // 对齐安卓：RecyclerView layout_weight=1，占据剩余空间
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.customBackButton.mas_bottom).offset(18);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
}

- (void)loadData {
    LanguageManager *manager = [LanguageManager sharedManager];
    self.languages = [manager supportedLanguages];
    self.currentLanguage = manager.currentLanguage;
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange:)
                                                 name:LanguageDidChangeNotification
                                               object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 通知处理

- (void)languageDidChange:(NSNotification *)notification {
    // 语言切换后更新界面
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadData];
        [self.tableView reloadData];
        self.title = LocalString(@"语言设置");
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.languages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"LanguageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone; // 去掉点击时的颜色效果
        cell.backgroundColor = [UIColor clearColor]; // 透明背景，让CardView样式显示
        
        // 对齐安卓：CardView样式，cardBackgroundColor=#0DFFFFFF (半透明白色), cardCornerRadius=dp_15
        UIView *cardView = [[UIView alloc] init];
        cardView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05]; // #0DFFFFFF 转换为 RGBA
        cardView.layer.cornerRadius = 15.0; // dp_15
        cardView.layer.masksToBounds = YES;
        cardView.tag = 1000; // 用于后续查找
        [cell.contentView addSubview:cardView];
        
        // 对齐安卓：paddingVertical=dp_16, paddingHorizontal=dp_16, marginBottom=dp_16
        // 对齐设置页面：cardView左右边距16（对齐安卓：RecyclerView paddingHorizontal=dp_16）
        [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(cell.contentView).offset(16);
            make.right.equalTo(cell.contentView).offset(-16);
            make.top.equalTo(cell.contentView);
            make.height.mas_equalTo(52); // 固定高度52dp（CardView内容高度）
        }];
        
        // 对齐安卓：自定义标题Label（textSize=sp_15, textStyle=bold, textColor=white）
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = BOLD_FONT(15);
        titleLabel.tag = 1001; // 用于后续查找
        [cardView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(cardView).offset(16); // paddingHorizontal=dp_16
            make.centerY.equalTo(cardView);
            make.right.lessThanOrEqualTo(cardView).offset(-50); // 为checkmark留出空间
        }];
        
        // 对齐安卓：选中状态图标（checkmark）
        UIImageView *checkmarkImageView = [[UIImageView alloc] init];
        // 使用系统checkmark图标，如果没有则使用箭头图标
        if (@available(iOS 13.0, *)) {
            UIImage *checkmarkImage = [UIImage systemImageNamed:@"checkmark"];
            if (checkmarkImage) {
                checkmarkImageView.image = [checkmarkImage imageWithTintColor:[UIColor whiteColor] renderingMode:UIImageRenderingModeAlwaysTemplate];
            } else {
                checkmarkImageView.image = [UIImage imageNamed:@"icon_mine_enter_default"];
            }
        } else {
            checkmarkImageView.image = [UIImage imageNamed:@"icon_mine_enter_default"];
        }
        checkmarkImageView.contentMode = UIViewContentModeScaleAspectFit;
        checkmarkImageView.tag = 1002; // 用于后续查找
        checkmarkImageView.hidden = YES; // 默认隐藏，选中时显示
        [cardView addSubview:checkmarkImageView];
        [checkmarkImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(cardView).offset(-16); // paddingHorizontal=dp_16
            make.centerY.equalTo(cardView);
            make.width.height.mas_equalTo(24); // 图标大小
        }];
    }
    
    // 获取自定义视图（通过tag查找）
    UIView *cardView = [cell.contentView viewWithTag:1000];
    UILabel *titleLabel = [cardView viewWithTag:1001];
    UIImageView *checkmarkImageView = [cardView viewWithTag:1002];
    
    NSDictionary *language = self.languages[indexPath.row];
    LanguageType languageType = [language[@"type"] integerValue];
    
    // 设置语言名称
    titleLabel.text = language[@"displayName"];
    
    // 设置选中状态
    if (languageType == self.currentLanguage) {
        checkmarkImageView.hidden = NO; // 显示checkmark
        // 对齐安卓：选中状态可以使用不同颜色，但这里保持白色（对齐安卓没有特殊颜色）
        titleLabel.textColor = [UIColor whiteColor];
    } else {
        checkmarkImageView.hidden = YES; // 隐藏checkmark
        titleLabel.textColor = [UIColor whiteColor];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *language = self.languages[indexPath.row];
    LanguageType languageType = [language[@"type"] integerValue];
    
    if (languageType != self.currentLanguage) {
        // 切换语言
        LanguageManager *manager = [LanguageManager sharedManager];
        [manager setLanguage:languageType];
        
        // 显示切换成功提示
        [self showLanguageChangeAlert:language[@"displayName"]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 对齐安卓：CardView高度52dp + marginBottom=dp_16 = 68dp
    return 53.0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 53.0; // 对齐安卓：CardView高度52dp + marginBottom=dp_16 = 68dp
}

// 对齐安卓：每个CardView有marginBottom=dp_16，通过section间距实现
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01; // 最小高度（对齐安卓：没有section header）
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01; // 最小高度
}

// 对齐安卓：列表项之间的间距（marginBottom=dp_16）
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

#pragma mark - 辅助方法

- (void)showLanguageChangeAlert:(NSString *)languageName {
    NSString *message = [NSString stringWithFormat:@"%@ %@", LocalString(@"语言已切换到"), languageName];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"提示")
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LocalString(@"确定")
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
