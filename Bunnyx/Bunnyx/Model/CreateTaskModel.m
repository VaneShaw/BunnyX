//
//  CreateTaskModel.m
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import "CreateTaskModel.h"

@implementation CreateTaskModel

+ (NSArray<CreateTaskModel *> *)modelsFromResponse:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        CreateTaskModel *m = [[CreateTaskModel alloc] init];
        m.createId = [dict[@"createId"] isKindOfClass:[NSString class]] ? dict[@"createId"] : @"";
        m.userId = [dict[@"userId"] integerValue];
        m.materialId = [dict[@"materialId"] integerValue];
        m.initialImage = [dict[@"initImage"] isKindOfClass:[NSString class]] ? dict[@"initImage"] : @"";
        m.addDate = [dict[@"addDate"] isKindOfClass:[NSString class]] ? dict[@"addDate"] : @"";
        m.completeDate = [dict[@"completeDate"] isKindOfClass:[NSString class]] ? dict[@"completeDate"] : @"";
        m.status = [dict[@"status"] integerValue];
        m.position = dict[@"position"];
        m.imageUrl = [dict[@"imageUrl"] isKindOfClass:[NSString class]] ? dict[@"imageUrl"] : @"";
        m.videoUrl = [dict[@"videoUrl"] isKindOfClass:[NSString class]] ? dict[@"videoUrl"] : @"";
        m.executionDuration = [dict[@"executionDuration"] isKindOfClass:[NSString class]] ? dict[@"executionDuration"] : @"";
        m.error = [dict[@"error"] isKindOfClass:[NSString class]] ? dict[@"error"] : @"";
        m.progress = [dict[@"progress"] integerValue];
        m.typeRemark = [dict[@"typeRemark"] isKindOfClass:[NSString class]] ? dict[@"typeRemark"] : @"";
        m.statusRemark = [dict[@"statusRemark"] isKindOfClass:[NSString class]] ? dict[@"statusRemark"] : @"";
        m.positionRemark = [dict[@"positionRemark"] isKindOfClass:[NSString class]] ? dict[@"positionRemark"] : @"";
        m.onlyVip = [dict[@"onlyVip"] integerValue];
        [result addObject:m];
    }
    return result.copy;
}

@end

