//
//  RechargeItemModel.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 充值项Model
@interface RechargeItemModel : NSObject

/// 充值项目ID
@property (nonatomic, assign) NSInteger rechargeId;

/// 支付代码（applePay或googlePay）
@property (nonatomic, copy) NSString *paymentCode;

/// 支付金额
@property (nonatomic, assign) CGFloat payMoney;

/// 充值金币数量
@property (nonatomic, assign) NSInteger buyNum;

/// 赠送数量
@property (nonatomic, assign) NSInteger giveNum;

/// 活动数量
@property (nonatomic, assign) NSInteger eventNum;

/// 活动说明
@property (nonatomic, copy, nullable) NSString *eventRemark;

/// 币别
@property (nonatomic, copy) NSString *currency;

/// 第三方支付上的产品ID
@property (nonatomic, copy) NSString *productId;

/// 赠送MXD数量
@property (nonatomic, assign) NSInteger giveMxdNum;

/// 原价
@property (nonatomic, strong, nullable) NSNumber *originalPrice;

/// 仅首充（1表示仅首充）
@property (nonatomic, assign) NSInteger onlyFirst;

/// 类型说明
@property (nonatomic, copy, nullable) NSString *typeRemark;

/// 价格说明
@property (nonatomic, copy, nullable) NSString *priceRemark;

/// 折扣说明
@property (nonatomic, copy, nullable) NSString *discountRemark;

/// 数量
@property (nonatomic, assign) NSInteger num;

/// 从API响应数组创建Model数组
+ (NSArray<RechargeItemModel *> *)modelsFromResponse:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END

