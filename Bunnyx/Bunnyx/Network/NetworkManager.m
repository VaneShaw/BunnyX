//
//  NetworkManager.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "NetworkManager.h"
#import <AFNetworking/AFNetworking.h>
#import <Toast/Toast.h>
#import "DeviceIdentifierManager.h"
#import "UserManager.h"
#import "LanguageManager.h"

@interface NetworkManager ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation NetworkManager

+ (instancetype)sharedManager {
    static NetworkManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupSessionManager];
    }
    return self;
}

- (void)setupSessionManager {
    self.sessionManager = [AFHTTPSessionManager manager];
    
    // 使用宏定义设置请求超时时间
    self.sessionManager.requestSerializer.timeoutInterval = BUNNYX_REQUEST_TIMEOUT;
    
    // 设置响应序列化器 - 支持更多内容类型
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:BUNNYX_CONTENT_TYPE_JSON, @"text/json", @"text/javascript", @"text/html", @"text/plain", @"application/xml", @"text/xml", @"application/octet-stream", @"*/*", nil];
    
    // 使用宏定义设置请求头 - 接受所有类型
    [self.sessionManager.requestSerializer setValue:@"*/*" forHTTPHeaderField:BUNNYX_HEADER_ACCEPT];
    
    // 设置其他必要的请求头
    [self setupCommonHeaders];
}

#pragma mark - Setup Common Headers

- (void)setupCommonHeaders {
    [self updateCommonHeaders];
}

- (void)updateCommonHeaders {
    AFHTTPRequestSerializer *serializer = self.sessionManager.requestSerializer;
    NSDictionary *deviceInfo = [[DeviceIdentifierManager sharedManager] getDeviceInfo];
    UIDevice *device = [UIDevice currentDevice];
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *shortVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
    NSString *buildVersion = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"";
    NSString *deviceId = deviceInfo[@"uuid"] ?: @"";
    
    [serializer setValue:[self getCurrentLanguageCode] forHTTPHeaderField:BUNNYX_HEADER_ACCEPT_LANGUAGE];
    [serializer setValue:shortVersion forHTTPHeaderField:BUNNYX_HEADER_APP_VERSION];
    [serializer setValue:shortVersion forHTTPHeaderField:BUNNYX_HEADER_VERSION_NAME];
    [serializer setValue:buildVersion forHTTPHeaderField:BUNNYX_HEADER_VERSION_CODE];
    [serializer setValue:BUNNYX_SYSTEM_NAME forHTTPHeaderField:BUNNYX_HEADER_SYSTEM_NAME];
    [serializer setValue:device.systemVersion ?: @"" forHTTPHeaderField:BUNNYX_HEADER_SYSTEM_VERSION];
    [serializer setValue:deviceId forHTTPHeaderField:BUNNYX_HEADER_DEVICE_ID];
    [serializer setValue:device.model ?: @"" forHTTPHeaderField:BUNNYX_HEADER_DEVICE_MODEL];
    [serializer setValue:BUNNYX_API_VERSION forHTTPHeaderField:BUNNYX_HEADER_API_VERSION];
    [serializer setValue:BUNNYX_CHANNEL forHTTPHeaderField:BUNNYX_HEADER_CHANNEL];
    [serializer setValue:deviceId forHTTPHeaderField:BUNNYX_HEADER_EFFECTIVE_IMEI];
    [serializer setValue:@"Apple" forHTTPHeaderField:BUNNYX_HEADER_EQUIPMENT_BRAND];
    
    NSLog(@"[NetworkManager] 通用请求头:%@",[self getCurrentLanguageCode]);
    NSLog(@"[NetworkManager] 设备信息: %@", deviceInfo);
}

- (NSString *)getCurrentLanguageCode {
    NSString *languageCode = [LanguageManager sharedManager].currentLanguageCode;
    if (languageCode.length == 0) {
        languageCode = [NSLocale preferredLanguages].firstObject;
    }
    return [self languageHeaderValueForCode:languageCode];
}

- (NSString *)languageHeaderValueForCode:(NSString *)languageCode {
    NSString *normalized = [(languageCode ? languageCode : @"") lowercaseString];
    if ([normalized containsString:@"zh-hant"] || [normalized containsString:@"zh_tw"]) {
        return BUNNYX_LANGUAGE_ZH_TW;
    }
    if ([normalized hasPrefix:@"en"]) {
        return BUNNYX_LANGUAGE_EN_US;
    }
    return BUNNYX_LANGUAGE_ZH_CN;
}

#pragma mark - Authentication Methods

/**
 * 设置Basic认证 (用于登录和刷新token接口)
 */
- (void)setBasicAuth {
//    NSString *authString = [NSString stringWithFormat:@"%@:%@", BUNNYX_BASIC_AUTH_USERNAME, BUNNYX_BASIC_AUTH_PASSWORD];
//    NSData *authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
//    NSString *base64AuthString = [authData base64EncodedStringWithOptions:0];
    [self.sessionManager.requestSerializer setValue:@"Basic d2VraW5nOndla2luZw==" forHTTPHeaderField:BUNNYX_HEADER_AUTHORIZATION];
    
    NSLog(@"[NetworkManager] 设置Basic认证完成");
}

/**
 * 设置Bearer认证 (用于除登录和刷新token外的其他接口)
 * @param token 从登录或刷新token接口返回的token
 */
- (void)setBearerAuthWithToken:(NSString *)token {
    if (token && token.length > 0) {
        // 获取token类型，默认为bearer
        NSString *tokenType = [[UserManager sharedManager] getTokenType];
        [self.sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"%@ %@", tokenType, token] forHTTPHeaderField:BUNNYX_HEADER_AUTHORIZATION];
        NSLog(@"[NetworkManager] 设置Bearer认证完成: %@ %@", tokenType, token);
    } else {
        NSLog(@"[NetworkManager] Token为空，跳过Bearer认证设置");
    }
}

/**
 * 清除认证信息
 */
- (void)clearAuth {
    [self.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:BUNNYX_HEADER_AUTHORIZATION];
    NSLog(@"[NetworkManager] 清除认证信息完成");
}

#pragma mark - Error Handling

- (void)showErrorToast:(NSError *)error {
    NSString *errorMessage = [self getErrorMessageFromError:error];
    
//    // 在主线程显示Toast
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[UIApplication sharedApplication].keyWindow makeToast:errorMessage 
//                                                      duration:3.0 
//                                                      position:CSToastPositionCenter];
//    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:errorMessage];
    });
}

- (NSString *)getErrorMessageFromError:(NSError *)error {
    NSString *errorMessage = @"网络请求失败";
    
    if (error) {
        // 检查是否有用户友好的错误信息
        if (error.userInfo[NSLocalizedDescriptionKey]) {
            errorMessage = error.userInfo[NSLocalizedDescriptionKey];
        } else if (error.userInfo[NSLocalizedFailureReasonErrorKey]) {
            errorMessage = error.userInfo[NSLocalizedFailureReasonErrorKey];
        } else {
            // 根据错误码提供更友好的提示
            switch (error.code) {
                case NSURLErrorNotConnectedToInternet:
                    errorMessage = @"网络连接失败，请检查网络设置";
                    break;
                case NSURLErrorTimedOut:
                    errorMessage = @"请求超时，请稍后重试";
                    break;
                case NSURLErrorCannotFindHost:
                    errorMessage = @"无法连接到服务器";
                    break;
                case NSURLErrorCannotConnectToHost:
                    errorMessage = @"服务器连接失败";
                    break;
                case NSURLErrorNetworkConnectionLost:
                    errorMessage = @"网络连接中断";
                    break;
                case NSURLErrorBadServerResponse:
                    errorMessage = @"服务器响应异常";
                    break;
                default:
                    errorMessage = [NSString stringWithFormat:@"请求失败 (错误码: %ld)", (long)error.code];
                    break;
            }
        }
    }
    
    return errorMessage;
}

#pragma mark - GET Request (form-data)

- (void)GET:(NSString *)url
 parameters:(NSDictionary *)parameters
    success:(NetworkSuccessBlock)success
    failure:(NetworkFailureBlock)failure {
    
    [self updateCommonHeaders];
    
    // GET 请求使用默认格式，不需要设置 Content-Type
    // GET 请求的参数会作为 URL 查询参数发送
    
    [self.sessionManager GET:url
                  parameters:parameters
                     headers:nil
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 校验响应对象
        if (!responseObject || ![responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *errorMessage = @"服务器响应格式错误";
            [SVProgressHUD showErrorWithStatus:errorMessage];
            if (failure) {
                NSError *err = [NSError errorWithDomain:@"NetworkError" code:-1002 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                failure(err);
            }
            return;
        }
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        if (code == 0) {
            if (success) { success(responseObject); }
        } else if (code == 1) {
            // Token 失效，统一处理并回调失败
            NSLog(@"[NetworkManager] Token失效（GET），准备跳转登录页");
            [self handleTokenExpired];
            if (failure) {
                NSError *err = [NSError errorWithDomain:@"TokenExpiredError" code:1 userInfo:@{NSLocalizedDescriptionKey: @"登录已过期，请重新登录"}];
                failure(err);
            }
        } else {
            NSString *message = dict[@"message"]; if (!message || message.length == 0) { message = @"请求失败，请稍后重试"; }
            [SVProgressHUD showErrorWithStatus:message];
            if (failure) {
                NSError *err = [NSError errorWithDomain:@"BusinessError" code:code userInfo:@{NSLocalizedDescriptionKey: message, @"responseObject": dict ?: @{} }];
                failure(err);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 打印详细的错误信息
        NSLog(@"[NetworkManager] GET请求失败: %@", error);
        NSLog(@"[NetworkManager] 响应数据: %@", task.response);
        NSLog(@"[NetworkManager] 错误详情: %@", error.userInfo);
        
        // 自动显示错误Toast
        [self showErrorToast:error];
        
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - POST Request (x-www-form-urlencoded)

- (void)POST:(NSString *)url
  parameters:(NSDictionary *)parameters
     success:(NetworkSuccessBlock)success
     failure:(NetworkFailureBlock)failure {
    
    [self updateCommonHeaders];
    
    // POST 请求使用 x-www-form-urlencoded 格式
    [self.sessionManager.requestSerializer setValue:BUNNYX_CONTENT_TYPE_FORM forHTTPHeaderField:BUNNYX_HEADER_CONTENT_TYPE];
    
    // 检查是否为登录或刷新token接口，设置Basic认证
    if ([url containsString:@"/login"] || [url containsString:@"/refresh/token"]) {
        [self setBasicAuth];
    }
    // 打印请求头
    NSDictionary *headersToLog = self.sessionManager.requestSerializer.HTTPRequestHeaders;
    NSLog(@"[NetworkManager] POST %@\nHeaders: %@\nParams: %@", url, headersToLog, parameters ?: @{});
    
    // 打印请求体内容（用于调试）- 只有当参数不为 nil 时才序列化
    if (parameters && [parameters isKindOfClass:[NSDictionary class]]) {
        NSError *error;
        NSData *requestData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
        if (requestData) {
            NSString *requestBody = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
            NSLog(@"[NetworkManager] Request Body: %@", requestBody);
        }
    } else {
        NSLog(@"[NetworkManager] Request Body: (无参数)");
    }
    
    [self.sessionManager POST:url
                   parameters:parameters
                      headers:nil
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 检查响应对象是否有效
        if (!responseObject || ![responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *errorMessage = @"服务器响应格式错误";
            [SVProgressHUD showErrorWithStatus:errorMessage];
            if (failure) {
                NSError *error = [NSError errorWithDomain:@"NetworkError" code:-1001 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                failure(error);
            }
            return;
        }
        
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            success(responseObject);
        }
        else if (code == 1) {
            // Token失效错误，需要跳转到登录页
            NSLog(@"[NetworkManager] Token失效，准备跳转登录页");
            [self handleTokenExpired];
            
            if (failure) {
                NSError *error = [NSError errorWithDomain:@"TokenExpiredError" 
                                                     code:1 
                                                 userInfo:@{NSLocalizedDescriptionKey: @"登录已过期，请重新登录"}];
                failure(error);
            }
        }
        else
        {
            NSString * message = responseObject[@"message"];
            // 如果没有message，使用默认错误信息
            if (!message || message.length == 0) {
                message = @"请求失败，请稍后重试";
            }
            
            [SVProgressHUD showErrorWithStatus:message];
            
            if (failure) {
                // 创建更详细的错误对象
                NSError *error = [NSError errorWithDomain:@"BusinessError" 
                                                     code:code 
                                                 userInfo:@{NSLocalizedDescriptionKey: message,
                                                          @"responseObject": responseObject}];
                failure(error);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 打印详细的错误信息
        NSLog(@"[NetworkManager] POST请求失败: %@", error);
        NSLog(@"[NetworkManager] 响应数据: %@", task.response);
        NSLog(@"[NetworkManager] 错误详情: %@", error.userInfo);
        
        // 自动显示错误Toast
        [self showErrorToast:error];
        
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - Token Expired Handling

- (void)handleTokenExpired {
    // 清除所有用户信息
    [[UserManager sharedManager] logout];
    
    // 跳转到登录页
    dispatch_async(dispatch_get_main_queue(), ^{
        [self navigateToLoginPage];
    });
}

- (void)navigateToLoginPage {
    // 获取当前窗口
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    if (!window) {
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        }
    }
    
    if (window) {
        // 创建登录页面
        Class loginClass = NSClassFromString(@"LoginViewController");
        UIViewController *loginViewController = nil;
        
        if (loginClass) {
            loginViewController = [[loginClass alloc] init];
        } else {
            // 如果没有找到LoginViewController，创建一个简单的提示页面
            UIViewController *vc = [[UIViewController alloc] init];
            vc.view.backgroundColor = [UIColor whiteColor];
            
            UILabel *label = [[UILabel alloc] init];
            label.text = @"登录已过期，请重新登录";
            label.textAlignment = NSTextAlignmentCenter;
            label.frame = vc.view.bounds;
            [vc.view addSubview:label];
            
            loginViewController = vc;
        }
        
        // 使用动画跳转到登录页
        [UIView transitionWithView:window duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            window.rootViewController = loginViewController;
        } completion:nil];
    }
}

@end
