//
//  LanguageSettingsViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "LanguageSettingsViewController.h"

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
    self.view.backgroundColor = BUNNYX_BACKGROUND_COLOR;
    self.title = LocalString(@"语言设置");
    
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = BUNNYX_BACKGROUND_COLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:self.tableView];
    
    // 设置约束
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
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
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    NSDictionary *language = self.languages[indexPath.row];
    LanguageType languageType = [language[@"type"] integerValue];
    
    // 设置语言名称
    cell.textLabel.text = language[@"displayName"];
    cell.textLabel.font = FONT(16);
    cell.textLabel.textColor = BUNNYX_TEXT_COLOR;
    
    // 设置选中状态
    if (languageType == self.currentLanguage) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = BUNNYX_MAIN_COLOR;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = BUNNYX_TEXT_COLOR;
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
    return 50.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return LocalString(@"选择语言");
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
