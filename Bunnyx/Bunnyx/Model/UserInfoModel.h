//
//  UserInfoModel.h
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserInfoExtend : BaseModel

@property (nonatomic, strong) NSNumber *msgLimit;

@end

@interface UserInfoModel : BaseModel

// 基本信息
@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, strong) NSNumber *sex;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, strong) NSNumber *level;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, strong) NSNumber *role;
@property (nonatomic, copy) NSString *roleName;
@property (nonatomic, strong) NSNumber *isAnchor;
@property (nonatomic, strong) NSNumber *isConnect;
@property (nonatomic, strong) NSNumber *inviteLevel;
@property (nonatomic, strong) NSNumber *parentId;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, strong) NSNumber *birthday;
@property (nonatomic, copy) NSString *cid;
@property (nonatomic, strong) NSNumber *experience;
@property (nonatomic, copy) NSString *inviteCode;
@property (nonatomic, strong) NSNumber *userState;
@property (nonatomic, strong) NSNumber *addTime;

// 社交信息
@property (nonatomic, strong) NSNumber *fansNum;
@property (nonatomic, strong) NSNumber *followNum;
@property (nonatomic, copy) NSString *langName;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *countryId;
@property (nonatomic, copy) NSString *province;
@property (nonatomic, copy) NSString *provinceId;
@property (nonatomic, copy) NSString *cityId;
@property (nonatomic, copy) NSString *backGround;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *tripartiteId;
@property (nonatomic, strong) NSNumber *isDel;
@property (nonatomic, strong) NSNumber *alliance;
@property (nonatomic, strong) NSNumber *allianceSort;
@property (nonatomic, copy) NSString *openId;
@property (nonatomic, strong) NSNumber *isCanComment;
@property (nonatomic, strong) NSNumber *inviteNum;
@property (nonatomic, strong) NSNumber *chatNum;
@property (nonatomic, copy) NSString *num;
@property (nonatomic, copy) NSString *equipmentBrand;
@property (nonatomic, copy) NSString *realCountry;
@property (nonatomic, strong) NSNumber *followState;

// 消费信息
@property (nonatomic, strong) NSNumber *totalConsume;
@property (nonatomic, strong) NSNumber *totalTicket;
@property (nonatomic, strong) NSNumber *surplusDiamond;
@property (nonatomic, strong) NSNumber *surplusMxdDiamond; // 金币数量余额
@property (nonatomic, strong) NSNumber *surplusMxpDiamond;
@property (nonatomic, assign) BOOL isEditAccount;

// 扩展信息
@property (nonatomic, strong) UserInfoExtend *extend;

// 状态信息
@property (nonatomic, assign) BOOL isBlack;
@property (nonatomic, copy) NSString *subExp;
@property (nonatomic, strong) NSNumber *cancelApply;
@property (nonatomic, assign) BOOL isBingEmail;
@property (nonatomic, assign) BOOL isWhiteUser;
@property (nonatomic, assign) BOOL isPerfectInfo;
@property (nonatomic, copy) NSString *career;
@property (nonatomic, copy) NSString *constellate;
@property (nonatomic, copy) NSString *email; // 邮箱
@property (nonatomic, assign) BOOL isVip; // 是否VIP
@property (nonatomic, strong) NSNumber *vipEndTime; // VIP截止时间
@property (nonatomic, copy) NSString *fillInInviteCode;
@property (nonatomic, copy) NSString *presetInviteCode;
@property (nonatomic, copy) NSString *jwtToken;
@property (nonatomic, strong) NSNumber *isEnableExternalAdv;
@property (nonatomic, strong) NSNumber *isEnableGoogleAdv;
@property (nonatomic, assign) BOOL bingEmail;
@property (nonatomic, assign) BOOL showRtc;
@property (nonatomic, assign) BOOL perfectInfo;
@property (nonatomic, assign) BOOL vip;
@property (nonatomic, strong) NSNumber *recommend;
@property (nonatomic, copy) NSString *identify;

@end

NS_ASSUME_NONNULL_END
