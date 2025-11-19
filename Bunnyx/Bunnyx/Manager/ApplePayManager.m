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

@interface ApplePayManager ()

@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, strong) NSMutableDictionary<NSString *, void(^)(NSArray<SKProduct *> * _Nullable, NSError * _Nullable)> *productRequestCallbacks;
@property (nonatomic, strong) NSMutableSet<NSString *> *pendingProductIds;
@property (nonatomic, strong) NSMapTable<SKProductsRequest *, NSSet<NSString *> *> *requestToProductIds;
@property (nonatomic, strong) NSHashTable<id<ApplePayManagerDelegate>> *delegates;

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
        SKPayment *payment = [SKPayment paymentWithProduct:product];
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
    if (!receiptData || receiptData.length == 0) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"ApplePayManager" 
                                                 code:-1005 
                                             userInfo:@{NSLocalizedDescriptionKey: @"收据数据为空"}];
            completion(NO, nil, error);
        }
        return;
    }
    
    // Base64编码收据
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:0];
    
    // 发送到服务器验证
    NSDictionary *parameters = @{
        @"receipt": receiptString
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_PAYMENT_VERIFY
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

- (void)destroy {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    self.isInitialized = NO;
    [self.productRequestCallbacks removeAllObjects];
    [self.pendingProductIds removeAllObjects];
    [self.requestToProductIds removeAllObjects];
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
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                BUNNYX_LOG(@"Transaction purchased: %@", transaction.transactionIdentifier);
                
                // 获取收据
                NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
                
                if (receiptData) {
                    // 验证收据
                    [self verifyReceipt:receiptData completion:^(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error) {
                        if (success) {
                            // 通知代理购买成功
                            [self notifyDelegatesPurchaseSuccess:transaction productId:transaction.payment.productIdentifier];
                        } else {
                            // 验证失败，但仍通知代理（由业务层决定如何处理）
                            NSError *verifyError = error ?: [NSError errorWithDomain:@"ApplePayManager" code:-1007 userInfo:@{NSLocalizedDescriptionKey: @"收据验证失败"}];
                            [self notifyDelegatesPurchaseFail:verifyError];
                        }
                    }];
                } else {
                    // 没有收据，直接通知成功（可能是测试环境）
                    [self notifyDelegatesPurchaseSuccess:transaction productId:transaction.payment.productIdentifier];
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


