//
//  VipListDataModel.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "BaseModel.h"
#import "VipItemModel.h"

NS_ASSUME_NONNULL_BEGIN

/// VIP列表数据Model
@interface VipListDataModel : BaseModel

/// VIP订阅项列表
@property (nonatomic, strong) NSArray<VipItemModel *> *list;

/// 是否首次购买（用于显示限时优惠弹窗）
@property (nonatomic, assign) BOOL firstBuy;

/// 从API响应创建Model
+ (instancetype)modelFromResponse:(NSDictionary *)response;

@end

NS_ASSUME_NONNULL_END



