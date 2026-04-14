//
//  AdMobConfigModel.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "AdMobConfigModel.h"
#import "BunnyxMacros.h"

@implementation AdMobConfigModel

#pragma mark - YYModel 映射配置

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"adPlacement": @"adPlacement",
        @"adType": @"adType",
        @"adUnitId": @"adUnitId",
        @"rewardCoins": @"rewardCoins",
        @"rewardMaxCount": @"rewardMaxCount"
    };
}

#pragma mark - 验证方法

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    // 验证广告位
    if (self.adPlacement < 0 || self.adPlacement > 2) {
        [errors addObject:@"广告位值必须在0-2之间"];
    }
    
    // 验证广告类型
    if (self.adType < 0 || self.adType > 1) {
        [errors addObject:@"广告类型值必须在0-1之间"];
    }
    
    // 验证广告单元ID
    if (BUNNYX_IS_EMPTY_STRING(self.adUnitId)) {
        [errors addObject:@"广告单元ID不能为空"];
    }
    
    return [errors copy];
}

@end

