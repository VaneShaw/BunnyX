//
//  SubscriptionViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "SubscriptionViewController.h"
#import <Masonry/Masonry.h>

@interface SubscriptionViewController ()

@end

@implementation SubscriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // 添加内容视图
    [self setupContentView];
}


- (void)setupContentView {
    // 创建订阅标签
    UILabel *subscriptionLabel = [[UILabel alloc] init];
    subscriptionLabel.text = @"📋 我的订阅";
    subscriptionLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    subscriptionLabel.textColor = [UIColor systemBlueColor];
    subscriptionLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:subscriptionLabel];
    
    // 使用Masonry设置约束，全屏展示
    [subscriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
}

@end
