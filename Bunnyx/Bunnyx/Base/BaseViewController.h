//
//  BaseViewController.h
//  Bunnyx
//
//  Created by fengwenxiao on 2024/11/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseViewController : UIViewController

/// 自定义返回按钮
@property (nonatomic, strong) UIButton *customBackButton;

/// 是否显示返回按钮，默认为YES
@property (nonatomic, assign) BOOL showBackButton;

/// 返回按钮点击事件，子类可以重写此方法来自定义返回逻辑
- (void)customBackButtonTapped:(UIButton *)sender;

/// 默认的返回操作，子类可以重写此方法
- (void)performBackAction;

@end

NS_ASSUME_NONNULL_END
