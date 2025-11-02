//
//  SettingsViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025/10/30.
//

#import "SettingsViewController.h"
#import "LanguageSettingsViewController.h"
#import "GradientButton.h"
#import "UserManager.h"
#import "LoginViewController.h"
#import <SafariServices/SafariServices.h>
#import <SVProgressHUD/SVProgressHUD.h>

typedef NS_ENUM(NSInteger, SettingsRow) {
    SettingsRowLanguage = 0,
    SettingsRowAgreement,
    SettingsRowPrivacy,
    SettingsRowVersion,
    SettingsRowDelete,
    SettingsRowCount
};

@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, strong) GradientButton *logoutButton;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalString(@"设置");
    
    self.titles = @[
        LocalString(@"语言"),
        LocalString(@"用户协议"),
        LocalString(@"隐私政策"),
        LocalString(@"版本号"),
        LocalString(@"注销账号")
    ];
    
    [self setupLogoutButton];
    [self setupTableView];
}

#pragma mark - UI
- (void)setupLogoutButton {
    self.logoutButton = [GradientButton buttonWithTitle:LocalString(@"退出登录")];
    [self.logoutButton addTarget:self action:@selector(logoutButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logoutButton];
    
    [self.logoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(MARGIN_20);
        make.right.equalTo(self.view).offset(-MARGIN_20);
        make.bottom.equalTo(self.view).offset(-(SAFE_AREA_BOTTOM + MARGIN_20));
        make.height.mas_equalTo(self.logoutButton.buttonHeight);
    }];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(NAVIGATION_BAR_HEIGHT+STATUS_BAR_HEIGHT+SAFE_AREA_TOP);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.logoutButton.mas_top).offset(-MARGIN_20);
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return SettingsRowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    }
    cell.backgroundColor = [UIColor colorWithWhite:0.06 alpha:1.0];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSString *title = self.titles[indexPath.row];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = nil;
    
    switch (indexPath.row) {
        case SettingsRowLanguage: {
            // 显示当前语言（来源于 LanguageManager）
            cell.detailTextLabel.text = [LanguageManager sharedManager].currentLanguageName;
        } break;
        case SettingsRowAgreement: {
        } break;
        case SettingsRowPrivacy: {
        } break;
        case SettingsRowVersion: {
            cell.accessoryType = UITableViewCellAccessoryNone;
            NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; 
            NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]; 
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", shortVersion ?: @"1.0", build ?: @"1"]; 
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } break;
        case SettingsRowDelete: {
            cell.textLabel.textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
        } break;
        default: break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case SettingsRowLanguage: {
            LanguageSettingsViewController *vc = [[LanguageSettingsViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        } break;
        case SettingsRowAgreement: {
            [self openURLString:@"https://example.com/user-agreement" title:LocalString(@"用户协议")];
        } break;
        case SettingsRowPrivacy: {
            [self openURLString:@"https://example.com/privacy" title:LocalString(@"隐私政策")];
        } break;
        case SettingsRowVersion: {
            // 无动作
        } break;
        case SettingsRowDelete: {
            [self confirmDeleteAccount];
        } break;
        default: break;
    }
}

#pragma mark - Actions

- (void)openURLString:(NSString *)urlString title:(NSString *)title {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) { return; }
    if (@available(iOS 9.0, *)) {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
        safari.preferredBarTintColor = [UIColor blackColor];
        safari.preferredControlTintColor = [UIColor whiteColor];
        [self presentViewController:safari animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)confirmDeleteAccount {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"确认注销")
                                                                   message:LocalString(@"此操作不可撤销，是否继续？")
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LocalString(@"注销账号") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // TODO: 接入后端注销流程
        NSLog(@"Delete account confirmed");
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)logoutButtonTapped:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"退出登录")
                                                                   message:LocalString(@"确定要退出登录吗？")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:LocalString(@"确定") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performLogout];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performLogout {
    // 显示加载提示
    [SVProgressHUD showWithStatus:LocalString(@"加载中")];
    
    // 执行退出登录（调用后端接口）
    [[UserManager sharedManager] logoutWithSuccess:^{
        [SVProgressHUD dismiss];
        
        // 接口调用成功，跳转到登录页面
        [self navigateToLoginPage];
    } failure:^(NSError *error) {
        // 接口调用失败，只关闭加载提示，错误提示由 NetworkManager 自动显示
        [SVProgressHUD dismiss];
        
        // 不进行后续操作，保持在当前页面
    }];
}

- (void)navigateToLoginPage {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                window = windowScene.windows.firstObject;
                break;
            }
        }
    } else {
        window = [UIApplication sharedApplication].delegate.window;
    }
    
    if (window) {
        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        [UIView transitionWithView:window duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            window.rootViewController = loginViewController;
        } completion:nil];
    }
}

@end


