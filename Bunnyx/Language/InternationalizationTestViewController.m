#import "InternationalizationTestViewController.h"
#import "LanguageManager.h"
#import "BunnyxMacros.h"

@interface InternationalizationTestViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *exampleLabel;
@property (nonatomic, strong) UIButton *switchLanguageButton;
@property (nonatomic, strong) UIButton *testButton;

@end

@implementation InternationalizationTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
    [self updateUI];
    
    // 监听语言切换通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange:)
                                                 name:[LanguageManager languageDidChangeNotification]
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.titleLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.titleLabel];
    
    // 示例标签
    self.exampleLabel = [[UILabel alloc] init];
    self.exampleLabel.textAlignment = NSTextAlignmentCenter;
    self.exampleLabel.font = [UIFont systemFontOfSize:16];
    self.exampleLabel.textColor = [UIColor darkGrayColor];
    self.exampleLabel.numberOfLines = 0;
    [self.view addSubview:self.exampleLabel];
    
    // 语言切换按钮
    self.switchLanguageButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.switchLanguageButton addTarget:self action:@selector(switchLanguageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchLanguageButton];
    
    // 测试按钮
    self.testButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.testButton addTarget:self action:@selector(testButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.testButton];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.exampleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.switchLanguageButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.testButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 标题标签
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:50],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        // 示例标签
        [self.exampleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.exampleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:30],
        [self.exampleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.exampleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        // 语言切换按钮
        [self.switchLanguageButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.switchLanguageButton.topAnchor constraintEqualToAnchor:self.exampleLabel.bottomAnchor constant:50],
        [self.switchLanguageButton.widthAnchor constraintEqualToConstant:200],
        [self.switchLanguageButton.heightAnchor constraintEqualToConstant:44],
        
        // 测试按钮
        [self.testButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.testButton.topAnchor constraintEqualToAnchor:self.switchLanguageButton.bottomAnchor constant:20],
        [self.testButton.widthAnchor constraintEqualToConstant:200],
        [self.testButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)updateUI {
    // 更新标题
    self.titleLabel.text = LocalString(@"欢迎使用");
    
    // 更新示例文本
    self.exampleLabel.text = LocalString(@"例子");
    
    // 更新按钮文本
    LanguageType currentLanguage = [[LanguageManager sharedManager] currentLanguage];
    if (currentLanguage == LanguageTypeChinese) {
        [self.switchLanguageButton setTitle:LocalString(@"切换到英文") forState:UIControlStateNormal];
    } else {
        [self.switchLanguageButton setTitle:LocalString(@"切换到中文") forState:UIControlStateNormal];
    }
    
    [self.testButton setTitle:LocalString(@"测试翻译") forState:UIControlStateNormal];
    
    // 更新导航栏标题
    self.navigationItem.title = LocalString(@"国际化测试");
}

#pragma mark - Actions

- (void)switchLanguageButtonTapped:(UIButton *)sender {
    LanguageType currentLanguage = [[LanguageManager sharedManager] currentLanguage];
    LanguageType newLanguage = (currentLanguage == LanguageTypeChinese) ? LanguageTypeEnglish : LanguageTypeChinese;
    
    [[LanguageManager sharedManager] setLanguage:newLanguage];
    
    // UI会在通知回调中自动更新
    BUNNYX_LOG(@"语言已切换到: %@", [[LanguageManager sharedManager] currentLanguageName]);
}

- (void)testButtonTapped:(UIButton *)sender {
    // 测试各种翻译
    NSArray *testKeys = @[@"确定", @"取消", @"设置", @"首页", @"个人中心", @"例子"];
    NSMutableString *testResults = [NSMutableString stringWithString:LocalString(@"测试结果")];
    [testResults appendString:@"\n\n"];
    
    for (NSString *key in testKeys) {
        NSString *translation = LocalString(key);
        [testResults appendFormat:@"%@ -> %@\n", key, translation];
    }
    
    // 显示测试结果
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"测试结果")
                                                                   message:testResults
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LocalString(@"确定") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Language Change Notification

- (void)languageDidChange:(NSNotification *)notification {
    BUNNYX_LOG(@"InternationalizationTestViewController 收到语言切换通知");
    [self updateUI];
}

@end
