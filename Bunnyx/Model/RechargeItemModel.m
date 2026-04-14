//
//  RechargeItemModel.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "RechargeItemModel.h"

@implementation RechargeItemModel

+ (NSArray<RechargeItemModel *> *)modelsFromResponse:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        
        RechargeItemModel *model = [[RechargeItemModel alloc] init];
        model.rechargeId = [dict[@"rechargeId"] integerValue];
        model.paymentCode = [dict[@"paymentCode"] isKindOfClass:[NSString class]] ? dict[@"paymentCode"] : @"";
        model.payMoney = [dict[@"payMoney"] floatValue];
        model.buyNum = [dict[@"buyNum"] integerValue];
        model.giveNum = [dict[@"giveNum"] integerValue];
        model.eventNum = [dict[@"eventNum"] integerValue];
        model.eventRemark = [dict[@"eventRemark"] isKindOfClass:[NSNull class]] || dict[@"eventRemark"] == nil ? nil : ([dict[@"eventRemark"] isKindOfClass:[NSString class]] ? dict[@"eventRemark"] : nil);
        model.currency = [dict[@"currency"] isKindOfClass:[NSString class]] ? dict[@"currency"] : @"";
        model.productId = [dict[@"productId"] isKindOfClass:[NSString class]] ? dict[@"productId"] : @"";
        model.giveMxdNum = [dict[@"giveMxdNum"] integerValue];
        model.originalPrice = [dict[@"originalPrice"] isKindOfClass:[NSNull class]] || dict[@"originalPrice"] == nil ? nil : dict[@"originalPrice"];
        model.onlyFirst = [dict[@"onlyFirst"] integerValue];
        model.typeRemark = [dict[@"typeRemark"] isKindOfClass:[NSNull class]] || dict[@"typeRemark"] == nil ? nil : ([dict[@"typeRemark"] isKindOfClass:[NSString class]] ? dict[@"typeRemark"] : nil);
        model.priceRemark = [dict[@"priceRemark"] isKindOfClass:[NSNull class]] || dict[@"priceRemark"] == nil ? nil : ([dict[@"priceRemark"] isKindOfClass:[NSString class]] ? dict[@"priceRemark"] : nil);
        model.discountRemark = [dict[@"discountRemark"] isKindOfClass:[NSNull class]] || dict[@"discountRemark"] == nil ? nil : ([dict[@"discountRemark"] isKindOfClass:[NSString class]] ? dict[@"discountRemark"] : nil);
        model.num = [dict[@"num"] integerValue];
        
        [result addObject:model];
    }
    return result.copy;
}

@end

