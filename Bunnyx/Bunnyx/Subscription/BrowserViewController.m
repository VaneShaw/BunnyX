//
//  BrowserViewController.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "BrowserViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>

@interface BrowserViewController ()

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString *urlString;

@end

@implementation BrowserViewController

- (instancetype)initWithURL:(NSString *)url {
    self = [super init];
    if (self) {
        self.urlString = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    [self.view addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    if (self.urlString && self.urlString.length > 0) {
        NSURL *url = [NSURL URLWithString:self.urlString];
        if (url) {
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [self.webView loadRequest:request];
        }
    }
}

@end

