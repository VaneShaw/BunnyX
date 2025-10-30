//
//  MaterialTypeModel.m
//  Bunnyx
//

#import "MaterialTypeModel.h"

@implementation MaterialTypeModel

- (NSString *)displayName {
    if (!self.typeNameRaw || self.typeNameRaw.length == 0) {
        return self.remark ?: @"";
    }
    NSData *data = [self.typeNameRaw dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) { return self.remark ?: self.typeNameRaw; }
    NSDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![map isKindOfClass:[NSDictionary class]]) { return self.remark ?: self.typeNameRaw; }
    NSString *language = [[NSLocale preferredLanguages] firstObject] ?: @"zh-Hans";
    NSString *key = [language hasPrefix:@"en"] ? @"en_US" : @"zh_CN";
    NSString *name = map[key];
    return name ?: (self.remark ?: self.typeNameRaw);
}

+ (NSArray<MaterialTypeModel *> *)modelsFromResponse:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        MaterialTypeModel *m = [[MaterialTypeModel alloc] init];
        m.typeId = [dict[@"typeId"] integerValue];
        m.typeNameRaw = [dict[@"typeName"] isKindOfClass:[NSString class]] ? dict[@"typeName"] : @"";
        m.typeSexy = [dict[@"typeSexy"] integerValue];
        m.sort = [dict[@"sort"] isKindOfClass:[NSString class]] ? dict[@"sort"] : @"";
        m.remark = [dict[@"remark"] isKindOfClass:[NSString class]] ? dict[@"remark"] : @"";
        [result addObject:m];
    }
    return result.copy;
}

@end


