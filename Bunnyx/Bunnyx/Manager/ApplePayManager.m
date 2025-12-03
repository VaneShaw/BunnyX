//
//  ApplePayManager.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "ApplePayManager.h"
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "PaymentOrderCacheManager.h"

@interface ApplePayManager ()

@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, strong) NSMutableDictionary<NSString *, void(^)(NSArray<SKProduct *> * _Nullable, NSError * _Nullable)> *productRequestCallbacks;
@property (nonatomic, strong) NSMutableSet<NSString *> *pendingProductIds;
@property (nonatomic, strong) NSMapTable<SKProductsRequest *, NSSet<NSString *> *> *requestToProductIds;
@property (nonatomic, strong) NSHashTable<id<ApplePayManagerDelegate>> *delegates;
// 临时存储 productId -> orderId 的映射，用于在 applicationUsername 丢失时恢复订单号
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *productIdToOrderIdMap;
// 正在处理的交易ID集合，用于去重（防止同一交易被重复处理）
@property (nonatomic, strong) NSMutableSet<NSString *> *processingTransactionIds;

@end

@implementation ApplePayManager

+ (instancetype)sharedManager {
    static ApplePayManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ApplePayManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isInitialized = NO;
        _productRequestCallbacks = [NSMutableDictionary dictionary];
        _pendingProductIds = [NSMutableSet set];
        _requestToProductIds = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
        _delegates = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _productIdToOrderIdMap = [NSMutableDictionary dictionary];
        _processingTransactionIds = [NSMutableSet set];
    }
    return self;
}

- (void)initializeWithDelegate:(id<ApplePayManagerDelegate>)delegate {
    if (self.isInitialized) {
        BUNNYX_LOG(@"ApplePayManager already initialized");
        // 如果已经初始化，仍然添加delegate
        if (delegate) {
            [self addDelegate:delegate];
        }
        return;
    }
    
    // 添加交易观察者
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    self.isInitialized = YES;
    
    // 添加delegate
    if (delegate) {
        [self addDelegate:delegate];
    }
    
    BUNNYX_LOG(@"ApplePayManager initialized successfully");
}

- (void)addDelegate:(id<ApplePayManagerDelegate>)delegate {
    if (delegate && ![self.delegates containsObject:delegate]) {
        [self.delegates addObject:delegate];
        BUNNYX_LOG(@"ApplePayManager: Added delegate: %@", delegate);
    }
}

- (void)removeDelegate:(id<ApplePayManagerDelegate>)delegate {
    if (delegate) {
        [self.delegates removeObject:delegate];
        BUNNYX_LOG(@"ApplePayManager: Removed delegate: %@", delegate);
    }
}

#pragma mark - Delegate Notification Helpers

- (void)notifyDelegatesPurchaseSuccess:(SKPaymentTransaction *)transaction productId:(NSString *)productId {
    // 兼容旧的delegate属性
    if (self.delegate && [self.delegate respondsToSelector:@selector(applePayManager:didPurchaseSuccessWithTransaction:productId:)]) {
        [self.delegate applePayManager:self didPurchaseSuccessWithTransaction:transaction productId:productId];
    }
    
    // 通知所有delegates
    // 注意：PaymentExceptionHandler 会在重启时确保订单完成（即使跳过了重复处理）
    // 业务层delegate（如 SubscriptionViewController）会在用户进入页面时处理订单完成
    for (id<ApplePayManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(applePayManager:didPurchaseSuccessWithTransaction:productId:)]) {
            [delegate applePayManager:self didPurchaseSuccessWithTransaction:transaction productId:productId];
        }
    }
}

- (void)notifyDelegatesPurchaseFail:(NSError *)error {
    // 兼容旧的delegate属性
    if (self.delegate && [self.delegate respondsToSelector:@selector(applePayManager:didPurchaseFailWithError:)]) {
        [self.delegate applePayManager:self didPurchaseFailWithError:error];
    }
    
    // 通知所有delegates
    for (id<ApplePayManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(applePayManager:didPurchaseFailWithError:)]) {
            [delegate applePayManager:self didPurchaseFailWithError:error];
        }
    }
}

- (void)notifyDelegatesRestoreSuccess:(NSArray<SKPaymentTransaction *> *)transactions {
    // 兼容旧的delegate属性
    if (self.delegate && [self.delegate respondsToSelector:@selector(applePayManager:didRestoreSuccessWithTransactions:)]) {
        [self.delegate applePayManager:self didRestoreSuccessWithTransactions:transactions];
    }
    
    // 通知所有delegates
    for (id<ApplePayManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(applePayManager:didRestoreSuccessWithTransactions:)]) {
            [delegate applePayManager:self didRestoreSuccessWithTransactions:transactions];
        }
    }
}

- (void)notifyDelegatesRestoreFail:(NSError *)error {
    // 兼容旧的delegate属性
    if (self.delegate && [self.delegate respondsToSelector:@selector(applePayManager:didRestoreFailWithError:)]) {
        [self.delegate applePayManager:self didRestoreFailWithError:error];
    }
    
    // 通知所有delegates
    for (id<ApplePayManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(applePayManager:didRestoreFailWithError:)]) {
            [delegate applePayManager:self didRestoreFailWithError:error];
        }
    }
}

- (void)requestProductsWithIds:(NSArray<NSString *> *)productIds
                    completion:(void(^)(NSArray<SKProduct *> * _Nullable products, NSError * _Nullable error))completion {
    if (!productIds || productIds.count == 0) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"ApplePayManager" 
                                                 code:-1001 
                                             userInfo:@{NSLocalizedDescriptionKey: @"商品ID列表为空"}];
            completion(nil, error);
        }
        return;
    }
    
    // 检查是否有正在进行的请求
    NSSet<NSString *> *requestingIds = [NSSet setWithArray:productIds];
    if ([self.pendingProductIds intersectsSet:requestingIds]) {
        BUNNYX_LOG(@"Product request already in progress for some IDs");
        // 可以合并回调或返回错误
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"ApplePayManager" 
                                                 code:-1002 
                                             userInfo:@{NSLocalizedDescriptionKey: @"商品请求正在进行中"}];
            completion(nil, error);
        }
        return;
    }
    
    // 创建请求
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:requestingIds];
    request.delegate = self;
    
    // 保存回调和产品ID映射
    NSString *key = [productIds componentsJoinedByString:@","];
    self.productRequestCallbacks[key] = completion;
    [self.requestToProductIds setObject:requestingIds forKey:request];
    [self.pendingProductIds addObjectsFromArray:productIds];
    
    // 发起请求
    [request start];
    BUNNYX_LOG(@"Requesting products: %@", productIds);
}

- (void)purchaseProductWithId:(NSString *)productId
                        orderId:(NSString *)orderId
                      timestamp:(NSString *)timestamp {
    if (!productId || productId.length == 0) {
        BUNNYX_ERROR(@"Product ID is empty");
        NSError *error = [NSError errorWithDomain:@"ApplePayManager" 
                                             code:-1003 
                                         userInfo:@{NSLocalizedDescriptionKey: @"商品ID为空"}];
        [self notifyDelegatesPurchaseFail:error];
        return;
    }
    
    // 先查询商品信息
    [self requestProductsWithIds:@[productId] completion:^(NSArray<SKProduct *> * _Nullable products, NSError * _Nullable error) {
        if (error || !products || products.count == 0) {
            BUNNYX_ERROR(@"Failed to get product info: %@", error);
            NSError *purchaseError = error ?: [NSError errorWithDomain:@"ApplePayManager" 
                                                                  code:-1004 
                                                              userInfo:@{NSLocalizedDescriptionKey: @"获取商品信息失败"}];
            [self notifyDelegatesPurchaseFail:purchaseError];
            return;
        }
        
        SKProduct *product = products.firstObject;
        // 使用 SKMutablePayment 以便设置 applicationUsername（订单号）
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        // 将订单号设置到 applicationUsername 中，以便在交易回调中获取
        if (orderId && orderId.length > 0) {
            payment.applicationUsername = orderId;
            // 同时保存到临时映射中，以防 applicationUsername 丢失（iOS StoreKit 的已知问题）
            self.productIdToOrderIdMap[productId] = orderId;
            // 在购买时就保存到持久化缓存（通过productId），防止用户杀掉应用导致订单丢失
            // 注意：此时还没有transactionId，所以先用productId保存，等有transactionId后再更新
            [[PaymentOrderCacheManager sharedManager] savePendingOrderWithProductId:productId orderSn:orderId];
            BUNNYX_LOG(@"Set applicationUsername (orderId) to payment: %@, and saved to map and persistent cache", orderId);
        }
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        
        BUNNYX_LOG(@"Added payment to queue for product: %@", productId);
    }];
}

- (void)restorePurchases {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    BUNNYX_LOG(@"Restoring purchases...");
}

- (void)verifyReceipt:(NSData *)receiptData
            completion:(void(^)(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error))completion {
    [self verifyReceipt:receiptData orderSn:nil completion:completion];
}

- (void)verifyReceipt:(NSData *)receiptData
               orderSn:(NSString * _Nullable)orderSn
            completion:(void(^)(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error))completion {
    if (!receiptData || receiptData.length == 0) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"ApplePayManager" 
                                                 code:-1005 
                                             userInfo:@{NSLocalizedDescriptionKey: @"收据数据为空"}];
            completion(NO, nil, error);
        }
        return;
    }
    
    // Base64编码收据（Apple收据是二进制数据，必须使用Base64编码）
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:0];
    
    // 如果orderSn为空，尝试从缓存获取（需要transactionId，但这里没有，所以传空字符串）
    NSString *finalOrderSn = orderSn ?: @"";
    
    // 发送到服务器验证
    NSDictionary *parameters = @{
        @"appleReceipt": receiptString, // 苹果支付凭据（Base64编码的收据）
        @"orderSn": finalOrderSn // 订单号
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_PAY_APPLE_VERIFY
                              parameters:parameters
                                 success:^(id responseObject) {
        BUNNYX_LOG(@"Receipt verification success: %@", responseObject);
        if (completion) {
            completion(YES, responseObject, nil);
        }
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"Receipt verification failed: %@", error);
        if (completion) {
            completion(NO, nil, error);
        }
    }];
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    BUNNYX_LOG(@"Finished transaction: %@", transaction.transactionIdentifier);
}

- (BOOL)isProcessingTransaction:(NSString *)transactionId {
    if (!transactionId || transactionId.length == 0) {
        return NO;
    }
    return [self.processingTransactionIds containsObject:transactionId];
}

- (void)destroy {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    self.isInitialized = NO;
    [self.productRequestCallbacks removeAllObjects];
    [self.pendingProductIds removeAllObjects];
    [self.requestToProductIds removeAllObjects];
    [self.processingTransactionIds removeAllObjects];
    [self.productIdToOrderIdMap removeAllObjects];
    BUNNYX_LOG(@"ApplePayManager destroyed");
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray<SKProduct *> *products = response.products;
    NSArray<NSString *> *invalidProductIds = response.invalidProductIdentifiers;
    
    BUNNYX_LOG(@"Received products response: %lu products, %lu invalid", (unsigned long)products.count, (unsigned long)invalidProductIds.count);
    
    if (invalidProductIds.count > 0) {
        BUNNYX_ERROR(@"Invalid product IDs: %@", invalidProductIds);
    }
    
    // 查找对应的回调
    NSSet<NSString *> *requestedIds = [self.requestToProductIds objectForKey:request];
    if (!requestedIds) {
        BUNNYX_ERROR(@"Could not find product IDs for request");
        return;
    }
    
    NSString *key = [[requestedIds allObjects] componentsJoinedByString:@","];
    void(^completion)(NSArray<SKProduct *> * _Nullable, NSError * _Nullable) = self.productRequestCallbacks[key];
    
    if (completion) {
        if (products.count > 0) {
            completion(products, nil);
        } else {
            NSError *error = [NSError errorWithDomain:@"ApplePayManager" 
                                                 code:-1006 
                                             userInfo:@{NSLocalizedDescriptionKey: @"未找到有效商品"}];
            completion(nil, error);
        }
        [self.productRequestCallbacks removeObjectForKey:key];
    }
    
    // 移除pending IDs和请求映射
    [self.pendingProductIds minusSet:requestedIds];
    [self.requestToProductIds removeObjectForKey:request];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    BUNNYX_ERROR(@"Product request failed: %@", error);
    
    // 查找对应的回调
    if ([request isKindOfClass:[SKProductsRequest class]]) {
        SKProductsRequest *productRequest = (SKProductsRequest *)request;
        NSSet<NSString *> *requestedIds = [self.requestToProductIds objectForKey:productRequest];
        
        if (requestedIds) {
            NSString *key = [[requestedIds allObjects] componentsJoinedByString:@","];
            void(^completion)(NSArray<SKProduct *> * _Nullable, NSError * _Nullable) = self.productRequestCallbacks[key];
            
            if (completion) {
                completion(nil, error);
                [self.productRequestCallbacks removeObjectForKey:key];
            }
            
            // 移除pending IDs和请求映射
            [self.pendingProductIds minusSet:requestedIds];
            [self.requestToProductIds removeObjectForKey:productRequest];
        }
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    BUNNYX_LOG(@"ApplePayManager: 收到 %lu 笔交易更新", (unsigned long)transactions.count);
    
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *transactionId = transaction.transactionIdentifier ?: @"";
        
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                BUNNYX_LOG(@"Transaction purchased: %@", transactionId);
                
                // 检查是否正在处理此交易（去重机制，防止重复处理）
                if (transactionId.length > 0 && [self.processingTransactionIds containsObject:transactionId]) {
                    BUNNYX_LOG(@"ApplePayManager: 交易 %@ 正在处理中，跳过重复处理", transactionId);
                    break;
                }
                
                // 标记为正在处理
                if (transactionId.length > 0) {
                    [self.processingTransactionIds addObject:transactionId];
                }
                
                // 获取收据
                NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
                
                if (receiptData) {
                    // 优先从 applicationUsername 获取订单号（购买时设置）
                    NSString *orderSn = transaction.payment.applicationUsername;
                    NSString *productId = transaction.payment.productIdentifier;
                    BOOL needSaveToCache = NO; // 标记是否需要保存到缓存
                    
                    // 如果 applicationUsername 为空（iOS StoreKit 的已知问题，可能丢失），尝试从临时映射中获取
                    if (!orderSn || orderSn.length == 0) {
                        if (productId && productId.length > 0) {
                            orderSn = self.productIdToOrderIdMap[productId];
                            if (orderSn && orderSn.length > 0) {
                                BUNNYX_LOG(@"ApplePayManager: applicationUsername 丢失，从临时映射获取订单号，productId: %@, orderSn: %@", productId, orderSn);
                                needSaveToCache = YES; // 从临时映射获取的，需要保存到持久化缓存
                            }
                        }
                    } else {
                        BUNNYX_LOG(@"ApplePayManager: 从 applicationUsername 获取订单号: %@", orderSn);
                        needSaveToCache = YES; // 从 applicationUsername 获取的，需要保存到持久化缓存
                    }
                    
                    // 如果仍然为空，尝试从缓存中获取（兼容旧逻辑和异常恢复场景）
                    if (!orderSn || orderSn.length == 0) {
                        // 先尝试通过 transactionId 获取
                        if (transactionId.length > 0) {
                            orderSn = [[PaymentOrderCacheManager sharedManager] getOrderSnForTransactionId:transactionId];
                            if (orderSn && orderSn.length > 0) {
                                BUNNYX_LOG(@"ApplePayManager: 从缓存获取订单号（通过transactionId），transactionId: %@, orderSn: %@", transactionId, orderSn);
                                // 从缓存获取的，不需要再次保存（已经存在，业务层验证成功后会清除）
                                needSaveToCache = NO;
                            }
                        }
                        // 如果还是为空，尝试通过 productId 获取（购买时保存的）
                        if ((!orderSn || orderSn.length == 0) && productId && productId.length > 0) {
                            orderSn = [[PaymentOrderCacheManager sharedManager] getOrderSnForProductId:productId];
                            if (orderSn && orderSn.length > 0) {
                                BUNNYX_LOG(@"ApplePayManager: 从缓存获取订单号（通过productId），productId: %@, orderSn: %@", productId, orderSn);
                                needSaveToCache = YES; // 从productId缓存获取的，需要更新为transactionId映射
                            } else {
                                BUNNYX_LOG(@"ApplePayManager: 未找到订单号，transactionId: %@, productId: %@，将使用空字符串", transactionId, productId);
                            }
                        }
                    }
                    
                    // 如果获取到订单号且有 transactionId，保存到持久化缓存（通过transactionId）
                    // 这样可以更新之前通过productId保存的映射，同时清除productId的缓存
                    if (orderSn && orderSn.length > 0 && transactionId.length > 0) {
                        if (needSaveToCache) {
                            [[PaymentOrderCacheManager sharedManager] savePendingOrderWithTransactionId:transactionId orderSn:orderSn];
                            BUNNYX_LOG(@"ApplePayManager: 保存订单号到持久化缓存（通过transactionId），transactionId: %@, orderSn: %@", transactionId, orderSn);
                        }
                        // 清除productId的缓存（因为已经有transactionId了）
                        if (productId && productId.length > 0) {
                            [[PaymentOrderCacheManager sharedManager] clearPendingOrderForProductId:productId];
                        }
                    }
                    
                    // 验证收据（传递订单号）
                    [self verifyReceipt:receiptData orderSn:orderSn completion:^(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error) {
                        if (success) {
                            // 通知代理购买成功
                            [self notifyDelegatesPurchaseSuccess:transaction productId:transaction.payment.productIdentifier];
                        } else {
                            // 验证失败，但仍通知代理（由业务层决定如何处理）
                            NSError *verifyError = error ?: [NSError errorWithDomain:@"ApplePayManager" code:-1007 userInfo:@{NSLocalizedDescriptionKey: @"收据验证失败"}];
                            [self notifyDelegatesPurchaseFail:verifyError];
                        }
                        
                        // 验证完成后，移除处理标记（无论成功或失败）
                        if (transactionId.length > 0) {
                            [self.processingTransactionIds removeObject:transactionId];
                        }
                        
                        // 验证完成后，清理临时映射（延迟清理，确保所有交易都能获取到订单号）
                        // 注意：如果多笔交易有相同的 productId，只有在所有交易都处理完后才清理
                        // 这里使用延迟清理，给其他交易留出时间从临时映射获取订单号
                        if (productId && productId.length > 0) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self.productIdToOrderIdMap removeObjectForKey:productId];
                                BUNNYX_LOG(@"ApplePayManager: 延迟清理临时映射，productId: %@", productId);
                            });
                        }
                    }];
                } else {
                    // 没有收据，直接通知成功（可能是测试环境）
                    [self notifyDelegatesPurchaseSuccess:transaction productId:transaction.payment.productIdentifier];
                    
                    // 移除处理标记
                    if (transactionId.length > 0) {
                        [self.processingTransactionIds removeObject:transactionId];
                    }
                }
                
                // 注意：不要在这里finishTransaction，应该在业务层验证成功后调用
                break;
            }
            case SKPaymentTransactionStateFailed: {
                BUNNYX_ERROR(@"Transaction failed: %@, error: %@", transaction.transactionIdentifier, transaction.error);
                
                NSError *error = transaction.error ?: [NSError errorWithDomain:@"ApplePayManager" 
                                                                          code:-1008 
                                                                      userInfo:@{NSLocalizedDescriptionKey: @"购买失败"}];
                [self notifyDelegatesPurchaseFail:error];
                
                // 失败时完成交易
                [self finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored: {
                BUNNYX_LOG(@"Transaction restored: %@", transaction.transactionIdentifier);
                
                [self notifyDelegatesPurchaseSuccess:transaction productId:transaction.payment.productIdentifier];
                
                [self finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateDeferred:
                BUNNYX_LOG(@"Transaction deferred: %@", transaction.transactionIdentifier);
                break;
            case SKPaymentTransactionStatePurchasing:
                BUNNYX_LOG(@"Transaction purchasing: %@", transaction.transactionIdentifier);
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    BUNNYX_ERROR(@"Restore purchases failed: %@", error);
    [self notifyDelegatesRestoreFail:error];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    BUNNYX_LOG(@"Restore purchases completed");
    [self notifyDelegatesRestoreSuccess:queue.transactions];
}

@end


