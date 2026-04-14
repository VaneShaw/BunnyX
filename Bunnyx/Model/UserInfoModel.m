//
//  UserInfoModel.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "UserInfoModel.h"

@implementation UserInfoExtend

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"msgLimit": @"msgLimit"
    };
}

@end

@implementation UserInfoModel

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        // 基本信息
        @"userId": @"userId",
        @"account": @"account",
        @"nickname": @"nickname",
        @"sex": @"sex",
        @"avatar": @"avatar",
        @"level": @"level",
        @"signature": @"signature",
        @"role": @"role",
        @"roleName": @"roleName",
        @"isAnchor": @"isAnchor",
        @"isConnect": @"isConnect",
        @"inviteLevel": @"inviteLevel",
        @"parentId": @"parentId",
        @"realName": @"realName",
        @"city": @"city",
        @"birthday": @"birthday",
        @"cid": @"cid",
        @"experience": @"experience",
        @"inviteCode": @"inviteCode",
        @"userState": @"userState",
        @"addTime": @"addTime",
        
        // 社交信息
        @"fansNum": @"fansNum",
        @"followNum": @"followNum",
        @"langName": @"langName",
        @"country": @"country",
        @"countryId": @"countryId",
        @"province": @"province",
        @"provinceId": @"provinceId",
        @"cityId": @"cityId",
        @"backGround": @"backGround",
        @"channel": @"channel",
        @"tripartiteId": @"tripartiteId",
        @"isDel": @"isDel",
        @"alliance": @"alliance",
        @"allianceSort": @"allianceSort",
        @"openId": @"openId",
        @"isCanComment": @"isCanComment",
        @"inviteNum": @"inviteNum",
        @"chatNum": @"chatNum",
        @"num": @"num",
        @"equipmentBrand": @"equipmentBrand",
        @"realCountry": @"realCountry",
        @"followState": @"followState",
        
        // 消费信息
        @"totalConsume": @"totalConsume",
        @"totalTicket": @"totalTicket",
        @"surplusDiamond": @"surplusDiamond",
        @"surplusMxdDiamond": @"surplusMxdDiamond",
        @"surplusMxpDiamond": @"surplusMxpDiamond",
        @"isEditAccount": @"isEditAccount",
        
        // 扩展信息
        @"extend": @"extend",
        
        // 状态信息
        @"isBlack": @"isBlack",
        @"subExp": @"subExp",
        @"cancelApply": @"cancelApply",
        @"isBingEmail": @"isBingEmail",
        @"isWhiteUser": @"isWhiteUser",
        @"isPerfectInfo": @"isPerfectInfo",
        @"career": @"career",
        @"constellate": @"constellate",
        @"email": @"email",
        @"isVip": @"isVip",
        @"vipEndTime": @"vipEndTime",
        @"fillInInviteCode": @"fillInInviteCode",
        @"presetInviteCode": @"presetInviteCode",
        @"jwtToken": @"jwtToken",
        @"isEnableExternalAdv": @"isEnableExternalAdv",
        @"isEnableGoogleAdv": @"isEnableGoogleAdv",
        @"bingEmail": @"bingEmail",
        @"showRtc": @"showRtc",
        @"perfectInfo": @"perfectInfo",
        @"vip": @"vip",
        @"recommend": @"recommend",
        @"identify": @"identify"
    };
}

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"extend": [UserInfoExtend class]
    };
}

@end
