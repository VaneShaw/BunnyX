//
//  BunnyxNetworkMacros.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/11/30.
//

#ifndef BunnyxNetworkMacros_h
#define BunnyxNetworkMacros_h

// MARK: - 服务器环境配置
#ifdef DEBUG
    // 开发环境
    #define BUNNYX_BASE_URL @"https://testappapi.bunnyx.ai"
#else
    // 生产环境
    #define BUNNYX_BASE_URL @"https://api.bunnyx.com"
#endif

// MARK: - API版本
#define BUNNYX_API_VERSION @"v1"
#define BUNNYX_API_VERSION_V2 @"v2"

// MARK: - 完整API基础地址
#define BUNNYX_API_BASE_URL [NSString stringWithFormat:@"%@", BUNNYX_BASE_URL]
#define BUNNYX_API_BASE_URL_V2 [NSString stringWithFormat:@"%@/%@", BUNNYX_BASE_URL, BUNNYX_API_VERSION_V2]

// MARK: - 用户相关接口
#define BUNNYX_API_USER_LOGIN_ACCOUNT [NSString stringWithFormat:@"%@/user/login/account", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_LOGIN_QUICK [NSString stringWithFormat:@"%@/user/login/quick", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_REGISTER [NSString stringWithFormat:@"%@/user/register", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_LOGOUT [NSString stringWithFormat:@"%@/user/logout", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_REFRESH_TOKEN [NSString stringWithFormat:@"%@/user/refresh/token", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_INFO [NSString stringWithFormat:@"%@/user/info", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_UPDATE [NSString stringWithFormat:@"%@/user/update", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_AVATAR [NSString stringWithFormat:@"%@/user/avatar", BUNNYX_API_BASE_URL]
#define BUNNYX_API_USER_PASSWORD [NSString stringWithFormat:@"%@/user/password", BUNNYX_API_BASE_URL]

// MARK: - 服务器相关接口
#define BUNNYX_API_SERVER_GET_APP_CONFIG [NSString stringWithFormat:@"%@/server/getAppConfig", BUNNYX_API_BASE_URL]

// MARK: - 首页相关接口
#define BUNNYX_API_HOME_BANNER [NSString stringWithFormat:@"%@/home/banner", BUNNYX_API_BASE_URL]
#define BUNNYX_API_HOME_RECOMMEND [NSString stringWithFormat:@"%@/home/recommend", BUNNYX_API_BASE_URL]
#define BUNNYX_API_HOME_CATEGORY [NSString stringWithFormat:@"%@/home/category", BUNNYX_API_BASE_URL]
#define BUNNYX_API_HOME_HOT [NSString stringWithFormat:@"%@/home/hot", BUNNYX_API_BASE_URL]

// MARK: - 素材广场相关接口
#define BUNNYX_API_MATERIAL_TYPE_LIST [NSString stringWithFormat:@"%@/aitool/getMaterialTypeList", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MATERIAL_LIST [NSString stringWithFormat:@"%@/aitool/getMaterialList", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MATERIAL_DETAIL [NSString stringWithFormat:@"%@/aitool/getMaterialById", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MATERIAL_FAVORITE_ADD [NSString stringWithFormat:@"%@/aitool/favoriteMaterial", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MATERIAL_FAVORITE_REMOVE [NSString stringWithFormat:@"%@/aitool/unfavoriteMaterial", BUNNYX_API_BASE_URL]
// 举报素材接口
#define BUNNYX_API_MATERIAL_REPORT [NSString stringWithFormat:@"%@/aitool/reportMaterial", BUNNYX_API_BASE_URL]
// 获取 AWS 上传配置（与安卓版一致）
#define BUNNYX_API_AWS_UPLOAD [NSString stringWithFormat:@"%@/oss/upload/aws", BUNNYX_API_BASE_URL]
// 提交生成任务
#define BUNNYX_API_GENERATE_CREATE [NSString stringWithFormat:@"%@/aitool/generateCreate", BUNNYX_API_BASE_URL]
// 根据createIds获取生成任务列表（轮询进度）
#define BUNNYX_API_GENERATE_TASK_LIST [NSString stringWithFormat:@"%@/aitool/getGenerateTaskList", BUNNYX_API_BASE_URL]
// 检查素材生成金币是否足够
#define BUNNYX_API_CHECK_SURPLUS_MXD [NSString stringWithFormat:@"%@/aitool/checkSurplusMxd", BUNNYX_API_BASE_URL]

// MARK: - 内容相关接口
#define BUNNYX_API_CONTENT_LIST [NSString stringWithFormat:@"%@/content/list", BUNNYX_API_BASE_URL]
#define BUNNYX_API_CONTENT_DETAIL [NSString stringWithFormat:@"%@/content/detail", BUNNYX_API_BASE_URL]
#define BUNNYX_API_CONTENT_LIKE [NSString stringWithFormat:@"%@/content/like", BUNNYX_API_BASE_URL]
#define BUNNYX_API_CONTENT_COLLECT [NSString stringWithFormat:@"%@/content/collect", BUNNYX_API_BASE_URL]
#define BUNNYX_API_CONTENT_SHARE [NSString stringWithFormat:@"%@/content/share", BUNNYX_API_BASE_URL]
#define BUNNYX_API_CONTENT_COMMENT [NSString stringWithFormat:@"%@/content/comment", BUNNYX_API_BASE_URL]
#define BUNNYX_API_CONTENT_SEARCH [NSString stringWithFormat:@"%@/content/search", BUNNYX_API_BASE_URL]

// MARK: - 分类相关接口
#define BUNNYX_API_CATEGORY_LIST [NSString stringWithFormat:@"%@/category/list", BUNNYX_API_BASE_URL]
#define BUNNYX_API_CATEGORY_CONTENT [NSString stringWithFormat:@"%@/category/content", BUNNYX_API_BASE_URL]

// MARK: - 收藏相关接口
#define BUNNYX_API_FAVORITE_LIST [NSString stringWithFormat:@"%@/favorite/list", BUNNYX_API_BASE_URL]
#define BUNNYX_API_FAVORITE_ADD [NSString stringWithFormat:@"%@/favorite/add", BUNNYX_API_BASE_URL]
#define BUNNYX_API_FAVORITE_REMOVE [NSString stringWithFormat:@"%@/favorite/remove", BUNNYX_API_BASE_URL]

// MARK: - 历史记录相关接口
#define BUNNYX_API_HISTORY_LIST [NSString stringWithFormat:@"%@/history/list", BUNNYX_API_BASE_URL]
#define BUNNYX_API_HISTORY_ADD [NSString stringWithFormat:@"%@/history/add", BUNNYX_API_BASE_URL]
#define BUNNYX_API_HISTORY_CLEAR [NSString stringWithFormat:@"%@/history/clear", BUNNYX_API_BASE_URL]

// MARK: - 订阅相关接口
#define BUNNYX_API_SUBSCRIPTION_LIST [NSString stringWithFormat:@"%@/subscription/list", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SUBSCRIPTION_PLANS [NSString stringWithFormat:@"%@/subscription/plans", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SUBSCRIPTION_PURCHASE [NSString stringWithFormat:@"%@/subscription/purchase", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SUBSCRIPTION_STATUS [NSString stringWithFormat:@"%@/subscription/status", BUNNYX_API_BASE_URL]

// MARK: - 支付相关接口
#define BUNNYX_API_PAYMENT_CREATE [NSString stringWithFormat:@"%@/payment/create", BUNNYX_API_BASE_URL]
#define BUNNYX_API_PAYMENT_VERIFY [NSString stringWithFormat:@"%@/payment/verify", BUNNYX_API_BASE_URL]
#define BUNNYX_API_PAYMENT_HISTORY [NSString stringWithFormat:@"%@/payment/history", BUNNYX_API_BASE_URL]
#define BUNNYX_API_PAY_RECHARGE_LIST [NSString stringWithFormat:@"%@/pay/rechargeList", BUNNYX_API_BASE_URL]

// MARK: - 设置相关接口
#define BUNNYX_API_SETTINGS_GET [NSString stringWithFormat:@"%@/settings/get", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SETTINGS_UPDATE [NSString stringWithFormat:@"%@/settings/update", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SETTINGS_NOTIFICATION [NSString stringWithFormat:@"%@/settings/notification", BUNNYX_API_BASE_URL]

// MARK: - 反馈相关接口
#define BUNNYX_API_FEEDBACK_SUBMIT [NSString stringWithFormat:@"%@/feedback/submit", BUNNYX_API_BASE_URL]
#define BUNNYX_API_FEEDBACK_LIST [NSString stringWithFormat:@"%@/feedback/list", BUNNYX_API_BASE_URL]

// MARK: - 统计相关接口
#define BUNNYX_API_ANALYTICS_EVENT [NSString stringWithFormat:@"%@/analytics/event", BUNNYX_API_BASE_URL]
#define BUNNYX_API_ANALYTICS_PAGE [NSString stringWithFormat:@"%@/analytics/page", BUNNYX_API_BASE_URL]

// MARK: - 文件上传相关接口
#define BUNNYX_API_UPLOAD_IMAGE [NSString stringWithFormat:@"%@/upload/image", BUNNYX_API_BASE_URL]
#define BUNNYX_API_UPLOAD_VIDEO [NSString stringWithFormat:@"%@/upload/video", BUNNYX_API_BASE_URL]
#define BUNNYX_API_UPLOAD_FILE [NSString stringWithFormat:@"%@/upload/file", BUNNYX_API_BASE_URL]

// MARK: - 第三方服务接口
#define BUNNYX_API_THIRD_PARTY_WEIXIN [NSString stringWithFormat:@"%@/third/weixin", BUNNYX_API_BASE_URL]
#define BUNNYX_API_THIRD_PARTY_QQ [NSString stringWithFormat:@"%@/third/qq", BUNNYX_API_BASE_URL]
#define BUNNYX_API_THIRD_PARTY_WEIBO [NSString stringWithFormat:@"%@/third/weibo", BUNNYX_API_BASE_URL]

// MARK: - 系统相关接口
#define BUNNYX_API_SYSTEM_VERSION [NSString stringWithFormat:@"%@/system/version", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SYSTEM_CONFIG [NSString stringWithFormat:@"%@/system/config", BUNNYX_API_BASE_URL]
#define BUNNYX_API_SYSTEM_UPDATE [NSString stringWithFormat:@"%@/system/update", BUNNYX_API_BASE_URL]

// MARK: - 消息相关接口
#define BUNNYX_API_MESSAGE_LIST [NSString stringWithFormat:@"%@/message/list", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MESSAGE_READ [NSString stringWithFormat:@"%@/message/read", BUNNYX_API_BASE_URL]
#define BUNNYX_API_MESSAGE_DELETE [NSString stringWithFormat:@"%@/message/delete", BUNNYX_API_BASE_URL]

// MARK: - 推送相关接口
#define BUNNYX_API_PUSH_REGISTER [NSString stringWithFormat:@"%@/push/register", BUNNYX_API_BASE_URL]
#define BUNNYX_API_PUSH_UNREGISTER [NSString stringWithFormat:@"%@/push/unregister", BUNNYX_API_BASE_URL]
#define BUNNYX_API_PUSH_SETTINGS [NSString stringWithFormat:@"%@/push/settings", BUNNYX_API_BASE_URL]

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
#define BUNNYX_API_VERSION @"v1"
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

#endif /* BunnyxNetworkMacros_h */
