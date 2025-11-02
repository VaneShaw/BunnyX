//
//  MaterialDetailModel.m
//  Bunnyx
//

#import "MaterialDetailModel.h"

@implementation MaterialDetailModel

+ (instancetype)modelFromResponse:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    MaterialDetailModel *model = [[MaterialDetailModel alloc] init];
    model.materialId = [dict[@"materialId"] integerValue];
    model.materialUrl = [dict[@"materialUrl"] isKindOfClass:[NSString class]] ? dict[@"materialUrl"] : @"";
    model.materialMode = [dict[@"materialMode"] integerValue];
    model.materialFormat = [dict[@"materialFormat"] isKindOfClass:[NSString class]] ? dict[@"materialFormat"] : @"";
    model.materialSexy = [dict[@"materialSexy"] integerValue];
    model.addDate = [dict[@"addDate"] isKindOfClass:[NSString class]] ? dict[@"addDate"] : @"";
    model.lastSyncTime = [dict[@"lastSyncTime"] isKindOfClass:[NSString class]] ? dict[@"lastSyncTime"] : @"";
    model.isEnable = [dict[@"isEnable"] integerValue];
    model.favoriteQty = [dict[@"favoriteQty"] integerValue];
    model.generatePrice = [dict[@"generatePrice"] integerValue];
    model.materialType = [dict[@"materialType"] integerValue];
    model.favoriteDate = [dict[@"favoriteDate"] isKindOfClass:[NSString class]] ? dict[@"favoriteDate"] : @"";
    model.isFavorite = [dict[@"isFavorite"] boolValue];
    
    return model;
}

@end
