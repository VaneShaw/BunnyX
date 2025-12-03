//
//  PaymentOrderCacheManager.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "PaymentOrderCacheManager.h"
#import "BunnyxMacros.h"

static NSString *const kPendingOrdersKey = @"BunnyxPendingPaymentOrders";
static NSString *const kOrderTimestampKey = @"BunnyxPendingOrderTimestamp";
static NSString *const kPendingOrdersByProductIdKey = @"BunnyxPendingPaymentOrdersByProductId"; // productId -> orderSn
static NSString *const kOrderTimestampsByProductIdKey = @"BunnyxPendingOrderTimestampByProductId"; // productId -> timestamp
static NSTimeInterval const kCacheValidTime = 7 * 24 * 60 * 60; // 7天

@interface PaymentOrderCacheManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *pendingOrders; // transactionId -> orderSn
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *orderTimestamps; // transactionId -> timestamp
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *pendingOrdersByProductId; // productId -> orderSn
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *orderTimestampsByProductId; // productId -> timestamp

@end

@implementation PaymentOrderCacheManager

+ (instancetype)sharedManager {
    static PaymentOrderCacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PaymentOrderCacheManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadPendingOrders];
    }
    return self;
}

- (void)loadPendingOrders {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary<NSString *, NSString *> *savedOrders = [defaults dictionaryForKey:kPendingOrdersKey];
    NSDictionary<NSString *, NSNumber *> *savedTimestamps = [defaults dictionaryForKey:kOrderTimestampKey];
    NSDictionary<NSString *, NSString *> *savedOrdersByProductId = [defaults dictionaryForKey:kPendingOrdersByProductIdKey];
    NSDictionary<NSString *, NSNumber *> *savedTimestampsByProductId = [defaults dictionaryForKey:kOrderTimestampsByProductIdKey];
    
    if (savedOrders) {
        self.pendingOrders = [savedOrders mutableCopy];
    } else {
        self.pendingOrders = [NSMutableDictionary dictionary];
    }
    
    if (savedTimestamps) {
        self.orderTimestamps = [savedTimestamps mutableCopy];
    } else {
        self.orderTimestamps = [NSMutableDictionary dictionary];
    }
    
    if (savedOrdersByProductId) {
        self.pendingOrdersByProductId = [savedOrdersByProductId mutableCopy];
    } else {
        self.pendingOrdersByProductId = [NSMutableDictionary dictionary];
    }
    
    if (savedTimestampsByProductId) {
        self.orderTimestampsByProductId = [savedTimestampsByProductId mutableCopy];
    } else {
        self.orderTimestampsByProductId = [NSMutableDictionary dictionary];
    }
    
    // 清理过期的订单
    [self cleanExpiredOrders];
}

- (void)savePendingOrders {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.pendingOrders forKey:kPendingOrdersKey];
    [defaults setObject:self.orderTimestamps forKey:kOrderTimestampKey];
    [defaults setObject:self.pendingOrdersByProductId forKey:kPendingOrdersByProductIdKey];
    [defaults setObject:self.orderTimestampsByProductId forKey:kOrderTimestampsByProductIdKey];
    [defaults synchronize];
}

- (void)savePendingOrderWithProductId:(NSString *)productId orderSn:(NSString *)orderSn {
    if (!productId || productId.length == 0 || !orderSn || orderSn.length == 0) {
        BUNNYX_ERROR(@"PaymentOrderCacheManager: 保存订单失败，参数不完整");
        return;
    }
    
    self.pendingOrdersByProductId[productId] = orderSn;
    self.orderTimestampsByProductId[productId] = @([[NSDate date] timeIntervalSince1970]);
    
    [self savePendingOrders];
    
    BUNNYX_LOG(@"PaymentOrderCacheManager: 保存待验证订单成功（通过productId），productId: %@, orderSn: %@", productId, orderSn);
}

- (void)savePendingOrderWithTransactionId:(NSString *)transactionId orderSn:(NSString *)orderSn {
    if (!transactionId || transactionId.length == 0 || !orderSn || orderSn.length == 0) {
        BUNNYX_ERROR(@"PaymentOrderCacheManager: 保存订单失败，参数不完整");
        return;
    }
    
    self.pendingOrders[transactionId] = orderSn;
    self.orderTimestamps[transactionId] = @([[NSDate date] timeIntervalSince1970]);
    
    [self savePendingOrders];
    
    BUNNYX_LOG(@"PaymentOrderCacheManager: 保存待验证订单成功，transactionId: %@, orderSn: %@", transactionId, orderSn);
}

- (NSString *)getOrderSnForProductId:(NSString *)productId {
    if (!productId || productId.length == 0) {
        return nil;
    }
    
    // 检查是否过期
    NSNumber *timestamp = self.orderTimestampsByProductId[productId];
    if (timestamp) {
        NSTimeInterval timeSinceSaved = [[NSDate date] timeIntervalSince1970] - [timestamp doubleValue];
        if (timeSinceSaved > kCacheValidTime) {
            BUNNYX_LOG(@"PaymentOrderCacheManager: 订单缓存已过期，自动清除，productId: %@", productId);
            [self.pendingOrdersByProductId removeObjectForKey:productId];
            [self.orderTimestampsByProductId removeObjectForKey:productId];
            [self savePendingOrders];
            return nil;
        }
    }
    
    NSString *orderSn = self.pendingOrdersByProductId[productId];
    if (orderSn) {
        BUNNYX_LOG(@"PaymentOrderCacheManager: 获取待验证订单成功（通过productId），productId: %@, orderSn: %@", productId, orderSn);
    }
    
    return orderSn;
}

- (NSString *)getOrderSnForTransactionId:(NSString *)transactionId {
    if (!transactionId || transactionId.length == 0) {
        return nil;
    }
    
    // 检查是否过期
    NSNumber *timestamp = self.orderTimestamps[transactionId];
    if (timestamp) {
        NSTimeInterval timeSinceSaved = [[NSDate date] timeIntervalSince1970] - [timestamp doubleValue];
        if (timeSinceSaved > kCacheValidTime) {
            BUNNYX_LOG(@"PaymentOrderCacheManager: 订单缓存已过期，自动清除，transactionId: %@", transactionId);
            [self clearPendingOrderForTransactionId:transactionId];
            return nil;
        }
    }
    
    NSString *orderSn = self.pendingOrders[transactionId];
    if (orderSn) {
        BUNNYX_LOG(@"PaymentOrderCacheManager: 获取待验证订单成功，transactionId: %@, orderSn: %@", transactionId, orderSn);
    }
    
    return orderSn;
}

- (void)clearPendingOrderForTransactionId:(NSString *)transactionId {
    if (!transactionId || transactionId.length == 0) {
        return;
    }
    
    [self.pendingOrders removeObjectForKey:transactionId];
    [self.orderTimestamps removeObjectForKey:transactionId];
    
    [self savePendingOrders];
    
    BUNNYX_LOG(@"PaymentOrderCacheManager: 清除待验证订单，transactionId: %@", transactionId);
}

- (void)clearPendingOrderForProductId:(NSString *)productId {
    if (!productId || productId.length == 0) {
        return;
    }
    
    [self.pendingOrdersByProductId removeObjectForKey:productId];
    [self.orderTimestampsByProductId removeObjectForKey:productId];
    
    [self savePendingOrders];
    
    BUNNYX_LOG(@"PaymentOrderCacheManager: 清除待验证订单（通过productId），productId: %@", productId);
}

- (BOOL)hasPendingOrder {
    [self cleanExpiredOrders];
    return self.pendingOrders.count > 0;
}

- (void)cleanExpiredOrders {
    NSMutableArray<NSString *> *expiredTransactionIds = [NSMutableArray array];
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    for (NSString *transactionId in self.orderTimestamps.allKeys) {
        NSNumber *timestamp = self.orderTimestamps[transactionId];
        if (timestamp) {
            NSTimeInterval timeSinceSaved = currentTime - [timestamp doubleValue];
            if (timeSinceSaved > kCacheValidTime) {
                [expiredTransactionIds addObject:transactionId];
            }
        }
    }
    
    for (NSString *transactionId in expiredTransactionIds) {
        [self.pendingOrders removeObjectForKey:transactionId];
        [self.orderTimestamps removeObjectForKey:transactionId];
    }
    
    if (expiredTransactionIds.count > 0) {
        [self savePendingOrders];
        BUNNYX_LOG(@"PaymentOrderCacheManager: 清理了 %lu 个过期订单", (unsigned long)expiredTransactionIds.count);
    }
}

@end

