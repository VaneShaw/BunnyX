//
//  PaginationModel.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 分页模型
 * 用于处理分页相关的数据
 */
@interface PaginationModel : BaseModel

/// 当前页码
@property (nonatomic, assign) NSInteger currentPage;

/// 每页数量
@property (nonatomic, assign) NSInteger pageSize;

/// 总页数
@property (nonatomic, assign) NSInteger totalPages;

/// 总记录数
@property (nonatomic, assign) NSInteger totalCount;

/// 是否有下一页
@property (nonatomic, assign) BOOL hasNextPage;

/// 是否有上一页
@property (nonatomic, assign) BOOL hasPreviousPage;

/// 下一页页码
@property (nonatomic, assign) NSInteger nextPage;

/// 上一页页码
@property (nonatomic, assign) NSInteger previousPage;

#pragma mark - 便利方法

/**
 * 检查是否为第一页
 * @return 是否为第一页
 */
- (BOOL)isFirstPage;

/**
 * 检查是否为最后一页
 * @return 是否为最后一页
 */
- (BOOL)isLastPage;

/**
 * 获取下一页页码
 * @return 下一页页码，如果没有下一页返回-1
 */
- (NSInteger)getNextPageNumber;

/**
 * 获取上一页页码
 * @return 上一页页码，如果没有上一页返回-1
 */
- (NSInteger)getPreviousPageNumber;

/**
 * 获取分页描述信息
 * @return 分页描述字符串
 */
- (NSString *)paginationDescription;

@end

NS_ASSUME_NONNULL_END
