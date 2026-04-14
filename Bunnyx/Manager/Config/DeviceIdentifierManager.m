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

- (NSString *)getValueFromKeychainForKey:(NSString *)key {
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrAccount: key,
        (__bridge NSString *)kSecReturnData: (__bridge id)kCFBooleanTrue,
        (__bridge NSString *)kSecMatchLimit: (__bridge NSString *)kSecMatchLimitOne
    };
    
    CFDataRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataRef);
    
    if (status == errSecSuccess && dataRef) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return value;
    }
    
    return nil;
}

- (BOOL)saveValueToKeychain:(NSString *)value forKey:(NSString *)key {
    // 先删除已存在的项
    [self deleteValueFromKeychainForKey:key];
    
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrAccount: key,
        (__bridge NSString *)kSecValueData: data,
        (__bridge NSString *)kSecAttrAccessible: (__bridge NSString *)kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    };
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    
    if (status == errSecSuccess) {
        NSLog(@"[DeviceIdentifierManager] 成功保存到 Keychain: %@", key);
        return YES;
    } else {
        NSLog(@"[DeviceIdentifierManager] 保存到 Keychain 失败: %@, 错误码: %d", key, (int)status);
        return NO;
    }
}

- (BOOL)deleteValueFromKeychainForKey:(NSString *)key {
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrAccount: key
    };
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    
    if (status == errSecSuccess || status == errSecItemNotFound) {
        return YES;
    } else {
        NSLog(@"[DeviceIdentifierManager] 从 Keychain 删除失败: %@, 错误码: %d", key, (int)status);
        return NO;
    }
}

@end
