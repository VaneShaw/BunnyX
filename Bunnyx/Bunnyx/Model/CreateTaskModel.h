//
//  CreateTaskModel.h
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 生成任务模型
 * 状态: 0:等待进入队列 1:排队中 2:生成中 3:生成成功 4:生成失败 5:生成不存在
 */
@interface CreateTaskModel : NSObject

@property (nonatomic, copy) NSString *createId;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, copy) NSString *initialImage; // 用户上传图片URL (对应API的initImage字段)
@property (nonatomic, copy) NSString *addDate;
@property (nonatomic, copy) NSString *completeDate;
@property (nonatomic, assign) NSInteger status; // 0:等待进入队列 1:排队中 2:生成中 3:生成成功 4:生成失败 5:生成不存在
@property (nonatomic, strong) NSNumber *position; // 排队位置（排队中状态返回）
@property (nonatomic, copy) NSString *imageUrl; // 图片URL或视频封面URL（生成成功状态返回）
@property (nonatomic, copy) NSString *videoUrl; // 视频URL（视频类型，生成成功状态返回）
@property (nonatomic, copy) NSString *executionDuration; // 生成时间（秒，生成成功状态返回）
@property (nonatomic, copy) NSString *error; // 错误信息（生成失败状态返回）
@property (nonatomic, assign) NSInteger progress; // 进度，1为100%
@property (nonatomic, copy) NSString *typeRemark; // 生成列表的标题
@property (nonatomic, copy) NSString *statusRemark; // 生成列表的状态标签
@property (nonatomic, copy) NSString *positionRemark; // 生成列表的排队进度

+ (NSArray<CreateTaskModel *> *)modelsFromResponse:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END

