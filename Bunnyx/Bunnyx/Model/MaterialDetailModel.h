//
//  MaterialDetailModel.h
//  Bunnyx
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MaterialDetailModel : NSObject

@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, copy) NSString *materialUrl;
@property (nonatomic, assign) NSInteger materialMode; // 0:换脸 1:换衣 2:视频
@property (nonatomic, copy) NSString *materialFormat;
@property (nonatomic, assign) NSInteger materialSexy;
@property (nonatomic, copy) NSString *addDate;
@property (nonatomic, copy) NSString *lastSyncTime;
@property (nonatomic, assign) NSInteger isEnable;
@property (nonatomic, assign) NSInteger favoriteQty;
@property (nonatomic, assign) NSInteger generatePrice;
@property (nonatomic, assign) NSInteger materialType;
@property (nonatomic, copy) NSString *favoriteDate;
@property (nonatomic, assign) BOOL isFavorite;

+ (instancetype)modelFromResponse:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
