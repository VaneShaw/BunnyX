# Bunnyx Model 基类使用指南

## 概述

本项目提供了一套完整的模型基类系统，基于 YYModel 库构建，为 iOS 应用提供强大的数据模型功能。

## 文件结构

```
Model/
├── BaseModel.h/m              # 模型基类
├── UserInfoModel.h/m          # 用户信息模型
├── APIResponseModel.h/m       # API响应模型
├── PaginationModel.h/m        # 分页模型
├── ModelUsageExample.m        # 使用示例
└── README.md                  # 说明文档
```

## 核心功能

### BaseModel 基类

`BaseModel` 是所有模型的基类，提供以下功能：

#### 初始化方法
- `+modelWithDictionary:` - 通过字典初始化
- `+modelWithJSONString:` - 通过JSON字符串初始化
- `+modelWithJSONData:` - 通过JSON数据初始化

#### 转换方法
- `-toDictionary` - 转换为字典
- `-toJSONString` - 转换为JSON字符串
- `-toJSONData` - 转换为JSON数据

#### 批量转换方法
- `+modelArrayWithDictionaryArray:` - 字典数组转模型数组
- `+dictionaryArrayWithModelArray:` - 模型数组转字典数组
- `+jsonStringWithModelArray:` - 模型数组转JSON字符串

#### 验证方法
- `-isValid` - 检查模型是否有效
- `-validationErrors` - 获取验证错误信息

#### 其他功能
- 支持 NSCoding 协议（归档/解档）
- 支持 NSCopying 协议（拷贝）
- 提供调试描述方法

### 子类模型

#### UserInfoModel - 用户信息模型
```objc
// 创建用户模型
NSDictionary *userDict = @{
    @"userId": @12345,
    @"account": @"testuser",
    @"nickname": @"测试用户",
    @"email": @"test@example.com",
    @"sex": @1,
    @"userState": @0,
    @"isVip": @YES
};

UserInfoModel *user = [UserInfoModel modelWithDictionary:userDict];
```

#### APIResponseModel - API响应模型
```objc
// 处理API响应
NSDictionary *responseDict = @{
    @"code": @200,
    @"message": @"成功",
    @"data": @{@"userId": @"12345"},
    @"timestamp": @"2025-11-30 12:00:00"
};

APIResponseModel *response = [APIResponseModel modelWithDictionary:responseDict];

// 检查响应状态
if ([response isSuccess]) {
    NSDictionary *data = [response dataDictionary];
    // 处理成功数据
} else {
    NSString *errorMsg = [response errorMessage];
    // 处理错误信息
}
```

#### PaginationModel - 分页模型
```objc
// 处理分页数据
NSDictionary *paginationDict = @{
    @"currentPage": @2,
    @"pageSize": @20,
    @"totalPages": @10,
    @"totalCount": @200
};

PaginationModel *pagination = [PaginationModel modelWithDictionary:paginationDict];

// 使用分页便利方法
BOOL isFirst = [pagination isFirstPage];           // NO
BOOL isLast = [pagination isLastPage];             // NO
NSInteger nextPage = [pagination getNextPageNumber]; // 3
NSString *desc = [pagination paginationDescription];  // "第 2/10 页，共 200 条记录"
```

## 使用示例

### 基本使用

```objc
// 1. 创建模型
UserInfoModel *user = [UserInfoModel modelWithDictionary:userDict];

// 2. 验证模型
if ([user isValid]) {
    // 模型有效，可以使用
    NSLog(@"用户: %@", user.nickname);
} else {
    // 模型无效，处理错误
    NSArray *errors = [user validationErrors];
    NSLog(@"验证错误: %@", errors);
}

// 3. 转换为JSON
NSString *jsonString = [user toJSONString];
NSLog(@"JSON: %@", jsonString);
```

### 批量处理

```objc
// 字典数组转模型数组
NSArray *userDicts = @[dict1, dict2, dict3];
NSArray *users = [UserModel modelArrayWithDictionaryArray:userDicts];

// 模型数组转JSON
NSString *jsonString = [UserModel jsonStringWithModelArray:users];
```

### 网络请求集成

```objc
// 在 NetworkManager 中使用
[[NetworkManager sharedManager] GET:url parameters:params success:^(id responseObject) {
    APIResponseModel *response = [APIResponseModel modelWithDictionary:responseObject];
    
    if ([response isSuccess]) {
        NSArray *userDicts = [response dataArray];
        NSArray *users = [UserInfoModel modelArrayWithDictionaryArray:userDicts];
        // 处理用户数据
    } else {
        NSString *errorMsg = [response errorMessage];
        // 处理错误
    }
} failure:^(NSError *error) {
    // 处理网络错误
}];
```

## 自定义模型

创建自定义模型时，继承 `BaseModel` 并重写验证方法：

```objc
// MyCustomModel.h
@interface MyCustomModel : BaseModel
@property (nonatomic, strong) NSString *customProperty;
@end

// MyCustomModel.m
@implementation MyCustomModel

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    // 添加自定义验证逻辑
    if (BUNNYX_IS_EMPTY_STRING(self.customProperty)) {
        [errors addObject:@"自定义属性不能为空"];
    }
    
    return [errors copy];
}

@end
```

## 注意事项

1. **依赖库**: 确保项目中已集成 YYModel 库
2. **宏定义**: 使用项目中的 BunnyxMacros.h 中定义的宏
3. **内存管理**: 模型对象遵循 ARC 内存管理
4. **线程安全**: 模型对象不是线程安全的，多线程访问时需要注意
5. **性能**: 大量数据转换时建议在后台线程进行

## 扩展功能

可以根据项目需要扩展以下功能：

1. **数据库集成**: 添加 Core Data 或 FMDB 支持
2. **缓存机制**: 集成 YYCache 进行本地缓存
3. **网络同步**: 与 NetworkManager 深度集成
4. **数据验证**: 添加更复杂的验证规则
5. **国际化**: 支持多语言错误信息

## 运行示例

要查看完整的使用示例，可以调用：

```objc
[NSObject runAllExamples];
```

这将运行所有模型使用示例，帮助理解各种功能的使用方法。
