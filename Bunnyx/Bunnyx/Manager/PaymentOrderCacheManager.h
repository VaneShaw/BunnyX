//
//  PaymentOrderCacheManager.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 支付订单缓存管理器
/// 用于缓存支付成功但未完成验证的订单信息，防止应用闪退导致订单卡住
@interface PaymentOrderCacheManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 保存待验证的支付订单（通过productId，用于购买时保存，此时还没有transactionId）
/// @param productId 商品ID
/// @param orderSn 服务器订单号
- (void)savePendingOrderWithProductId:(NSString *)productId orderSn:(NSString *)orderSn;

/// 保存待验证的支付订单
/// @param transactionId 交易ID（transactionIdentifier）
/// @param orderSn 服务器订单号
- (void)savePendingOrderWithTransactionId:(NSString *)transactionId orderSn:(NSString *)orderSn;

/// 获取待验证订单的服务器订单号（通过productId）
/// @param productId 商品ID
/// @return 服务器订单号，如果不存在则返回nil
- (NSString * _Nullable)getOrderSnForProductId:(NSString *)productId;

/// 获取待验证订单的服务器订单号
/// @param transactionId 交易ID
/// @return 服务器订单号，如果不存在则返回nil
- (NSString * _Nullable)getOrderSnForTransactionId:(NSString *)transactionId;

/// 清除待验证的支付订单
/// @param transactionId 交易ID
- (void)clearPendingOrderForTransactionId:(NSString *)transactionId;

/// 清除待验证的支付订单（通过productId）
/// @param productId 商品ID
- (void)clearPendingOrderForProductId:(NSString *)productId;

/// 检查是否有待验证的订单
- (BOOL)hasPendingOrder;

@end

NS_ASSUME_NONNULL_END

