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
    
    // 标记为正在处理
    [self.processingTransactions addObject:transactionId];
    
    BUNNYX_LOG(@"PaymentExceptionHandler: Detected unfinished transaction: %@, productId: %@", transactionId, productId);
    
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
    
    // 检查StoreKit的未完成交易队列
    // 注意：iOS的StoreKit会自动回调未完成的交易，这里主要是作为兜底逻辑
    // 如果StoreKit已经回调了，会在didPurchaseSuccessWithTransaction中处理
    // 如果没有回调，我们需要等待StoreKit的回调，因为iOS需要transaction对象才能获取收据
    
    BUNNYX_LOG(@"PaymentExceptionHandler: 检测到有缓存的订单，等待StoreKit回调未完成的交易");
    // iOS的StoreKit会自动处理未完成的交易，我们已经在initialize中设置了delegate
    // 所以这里只需要记录日志即可，实际的恢复会在didPurchaseSuccessWithTransaction中完成
}

@end

