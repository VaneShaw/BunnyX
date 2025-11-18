//
//  BrowserViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "BrowserViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>

@interface BrowserViewController ()

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString *urlString;

@end

@implementation BrowserViewController

- (instancetype)initWithURL:(NSString *)url {
    self = [super init];
    if (self) {
        self.urlString = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    // 使用BaseViewController的自定义返回按钮，确保图标是icon_login_account_back
    // BaseViewController已经在setupCustomBackButton中设置了icon_login_account_back图标
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    [self.view addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    if (self.urlString && self.urlString.length > 0) {
        NSURL *url = [NSURL URLWithString:self.urlString];
        if (url) {
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [self.webView loadRequest:request];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // BrowserViewController需要显示导航栏（因为是通过UINavigationController呈现的）
    // 但BaseViewController默认隐藏导航栏，所以需要覆盖这个方法
    if (self.navigationController) {
        UINavigationBar *navigationBar = self.navigationController.navigationBar;
        
        // 显示导航栏
        [self.navigationController setNavigationBarHidden:NO animated:animated];
        
        // 设置导航栏为黑色，不透明
        navigationBar.translucent = NO;
        navigationBar.barTintColor = [UIColor blackColor];
        navigationBar.backgroundColor = [UIColor blackColor];
        
        // 设置导航栏标题颜色为白色
        navigationBar.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor]
        };
        
        // iOS 13+ 使用新的导航栏外观API
        if (@available(iOS 13.0, *)) {
            UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
            [appearance configureWithOpaqueBackground];
            appearance.backgroundColor = [UIColor blackColor];
            appearance.shadowColor = [UIColor clearColor];
            // 设置标题颜色为白色
            appearance.titleTextAttributes = @{
                NSForegroundColorAttributeName: [UIColor whiteColor]
            };
            navigationBar.standardAppearance = appearance;
            navigationBar.scrollEdgeAppearance = appearance;
        }
        
        // 设置导航栏返回按钮图标（对齐安卓：使用icon_login_account_back，图片显示尺寸23*23）
        // 使用44x44的容器（iOS标准触摸区域），但图片显示为23x23
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        buttonContainer.backgroundColor = [UIColor clearColor];
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backImage = [UIImage imageNamed:@"icon_login_account_back"];
        [backButton setImage:backImage forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:backButton];
        
        // 按钮填满容器，图片居中显示
        [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(buttonContainer);
        }];
        
        // 设置按钮的图片内容模式，确保图片按23x23尺寸显示
        backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        backButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        
        // 使用imageEdgeInsets来调整图片位置，使图片显示为23x23
        CGFloat imageSize = 23.0;
        CGFloat containerSize = 44.0;
        CGFloat inset = (containerSize - imageSize) / 2.0;
        backButton.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
        
        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonContainer];
        self.navigationItem.leftBarButtonItem = backBarButtonItem;
        
        // 隐藏BaseViewController的自定义返回按钮（因为使用导航栏的返回按钮）
        self.showBackButton = NO;
    }
}

- (void)backButtonTapped:(UIButton *)sender {
    // 对齐安卓：返回按钮点击事件
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

