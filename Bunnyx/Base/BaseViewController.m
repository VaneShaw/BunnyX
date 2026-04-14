//
//  BaseViewController.m
//  Bunnyx
//
//  Created by fengwenxiao on 2024/11/30.
//

#import "BaseViewController.h"
#import <Masonry/Masonry.h>

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置全屏显示
    [self setupFullScreenDisplay];
    // 设置背景
    [self setupBackground];
    // 设置自定义返回按钮
    [self setupCustomBackButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 隐藏导航栏
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 如果下一个页面需要导航栏，可以在这里恢复
    // [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 确保返回按钮在最上层
    [self bringBackButtonToFront];
}

- (void)setupBackground {
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.3 blue:0.2 alpha:1.0];
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.image = [UIImage imageNamed:@"bg_login_account"];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - Setup Methods

- (void)setupFullScreenDisplay {
    // 设置视图背景色
    self.view.backgroundColor = [UIColor blackColor];
    
    // 确保视图控制器占满整个屏幕
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // 设置状态栏样式
    if (@available(iOS 13.0, *)) {
        // iOS 13+ 使用新的状态栏管理方式
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    } else {
        // iOS 13 以下使用旧的方式
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    }
}

- (void)setupCustomBackButton {
    // 默认显示返回按钮
    self.showBackButton = YES;
    
    // 创建自定义返回按钮
    self.customBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self.customBackButton setImage:[UIImage imageNamed:@"icon_login_account_back"] forState:UIControlStateNormal];

    // 添加点击事件
    [self.customBackButton addTarget:self action:@selector(customBackButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // 添加到视图
    [self.view addSubview:self.customBackButton];
    
    // 设置约束
    [self.customBackButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.width.height.mas_equalTo(23);
    }];
    
    // 根据showBackButton属性控制显示/隐藏
    self.customBackButton.hidden = !self.showBackButton;
}

#pragma mark - Helper Methods

- (UIImage *)createDefaultBackImage {
    // 创建一个默认的返回箭头图标
    CGSize size = CGSizeMake(20, 20);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    // 绘制返回箭头
    CGContextMoveToPoint(context, 12, 6);
    CGContextAddLineToPoint(context, 6, 10);
    CGContextAddLineToPoint(context, 12, 14);
    
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Public Methods

- (void)setShowBackButton:(BOOL)showBackButton {
    _showBackButton = showBackButton;
    self.customBackButton.hidden = !showBackButton;
}

- (void)bringBackButtonToFront {
    if (self.customBackButton && self.customBackButton.superview) {
        [self.view bringSubviewToFront:self.customBackButton];
    }
}

#pragma mark - Button Actions

- (void)customBackButtonTapped:(UIButton *)sender {
    NSLog(@"自定义返回按钮被点击");
    [self performBackAction];
}

- (void)performBackAction {
    // 默认的返回逻辑
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        // 如果有导航控制器且不是根视图控制器，则pop
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        // 如果是模态呈现的，则dismiss
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        // 其他情况，尝试从window中移除
        UIWindow *window = [UIApplication sharedApplication].delegate.window;
        if (window && window.rootViewController == self) {
            // 如果是根视图控制器，可能需要特殊处理
            NSLog(@"警告：尝试从根视图控制器返回");
        }
    }
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // 当收到内存警告时，清理SDWebImage的内存缓存，防止闪退
    // 这是处理大量WebP图片导致内存过载的关键措施
    [[SDImageCache sharedImageCache] clearMemory];
    
    // 清理预加载器
    [[SDWebImagePrefetcher sharedImagePrefetcher] cancelPrefetching];
}

@end
