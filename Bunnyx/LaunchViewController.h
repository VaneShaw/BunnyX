//
//  LaunchViewController.h
//  Bunnyx
//
//  Created by fengwenxiao on 2024/11/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 开屏页完成后的回调
typedef void(^LaunchViewControllerCompletionBlock)(void);

@interface LaunchViewController : UIViewController

- (void)setBackgroundImage:(UIImage *)backgroundImage;
- (void)setLogoImage:(UIImage *)logoImage;

// 设置完成后的回调（广告播放完成或超时后调用）
- (void)setCompletionBlock:(LaunchViewControllerCompletionBlock)completionBlock;

// 开始加载和展示开屏广告
- (void)startSplashAdFlow;

@end

NS_ASSUME_NONNULL_END
