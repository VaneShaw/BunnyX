//
//  SignSuccessDialog.h
//  Bunnyx
//
//  签到成功弹窗（SignSuccessDialog）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 签到成功弹窗
@interface SignSuccessDialog : UIView

/// 显示签到成功弹窗（show）
/// @param reward 奖励金币数量
+ (void)showWithReward:(NSInteger)reward;

/// 显示获得金币弹窗（支持自定义标题）
/// @param reward 奖励金币数量
/// @param title 弹窗标题（如果为nil，使用默认标题）
+ (void)showWithReward:(NSInteger)reward title:(NSString * _Nullable)title;

/// 关闭弹窗
- (void)dismiss;

/// 关闭所有显示的签到成功弹窗（类方法）
+ (void)dismissAll;

/// 隐藏所有显示的签到成功弹窗（但不销毁，用于开屏广告显示时）
+ (void)hideAll;

/// 重新显示所有隐藏的签到成功弹窗（用于开屏广告关闭后）
+ (void)showAllHidden;

@end

NS_ASSUME_NONNULL_END

