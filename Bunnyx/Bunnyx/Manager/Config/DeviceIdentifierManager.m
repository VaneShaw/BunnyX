//
//  DeviceIdentifierManager.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "DeviceIdentifierManager.h"
#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import "BunnyxNetworkMacros.h"

@interface DeviceIdentifierManager ()

@end

@implementation DeviceIdentifierManager

+ (instancetype)sharedManager {
    static DeviceIdentifierManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DeviceIdentifierManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化时确保 UUID 存在
        [self getDeviceUUID];
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)getDeviceUUID {
    // 先从 Keychain 中获取
    NSString *uuid = [self getValueFromKeychainForKey:BUNNYX_DEVICE_UUID_KEY];
    
    if (!uuid || uuid.length == 0) {
        // 如果 Keychain 中没有，生成新的 UUID
        uuid = [[NSUUID UUID] UUIDString];
        
        // 保存到 Keychain
        [self saveValueToKeychain:uuid forKey:BUNNYX_DEVICE_UUID_KEY];
        
        NSLog(@"[DeviceIdentifierManager] 生成新的设备 UUID: %@", uuid);
    } else {
        NSLog(@"[DeviceIdentifierManager] 从 Keychain 获取设备 UUID: %@", uuid);
    }
    
    return uuid;
}

- (NSString *)getIDFV {
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSLog(@"[DeviceIdentifierManager] IDFV: %@", idfv);
    return idfv;
}

- (NSDictionary *)getDeviceInfo {
    UIDevice *device = [UIDevice currentDevice];
    
    NSMutableDictionary *deviceInfo = [NSMutableDictionary dictionary];
    deviceInfo[@"uuid"] = [self getDeviceUUID];
    deviceInfo[@"idfv"] = [self getIDFV];
    deviceInfo[@"model"] = device.model;
    deviceInfo[@"name"] = device.name;
    deviceInfo[@"systemName"] = device.systemName;
    deviceInfo[@"systemVersion"] = device.systemVersion;
    deviceInfo[@"batteryLevel"] = @(device.batteryLevel);
    deviceInfo[@"batteryState"] = @(device.batteryState);
    
    // 屏幕信息
    UIScreen *screen = [UIScreen mainScreen];
    deviceInfo[@"screenScale"] = @(screen.scale);
    deviceInfo[@"screenBounds"] = NSStringFromCGRect(screen.bounds);
    
    // 应用信息
    NSBundle *bundle = [NSBundle mainBundle];
    deviceInfo[@"appVersion"] = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    deviceInfo[@"buildVersion"] = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    deviceInfo[@"bundleIdentifier"] = [bundle bundleIdentifier];
    
    NSLog(@"[DeviceIdentifierManager] 设备信息: %@", deviceInfo);
    return [deviceInfo copy];
}

#pragma mark - Keychain Methods

/**
 * 获取Bundle Identifier作为Keychain Service标识符
 * 确保跨版本读取的一致性
 */
- (NSString *)keychainService {
    static NSString *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        service = [bundle bundleIdentifier];
        if (!service || service.length == 0) {
            // 如果Bundle Identifier为空，使用固定值
            service = @"com.bunnyx.ai";
        }
        NSLog(@"[DeviceIdentifierManager] Keychain Service: %@", service);
    });
    return service;
}

- (NSString *)getValueFromKeychainForKey:(NSString *)key {
    NSString *service = [self keychainService];
    
    // 首先尝试使用Service读取（新版本方式）
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: service,
        (__bridge NSString *)kSecAttrAccount: key,
        (__bridge NSString *)kSecReturnData: (__bridge id)kCFBooleanTrue,
        (__bridge NSString *)kSecMatchLimit: (__bridge NSString *)kSecMatchLimitOne
    };
    
    CFDataRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataRef);
    
    if (status == errSecSuccess && dataRef) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[DeviceIdentifierManager] 从 Keychain 成功读取: %@, Service: %@", key, service);
        return value;
    }
    
    // 如果使用Service读取失败，尝试不使用Service读取（兼容旧版本1.0.2）
    NSLog(@"[DeviceIdentifierManager] 使用Service读取失败，尝试兼容旧版本方式读取: %@, 错误码: %d", key, (int)status);
    
    NSDictionary *legacyQuery = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrAccount: key,
        (__bridge NSString *)kSecReturnData: (__bridge id)kCFBooleanTrue,
        (__bridge NSString *)kSecMatchLimit: (__bridge NSString *)kSecMatchLimitOne
    };
    
    dataRef = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)legacyQuery, (CFTypeRef *)&dataRef);
    
    if (status == errSecSuccess && dataRef) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[DeviceIdentifierManager] 从 Keychain 成功读取（兼容旧版本）: %@", key);
        
        // 如果从旧版本读取成功，使用新方式重新保存，确保后续读取使用新方式
        [self saveValueToKeychain:value forKey:key];
        NSLog(@"[DeviceIdentifierManager] 已将旧版本数据迁移到新格式: %@", key);
        
        return value;
    } else {
        NSLog(@"[DeviceIdentifierManager] 从 Keychain 读取失败: %@, 错误码: %d", key, (int)status);
    }
    
    return nil;
}

- (BOOL)saveValueToKeychain:(NSString *)value forKey:(NSString *)key {
    NSString *service = [self keychainService];
    
    // 先删除已存在的项（使用相同的Service和Account）
    [self deleteValueFromKeychainForKey:key];
    
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: service,
        (__bridge NSString *)kSecAttrAccount: key,
        (__bridge NSString *)kSecValueData: data,
        (__bridge NSString *)kSecAttrAccessible: (__bridge NSString *)kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    };
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    
    if (status == errSecSuccess) {
        NSLog(@"[DeviceIdentifierManager] 成功保存到 Keychain: %@, Service: %@", key, service);
        return YES;
    } else {
        NSLog(@"[DeviceIdentifierManager] 保存到 Keychain 失败: %@, Service: %@, 错误码: %d", key, service, (int)status);
        return NO;
    }
}

- (BOOL)deleteValueFromKeychainForKey:(NSString *)key {
    NSString *service = [self keychainService];
    BOOL success = YES;
    
    // 先尝试删除新版本格式的数据（使用Service）
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: service,
        (__bridge NSString *)kSecAttrAccount: key
    };
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status != errSecSuccess && status != errSecItemNotFound) {
        NSLog(@"[DeviceIdentifierManager] 删除新版本格式失败: %@, Service: %@, 错误码: %d", key, service, (int)status);
        success = NO;
    }
    
    // 再尝试删除旧版本格式的数据（不使用Service，兼容旧版本）
    NSDictionary *legacyQuery = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrAccount: key
    };
    
    status = SecItemDelete((__bridge CFDictionaryRef)legacyQuery);
    if (status != errSecSuccess && status != errSecItemNotFound) {
        NSLog(@"[DeviceIdentifierManager] 删除旧版本格式失败: %@, 错误码: %d", key, (int)status);
        success = NO;
    }
    
    return success;
}

@end
