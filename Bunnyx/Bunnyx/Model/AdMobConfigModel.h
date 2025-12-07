//
//  AdMobConfigModel.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * AdMob广告配置模型
 */
@interface AdMobConfigModel : BaseModel

/// 广告位：0:开屏，1：签到，2：充值
@property (nonatomic, assign) NSInteger adPlacement;

/// 广告类型：0:开屏广告 1：激励广告
@property (nonatomic, assign) NSInteger adType;

/// 广告单元ID
@property (nonatomic, strong) NSString *adUnitId;

/// 奖励金额数量，广告类型adType=1激励广告才有值
@property (nonatomic, assign) NSInteger rewardCoins;

/// 最大奖励次数(即可观看广告获取奖励的次数, 目前仅充值广告位且类型为激励广告才有控制次数)
@property (nonatomic, assign) NSInteger rewardMaxCount;

@end

NS_ASSUME_NONNULL_END

