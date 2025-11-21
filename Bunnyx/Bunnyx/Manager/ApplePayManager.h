//
//  ApplePayManager.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApplePayManager;

/// 购买结果回调
@protocol ApplePayManagerDelegate <NSObject>

@optional
/// 购买成功
- (void)applePayManager:(ApplePayManager *)manager didPurchaseSuccessWithTransaction:(SKPaymentTransaction *)transaction productId:(NSString *)productId;

/// 购买失败
- (void)applePayManager:(ApplePayManager *)manager didPurchaseFailWithError:(NSError *)error;

/// 购买恢复成功
- (void)applePayManager:(ApplePayManager *)manager didRestoreSuccessWithTransactions:(NSArray<SKPaymentTransaction *> *)transactions;

/// 购买恢复失败
- (void)applePayManager:(ApplePayManager *)manager didRestoreFailWithError:(NSError *)error;

@end

/// Apple内购管理器
@interface ApplePayManager : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>

/// 单例
+ (instancetype)sharedManager;

/// 代理（已废弃，使用addDelegate:和removeDelegate:）
@property (nonatomic, weak) id<ApplePayManagerDelegate> delegate DEPRECATED_MSG_ATTRIBUTE("Use addDelegate: and removeDelegate: instead");

/// 添加代理（支持多个代理）
- (void)addDelegate:(id<ApplePayManagerDelegate>)delegate;

/// 移除代理
- (void)removeDelegate:(id<ApplePayManagerDelegate>)delegate;

/// 是否已初始化
@property (nonatomic, assign, readonly) BOOL isInitialized;

/// 初始化内购
- (void)initializeWithDelegate:(id<ApplePayManagerDelegate>)delegate;

/// 查询商品信息
/// @param productIds 商品ID数组
/// @param completion 完成回调，返回商品信息数组
- (void)requestProductsWithIds:(NSArray<NSString *> *)productIds
                     completion:(void(^)(NSArray<SKProduct *> * _Nullable products, NSError * _Nullable error))completion;

/// 购买商品
/// @param productId 商品ID
/// @param orderId 订单ID（可选，用于服务器验证）
/// @param timestamp 时间戳（可选，用于服务器验证）
- (void)purchaseProductWithId:(NSString *)productId
                        orderId:(NSString * _Nullable)orderId
                      timestamp:(NSString * _Nullable)timestamp;

/// 恢复购买
- (void)restorePurchases;

/// 验证收据
/// @param receiptData 收据数据
/// @param completion 完成回调
- (void)verifyReceipt:(NSData *)receiptData
            completion:(void(^)(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// 验证收据（带订单号）
/// @param receiptData 收据数据
/// @param orderSn 订单号（可选，如果为nil则传空字符串）
/// @param completion 完成回调
- (void)verifyReceipt:(NSData *)receiptData
               orderSn:(NSString * _Nullable)orderSn
            completion:(void(^)(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// 完成交易（消耗型商品需要调用此方法）
/// @param transaction 交易对象
- (void)finishTransaction:(SKPaymentTransaction *)transaction;

/// 销毁管理器
- (void)destroy;

@end

NS_ASSUME_NONNULL_END



