//
//  SignRewardCell.h
//  Bunnyx
//
//  签到奖励列表Cell（item_sign_reward.xml）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignRewardCell : UICollectionViewCell

/// 配置Cell
/// @param coinText 金币文本（如：+10）
/// @param daysText 天数文本（如：7 Days）
- (void)configureWithCoinText:(NSString *)coinText daysText:(NSString *)daysText;

@end

NS_ASSUME_NONNULL_END

