//
//  HostEnvironmentSwitchViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025/11/19.
//

#import "HostEnvironmentSwitchViewController.h"
#import <Masonry/Masonry.h>
#import "HostEnvironmentManager.h"
#import "GradientButton.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "BunnyxMacros.h"

@interface HostEnvironmentSwitchViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *currentEnvLabel;
@property (nonatomic, strong) UILabel *currentUrlLabel;
@property (nonatomic, strong) UIButton *productionButton;
@property (nonatomic, strong) UIButton *testButton;
@property (nonatomic, strong) UIView *customInputContainer;
@property (nonatomic, strong) UITextField *customTextField;
@property (nonatomic, strong) GradientButton *saveButton;
@property (nonatomic, assign) BXHostEnvironmentType selectedEnvironment;

@end

@implementation HostEnvironmentSwitchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalString(@"环境切换");
    self.view.backgroundColor = HEX_COLOR(0x0A1C1B);
    
    self.selectedEnvironment = [HostEnvironmentManager sharedManager].currentEnvironment;
    self.customTextField.text = [HostEnvironmentManager sharedManager].customBaseURL;
    
    [self setupUI];
    [self updateSelectionState];
    [self updateCurrentInfo];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI

- (void)setupUI {
    [self.view addSubview:self.currentEnvLabel];
    [self.currentEnvLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(24);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    [self.view addSubview:self.currentUrlLabel];
    [self.currentUrlLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.currentEnvLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.currentEnvLabel);
    }];
    
    [self.view addSubview:self.productionButton];
    [self.view addSubview:self.testButton];
    
    [self.productionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.currentUrlLabel.mas_bottom).offset(32);
        make.left.equalTo(self.view).offset(20);
        make.height.mas_equalTo(52);
    }];
    
    [self.testButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.productionButton);
        make.left.equalTo(self.productionButton.mas_right).offset(12);
        make.right.equalTo(self.view).offset(-20);
        make.width.equalTo(self.productionButton);
        make.height.equalTo(self.productionButton);
    }];
    
    [self.view addSubview:self.customInputContainer];
    [self.customInputContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.productionButton.mas_bottom).offset(24);
        make.left.equalTo(self.productionButton);
        make.right.equalTo(self.testButton);
        make.height.mas_equalTo(72);
    }];
    
    [self.customInputContainer addSubview:self.customTextField];
    [self.customTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.customInputContainer).insets(UIEdgeInsetsMake(12, 12, 12, 12));
    }];
    UITapGestureRecognizer *customTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(customContainerTapped)];
    customTap.cancelsTouchesInView = NO;
    [self.customInputContainer addGestureRecognizer:customTap];
    
    [self.view addSubview:self.saveButton];
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-40);
        make.height.mas_equalTo(48);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hostEnvironmentChanged) name:BXHostEnvironmentDidChangeNotification object:nil];
}

- (void)hostEnvironmentChanged {
    self.selectedEnvironment = [HostEnvironmentManager sharedManager].currentEnvironment;
    self.customTextField.text = [HostEnvironmentManager sharedManager].customBaseURL;
    [self updateSelectionState];
    [self updateCurrentInfo];
}

#pragma mark - Actions

- (void)optionButtonTapped:(UIButton *)sender {
    self.selectedEnvironment = (BXHostEnvironmentType)sender.tag;
    if (self.selectedEnvironment != BXHostEnvironmentTypeCustom) {
        [self.customTextField resignFirstResponder];
    }
    [self updateSelectionState];
}

- (void)customContainerTapped {
    self.selectedEnvironment = BXHostEnvironmentTypeCustom;
    [self updateSelectionState];
}

- (void)saveButtonTapped {
    NSString *customURL = nil;
    if (self.selectedEnvironment == BXHostEnvironmentTypeCustom) {
        customURL = [self.customTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (customURL.length == 0) {
            [SVProgressHUD showErrorWithStatus:LocalString(@"请输入合法的地址")];
            return;
        }
    }
    
    [[HostEnvironmentManager sharedManager] switchToEnvironment:self.selectedEnvironment customURL:customURL];
    [self updateCurrentInfo];
    [SVProgressHUD showSuccessWithStatus:LocalString(@"切换成功")];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark - Helpers

- (void)updateCurrentInfo {
    HostEnvironmentManager *manager = [HostEnvironmentManager sharedManager];
    NSString *envName = @"";
    switch (manager.currentEnvironment) {
        case BXHostEnvironmentTypeProduction:
            envName = LocalString(@"正式环境");
            break;
        case BXHostEnvironmentTypeTest:
            envName = LocalString(@"测试环境");
            break;
        case BXHostEnvironmentTypeCustom:
            envName = LocalString(@"自定义环境");
            break;
    }
    self.currentEnvLabel.text = [NSString stringWithFormat:@"%@：%@", LocalString(@"当前环境"), envName];
    self.currentUrlLabel.text = [NSString stringWithFormat:@"%@：%@", LocalString(@"当前地址"), manager.currentBaseURL];
}

- (void)updateSelectionState {
    [self styleButton:self.productionButton selected:(self.selectedEnvironment == BXHostEnvironmentTypeProduction)];
    [self styleButton:self.testButton selected:(self.selectedEnvironment == BXHostEnvironmentTypeTest)];
    
    BOOL isCustom = (self.selectedEnvironment == BXHostEnvironmentTypeCustom);
    self.customInputContainer.layer.borderColor = (isCustom ? HEX_COLOR(0x1CB3C1).CGColor : [UIColor colorWithWhite:1 alpha:0.1].CGColor);
    self.customInputContainer.layer.borderWidth = 1.0;
    self.customTextField.textColor = [UIColor whiteColor];
    
    if (isCustom) {
        [self.customTextField becomeFirstResponder];
    }
}

- (void)styleButton:(UIButton *)button selected:(BOOL)selected {
    if (selected) {
        button.backgroundColor = HEX_COLOR(0x1CB3C1);
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.layer.borderColor = HEX_COLOR(0x1CB3C1).CGColor;
    } else {
        button.backgroundColor = [UIColor clearColor];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.selectedEnvironment = BXHostEnvironmentTypeCustom;
    [self updateSelectionState];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Lazy Load

- (UILabel *)currentEnvLabel {
    if (!_currentEnvLabel) {
        _currentEnvLabel = [[UILabel alloc] init];
        _currentEnvLabel.font = BOLD_FONT(16);
        _currentEnvLabel.textColor = [UIColor whiteColor];
    }
    return _currentEnvLabel;
}

- (UILabel *)currentUrlLabel {
    if (!_currentUrlLabel) {
        _currentUrlLabel = [[UILabel alloc] init];
        _currentUrlLabel.font = FONT(14);
        _currentUrlLabel.textColor = HEX_COLOR(0x87A0A0);
        _currentUrlLabel.numberOfLines = 0;
    }
    return _currentUrlLabel;
}

- (UIButton *)productionButton {
    if (!_productionButton) {
        _productionButton = [self createOptionButtonWithTitle:LocalString(@"正式环境") tag:BXHostEnvironmentTypeProduction];
    }
    return _productionButton;
}

- (UIButton *)testButton {
    if (!_testButton) {
        _testButton = [self createOptionButtonWithTitle:LocalString(@"测试环境") tag:BXHostEnvironmentTypeTest];
    }
    return _testButton;
}

- (UIView *)customInputContainer {
    if (!_customInputContainer) {
        _customInputContainer = [[UIView alloc] init];
        _customInputContainer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
        _customInputContainer.layer.cornerRadius = 12;
        _customInputContainer.layer.masksToBounds = YES;
        _customInputContainer.layer.borderWidth = 1.0;
        _customInputContainer.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
    }
    return _customInputContainer;
}

- (UITextField *)customTextField {
    if (!_customTextField) {
        _customTextField = [[UITextField alloc] init];
        _customTextField.delegate = self;
        _customTextField.textColor = [UIColor whiteColor];
        _customTextField.font = FONT(14);
        _customTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LocalString(@"请输入自定义地址")
                                                                                attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.4]}];
        _customTextField.keyboardType = UIKeyboardTypeURL;
        _customTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _customTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _customTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    return _customTextField;
}

- (GradientButton *)saveButton {
    if (!_saveButton) {
        _saveButton = [GradientButton buttonWithTitle:LocalString(@"保存")];
        [_saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveButton;
}

- (UIButton *)createOptionButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = BOLD_FONT(16);
    button.layer.cornerRadius = 12;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    button.tag = tag;
    [button addTarget:self action:@selector(optionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end

