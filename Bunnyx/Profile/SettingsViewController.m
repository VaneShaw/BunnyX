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
#import "BrowserViewController.h"
#import "AppConfigManager.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
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
    
    // background="#0A1C1B"
    self.view.backgroundColor = HEX_COLOR(0x0A1C1B);
    
    self.titles = @[
        LocalString(@"语言"),
        LocalString(@"用户协议"),
        LocalString(@"隐私政策"),
        LocalString(@"版本号"),
        LocalString(@"删除账号")
    ];
    
    [self setupLogoutButton];
    [self setupTableView];
}

#pragma mark - UI
- (void)setupLogoutButton {
    self.logoutButton = [GradientButton buttonWithTitle:LocalString(@"退出登录")];
    // 文字大小 sp_16
    self.logoutButton.titleLabel.font = FONT(FONT_SIZE_16);
    [self.logoutButton addTarget:self action:@selector(logoutButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logoutButton];
    
    // marginHorizontal=dp_16, marginTop=dp_30, marginBottom=dp_60, height=dp_48
    [self.logoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16); // dp_16
        make.right.equalTo(self.view).offset(-16); // dp_16
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-60); // marginBottom=dp_60
        make.height.mas_equalTo(48); // dp_48
    }];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // 使用CardView，不需要分隔线
    // paddingHorizontal=dp_16, paddingTop=dp_20
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    // RecyclerView layout_weight=1，占据剩余空间
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.customBackButton.mas_bottom).offset(18);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.logoutButton.mas_top).offset(-30); // marginTop=dp_30（相对于退出登录按钮）
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone; // 去掉点击时的颜色效果
        cell.backgroundColor = [UIColor clearColor]; // 透明背景，让CardView样式显示
        
        // CardView样式，cardBackgroundColor=#0DFFFFFF (半透明白色), cardCornerRadius=dp_15
        UIView *cardView = [[UIView alloc] init];
        cardView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05]; // #0DFFFFFF 转换为 RGBA
        cardView.layer.cornerRadius = 15.0; // dp_15
        cardView.layer.masksToBounds = YES;
        cardView.tag = 1000; // 用于后续查找
        [cell.contentView addSubview:cardView];
        
        // paddingVertical=dp_16, paddingHorizontal=dp_16, marginBottom=dp_16
        [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(cell.contentView).offset(15);
            make.right.offset(-15);
            make.top.equalTo(cell.contentView);
            make.height.mas_equalTo(52); // 固定高度52dp（CardView内容高度）
        }];
        
        // 自定义标题Label（textSize=sp_15, textStyle=bold, textColor=white）
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = BOLD_FONT(15);
        titleLabel.tag = 1001; // 用于后续查找
        [cardView addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(cardView).offset(16); // paddingHorizontal=dp_16
            make.centerY.equalTo(cardView);
            make.right.lessThanOrEqualTo(cardView).offset(-100); // 为副标题和箭头留出空间
        }];
        
        // 自定义副标题Label（textSize=sp_15, textColor=black9）
        UILabel *subtitleLabel = [[UILabel alloc] init];
        subtitleLabel.textColor = HEX_COLOR(0x999999); // black9 对应 #999999
        subtitleLabel.font = FONT(15);
        subtitleLabel.textAlignment = NSTextAlignmentRight;
        subtitleLabel.tag = 1002; // 用于后续查找
        [cardView addSubview:subtitleLabel];
        [subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(cardView).offset(-40); // 为箭头留出空间（箭头宽度约24dp + padding 16dp）
            make.centerY.equalTo(cardView);
            make.left.greaterThanOrEqualTo(titleLabel.mas_right).offset(12); // marginEnd=dp_12（相对于标题）
        }];
        
        // 箭头图标（icon_mine_enter_default）
        UIImageView *arrowImageView = [[UIImageView alloc] init];
        arrowImageView.image = [UIImage imageNamed:@"icon_mine_enter_default"];
        arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
        arrowImageView.tag = 1003; // 用于后续查找
        [cardView addSubview:arrowImageView];
        [arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(cardView).offset(-16); // paddingHorizontal=dp_16
            make.centerY.equalTo(cardView);
            make.width.height.mas_equalTo(24); // 箭头图标大小
        }];
    }
    
    // 获取自定义视图（通过tag查找）
    UIView *cardView = [cell.contentView viewWithTag:1000];
    UILabel *titleLabel = [cardView viewWithTag:1001];
    UILabel *subtitleLabel = [cardView viewWithTag:1002];
    UIImageView *arrowImageView = [cardView viewWithTag:1003];
    
    // 设置标题
    NSString *title = self.titles[indexPath.row];
    titleLabel.text = title;
    subtitleLabel.text = nil;
    subtitleLabel.hidden = YES;
    
    switch (indexPath.row) {
        case SettingsRowLanguage: {
            // 显示当前语言（来源于 LanguageManager）
            subtitleLabel.text = [LanguageManager sharedManager].currentLanguageName;
            subtitleLabel.hidden = NO;
            arrowImageView.hidden = NO; // 有箭头
        } break;
        case SettingsRowAgreement: {
            arrowImageView.hidden = NO; // 有箭头
        } break;
        case SettingsRowPrivacy: {
            arrowImageView.hidden = NO; // 有箭头
        } break;
        case SettingsRowVersion: {
            NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; 
            NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]; 
            subtitleLabel.text = [NSString stringWithFormat:@"%@ (%@)", shortVersion ?: @"1.0", build ?: @"1"]; 
            subtitleLabel.hidden = NO;
            arrowImageView.hidden = YES; // 没有箭头
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } break;
        case SettingsRowDelete: {
            arrowImageView.hidden = NO; // 有箭头
            // 删除账号保持白色文字（安卓中没有特殊颜色）
            titleLabel.textColor = [UIColor whiteColor];
        } break;
        default: break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // CardView高度52dp + marginBottom=dp_16 = 68dp
    return 53.0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68.0; // CardView高度52dp + marginBottom=dp_16 = 68dp
}

// 每个CardView有marginBottom=dp_16，通过section间距实现
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01; // 最小高度
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01; // 最小高度
}

// 列表项之间的间距（marginBottom=dp_16）
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case SettingsRowLanguage: {
            LanguageSettingsViewController *vc = [[LanguageSettingsViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        } break;
        case SettingsRowAgreement: {
            [self openUserAgreement];
        } break;
        case SettingsRowPrivacy: {
            [self openPrivacyPolicy];
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

// 打开用户协议
- (void)openUserAgreement {
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    if (config && config.userAgreementUrl && config.userAgreementUrl.length > 0) {
        BrowserViewController *browserVC = [[BrowserViewController alloc] initWithURL:config.userAgreementUrl];
        browserVC.title = LocalString(@"用户协议");
        browserVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:browserVC animated:YES];
    } else {
        [SVProgressHUD showErrorWithStatus:LocalString(@"用户协议链接暂不可用")];
    }
}

// 打开隐私政策
- (void)openPrivacyPolicy {
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    if (config && config.privacyPolicyUrl && config.privacyPolicyUrl.length > 0) {
        BrowserViewController *browserVC = [[BrowserViewController alloc] initWithURL:config.privacyPolicyUrl];
        browserVC.title = LocalString(@"隐私政策");
        browserVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:browserVC animated:YES];
    } else {
        [SVProgressHUD showErrorWithStatus:LocalString(@"隐私政策链接暂不可用")];
    }
}

// 显示删除账号确认对话框
- (void)confirmDeleteAccount {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"确认删除")
                                                                   message:LocalString(@"此操作不可撤销，是否继续？")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LocalString(@"删除账号") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performDeleteAccount];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

// 调用删除账号接口
- (void)performDeleteAccount {
    [SVProgressHUD showWithStatus:LocalString(@"加载中")];
    
    // 调用删除账号接口 user/del/user
    [[NetworkManager sharedManager] POST:BUNNYX_API_USER_DELETE
                               parameters:nil
                                  success:^(id responseObject) {
        [SVProgressHUD dismiss];
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 删除成功，清理本地数据并返回登录页
            [self clearUserData];
            [self navigateToLoginPage];
        } else {
            // 即使接口返回失败，也清理本地数据并跳转
            [self clearUserData];
            [self navigateToLoginPage];
        }
    } failure:^(NSError *error) {
        // 失败也清理并回到登录
        [self clearUserData];
        [self navigateToLoginPage];
    }];
}

// 清除用户数据
- (void)clearUserData {
    // 清除Token信息（TokenManager.getInstance(this).clearLoginInfo()）
    [[UserManager sharedManager] logout];
    
    // 清除用户信息（UserInfoManager.getInstance(this).clearUserInfo()）
    // UserManager的logout方法已经包含了清除用户信息的逻辑
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
        // 接口调用失败，错误提示由 NetworkManager 自动显示
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


