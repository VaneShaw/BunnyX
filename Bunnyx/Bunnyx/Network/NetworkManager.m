//
//  NetworkManager.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "NetworkManager.h"
#import <AFNetworking/AFNetworking.h>
#import <Toast/Toast.h>

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
    
    // 设置响应序列化器
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:BUNNYX_CONTENT_TYPE_JSON, @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
    
    // 使用宏定义设置请求头
    [self.sessionManager.requestSerializer setValue:BUNNYX_CONTENT_TYPE_JSON forHTTPHeaderField:BUNNYX_HEADER_ACCEPT];
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
    
    // GET 请求使用默认格式，不需要设置 Content-Type
    // GET 请求的参数会作为 URL 查询参数发送
    
    [self.sessionManager GET:url
                  parameters:parameters
                     headers:nil
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
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
    
    // POST 请求使用 x-www-form-urlencoded 格式
    [self.sessionManager.requestSerializer setValue:BUNNYX_CONTENT_TYPE_FORM forHTTPHeaderField:BUNNYX_HEADER_CONTENT_TYPE];
    // 打印请求头
    NSDictionary *headersToLog = self.sessionManager.requestSerializer.HTTPRequestHeaders;
    NSLog(@"[NetworkManager] POST %@\nHeaders: %@\nParams: %@", url, headersToLog, parameters);
    
    [self.sessionManager POST:url
                   parameters:parameters
                      headers:nil
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 200) {
            success(responseObject);
        }
        else
        {
            NSString * message = responseObject[@"message"];
            
            [SVProgressHUD showErrorWithStatus:message];
            
            if (failure) {
                failure(responseObject);
            }
            
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 自动显示错误Toast
        [self showErrorToast:error];
        
        if (failure) {
            failure(error);
        }
    }];
}

@end
