//
//  HotViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "HotViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"

@interface HotViewController ()
@property (nonatomic, strong) UILabel *label;

@end

@implementation HotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = BUNNYX_BACKGROUND_COLOR;
    UILabel *label = [[UILabel alloc] init];
    label.text = LocalString(@"热门内容稍后呈现");
    label.textColor = BUNNYX_LIGHT_TEXT_COLOR;
    label.font = FONT(14);
    label.textAlignment = NSTextAlignmentCenter;
    self.label = label;
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
}

@end
