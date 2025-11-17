//
//  SignDayCell.h
//  Bunnyx
//
//  签到天列表Cell（对齐安卓item_sign_day.xml）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignDayCell : UICollectionViewCell

/// 配置Cell（对齐安卓）
/// @param coinText 金币文本（如：+2）
/// @param dateText 日期文本（如：24/10）
- (void)configureWithCoinText:(NSString *)coinText dateText:(NSString *)dateText;

@end

NS_ASSUME_NONNULL_END

