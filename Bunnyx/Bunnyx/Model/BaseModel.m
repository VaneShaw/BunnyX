//
//  BaseModel.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "BaseModel.h"
#import "BunnyxMacros.h"

@implementation BaseModel

#pragma mark - 初始化方法

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        BUNNYX_ERROR(@"Invalid dictionary for model initialization");
        return nil;
    }
    
    return [self yy_modelWithDictionary:dictionary];
}

+ (instancetype)modelWithJSONString:(NSString *)jsonString {
    if (BUNNYX_IS_EMPTY_STRING(jsonString)) {
        BUNNYX_ERROR(@"Empty JSON string for model initialization");
        return nil;
    }
    
    return [self yy_modelWithJSON:jsonString];
}

+ (instancetype)modelWithJSONData:(NSData *)jsonData {
    if (!jsonData || jsonData.length == 0) {
        BUNNYX_ERROR(@"Invalid JSON data for model initialization");
        return nil;
    }
    
    return [self yy_modelWithJSON:jsonData];
}

#pragma mark - 转换方法

- (NSDictionary *)toDictionary {
    NSDictionary *dictionary = [self yy_modelToJSONObject];
    return [dictionary isKindOfClass:[NSDictionary class]] ? dictionary : @{};
}

- (NSString *)toJSONString {
    NSString *jsonString = [self yy_modelToJSONString];
    return BUNNYX_SAFE_STRING(jsonString);
}

- (NSData *)toJSONData {
    NSData *jsonData = [self yy_modelToJSONData];
    return jsonData ?: [NSData data];
}

#pragma mark - 批量转换方法

+ (NSArray *)modelArrayWithDictionaryArray:(NSArray<NSDictionary *> *)dictionaryArray {
    if (BUNNYX_IS_EMPTY_ARRAY(dictionaryArray)) {
        return @[];
    }
    
    NSMutableArray *modelArray = [NSMutableArray array];
    for (NSDictionary *dictionary in dictionaryArray) {
        if ([dictionary isKindOfClass:[NSDictionary class]]) {
            id model = [self modelWithDictionary:dictionary];
            if (model) {
                [modelArray addObject:model];
            }
        }
    }
    
    return [modelArray copy];
}

+ (NSArray<NSDictionary *> *)dictionaryArrayWithModelArray:(NSArray<BaseModel *> *)modelArray {
    if (BUNNYX_IS_EMPTY_ARRAY(modelArray)) {
        return @[];
    }
    
    NSMutableArray *dictionaryArray = [NSMutableArray array];
    for (BaseModel *model in modelArray) {
        if ([model isKindOfClass:[BaseModel class]]) {
            NSDictionary *dictionary = [model toDictionary];
            if (dictionary) {
                [dictionaryArray addObject:dictionary];
            }
        }
    }
    
    return [dictionaryArray copy];
}

+ (NSString *)jsonStringWithModelArray:(NSArray<BaseModel *> *)modelArray {
    if (BUNNYX_IS_EMPTY_ARRAY(modelArray)) {
        return @"[]";
    }
    
    NSArray *dictionaryArray = [self dictionaryArrayWithModelArray:modelArray];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionaryArray options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        BUNNYX_ERROR(@"JSON serialization failed: %@", error.localizedDescription);
        return @"[]";
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - 验证方法

- (BOOL)isValid {
    NSArray *errors = [self validationErrors];
    return errors.count == 0;
}

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    // 子类可以重写此方法来添加具体的验证逻辑
    // 这里提供基础的验证框架
    
    return [errors copy];
}

#pragma mark - 调试方法

- (NSString *)modelDescription {
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"<%@: %p>", NSStringFromClass([self class]), self];
    [description appendFormat:@"\nDictionary: %@", [self toDictionary]];
    return [description copy];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    NSDictionary *dictionary = [self toDictionary];
    [coder encodeObject:dictionary forKey:@"modelData"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        NSDictionary *dictionary = [coder decodeObjectForKey:@"modelData"];
        if (dictionary) {
            [self yy_modelSetWithDictionary:dictionary];
        }
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    BaseModel *copy = [[[self class] allocWithZone:zone] init];
    NSDictionary *dictionary = [self toDictionary];
    [copy yy_modelSetWithDictionary:dictionary];
    return copy;
}

#pragma mark - 描述方法

- (NSString *)description {
    return [self modelDescription];
}

- (NSString *)debugDescription {
    return [self modelDescription];
}

@end
