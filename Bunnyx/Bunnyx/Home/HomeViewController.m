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
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
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
    welcomeLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    welcomeLabel.textColor = [UIColor labelColor];
    welcomeLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:welcomeLabel];
    
    // 使用Masonry设置约束
    [welcomeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

@end
