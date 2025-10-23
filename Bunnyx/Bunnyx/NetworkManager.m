//
//  NetworkManager.m
//  Bunnyx
//
//  Created by fengwenxiao on 2025-01-30.
//

#import "NetworkManager.h"
#import <AFNetworking/AFNetworking.h>

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
    
    // 设置请求超时时间
    self.sessionManager.requestSerializer.timeoutInterval = 30.0;
    
    // 设置响应序列化器
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
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
    [self.sessionManager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    [self.sessionManager POST:url
                   parameters:parameters
                      headers:nil
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end
