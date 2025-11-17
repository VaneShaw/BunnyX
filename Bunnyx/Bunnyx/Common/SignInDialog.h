//
//  SignInDialog.h
//  Bunnyx
//
//  签到弹窗（对齐安卓SignInDialog）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SignInDialog;

/// 签到数据模型（对齐安卓GetUserSignListApi.Data）
@interface SignInData : NSObject

/// 连续签到天数
@property (nonatomic, assign) NSInteger consecutiveDay;

/// 当天是否已签到
@property (nonatomic, assign) BOOL signIn;

/// 未来7天签到奖励列表（对齐安卓ResultItem）
@property (nonatomic, strong) NSArray<NSDictionary *> *result;

/// 连续签到奖励列表（对齐安卓SignReward）
@property (nonatomic, strong) NSArray<NSDictionary *> *signRewards;

@end

/// 签到弹窗
@interface SignInDialog : UIView

/// 显示签到弹窗（对齐安卓：show）
/// @param context 上下文（可选，用于网络请求）
+ (void)show;

/// 显示签到弹窗，并设置数据（对齐安卓：show with data）
/// @param data 签到数据
+ (void)showWithData:(SignInData * _Nullable)data;

/// 关闭弹窗
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

