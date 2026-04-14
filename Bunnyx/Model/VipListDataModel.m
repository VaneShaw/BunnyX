//
//  VipListDataModel.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "VipListDataModel.h"

@implementation VipListDataModel

+ (instancetype)modelFromResponse:(NSDictionary *)response {
    if (!response || ![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    VipListDataModel *model = [[VipListDataModel alloc] init];
    
    // 解析list数组
    NSArray *listArray = response[@"list"];
    if ([listArray isKindOfClass:[NSArray class]]) {
        model.list = [VipItemModel modelsFromResponse:listArray];
    } else {
        model.list = @[];
    }
    
    // 解析firstBuy
    id firstBuyValue = response[@"firstBuy"];
    if ([firstBuyValue isKindOfClass:[NSNumber class]]) {
        model.firstBuy = [firstBuyValue boolValue];
    } else if ([firstBuyValue isKindOfClass:[NSString class]]) {
        model.firstBuy = [firstBuyValue boolValue];
    } else {
        model.firstBuy = NO;
    }
    
    return model;
}

@end



