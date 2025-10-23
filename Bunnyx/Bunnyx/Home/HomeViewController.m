//
//  HomeViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "HomeViewController.h"
#import <Masonry/Masonry.h>

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"首页";
    // 使用宏定义设置背景色
    self.view.backgroundColor = BUNNYX_BACKGROUND_COLOR;
    
    // 使用宏定义记录日志
    BUNNYX_LOG(@"HomeViewController viewDidLoad");
    
    // 设置导航栏样式
    [self setupNavigationBar];
    
    // 添加内容视图
    [self setupContentView];
}

- (void)setupNavigationBar {
    // 设置导航栏标题颜色
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor labelColor]
    };
    
    // 设置导航栏背景色
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor systemBackgroundColor];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor labelColor]};
        
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}

- (void)setupContentView {
    // 创建欢迎标签
    UILabel *welcomeLabel = [[UILabel alloc] init];
    welcomeLabel.text = @"欢迎来到首页";
    // 使用宏定义设置字体
    welcomeLabel.font = BOLD_FONT(FONT_SIZE_24);
    // 使用宏定义设置文字颜色
    welcomeLabel.textColor = BUNNYX_TEXT_COLOR;
    welcomeLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:welcomeLabel];
    
    // 使用Masonry设置约束
    [welcomeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    // 演示其他宏定义的使用
    BUNNYX_LOG(@"屏幕宽度: %.0f, 屏幕高度: %.0f", SCREEN_WIDTH, SCREEN_HEIGHT);
    BUNNYX_LOG(@"是否为iPhone X系列: %@", IS_IPHONE_X ? @"是" : @"否");
    BUNNYX_LOG(@"应用版本: %@", BUNNYX_APP_VERSION);
}

@end
