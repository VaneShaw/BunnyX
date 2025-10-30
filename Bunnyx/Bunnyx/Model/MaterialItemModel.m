//
//  MaterialItemModel.m
//  Bunnyx
//

#import "MaterialItemModel.h"

@implementation MaterialItemModel

+ (NSArray<MaterialItemModel *> *)modelsFromResponse:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        MaterialItemModel *m = [[MaterialItemModel alloc] init];
        m.materialId = [dict[@"materialId"] integerValue];
        m.materialUrl = [dict[@"materialUrl"] isKindOfClass:[NSString class]] ? dict[@"materialUrl"] : @"";
        m.materialMode = [dict[@"materialMode"] integerValue];
        m.materialFormat = [dict[@"materialFormat"] isKindOfClass:[NSString class]] ? dict[@"materialFormat"] : @"";
        m.materialSexy = [dict[@"materialSexy"] integerValue];
        m.generatePrice = [dict[@"generatePrice"] integerValue];
        m.materialType = [dict[@"materialType"] integerValue];
        m.isFavorite = [dict[@"isFavorite"] boolValue];
        m.favoriteQty = dict[@"favoriteQty"];
        [result addObject:m];
    }
    return result.copy;
}

@end


