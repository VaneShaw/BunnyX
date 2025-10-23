//
//  ModelUsageExample.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"
#import "UserModel.h"
#import "APIResponseModel.h"
#import "PaginationModel.h"
#import "BunnyxMacros.h"

/**
 * 模型使用示例
 * 展示如何使用BaseModel及其子类
 */

@implementation NSObject (ModelUsageExample)

#pragma mark - BaseModel 使用示例

+ (void)baseModelUsageExample {
    BUNNYX_LOG(@"=== BaseModel 使用示例 ===");
    
    // 1. 通过字典创建模型
    NSDictionary *userDict = @{
        @"userId": @"12345",
        @"username": @"testuser",
        @"nickname": @"测试用户",
        @"email": @"test@example.com",
        @"phone": @"13800138000",
        @"gender": @1,
        @"status": @0,
        @"isVip": @YES
    };
    
    UserModel *user = [UserModel modelWithDictionary:userDict];
    BUNNYX_LOG(@"创建的用户模型: %@", user);
    
    // 2. 转换为字典
    NSDictionary *dict = [user toDictionary];
    BUNNYX_LOG(@"转换的字典: %@", dict);
    
    // 3. 转换为JSON字符串
    NSString *jsonString = [user toJSONString];
    BUNNYX_LOG(@"JSON字符串: %@", jsonString);
    
    // 4. 验证模型
    BOOL isValid = [user isValid];
    BUNNYX_LOG(@"模型是否有效: %@", isValid ? @"是" : @"否");
    
    if (!isValid) {
        NSArray *errors = [user validationErrors];
        BUNNYX_LOG(@"验证错误: %@", errors);
    }
}

#pragma mark - 批量转换示例

+ (void)batchConversionExample {
    BUNNYX_LOG(@"=== 批量转换示例 ===");
    
    // 用户数组数据
    NSArray *userArray = @[
        @{@"userId": @"1", @"username": @"user1", @"nickname": @"用户1"},
        @{@"userId": @"2", @"username": @"user2", @"nickname": @"用户2"},
        @{@"userId": @"3", @"username": @"user3", @"nickname": @"用户3"}
    ];
    
    // 字典数组转模型数组
    NSArray *modelArray = [UserModel modelArrayWithDictionaryArray:userArray];
    BUNNYX_LOG(@"模型数组: %@", modelArray);
    
    // 模型数组转字典数组
    NSArray *dictArray = [UserModel dictionaryArrayWithModelArray:modelArray];
    BUNNYX_LOG(@"字典数组: %@", dictArray);
    
    // 模型数组转JSON字符串
    NSString *jsonString = [UserModel jsonStringWithModelArray:modelArray];
    BUNNYX_LOG(@"JSON字符串: %@", jsonString);
}

#pragma mark - API响应模型示例

+ (void)apiResponseExample {
    BUNNYX_LOG(@"=== API响应模型示例 ===");
    
    // 模拟API响应数据
    NSDictionary *responseDict = @{
        @"code": @200,
        @"message": @"成功",
        @"data": @{
            @"userId": @"12345",
            @"username": @"testuser",
            @"nickname": @"测试用户"
        },
        @"timestamp": @"2025-11-30 12:00:00",
        @"requestId": @"req_123456"
    };
    
    APIResponseModel *response = [APIResponseModel modelWithDictionary:responseDict];
    BUNNYX_LOG(@"API响应: %@", response);
    
    // 检查响应是否成功
    BOOL isSuccess = [response isSuccess];
    BUNNYX_LOG(@"响应是否成功: %@", isSuccess ? @"是" : @"否");
    
    if (isSuccess) {
        NSDictionary *dataDict = [response dataDictionary];
        BUNNYX_LOG(@"响应数据: %@", dataDict);
    } else {
        NSString *errorMsg = [response errorMessage];
        BUNNYX_LOG(@"错误信息: %@", errorMsg);
    }
}

#pragma mark - 分页模型示例

+ (void)paginationExample {
    BUNNYX_LOG(@"=== 分页模型示例 ===");
    
    // 分页数据
    NSDictionary *paginationDict = @{
        @"currentPage": @2,
        @"pageSize": @20,
        @"totalPages": @10,
        @"totalCount": @200,
        @"hasNextPage": @YES,
        @"hasPreviousPage": @YES
    };
    
    PaginationModel *pagination = [PaginationModel modelWithDictionary:paginationDict];
    BUNNYX_LOG(@"分页信息: %@", pagination);
    
    // 分页便利方法
    BUNNYX_LOG(@"是否为第一页: %@", [pagination isFirstPage] ? @"是" : @"否");
    BUNNYX_LOG(@"是否为最后一页: %@", [pagination isLastPage] ? @"是" : @"否");
    BUNNYX_LOG(@"下一页页码: %ld", (long)[pagination getNextPageNumber]);
    BUNNYX_LOG(@"上一页页码: %ld", (long)[pagination getPreviousPageNumber]);
    BUNNYX_LOG(@"分页描述: %@", [pagination paginationDescription]);
}

#pragma mark - 归档和拷贝示例

+ (void)archivingAndCopyingExample {
    BUNNYX_LOG(@"=== 归档和拷贝示例 ===");
    
    // 创建用户模型
    UserModel *originalUser = [UserModel modelWithDictionary:@{
        @"userId": @"12345",
        @"username": @"testuser",
        @"nickname": @"测试用户"
    }];
    
    // 拷贝模型
    UserModel *copiedUser = [originalUser copy];
    BUNNYX_LOG(@"原始用户: %@", originalUser);
    BUNNYX_LOG(@"拷贝用户: %@", copiedUser);
    
    // 归档模型
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:originalUser];
    BUNNYX_LOG(@"归档数据大小: %lu bytes", (unsigned long)archivedData.length);
    
    // 解档模型
    UserModel *unarchivedUser = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
    BUNNYX_LOG(@"解档用户: %@", unarchivedUser);
}

#pragma mark - 运行所有示例

+ (void)runAllExamples {
    BUNNYX_LOG(@"开始运行模型使用示例...");
    
    [self baseModelUsageExample];
    [self batchConversionExample];
    [self apiResponseExample];
    [self paginationExample];
    [self archivingAndCopyingExample];
    
    BUNNYX_LOG(@"模型使用示例运行完成！");
}

@end
