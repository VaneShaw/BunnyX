//
//  DeviceIdentifierManager.h
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeviceIdentifierManager : NSObject

+ (instancetype)sharedManager;

/**
 * 获取设备唯一标识符
 * 使用 Keychain 存储，卸载重装后保持一致
 * @return 设备唯一标识符
 */
- (NSString *)getDeviceUUID;

/**
 * 获取 IDFV (Identifier for Vendor)
 * 同一开发者的应用间保持一致
 * @return IDFV 字符串
 */
- (NSString *)getIDFV;

/**
 * 获取设备信息
 * @return 设备信息字典
 */
- (NSDictionary *)getDeviceInfo;

@end

NS_ASSUME_NONNULL_END
