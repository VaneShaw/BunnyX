//
//  MaterialTypeModel.h
//  Bunnyx
//

#import <Foundation/Foundation.h>

@interface MaterialTypeModel : NSObject

@property (nonatomic, assign) NSInteger typeId;
@property (nonatomic, copy) NSString *typeNameRaw; // JSON string
@property (nonatomic, assign) NSInteger typeSexy;
@property (nonatomic, copy) NSString *sort;
@property (nonatomic, copy) NSString *remark;

// Convenience
- (NSString *)displayName;

+ (NSArray<MaterialTypeModel *> *)modelsFromResponse:(NSArray *)array;

@end


