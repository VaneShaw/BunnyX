//
//  InsufficientBalanceDialog.h
//  Bunnyx
//
//  余额不足弹窗
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 余额不足弹窗
@interface InsufficientBalanceDialog : UIView

/// 显示余额不足弹窗
/// @param title 标题
/// @param canShowAd 是否有广告配置（决定是否显示看广告按钮和背景图）
/// @param leftCount 剩余看广告次数（如果canShowAd为NO则此参数无效）
/// @param cancelBlock 取消按钮回调
/// @param confirmBlock 确认按钮回调
/// @param watchAdBlock 看广告按钮回调（如果canShowAd为NO则此参数无效）
+ (void)showWithTitle:(NSString *)title
            canShowAd:(BOOL)canShowAd
            leftCount:(NSInteger)leftCount
           cancelBlock:(void(^_Nullable)(void))cancelBlock
          confirmBlock:(void(^_Nullable)(void))confirmBlock
          watchAdBlock:(void(^_Nullable)(void))watchAdBlock;

/// 关闭弹窗
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

