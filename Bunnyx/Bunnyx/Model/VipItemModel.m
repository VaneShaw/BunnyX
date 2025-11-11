//
//  VipItemModel.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "VipItemModel.h"

@implementation VipItemModel

+ (NSArray<VipItemModel *> *)modelsFromResponse:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        
        VipItemModel *model = [[VipItemModel alloc] init];
        model.rechargeId = [dict[@"rechargeId"] integerValue];
        model.paymentCode = [dict[@"paymentCode"] isKindOfClass:[NSString class]] ? dict[@"paymentCode"] : @"";
        model.payMoney = [dict[@"payMoney"] floatValue];
        model.originalPrice = [dict[@"originalPrice"] isKindOfClass:[NSNull class]] || dict[@"originalPrice"] == nil ? nil : dict[@"originalPrice"];
        model.typeRemark = [dict[@"typeRemark"] isKindOfClass:[NSNull class]] || dict[@"typeRemark"] == nil ? nil : ([dict[@"typeRemark"] isKindOfClass:[NSString class]] ? dict[@"typeRemark"] : @"");
        model.productId = [dict[@"productId"] isKindOfClass:[NSString class]] ? dict[@"productId"] : @"";
        model.giveMxdNum = [dict[@"giveMxdNum"] integerValue];
        model.priceRemark = [dict[@"priceRemark"] isKindOfClass:[NSNull class]] || dict[@"priceRemark"] == nil ? nil : ([dict[@"priceRemark"] isKindOfClass:[NSString class]] ? dict[@"priceRemark"] : @"");
        model.discountRemark = [dict[@"discountRemark"] isKindOfClass:[NSNull class]] || dict[@"discountRemark"] == nil ? nil : ([dict[@"discountRemark"] isKindOfClass:[NSString class]] ? dict[@"discountRemark"] : @"");
        
        [result addObject:model];
    }
    return result;
}

@end



