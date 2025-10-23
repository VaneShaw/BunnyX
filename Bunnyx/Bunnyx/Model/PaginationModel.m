//
//  PaginationModel.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "PaginationModel.h"
#import "BunnyxMacros.h"

@implementation PaginationModel

#pragma mark - 便利方法

- (BOOL)isFirstPage {
    return self.currentPage <= 1;
}

- (BOOL)isLastPage {
    return self.currentPage >= self.totalPages;
}

- (NSInteger)getNextPageNumber {
    return self.hasNextPage ? (self.currentPage + 1) : -1;
}

- (NSInteger)getPreviousPageNumber {
    return self.hasPreviousPage ? (self.currentPage - 1) : -1;
}

- (NSString *)paginationDescription {
    return [NSString stringWithFormat:@"第 %ld/%ld 页，共 %ld 条记录", 
            (long)self.currentPage, (long)self.totalPages, (long)self.totalCount];
}

#pragma mark - 验证方法重写

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    // 验证当前页码
    if (self.currentPage < 1) {
        [errors addObject:@"当前页码必须大于0"];
    }
    
    // 验证每页数量
    if (self.pageSize < 1) {
        [errors addObject:@"每页数量必须大于0"];
    } else if (self.pageSize > BUNNYX_PAGE_SIZE_MAX) {
        [errors addObject:[NSString stringWithFormat:@"每页数量不能超过%ld", (long)BUNNYX_PAGE_SIZE_MAX]];
    }
    
    // 验证总页数
    if (self.totalPages < 0) {
        [errors addObject:@"总页数不能为负数"];
    }
    
    // 验证总记录数
    if (self.totalCount < 0) {
        [errors addObject:@"总记录数不能为负数"];
    }
    
    // 验证当前页码与总页数的关系
    if (self.currentPage > self.totalPages && self.totalPages > 0) {
        [errors addObject:@"当前页码不能大于总页数"];
    }
    
    return [errors copy];
}

#pragma mark - 描述方法

- (NSString *)modelDescription {
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"<%@: %p>", NSStringFromClass([self class]), self];
    [description appendFormat:@"\n当前页码: %ld", (long)self.currentPage];
    [description appendFormat:@"\n每页数量: %ld", (long)self.pageSize];
    [description appendFormat:@"\n总页数: %ld", (long)self.totalPages];
    [description appendFormat:@"\n总记录数: %ld", (long)self.totalCount];
    [description appendFormat:@"\n是否有下一页: %@", self.hasNextPage ? @"是" : @"否"];
    [description appendFormat:@"\n是否有上一页: %@", self.hasPreviousPage ? @"是" : @"否"];
    [description appendFormat:@"\n分页描述: %@", [self paginationDescription]];
    return [description copy];
}

@end
