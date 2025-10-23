//
//  BaseModel.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 模型基类
 * 提供JSON序列化、字典转换、归档等基础功能
 */
@interface BaseModel : NSObject <NSCoding, NSCopying>

#pragma mark - 初始化方法

/**
 * 通过字典初始化模型
 * @param dictionary 字典数据
 * @return 模型实例
 */
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

/**
 * 通过JSON字符串初始化模型
 * @param jsonString JSON字符串
 * @return 模型实例
 */
+ (instancetype)modelWithJSONString:(NSString *)jsonString;

/**
 * 通过JSON数据初始化模型
 * @param jsonData JSON数据
 * @return 模型实例
 */
+ (instancetype)modelWithJSONData:(NSData *)jsonData;

#pragma mark - 转换方法

/**
 * 转换为字典
 * @return 字典对象
 */
- (NSDictionary *)toDictionary;

/**
 * 转换为JSON字符串
 * @return JSON字符串
 */
- (NSString *)toJSONString;

/**
 * 转换为JSON数据
 * @return JSON数据
 */
- (NSData *)toJSONData;

#pragma mark - 批量转换方法

/**
 * 字典数组转模型数组
 * @param dictionaryArray 字典数组
 * @return 模型数组
 */
+ (NSArray *)modelArrayWithDictionaryArray:(NSArray<NSDictionary *> *)dictionaryArray;

/**
 * 模型数组转字典数组
 * @param modelArray 模型数组
 * @return 字典数组
 */
+ (NSArray<NSDictionary *> *)dictionaryArrayWithModelArray:(NSArray<BaseModel *> *)modelArray;

/**
 * 模型数组转JSON字符串
 * @param modelArray 模型数组
 * @return JSON字符串
 */
+ (NSString *)jsonStringWithModelArray:(NSArray<BaseModel *> *)modelArray;

#pragma mark - 验证方法

/**
 * 验证模型数据是否有效
 * @return 是否有效
 */
- (BOOL)isValid;

/**
 * 获取验证错误信息
 * @return 错误信息数组
 */
- (NSArray<NSString *> *)validationErrors;

#pragma mark - 调试方法

/**
 * 获取模型的描述信息
 * @return 描述字符串
 */
- (NSString *)modelDescription;

@end

NS_ASSUME_NONNULL_END
