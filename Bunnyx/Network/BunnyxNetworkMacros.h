//
//  BunnyxNetworkMacros.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#ifndef BunnyxNetworkMacros_h
#define BunnyxNetworkMacros_h

#import "HostEnvironmentManager.h"

// MARK: - 服务器环境配置
#define BUNNYX_BASE_URL [[HostEnvironmentManager sharedManager] currentBaseURL]

// MARK: - API版本
#define BUNNYX_API_VERSION @"1.0"
#define BUNNYX_API_VERSION_V2 @"v2"

// MARK: - 完整API基础地址
#define BUNNYX_API_BASE_URL [NSString stringWithFormat:@"%@", BUNNYX_BASE_URL]
#define BUNNYX_API_BASE_URL_V2 [NSString stringWithFormat:@"%@/%@", BUNNYX_BASE_URL, BUNNYX_API_VERSION_V2]

// MARK: - 用户相关接口
#define BUNNYX_API_USER_LOGIN_ACCOUNT [NSString stringWithFormat:@"%@/user/login/account", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_LOGIN_QUICK [NSString stringWithFormat:@"%@/user/login/quick", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_LOGIN_APPLE [NSString stringWithFormat:@"%@/user/login/apple", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_LOGOUT [NSString stringWithFormat:@"%@/user/logout", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_REFRESH_TOKEN [NSString stringWithFormat:@"%@/user/refresh/token", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_INFO [NSString stringWithFormat:@"%@/user/info", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_DELETE [NSString stringWithFormat:@"%@/user/del/user", BUNNYX_API_BASE_URL] // 删除账号接口

// MARK: - 服务器相关接口
#define BUNNYX_API_SERVER_GET_APP_CONFIG [NSString stringWithFormat:@"%@/server/getAppConfig", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SERVER_GET_CHANNEL_BY_ADJUST [NSString stringWithFormat:@"%@/server/getChannelByAdjust", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SERVER_ADD_ADJUST_EVENT [NSString stringWithFormat:@"%@/server/addAdjustEvent", BUNNYX_API_BASE_URL]

// MARK: - 素材广场相关接口
#define BUNNYX_API_MATERIAL_TYPE_LIST [NSString stringWithFormat:@"%@/aitool/getMaterialTypeList", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MATERIAL_LIST [NSString stringWithFormat:@"%@/aitool/getMaterialList", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MATERIAL_DETAIL [NSString stringWithFormat:@"%@/aitool/getMaterialById", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MATERIAL_FAVORITE_ADD [NSString stringWithFormat:@"%@/aitool/favoriteMaterial", BUNNYX_API_BASE_URL]
// 举报素材接口
#define BUNNYX_API_MATERIAL_REPORT [NSString stringWithFormat:@"%@/aitool/reportMaterial", BUNNYX_API_BASE_URL]
// 获取 AWS 上传配置（与安卓版一致）
#define BUNNYX_API_AWS_UPLOAD [NSString stringWithFormat:@"%@/oss/upload/aws", BUNNYX_API_BASE_URL]
// 提交生成任务
#define BUNNYX_API_GENERATE_CREATE [NSString stringWithFormat:@"%@/aitool/generateCreate", BUNNYX_API_BASE_URL]
// 根据createIds获取生成任务列表（轮询进度，aitool/getCreateByIds）
#define BUNNYX_API_GENERATE_TASK_LIST [NSString stringWithFormat:@"%@/aitool/getCreateByIds", BUNNYX_API_BASE_URL]
// 获取生成列表（我的页面）
#define BUNNYX_API_GET_CREATE_LIST [NSString stringWithFormat:@"%@/aitool/getCreateList", BUNNYX_API_BASE_URL]
// 删除生成接口（DeleteCreateApi）
#define BUNNYX_API_DELETE_CREATE [NSString stringWithFormat:@"%@/aitool/deleteCreate", BUNNYX_API_BASE_URL]
// 获取收藏素材列表（我的页面）
#define BUNNYX_API_GET_FAVORITE_MATERIAL_LIST [NSString stringWithFormat:@"%@/aitool/getFavoriteMaterialList", BUNNYX_API_BASE_URL]
// 检查素材生成金币是否足够
#define BUNNYX_API_CHECK_SURPLUS_MXD [NSString stringWithFormat:@"%@/aitool/checkSurplusMxd", BUNNYX_API_BASE_URL]
// 提交工单接口
#define BUNNYX_API_WORK_ORDER_SUBMIT [NSString stringWithFormat:@"%@/workOrder/submit", BUNNYX_API_BASE_URL]

// MARK: - 支付相关接口
#define BUNNYX_API_PAY_RECHARGE_LIST [NSString stringWithFormat:@"%@/pay/rechargeList", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_BUDGET_LIST [NSString stringWithFormat:@"%@/user/getUserBudgetList", BUNNYX_API_BASE_URL] // 钱包明细列表接口
#define BUNNYX_API_PAY_VIP_LIST [NSString stringWithFormat:@"%@/pay/vipList", BUNNYX_API_BASE_URL]
#define BUNNYX_API_PAY_BUY_VIP [NSString stringWithFormat:@"%@/pay/buy/vip", BUNNYX_API_BASE_URL]
#define BUNNYX_API_PAY_APPLE_VERIFY [NSString stringWithFormat:@"%@/pay/applePay/verify", BUNNYX_API_BASE_URL]

// MARK: - 网络请求参数宏
#define BUNNYX_REQUEST_TIMEOUT 30.0
#define BUNNYX_UPLOAD_TIMEOUT 60.0
#define BUNNYX_DOWNLOAD_TIMEOUT 120.0

// MARK: - 请求头宏
#define BUNNYX_HEADER_CONTENT_TYPE @"Content-Type"
#define BUNNYX_HEADER_AUTHORIZATION @"Authorization"
#define BUNNYX_HEADER_USER_AGENT @"User-Agent"
#define BUNNYX_HEADER_ACCEPT @"Accept"

// MARK: - 内容类型宏
#define BUNNYX_CONTENT_TYPE_JSON @"application/json"
#define BUNNYX_CONTENT_TYPE_FORM @"application/x-www-form-urlencoded"
#define BUNNYX_CONTENT_TYPE_MULTIPART @"multipart/form-data"

// MARK: - HTTP状态码宏
#define BUNNYX_HTTP_SUCCESS 200
#define BUNNYX_HTTP_CREATED 201
#define BUNNYX_HTTP_BAD_REQUEST 400
#define BUNNYX_HTTP_UNAUTHORIZED 401
#define BUNNYX_HTTP_FORBIDDEN 403
#define BUNNYX_HTTP_NOT_FOUND 404
#define BUNNYX_HTTP_INTERNAL_ERROR 500

// MARK: - 响应码宏
#define BUNNYX_CODE_SUCCESS 0
#define BUNNYX_CODE_ERROR -1
#define BUNNYX_CODE_TOKEN_EXPIRED 1001
#define BUNNYX_CODE_USER_NOT_FOUND 1002
#define BUNNYX_CODE_PARAM_ERROR 1003

// MARK: - 分页参数宏
#define BUNNYX_PAGE_SIZE_DEFAULT 20
#define BUNNYX_PAGE_SIZE_MAX 100
#define BUNNYX_PAGE_INDEX_DEFAULT 1

// MARK: - 缓存相关宏
#define BUNNYX_CACHE_DURATION_SHORT 300    // 5分钟
#define BUNNYX_CACHE_DURATION_MEDIUM 1800  // 30分钟
#define BUNNYX_CACHE_DURATION_LONG 3600    // 1小时
#define BUNNYX_CACHE_DURATION_DAY 86400   // 1天

// MARK: - 网络状态宏
#define BUNNYX_NETWORK_STATUS_UNKNOWN 0
#define BUNNYX_NETWORK_STATUS_WIFI 1
#define BUNNYX_NETWORK_STATUS_CELLULAR 2
#define BUNNYX_NETWORK_STATUS_OFFLINE 3

// MARK: - 文件类型宏
#define BUNNYX_FILE_TYPE_IMAGE @"image"
#define BUNNYX_FILE_TYPE_VIDEO @"video"
#define BUNNYX_FILE_TYPE_AUDIO @"audio"
#define BUNNYX_FILE_TYPE_DOCUMENT @"document"

// MARK: - 图片尺寸宏
#define BUNNYX_IMAGE_SIZE_THUMBNAIL @"thumbnail"
#define BUNNYX_IMAGE_SIZE_SMALL @"small"
#define BUNNYX_IMAGE_SIZE_MEDIUM @"medium"
#define BUNNYX_IMAGE_SIZE_LARGE @"large"
#define BUNNYX_IMAGE_SIZE_ORIGINAL @"original"

// MARK: - 视频质量宏
#define BUNNYX_VIDEO_QUALITY_LOW @"low"
#define BUNNYX_VIDEO_QUALITY_MEDIUM @"medium"
#define BUNNYX_VIDEO_QUALITY_HIGH @"high"
#define BUNNYX_VIDEO_QUALITY_ORIGINAL @"original"

// MARK: - 排序相关宏
#define BUNNYX_SORT_BY_TIME @"time"
#define BUNNYX_SORT_BY_POPULARITY @"popularity"
#define BUNNYX_SORT_BY_RATING @"rating"
#define BUNNYX_SORT_BY_PRICE @"price"

// MARK: - 排序方向宏
#define BUNNYX_SORT_ASC @"asc"
#define BUNNYX_SORT_DESC @"desc"

// MARK: - 时间格式宏
#define BUNNYX_TIME_FORMAT_DATE @"yyyy-MM-dd"
#define BUNNYX_TIME_FORMAT_DATETIME @"yyyy-MM-dd HH:mm:ss"
#define BUNNYX_TIME_FORMAT_TIMESTAMP @"yyyy-MM-dd HH:mm:ss.SSS"

// MARK: - 正则表达式宏
#define BUNNYX_REGEX_EMAIL @"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
#define BUNNYX_REGEX_PHONE @"^1[3-9]\\d{9}$"
#define BUNNYX_REGEX_PASSWORD @"^(?=.*[a-zA-Z])(?=.*\\d)[a-zA-Z\\d]{6,20}$"

// MARK: - 错误信息宏
#define BUNNYX_ERROR_NETWORK @"网络连接失败"
#define BUNNYX_ERROR_TIMEOUT @"请求超时"
#define BUNNYX_ERROR_SERVER @"服务器错误"
#define BUNNYX_ERROR_PARAM @"参数错误"
#define BUNNYX_ERROR_AUTH @"认证失败"
#define BUNNYX_ERROR_PERMISSION @"权限不足"

// MARK: - 成功信息宏
#define BUNNYX_SUCCESS_LOGIN @"登录成功"
#define BUNNYX_SUCCESS_REGISTER @"注册成功"
#define BUNNYX_SUCCESS_UPDATE @"更新成功"
#define BUNNYX_SUCCESS_DELETE @"删除成功"
#define BUNNYX_SUCCESS_UPLOAD @"上传成功"

// MARK: - 设备相关宏
#define BUNNYX_DEVICE_UUID_KEY @"BunnyxDeviceUUID"
#define BUNNYX_APP_VERSION @"1.0.0"
#define BUNNYX_SYSTEM_NAME @"ios"
#define BUNNYX_API_VERSION @"1.0"
#define BUNNYX_CHANNEL @"AppStore"

// MARK: - 认证相关宏
#define BUNNYX_BASIC_AUTH_USERNAME @"weking"
#define BUNNYX_BASIC_AUTH_PASSWORD @"weking"

// MARK: - 语言相关宏
#define BUNNYX_LANGUAGE_ZH_CN @"zh_CN"
#define BUNNYX_LANGUAGE_EN_US @"en_US"
#define BUNNYX_LANGUAGE_ZH_TW @"zh_TW"

// MARK: - 请求头字段宏
#define BUNNYX_HEADER_ACCEPT_LANGUAGE @"Accept-Language"
#define BUNNYX_HEADER_APP_VERSION @"App-Version"
#define BUNNYX_HEADER_SYSTEM_NAME @"System-Name"
#define BUNNYX_HEADER_SYSTEM_VERSION @"System-Version"
#define BUNNYX_HEADER_DEVICE_ID @"Device-Id"
#define BUNNYX_HEADER_DEVICE_MODEL @"Device-Model"
#define BUNNYX_HEADER_API_VERSION @"Api-Version"
#define BUNNYX_HEADER_CHANNEL @"channel"
#define BUNNYX_HEADER_EFFECTIVE_IMEI @"Effective-imei"
#define BUNNYX_HEADER_EQUIPMENT_BRAND @"Equipment-brand"
#define BUNNYX_HEADER_VERSION_NAME @"versionName"
#define BUNNYX_HEADER_VERSION_CODE @"versionCode"
#define BUNNYX_HEADER_IDFA @"idfa"
#define BUNNYX_HEADER_ADID @"adid"

#endif /* BunnyxNetworkMacros_h */
