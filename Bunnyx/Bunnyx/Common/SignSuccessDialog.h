//
//  SignSuccessDialog.h
//  Bunnyx
//
//  签到成功弹窗（对齐安卓SignSuccessDialog）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 签到成功弹窗
@interface SignSuccessDialog : UIView

/// 显示签到成功弹窗（对齐安卓：show）
/// @param reward 奖励金币数量
+ (void)showWithReward:(NSInteger)reward;

/// 关闭弹窗
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

