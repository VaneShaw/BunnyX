//
//  APIResponseModel.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * API响应模型基类
 * 用于处理服务器返回的通用响应格式
 */
@interface APIResponseModel : BaseModel

/// 响应码
@property (nonatomic, assign) NSInteger code;

/// 响应消息
@property (nonatomic, strong) NSString *message;

/// 响应数据
@property (nonatomic, strong) id data;

/// 时间戳
@property (nonatomic, strong) NSString *timestamp;

/// 请求ID
@property (nonatomic, strong) NSString *requestId;

#pragma mark - 便利方法

/**
 * 检查响应是否成功
 * @return 是否成功
 */
- (BOOL)isSuccess;

/**
 * 获取错误信息
 * @return 错误信息
 */
- (NSString *)errorMessage;

/**
 * 获取数据字典
 * @return 数据字典
 */
- (NSDictionary *)dataDictionary;

/**
 * 获取数据数组
 * @return 数据数组
 */
- (NSArray *)dataArray;

/**
 * 获取数据字符串
 * @return 数据字符串
 */
- (NSString *)dataString;

@end

NS_ASSUME_NONNULL_END
