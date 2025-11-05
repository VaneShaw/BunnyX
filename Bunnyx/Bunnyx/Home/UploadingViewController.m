//
//  UploadingViewController.m
//
//  上传中页面（仿照安卓 UploadingActivity）
//

#import "UploadingViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "ImageUploadManager.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "UploadHistoryManager.h"
#import <SDWebImage/SDWebImage.h>
#import "GradientButton.h"

static const NSTimeInterval kPollingInterval = 5.0; // 5秒轮询一次
static const NSInteger kMaxPollingFailCount = 3; // 最多连续失败3次

@interface UploadingViewController ()

@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, strong) UIImage *uploadImage;

    // 从历史记录生成时的参数
    @property (nonatomic, strong) NSString *createIds;
    @property (nonatomic, strong) NSString *uploadedImagePath;

// UI 元素
@property (nonatomic, strong) UILabel *titleLabel; // "创建灵感中..."
@property (nonatomic, strong) UIImageView *uploadedImageView; // 上传的图片（左侧）
@property (nonatomic, strong) UIImageView *templateImageView; // 模板图片（右侧）
@property (nonatomic, strong) UIImageView *arrowImageView; // 箭头图标
@property (nonatomic, strong) UIView *progressStepsContainer; // 进度步骤指示器（5个小方块）
@property (nonatomic, strong) NSMutableArray<UIView *> *progressStepViews;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *queueInfoLabel; // 队列信息
@property (nonatomic, strong) GradientButton *vipButton; // VIP加速按钮
@property (nonatomic, strong) UIButton *backgroundButton; // 移到后台按钮

// 轮询相关
@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, assign) BOOL isPolling;
@property (nonatomic, assign) NSInteger pollingFailCount;

// 上传状态
@property (nonatomic, assign) BOOL isUploading;
@property (nonatomic, assign) BOOL isCancelled;

@end

@implementation UploadingViewController

- (instancetype)initWithMaterialId:(NSInteger)materialId image:(UIImage *)image {
    self = [super init];
    if (self) {
        _materialId = materialId;
        _uploadImage = image;
        _isUploading = YES;
        _isCancelled = NO;
        _isPolling = NO;
        _pollingFailCount = 0;
    }
    return self;
}

- (instancetype)initWithMaterialId:(NSInteger)materialId 
                             image:(UIImage * _Nullable)image 
                          createIds:(NSString *)createIds 
                  uploadedImagePath:(NSString * _Nullable)uploadedImagePath 
                   templateImageUrl:(NSString * _Nullable)templateImageUrl {
    self = [super init];
    if (self) {
        _materialId = materialId;
        _uploadImage = image;
        _createIds = createIds;
        _uploadedImagePath = uploadedImagePath;
        self.templateImageUrl = templateImageUrl; // 使用属性设置
        _isUploading = NO; // 从历史记录生成，不需要上传
        _isCancelled = NO;
        _isPolling = NO;
        _pollingFailCount = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalString(@"创建灵感中...");
    self.view.backgroundColor = [UIColor blackColor];
    self.progressStepViews = [NSMutableArray array];
    [self setupUI];
    
    if (self.isUploading) {
        // 需要上传图片
        [self startUpload];
    } else if (self.createIds && self.createIds.length > 0) {
        // 从历史记录生成，直接开始轮询
        [self startPolling];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self bringBackButtonToFront];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopPolling];
}

- (void)dealloc {
    [self stopPolling];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"创建灵感中...");
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = BOLD_FONT(FONT_SIZE_20);
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(MARGIN_20 + 50);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(30);
    }];
    
    // 左右对比图片容器
    UIView *imagesContainer = [[UIView alloc] init];
    [self.view addSubview:imagesContainer];
    
    [imagesContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(MARGIN_30);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 40, 0, 40));
        make.height.mas_equalTo(120);
    }];
    
    // 上传的图片（左侧）
    self.uploadedImageView = [[UIImageView alloc] init];
    self.uploadedImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.uploadedImageView.clipsToBounds = YES;
    self.uploadedImageView.layer.cornerRadius = 10;
    self.uploadedImageView.layer.masksToBounds = YES;
    self.uploadedImageView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    // TODO: 使用切图占位 - self.uploadedImageView.image = [UIImage imageNamed:@"bg_image_rounded"];
    [imagesContainer addSubview:self.uploadedImageView];
    
    // 箭头图标（中间）
    self.arrowImageView = [[UIImageView alloc] init];
    // TODO: 使用切图占位 - self.arrowImageView.image = [UIImage imageNamed:@"icon_arrow_right"];
    self.arrowImageView.image = [UIImage systemImageNamed:@"arrow.right"];
    self.arrowImageView.tintColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    [imagesContainer addSubview:self.arrowImageView];
    
    // 模板图片（右侧）
    self.templateImageView = [[UIImageView alloc] init];
    self.templateImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.templateImageView.clipsToBounds = YES;
    self.templateImageView.layer.cornerRadius = 10;
    self.templateImageView.layer.masksToBounds = YES;
    self.templateImageView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    // TODO: 使用切图占位 - self.templateImageView.image = [UIImage imageNamed:@"bg_image_rounded"];
    [imagesContainer addSubview:self.templateImageView];
    
    // 动态设置图片尺寸（参考安卓逻辑）
    CGFloat imageSize = MIN(self.view.bounds.size.width * 0.25, 120);
    
    [self.uploadedImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imagesContainer);
        make.centerY.equalTo(imagesContainer);
        make.width.height.mas_equalTo(imageSize);
    }];
    
    [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(imagesContainer);
        make.width.height.mas_equalTo(24);
    }];
    
    [self.templateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(imagesContainer);
        make.centerY.equalTo(imagesContainer);
        make.width.height.mas_equalTo(imageSize);
    }];
    
    // 设置图片内容
    [self setupImages];
    
    // 进度步骤指示器（5个小方块）
    self.progressStepsContainer = [[UIView alloc] init];
    [self.view addSubview:self.progressStepsContainer];
    
    [self.progressStepsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imagesContainer.mas_bottom).offset(MARGIN_20);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(12);
    }];
    
    [self setupProgressSteps];
    
    // 进度条
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progressTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.5 alpha:1.0];
    self.progressView.trackTintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    self.progressView.layer.cornerRadius = 2;
    self.progressView.layer.masksToBounds = YES;
    self.progressView.progress = 0.0;
    [self.view addSubview:self.progressView];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressStepsContainer.mas_bottom).offset(MARGIN_15);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 40, 0, 40));
        make.height.mas_equalTo(4);
    }];
    
    // 队列信息标签
    self.queueInfoLabel = [[UILabel alloc] init];
    self.queueInfoLabel.text = @"";
    self.queueInfoLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    self.queueInfoLabel.font = FONT(FONT_SIZE_14);
    self.queueInfoLabel.textAlignment = NSTextAlignmentCenter;
    self.queueInfoLabel.hidden = YES;
    [self.view addSubview:self.queueInfoLabel];
    
    [self.queueInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressView.mas_bottom).offset(MARGIN_10);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(20);
    }];
    
    // VIP加速按钮（非VIP用户显示）
    self.vipButton = [GradientButton buttonWithTitle:LocalString(@"激活VIP加速")];
    [self.vipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.vipButton.cornerRadius = 20;
    // TODO: 使用切图占位（带闪电图标）
    [self.vipButton addTarget:self action:@selector(vipButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.vipButton];
    
    // 移到后台按钮
    self.backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backgroundButton setTitle:LocalString(@"移到后台") forState:UIControlStateNormal];
    [self.backgroundButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.backgroundButton.titleLabel.font = FONT(FONT_SIZE_16);
    self.backgroundButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.6];
    self.backgroundButton.layer.cornerRadius = 20;
    self.backgroundButton.layer.masksToBounds = YES;
    [self.backgroundButton addTarget:self action:@selector(backgroundButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backgroundButton];
    
    // TODO: 根据用户VIP状态显示/隐藏VIP按钮
    BOOL isVip = NO; // 需要从用户信息获取
    self.vipButton.hidden = isVip;
    
    if (isVip) {
        [self.vipButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-70);
            make.height.mas_equalTo(50);
        }];
        
        [self.backgroundButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
            make.height.mas_equalTo(50);
        }];
    } else {
        [self.vipButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-70);
            make.height.mas_equalTo(50);
        }];
        
        [self.backgroundButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
            make.height.mas_equalTo(50);
        }];
    }
}

- (void)setupImages {
    // 设置上传的图片
    if (self.uploadImage) {
        self.uploadedImageView.image = self.uploadImage;
    } else if (self.uploadedImagePath && self.uploadedImagePath.length > 0) {
        // 从历史记录传入的图片路径
        if ([self.uploadedImagePath hasPrefix:@"http://"] || [self.uploadedImagePath hasPrefix:@"https://"]) {
            [self.uploadedImageView sd_setImageWithURL:[NSURL URLWithString:self.uploadedImagePath] 
                                       placeholderImage:[UIImage systemImageNamed:@"photo"]];
        } else {
            UIImage *localImage = [UIImage imageWithContentsOfFile:self.uploadedImagePath];
            if (localImage) {
                self.uploadedImageView.image = localImage;
            } else {
                // TODO: 使用切图占位
                self.uploadedImageView.image = [UIImage systemImageNamed:@"photo"];
            }
        }
    } else {
        // TODO: 使用切图占位
        self.uploadedImageView.image = [UIImage systemImageNamed:@"photo"];
    }
    
    // 设置模板图片（需要从素材信息获取）
    if (self.templateImageUrl && self.templateImageUrl.length > 0) {
        [self.templateImageView sd_setImageWithURL:[NSURL URLWithString:self.templateImageUrl] 
                                  placeholderImage:[UIImage systemImageNamed:@"photo"]];
        BUNNYX_LOG(@"设置模板图片URL: %@", self.templateImageUrl);
    } else {
        // TODO: 使用切图占位
        self.templateImageView.image = [UIImage systemImageNamed:@"photo"];
        BUNNYX_LOG(@"模板图片URL为空，使用占位图");
    }
}

- (void)setupProgressSteps {
    // 创建5个小方块进度指示器
    CGFloat stepSize = 12;
    CGFloat spacing = 8;
    CGFloat totalWidth = stepSize * 5 + spacing * 4;
    CGFloat startX = (100 - totalWidth) / 2;
    
    for (NSInteger i = 0; i < 5; i++) {
        UIView *stepView = [[UIView alloc] init];
        stepView.frame = CGRectMake(startX + i * (stepSize + spacing), 0, stepSize, stepSize);
        stepView.layer.cornerRadius = 2;
        stepView.layer.masksToBounds = YES;
        stepView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0]; // 默认未完成
        stepView.layer.borderWidth = 1;
        stepView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:1.0].CGColor;
        [self.progressStepsContainer addSubview:stepView];
        [self.progressStepViews addObject:stepView];
    }
}

- (void)updateProgressSteps:(NSInteger)completedSteps {
    // 更新进度步骤指示器（0-5）
    for (NSInteger i = 0; i < self.progressStepViews.count; i++) {
        UIView *stepView = self.progressStepViews[i];
        if (i < completedSteps) {
            // 已完成，填充蓝色
            stepView.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
            stepView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor;
        } else {
            // 未完成，灰色边框
            stepView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            stepView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:1.0].CGColor;
        }
    }
}

#pragma mark - Upload Flow

- (void)startUpload {
    if (!self.uploadImage) {
        [self showError:LocalString(@"图片为空")];
        return;
    }
    
    BUNNYX_LOG(@"开始上传生成流程，materialId: %ld", (long)self.materialId);
    
    // 使用 ImageUploadManager 上传图片
    [[ImageUploadManager sharedManager] uploadImage:self.materialId
                                              image:self.uploadImage
                                            progress:^(CGFloat progress, NSString *status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isCancelled) {
                return;
            }
            [self updateProgress:progress status:status];
        });
    } success:^(NSString *initImage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isCancelled) {
                return;
            }
            // 上传成功，保存历史记录
            BUNNYX_LOG(@"图片上传成功，initImage: %@", initImage);
            
            // 保存历史记录（参考安卓逻辑）
            UploadHistoryManager *historyManager = [UploadHistoryManager sharedManager];
            // 构造图片标识（iOS使用时间戳作为唯一标识，因为无法直接获取原始图片Uri）
            NSString *imageUri = [NSString stringWithFormat:@"upload_%ld", (long)[[NSDate date] timeIntervalSince1970]];
            // 构造AWS完整URL（如果需要的话，可以从relativePath构建）
            NSString *awsFullPath = initImage; // 相对路径，完整URL需要从配置中获取
            [historyManager addUploadHistory:imageUri 
                             awsRelativePath:initImage 
                                 awsFullPath:awsFullPath];
            
            // 提交生成任务
            [self submitGenerateTaskWithImagePath:initImage];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isCancelled) {
                return;
            }
            // 上传失败
            [self showError:error.localizedDescription ?: LocalString(@"图片上传失败")];
            BUNNYX_ERROR(@"图片上传失败: %@", error.localizedDescription);
        });
    }];
}

- (void)submitGenerateTaskWithImagePath:(NSString *)imagePath {
    if (self.isCancelled) {
        return;
    }
    
    [self updateProgress:0.8 status:LocalString(@"正在提交生成任务...")];
    [self updateProgressSteps:3]; // 前3步完成
    
    NSDictionary *parameters = @{
        @"materialId": @(self.materialId),
        @"initImage": imagePath
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_GENERATE_CREATE
                                parameters:parameters
                                   success:^(id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isCancelled) {
                return;
            }
            
            NSDictionary *dict = (NSDictionary *)responseObject;
            NSInteger code = [dict[@"code"] integerValue];
            
            if (code == 0) {
                NSString *createIds = dict[@"data"];
                if (createIds && createIds.length > 0) {
                    BUNNYX_LOG(@"提交生成任务成功，createIds: %@", createIds);
                    self.createIds = createIds;
                    
                    // 开始轮询
                    [self startPolling];
                } else {
                    [self showError:LocalString(@"提交生成任务失败")];
                }
            } else {
                // 与安卓版一致：显示promptType
                NSString *promptType = dict[@"promptType"];
                NSString *errorMessage = promptType ?: dict[@"message"] ?: LocalString(@"提交生成任务失败");
                [self showError:errorMessage];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isCancelled) {
                return;
            }
            [self showError:LocalString(@"网络错误")];
            BUNNYX_ERROR(@"提交生成任务失败: %@", error.localizedDescription);
        });
    }];
}

#pragma mark - Polling

- (void)startPolling {
    if (self.isPolling) {
        return;
    }
    
    if (!self.createIds || self.createIds.length == 0) {
        BUNNYX_ERROR(@"createIds为空，无法开始轮询");
        return;
    }
    
    self.isPolling = YES;
    self.pollingFailCount = 0;
    BUNNYX_LOG(@"开始轮询，createIds: %@", self.createIds);
    
    // 立即执行一次
    [self requestCreateStatus];
    
    // 设置定时器，每5秒轮询一次
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:kPollingInterval
                                                         target:self
                                                       selector:@selector(requestCreateStatus)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stopPolling {
    self.isPolling = NO;
    if (self.pollingTimer) {
        [self.pollingTimer invalidate];
        self.pollingTimer = nil;
    }
}

- (void)requestCreateStatus {
    if (!self.isPolling || self.isCancelled) {
        return;
    }
    
    if (!self.createIds || self.createIds.length == 0) {
        [self stopPolling];
        return;
    }
    
    NSDictionary *parameters = @{
        @"createIds": self.createIds
    };
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_GENERATE_TASK_LIST
                                parameters:parameters
                                   success:^(id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isCancelled || !self.isPolling) {
                return;
            }
            
            // 请求成功，重置失败计数
            self.pollingFailCount = 0;
            
            NSDictionary *dict = (NSDictionary *)responseObject;
            NSInteger code = [dict[@"code"] integerValue];
            
            if (code == 0) {
                NSArray *dataArray = dict[@"data"];
                if (dataArray && [dataArray isKindOfClass:[NSArray class]] && dataArray.count > 0) {
                    NSDictionary *statusData = dataArray.firstObject;
                    [self updateUIWithStatusData:statusData];
                } else {
                    BUNNYX_LOG(@"接口返回数据为空");
                }
            } else {
                BUNNYX_ERROR(@"接口返回错误: %@", dict[@"message"]);
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isCancelled || !self.isPolling) {
                return;
            }
            
            // 请求失败，增加失败计数
            self.pollingFailCount++;
            
            if (self.pollingFailCount >= kMaxPollingFailCount) {
                // 连续失败3次，停止轮询
                [self stopPolling];
                BUNNYX_ERROR(@"轮询连续失败3次，停止轮询");
            }
        });
    }];
}

- (void)updateUIWithStatusData:(NSDictionary *)statusData {
    if (!statusData) {
        return;
    }
    
    NSInteger status = [statusData[@"status"] integerValue];
    CGFloat progress = [statusData[@"progress"] doubleValue];
    NSInteger position = [statusData[@"position"] integerValue];
    
    BUNNYX_LOG(@"收到进度值: %.2f, 状态: %ld", progress, (long)status);
    
    // 更新进度条
    self.progressView.progress = progress;
    
    // 更新进度步骤指示器（根据进度计算）
    NSInteger completedSteps = (NSInteger)(progress * 5);
    [self updateProgressSteps:completedSteps];
    
    // 根据状态更新UI
    if (status == 1) {
        // 排队中，显示队列信息
        self.queueInfoLabel.text = [NSString stringWithFormat:LocalString(@"当前队列号：%ld，请等待"), (long)position];
        self.queueInfoLabel.hidden = NO;
        self.titleLabel.text = LocalString(@"创建灵感中...");
    } else if (status == 2) {
        // 处理中
        NSInteger progressPercent = (NSInteger)(progress * 100);
        self.queueInfoLabel.text = [NSString stringWithFormat:@"%ld%%", (long)progressPercent];
        self.queueInfoLabel.hidden = NO;
        self.titleLabel.text = LocalString(@"创建灵感中...");
    } else if (status == 3) {
        // 完成
        self.queueInfoLabel.hidden = YES;
        self.progressView.progress = 1.0;
        [self updateProgressSteps:5];
        [self stopPolling];
        
        // 处理完成后的逻辑
        [self handleGenerationComplete:statusData];
    } else if (status == 4 || status == 5) {
        // 生成失败
        [self stopPolling];
        
        // 处理生成失败
        [self handleGenerationFailed:statusData];
    }
}

- (void)handleGenerationComplete:(NSDictionary *)statusData {
    // 延迟2秒后跳转到生成详情页（参考安卓逻辑）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.isCancelled) {
            // TODO: 跳转到生成详情页
            // VideoDetailActivity.startForGenerate(UploadingActivity.this, task);
            BUNNYX_LOG(@"生成完成，准备跳转到详情页");
            [self.navigationController popViewControllerAnimated:YES];
        }
    });
}

- (void)handleGenerationFailed:(NSDictionary *)statusData {
    NSString *errorMessage = statusData[@"error"];
    if (!errorMessage || errorMessage.length == 0) {
        errorMessage = LocalString(@"生成失败，请重试");
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"生成失败")
                                                                 message:errorMessage
                                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:LocalString(@"确定")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UI Updates

- (void)updateProgress:(CGFloat)progress status:(NSString *)status {
    self.progressView.progress = progress;
    NSInteger progressPercent = (NSInteger)(progress * 100);
    self.queueInfoLabel.text = [NSString stringWithFormat:@"%ld%%", (long)progressPercent];
    self.queueInfoLabel.hidden = NO;
    self.titleLabel.text = status;
    
    // 更新进度步骤
    NSInteger completedSteps = (NSInteger)(progress * 5);
    [self updateProgressSteps:completedSteps];
}

- (void)showError:(NSString *)errorMessage {
    self.titleLabel.text = errorMessage;
    self.titleLabel.textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
    
    // 延迟后返回上一页
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.isCancelled) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    });
}

#pragma mark - Actions

- (void)vipButtonTapped:(UIButton *)sender {
    // 跳转到VIP订阅页面
    // TODO: CoinsActivity.start(UploadingActivity.this);
    BUNNYX_LOG(@"跳转到VIP订阅页面");
}

- (void)backgroundButtonTapped:(UIButton *)sender {
    // 移到后台 - 关闭当前页面，返回到首页（参考安卓逻辑）
    // ActivityManager.getInstance().finishAllActivities();
    // HomeActivity.start(getContext());
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)performBackAction {
    // 点击返回键时停止轮询并关闭所有相关页面（参考安卓逻辑）
    [self stopPolling];
    
    // 关闭所有页面并跳转到首页
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
