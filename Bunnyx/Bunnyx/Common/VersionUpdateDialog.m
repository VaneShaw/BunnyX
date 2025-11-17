//
//  VersionUpdateDialog.m
//  Bunnyx
//
//  版本更新弹窗（对齐安卓VersionUpdateDialog）
//

#import "VersionUpdateDialog.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "GradientButton.h"
#import <StoreKit/StoreKit.h>

@implementation VersionUpdateInfo

@end

@interface VersionUpdateDialog ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) GradientButton *updateButton;
@property (nonatomic, strong) UIButton *laterButton;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) VersionUpdateInfo *appInfo;
@property (nonatomic, assign) BOOL isForceUpdate;
@property (nonatomic, copy) OnDismissListener onDismissListener;

@end

@implementation VersionUpdateDialog

+ (void)showWithAppInfo:(VersionUpdateInfo *)appInfo {
    [self showWithAppInfo:appInfo onDismiss:nil];
}

+ (VersionUpdateDialog *)showWithAppInfo:(VersionUpdateInfo *)appInfo onDismiss:(OnDismissListener)onDismissListener {
    if (!appInfo) {
        return nil;
    }
    
    VersionUpdateDialog *dialog = [[VersionUpdateDialog alloc] init];
    dialog.appInfo = appInfo;
    dialog.onDismissListener = onDismissListener;
    // 判断是否强制更新（对齐安卓：forceType == 1）
    dialog.isForceUpdate = (appInfo.forceType == 1);
    [dialog setupUI];
    return dialog;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化
    }
    return self;
}

- (void)setupUI {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.frame = window.bounds;
    [window addSubview:self];
    
    // 背景遮罩（对齐安卓：paddingBottom 35dp）
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:self.backgroundView];
    
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    // 如果非强制更新，允许点击背景关闭（对齐安卓：setCancelable(false), setCanceledOnTouchOutside(false)）
    if (!self.isForceUpdate) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [self.backgroundView addGestureRecognizer:tap];
    }
    
    // 内容容器（对齐安卓：335dp × 445dp，marginHorizontal 30dp，marginBottom 5dp）
    self.containerView = [[UIView alloc] init];
    [self addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(335); // 对齐安卓：335dp
        make.height.mas_equalTo(445); // 对齐安卓：445dp
    }];
    
    // 背景图片（对齐安卓：bg_version_topup，335dp × 445dp，scaleType fitXY）
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.image = [UIImage imageNamed:@"bg_version_topup"];
    self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    self.backgroundImageView.clipsToBounds = YES;
    [self.containerView addSubview:self.backgroundImageView];
    
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    
    // 内容区域（对齐安卓：paddingHorizontal 20dp，paddingTop 107dp，paddingBottom 20dp）
    UIView *contentView = [[UIView alloc] init];
    [self.containerView addSubview:contentView];
    
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView).insets(UIEdgeInsetsMake(107, 20, 20, 20)); // 对齐安卓：padding
    }];
    
    // 标题（对齐安卓：23sp bold，黑色#333333，marginTop 25dp，居中）
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"发现新版本");
    self.titleLabel.textColor = HEX_COLOR(0x333333); // 对齐安卓：@color/black3
    self.titleLabel.font = BOLD_FONT(23); // 对齐安卓：23sp bold
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView).offset(25); // 对齐安卓：marginTop 25dp
        make.left.right.equalTo(contentView);
    }];
    
    // 稍后提醒按钮（对齐安卓：48dp高度，透明背景，1dp绿色边框#0AEA6F，圆角50dp）
    self.laterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.laterButton setTitle:LocalString(@"以后再说") forState:UIControlStateNormal];
    [self.laterButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal]; // 对齐安卓：@color/black3
    self.laterButton.titleLabel.font = FONT(16); // 对齐安卓：16sp
    self.laterButton.backgroundColor = [UIColor clearColor]; // 对齐安卓：#00FFFFFF
    self.laterButton.layer.cornerRadius = 50.0; // 对齐安卓：50dp
    self.laterButton.layer.borderWidth = 1.0; // 对齐安卓：1dp
    self.laterButton.layer.borderColor = HEX_COLOR(0x0AEA6F).CGColor; // 对齐安卓：#0AEA6F
    [self.laterButton addTarget:self action:@selector(laterButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:self.laterButton];
    
    [self.laterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(contentView);
        make.height.mas_equalTo(48); // 对齐安卓：48dp
        make.bottom.equalTo(contentView);
    }];
    
    // 更新按钮（对齐安卓：48dp高度，渐变背景#0AEA6F到#1CB3C1，圆角50dp，marginBottom 15dp）
    self.updateButton = [GradientButton buttonWithTitle:LocalString(@"立即更新")
                                               startColor:HEX_COLOR(0x0AEA6F) // 对齐安卓：#0AEA6F
                                                 endColor:HEX_COLOR(0x1CB3C1)]; // 对齐安卓：#1CB3C1
    self.updateButton.cornerRadius = 50.0; // 对齐安卓：50dp
    self.updateButton.buttonHeight = 48.0; // 对齐安卓：48dp
    [self.updateButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal]; // 对齐安卓：@color/black3
    self.updateButton.titleLabel.font = FONT(16); // 对齐安卓：16sp
    [self.updateButton addTarget:self action:@selector(updateButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:self.updateButton];
    
    [self.updateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(contentView);
        make.height.mas_equalTo(48); // 对齐安卓：48dp
        make.bottom.equalTo(self.laterButton.mas_top).offset(-15); // 对齐安卓：marginBottom 15dp
    }];
    
    // 更新内容（对齐安卓：15sp，黑色#333333，marginHorizontal 30dp，marginTop 30dp，marginBottom 15dp，weight=1）
    self.contentTextView = [[UITextView alloc] init];
    self.contentTextView.backgroundColor = [UIColor clearColor];
    self.contentTextView.textColor = HEX_COLOR(0x333333); // 对齐安卓：@color/black3
    self.contentTextView.font = FONT(15); // 对齐安卓：15sp
    self.contentTextView.editable = NO;
    self.contentTextView.scrollEnabled = YES;
    self.contentTextView.textContainerInset = UIEdgeInsetsZero;
    self.contentTextView.textContainer.lineFragmentPadding = 0;
    [contentView addSubview:self.contentTextView];
    
    [self.contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(30); // 对齐安卓：marginTop 30dp
        make.left.equalTo(contentView).offset(30); // 对齐安卓：marginHorizontal 30dp
        make.right.equalTo(contentView).offset(-30);
        make.bottom.equalTo(self.updateButton.mas_top).offset(-15); // 对齐安卓：marginBottom 15dp，weight=1
    }];
    
    // 外部关闭按钮（对齐安卓：icon_home_pop_up_close_default，marginBottom -35dp，底部居中，仅在非强制更新时显示）
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setImage:[UIImage imageNamed:@"icon_home_pop_up_close_default"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.containerView.mas_bottom).offset(-35); // 对齐安卓：marginBottom -35dp
        make.centerX.equalTo(self.containerView);
    }];
    
    // 根据是否强制更新设置关闭按钮的显示（对齐安卓）
    self.closeButton.hidden = self.isForceUpdate;
    
    // 设置内容
    [self updateContent];
}

- (void)updateContent {
    if (!self.appInfo) {
        return;
    }
    
    // 设置更新内容（对齐安卓）
    NSString *releaseNotes = LocalString(@"更新说明：");
    NSString *updateMsg = self.appInfo.updateMsg ?: @"";
    if (updateMsg.length > 0) {
        self.contentTextView.text = [NSString stringWithFormat:@"%@\n%@", releaseNotes, updateMsg];
    } else {
        self.contentTextView.text = releaseNotes;
    }
}

#pragma mark - Actions

- (void)updateButtonTapped {
    // 跳转到App Store（对齐安卓：openGooglePlayStore）
    [self openAppStore];
}

- (void)laterButtonTapped {
    // 稍后提醒按钮（对齐安卓）
    if (self.isForceUpdate) {
        // 强制更新：退出APP（对齐安卓：finish(), System.exit(0)）
        exit(0);
    } else {
        // 非强制更新：关闭弹窗（对齐安卓：dismiss()）
        [self dismiss];
    }
}

- (void)dismiss {
    [self removeFromSuperview];
    if (self.onDismissListener) {
        self.onDismissListener();
    }
}

#pragma mark - App Store

- (void)openAppStore {
    // 打开App Store（对齐安卓：openGooglePlayStore）
    // 优先使用appUrl（如果提供）
    NSString *appUrl = self.appInfo.appUrl;
    if (appUrl && appUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:appUrl];
        if (url) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:url];
            }
            return;
        }
    }
    
    // 如果没有appUrl，使用bundle identifier构建App Store链接
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    // iOS App Store URL格式：itms-apps://apps.apple.com/app/id{APP_ID}
    // 但通常我们需要App Store ID，而不是bundle identifier
    // 这里先使用bundle identifier，实际使用时应该从服务器获取App Store ID
    NSString *itmsURL = [NSString stringWithFormat:@"itms-apps://apps.apple.com/app/id%@", bundleId];
    NSURL *url = [NSURL URLWithString:itmsURL];
    
    if (url) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                if (!success) {
                    // 如果itms协议失败，使用网页版（对齐安卓：openGooglePlayWeb）
                    NSString *webURL = [NSString stringWithFormat:@"https://apps.apple.com/app/id%@", bundleId];
                    NSURL *webUrl = [NSURL URLWithString:webURL];
                    if (webUrl) {
                        [[UIApplication sharedApplication] openURL:webUrl options:@{} completionHandler:nil];
                    }
                }
            }];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end

