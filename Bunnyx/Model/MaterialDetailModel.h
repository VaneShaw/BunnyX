//
//  MaterialDetailModel.h
//  Bunnyx
//
//

#import "MaterialItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MaterialDetailModel : MaterialItemModel

@property (nonatomic, copy) NSString *addDate;
@property (nonatomic, copy) NSString *lastSyncTime;
@property (nonatomic, assign) NSInteger isEnable;
@property (nonatomic, copy) NSString *favoriteDate;

+ (instancetype)modelFromResponse:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
