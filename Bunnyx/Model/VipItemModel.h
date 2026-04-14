//
//  VipItemModel.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

/// VIP订阅项Model
@interface VipItemModel : BaseModel

/// 订阅项目ID
@property (nonatomic, assign) NSInteger rechargeId;

/// 支付代码（applePay或googlePay）
@property (nonatomic, copy) NSString *paymentCode;

/// 支付金额
@property (nonatomic, assign) CGFloat payMoney;

/// 原价（可选）
@property (nonatomic, strong, nullable) NSNumber *originalPrice;

/// 类型说明（如：week, month）
@property (nonatomic, copy, nullable) NSString *typeRemark;

/// 第三方支付上的产品ID
@property (nonatomic, copy) NSString *productId;

/// 赠送MXD数量（金币数量）
@property (nonatomic, assign) NSInteger giveMxdNum;

/// 价格说明
@property (nonatomic, copy, nullable) NSString *priceRemark;

/// 折扣说明
@property (nonatomic, copy, nullable) NSString *discountRemark;

/// 从API响应数组创建Model数组
+ (NSArray<VipItemModel *> *)modelsFromResponse:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END



