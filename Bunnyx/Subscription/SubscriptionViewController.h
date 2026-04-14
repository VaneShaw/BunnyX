//
//  SubscriptionViewController.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SubscriptionViewController : BaseViewController

/// 重置订阅弹窗会话标记（在App启动时调用）
+ (void)resetSessionDialogFlag;

@end

NS_ASSUME_NONNULL_END
