//
//  HostEnvironmentManager.h
//  Bunnyx
//
//  Created by Assistant on 2025/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BXHostEnvironmentType) {
    BXHostEnvironmentTypeProduction = 0,
    BXHostEnvironmentTypeTest = 1,
    BXHostEnvironmentTypeCustom = 2,
};

FOUNDATION_EXPORT NSString * const BXHostEnvironmentDidChangeNotification;

@interface HostEnvironmentManager : NSObject

@property (nonatomic, assign, readonly) BXHostEnvironmentType currentEnvironment;
@property (nonatomic, copy, readonly) NSString *currentBaseURL;
@property (nonatomic, copy, readonly) NSString *customBaseURL;

+ (instancetype)sharedManager;

- (void)switchToEnvironment:(BXHostEnvironmentType)environment
                   customURL:(NSString * _Nullable)customURL;

@end

NS_ASSUME_NONNULL_END

