//
//  MaterialItemModel.h
//  Bunnyx
//

#import <Foundation/Foundation.h>

@interface MaterialItemModel : NSObject

@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, copy) NSString *materialUrl;
@property (nonatomic, assign) NSInteger materialMode; // 0换脸 1换衣 2视频
@property (nonatomic, copy) NSString *materialFormat;
@property (nonatomic, assign) NSInteger materialSexy;
@property (nonatomic, assign) NSInteger generatePrice;
@property (nonatomic, assign) NSInteger materialType;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, strong) NSNumber *favoriteQty; // 可能为null

+ (NSArray<MaterialItemModel *> *)modelsFromResponse:(NSArray *)array;

@end


