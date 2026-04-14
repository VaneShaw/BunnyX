//
//  UserInfoManager.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "UserInfoManager.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"

@interface UserInfoManager ()

@property (nonatomic, strong) UserInfoModel *currentUserInfo;

@end

@implementation UserInfoManager

+ (instancetype)sharedManager {
    static UserInfoManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UserInfoManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 从本地加载用户信息
        [self loadUserInfoFromLocal];
    }
    return self;
}

#pragma mark - Public Methods

- (UserInfoModel *)getCurrentUserInfo {
    return self.currentUserInfo;
}

- (void)refreshUserInfoWithAccount:(NSString *)account
                           success:(UserInfoSuccessBlock)success
                           failure:(UserInfoFailureBlock)failure {
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (account && account.length > 0) {
        parameters[@"account"] = account;
    }
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_USER_INFO
                             parameters:parameters
                                success:^(id responseObject) {
        NSLog(@"[UserInfoManager] 获取用户信息成功: %@", responseObject);
        
        // 解析用户信息
        UserInfoModel *userInfo = [UserInfoModel yy_modelWithJSON:responseObject[@"data"]];
        if (userInfo) {
            // 如果是当前用户，保存到本地
            if (!account || account.length == 0) {
                self.currentUserInfo = userInfo;
                [self saveUserInfoToLocal:userInfo];
            }
            
            if (success) {
                success(userInfo);
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"UserInfoError" 
                                                 code:-1001 
                                             userInfo:@{NSLocalizedDescriptionKey: @"用户信息解析失败"}];
            if (failure) {
                failure(error);
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"[UserInfoManager] 获取用户信息失败: %@", error);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)refreshCurrentUserInfoWithSuccess:(UserInfoSuccessBlock)success
                                  failure:(UserInfoFailureBlock)failure {
    [self refreshUserInfoWithAccount:nil success:success failure:failure];
}

- (void)clearUserInfo {
    self.currentUserInfo = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BunnyxCurrentUserInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"[UserInfoManager] 清除用户信息成功");
}

#pragma mark - Private Methods

- (void)loadUserInfoFromLocal {
    NSData *userInfoData = [[NSUserDefaults standardUserDefaults] objectForKey:@"BunnyxCurrentUserInfo"];
    if (userInfoData) {
        NSDictionary *userInfoDict = [NSKeyedUnarchiver unarchiveObjectWithData:userInfoData];
        if (userInfoDict && [userInfoDict isKindOfClass:[NSDictionary class]]) {
            self.currentUserInfo = [UserInfoModel yy_modelWithJSON:userInfoDict];
            NSLog(@"[UserInfoManager] 从本地加载用户信息成功");
        }
    }
}

- (void)saveUserInfoToLocal:(UserInfoModel *)userInfo {
    if (userInfo) {
        NSDictionary *userInfoDict = [userInfo yy_modelToJSONObject];
        NSData *userInfoData = [NSKeyedArchiver archivedDataWithRootObject:userInfoDict];
        [[NSUserDefaults standardUserDefaults] setObject:userInfoData forKey:@"BunnyxCurrentUserInfo"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"[UserInfoManager] 保存用户信息到本地成功");
    }
}

#pragma mark - 便捷访问方法

// 基本信息
- (NSNumber *)getUserId {
    return self.currentUserInfo.userId;
}

- (NSString *)getAccount {
    return self.currentUserInfo.account ?: @"";
}

- (NSString *)getNickname {
    return self.currentUserInfo.nickname ?: @"";
}

- (NSString *)getAvatar {
    return self.currentUserInfo.avatar ?: @"";
}

- (NSNumber *)getLevel {
    return self.currentUserInfo.level ?: @0;
}

- (NSString *)getSignature {
    return self.currentUserInfo.signature ?: @"";
}

- (NSString *)getRoleName {
    return self.currentUserInfo.roleName ?: @"";
}

- (NSString *)getRealName {
    return self.currentUserInfo.realName ?: @"";
}

- (NSString *)getCity {
    return self.currentUserInfo.city ?: @"";
}

- (NSString *)getInviteCode {
    return self.currentUserInfo.inviteCode ?: @"";
}

// 社交信息
- (NSNumber *)getFansNum {
    return self.currentUserInfo.fansNum ?: @0;
}

- (NSNumber *)getFollowNum {
    return self.currentUserInfo.followNum ?: @0;
}

- (NSString *)getCountry {
    return self.currentUserInfo.country ?: @"";
}

- (NSString *)getProvince {
    return self.currentUserInfo.province ?: @"";
}

- (NSNumber *)getInviteNum {
    return self.currentUserInfo.inviteNum ?: @0;
}

- (NSNumber *)getChatNum {
    return self.currentUserInfo.chatNum ?: @0;
}

// 消费信息
- (NSNumber *)getTotalConsume {
    return self.currentUserInfo.totalConsume ?: @0;
}

- (NSNumber *)getTotalTicket {
    return self.currentUserInfo.totalTicket ?: @0;
}

- (NSNumber *)getSurplusDiamond {
    return self.currentUserInfo.surplusDiamond ?: @0;
}

- (NSNumber *)getSurplusMxdDiamond {
    return self.currentUserInfo.surplusMxdDiamond ?: @0;
}

- (NSNumber *)getSurplusMxpDiamond {
    return self.currentUserInfo.surplusMxpDiamond ?: @0;
}

// 状态信息
- (BOOL)isVip {
    return self.currentUserInfo.isVip;
}

- (NSNumber *)getVipEndTime {
    return self.currentUserInfo.vipEndTime ?: @0;
}

- (NSString *)getEmail {
    return self.currentUserInfo.email ?: @"";
}

- (BOOL)isBlack {
    return self.currentUserInfo.isBlack;
}

- (BOOL)isWhiteUser {
    return self.currentUserInfo.isWhiteUser;
}

- (BOOL)isPerfectInfo {
    return self.currentUserInfo.isPerfectInfo;
}

- (NSString *)getCareer {
    return self.currentUserInfo.career ?: @"";
}

- (NSString *)getConstellate {
    return self.currentUserInfo.constellate ?: @"";
}

@end
