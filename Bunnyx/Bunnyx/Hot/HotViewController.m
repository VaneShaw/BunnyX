//
//  HotViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "HotViewController.h"
#import <Masonry/Masonry.h>

@interface HotViewController ()

@end

@implementation HotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"热门";
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
    // 创建热门标签
    UILabel *hotLabel = [[UILabel alloc] init];
    hotLabel.text = @"🔥 热门内容";
    hotLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    hotLabel.textColor = [UIColor systemOrangeColor];
    hotLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:hotLabel];
    
    // 使用Masonry设置约束
    [hotLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

@end
