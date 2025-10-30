//
//  SettingsViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025/10/30.
//

#import "SettingsViewController.h"
#import "LanguageSettingsViewController.h"
#import <SafariServices/SafariServices.h>

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
    
    [self setupTableView];
}

#pragma mark - UI
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
        make.left.bottom.right.equalTo(self.view);
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

@end


