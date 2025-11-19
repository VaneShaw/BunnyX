//
//  PaymentExceptionHandler.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <Foundation/Foundation.h>
#import "ApplePayManager.h"

NS_ASSUME_NONNULL_BEGIN

/// 支付异常处理器
/// 用于处理app启动时检测到的未完成交易（如用户付款后杀掉进程的情况）
@interface PaymentExceptionHandler : NSObject <ApplePayManagerDelegate>

/// 单例
+ (instancetype)sharedHandler;

/// 初始化支付异常处理（在app启动时调用）
- (void)initialize;

/// 检查并恢复未完成的订单（在用户登录后调用，与安卓版本保持一致）
- (void)checkAndRecoverPendingOrder;

@end

NS_ASSUME_NONNULL_END

