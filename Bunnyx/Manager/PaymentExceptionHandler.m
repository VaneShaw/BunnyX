//
//  PaymentExceptionHandler.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "PaymentExceptionHandler.h"
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "UserInfoManager.h"
#import "PaymentOrderCacheManager.h"
#import <StoreKit/StoreKit.h>

@interface PaymentExceptionHandler ()

@property (nonatomic, strong) NSMutableSet<NSString *> *processingTransactions;

@end

@implementation PaymentExceptionHandler

+ (instancetype)sharedHandler {
    static PaymentExceptionHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PaymentExceptionHandler alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _processingTransactions = [NSMutableSet set];
    }
    return self;
}

- (void)initialize {
    // 初始化ApplePayManager并添加自己为delegate
    ApplePayManager *applePayManager = [ApplePayManager sharedManager];
    if (!applePayManager.isInitialized) {
        [applePayManager initializeWithDelegate:self];
        BUNNYX_LOG(@"PaymentExceptionHandler: ApplePayManager initialized for exception handling");
    } else {
        // 如果已经初始化，添加自己为delegate（支持多个delegate）
        [applePayManager addDelegate:self];
        BUNNYX_LOG(@"PaymentExceptionHandler: Added as delegate to existing ApplePayManager");
    }
}

#pragma mark - ApplePayManagerDelegate

- (void)applePayManager:(ApplePayManager *)manager didPurchaseSuccessWithTransaction:(SKPaymentTransaction *)transaction productId:(NSString *)productId {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    
    // 检查是否正在处理此交易
    if ([self.processingTransactions containsObject:transactionId]) {
        BUNNYX_LOG(@"PaymentExceptionHandler: Transaction %@ is already being processed", transactionId);
        return;
    }
    
    // 检查 ApplePayManager 是否正在处理此交易（避免重复调用接口）
    // 如果 ApplePayManager 正在处理，说明它会调用验证接口，PaymentExceptionHandler 不需要再处理
    // 注意：这里检查的是"正在处理"，如果 ApplePayManager 已经处理完成（成功或失败），
    // processingTransactionIds 会被移除，此时 PaymentExceptionHandler 可以作为兜底处理
    if (transactionId.length > 0 && [manager isProcessingTransaction:transactionId]) {
        BUNNYX_LOG(@"PaymentExceptionHandler: Transaction %@ is being processed by ApplePayManager, skip exception handling to avoid duplicate API call", transactionId);
        // 即使跳过了异常恢复处理，也要确保订单完成（调用 finishTransaction）
        // 因为重启时业务层delegate可能还没添加，需要确保订单流程闭环
        [manager finishTransaction:transaction];
        // 清除缓存的订单信息
        [[PaymentOrderCacheManager sharedManager] clearPendingOrderForTransactionId:transactionId];
        return;
    }
    
    // 检查缓存中是否有订单号（只有缓存中有订单号时才需要异常恢复处理）
    NSString *orderSn = [[PaymentOrderCacheManager sharedManager] getOrderSnForTransactionId:transactionId];
    if (!orderSn || orderSn.length == 0) {
        BUNNYX_LOG(@"PaymentExceptionHandler: Transaction %@ has no cached orderSn, skip exception handling", transactionId);
        return;
    }
    
    // 标记为正在处理
    [self.processingTransactions addObject:transactionId];
    
    BUNNYX_LOG(@"PaymentExceptionHandler: Detected unfinished transaction: %@, productId: %@, orderSn: %@", transactionId, productId, orderSn);
    
    // 处理未完成的交易
    [self handleUnfinishedTransaction:transaction];
}

- (void)applePayManager:(ApplePayManager *)manager didPurchaseFailWithError:(NSError *)error {
    BUNNYX_ERROR(@"PaymentExceptionHandler: Purchase failed: %@", error);
    // 支付失败不需要特殊处理，错误已经记录
}

#pragma mark - Private Methods

- (void)handleUnfinishedTransaction:(SKPaymentTransaction *)transaction {
    if (!transaction) {
        return;
    }
    
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    
    // 获取收据
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    
    if (!receiptData) {
        BUNNYX_ERROR(@"PaymentExceptionHandler: No receipt data for transaction %@", transactionId);
        [self.processingTransactions removeObject:transactionId];
        return;
    }
    
    // Base64编码收据（Apple收据是二进制数据，必须使用Base64编码）
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:0];
    
    // 先尝试通过transactionIdentifier查询服务器订单信息
    // 如果服务器支持，可以通过token查询订单；如果不支持，直接使用收据验证
    [self verifyPaymentWithTransaction:transaction receiptString:receiptString];
}

- (void)verifyPaymentWithTransaction:(SKPaymentTransaction *)transaction receiptString:(NSString *)receiptString {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    
    // 尝试从缓存中获取orderSn
    NSString *orderSn = [[PaymentOrderCacheManager sharedManager] getOrderSnForTransactionId:transactionId];
    
    if (!orderSn || orderSn.length == 0) {
        BUNNYX_ERROR(@"PaymentExceptionHandler: 无法获取订单号，transactionId: %@", transactionId);
        [self.processingTransactions removeObject:transactionId];
        return;
    }
    
    // 构建验证参数（根据接口文档）
    NSDictionary *params = @{
        @"appleReceipt": receiptString, // 苹果支付凭据
        @"orderSn": orderSn // 订单号
    };
    
    BUNNYX_LOG(@"PaymentExceptionHandler: Verifying payment for transaction %@", transactionId);
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_PAY_APPLE_VERIFY
                              parameters:params
                                 success:^(id responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 验证通过，完成交易
            BUNNYX_LOG(@"PaymentExceptionHandler: Payment verified successfully for transaction %@", transactionId);
            [[ApplePayManager sharedManager] finishTransaction:transaction];
            
            // 清除缓存的订单信息
            [[PaymentOrderCacheManager sharedManager] clearPendingOrderForTransactionId:transactionId];
            
            // 刷新用户信息
            [[UserInfoManager sharedManager] refreshCurrentUserInfoWithSuccess:^(UserInfoModel *userInfo) {
                BUNNYX_LOG(@"PaymentExceptionHandler: User info refreshed after payment verification");
            } failure:^(NSError *error) {
                BUNNYX_ERROR(@"PaymentExceptionHandler: Failed to refresh user info: %@", error);
            }];
        } else {
            NSString *message = responseObject[@"message"] ?: LocalString(@"支付验证失败");
            BUNNYX_ERROR(@"PaymentExceptionHandler: Payment verification failed for transaction %@: %@", transactionId, message);
        }
        
        // 移除处理标记
        [self.processingTransactions removeObject:transactionId];
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"PaymentExceptionHandler: Payment verification request failed for transaction %@: %@", transactionId, error);
        
        // 移除处理标记
        [self.processingTransactions removeObject:transactionId];
    }];
}

#pragma mark - Check Pending Orders

- (void)checkAndRecoverPendingOrder {
    // 检查是否有待恢复的订单（与安卓版本保持一致）
    if (![[PaymentOrderCacheManager sharedManager] hasPendingOrder]) {
        BUNNYX_LOG(@"PaymentExceptionHandler: 没有待恢复的订单");
        return;
    }
    
    BUNNYX_LOG(@"PaymentExceptionHandler: 检测到有缓存的订单，开始主动检测未完成的交易");
    
    // 确保 ApplePayManager 已经初始化并添加为 observer
    ApplePayManager *applePayManager = [ApplePayManager sharedManager];
    if (!applePayManager.isInitialized) {
        BUNNYX_LOG(@"PaymentExceptionHandler: ApplePayManager 未初始化，先初始化");
        [applePayManager initializeWithDelegate:self];
        // 初始化时会添加 observer，StoreKit 会自动回调未完成的交易
    } else {
        // 确保 PaymentExceptionHandler 是 delegate
        [applePayManager addDelegate:self];
        
        // 如果 ApplePayManager 已经初始化，StoreKit 可能已经回调过了
        // 但是，如果交易还没有被 finish，StoreKit 会在某些情况下再次回调
        // 为了确保能够检测到未完成的交易，我们尝试通过 restoreCompletedTransactions 触发检测
        // 注意：restoreCompletedTransactions 主要用于恢复已完成的购买，但可能会触发 StoreKit 重新检查未完成的交易
        BUNNYX_LOG(@"PaymentExceptionHandler: ApplePayManager 已初始化，尝试通过 restoreCompletedTransactions 触发 StoreKit 重新检查未完成的交易");
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
    
    // 注意：实际的恢复处理会在 didPurchaseSuccessWithTransaction 中完成
    // StoreKit 会在适当时机自动回调未完成的交易给 ApplePayManager
    // ApplePayManager 会通过 delegate 通知 PaymentExceptionHandler
}

@end

