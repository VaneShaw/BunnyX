//
//  MaterialDetailModel.m
//  Bunnyx
//
//

#import "MaterialDetailModel.h"

@implementation MaterialDetailModel

+ (instancetype)modelFromResponse:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    MaterialDetailModel *model = [[MaterialDetailModel alloc] init];
    // 从父类继承的字段
    model.materialId = [dict[@"materialId"] integerValue];
    model.materialUrl = [dict[@"materialUrl"] isKindOfClass:[NSString class]] ? dict[@"materialUrl"] : @"";
    model.materialMode = [dict[@"materialMode"] integerValue];
    model.materialFormat = [dict[@"materialFormat"] isKindOfClass:[NSString class]] ? dict[@"materialFormat"] : @"";
    model.materialSexy = [dict[@"materialSexy"] integerValue];
    model.generatePrice = [dict[@"generatePrice"] integerValue];
    model.materialType = [dict[@"materialType"] integerValue];
    model.isFavorite = [dict[@"isFavorite"] boolValue];
    // favoriteQty在父类中是NSNumber类型
    model.favoriteQty = dict[@"favoriteQty"];
    
    // 子类特有字段
    model.addDate = [dict[@"addDate"] isKindOfClass:[NSString class]] ? dict[@"addDate"] : @"";
    model.lastSyncTime = [dict[@"lastSyncTime"] isKindOfClass:[NSString class]] ? dict[@"lastSyncTime"] : @"";
    model.isEnable = [dict[@"isEnable"] integerValue];
    model.favoriteDate = [dict[@"favoriteDate"] isKindOfClass:[NSString class]] ? dict[@"favoriteDate"] : @"";
    // 对齐安卓：解析onlyVip字段
    model.onlyVip = [dict[@"onlyVip"] integerValue];
    
    return model;
}

@end
