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
#import "MaterialDetailViewController.h"
#import "CreateTaskModel.h"

static const NSTimeInterval kPollingInterval = 5.0; // 5秒轮询一次
static const NSInteger kMaxPollingFailCount = 3; // 最多连续失败3次

@interface UploadingViewController ()

@property (nonatomic, assign) NSInteger materialId;

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
@property (nonatomic, strong) CAShapeLayer *dashedBorderLayer; // 虚线边框层

// 轮询相关
@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, assign) BOOL isPolling;
@property (nonatomic, assign) NSInteger pollingFailCount;

// 进度点动画相关
@property (nonatomic, strong) NSTimer *progressStepsAnimationTimer;
@property (nonatomic, assign) NSInteger currentAnimatedStepIndex;

// 状态
@property (nonatomic, assign) BOOL isCancelled;

@end

@implementation UploadingViewController

// 不再需要这个初始化方法，上传在PhotoUploadActivity中完成
// 保留此方法以兼容旧代码，但会直接返回错误
- (instancetype)initWithMaterialId:(NSInteger)materialId image:(UIImage *)image {
    // UploadingActivity不再处理上传，只处理轮询
    // 如果传入了image，说明流程错误，应该使用createIds初始化
    return [self initWithMaterialId:materialId 
                              image:nil 
                          createIds:nil 
                  uploadedImagePath:nil 
                   templateImageUrl:nil];
}

- (instancetype)initWithMaterialId:(NSInteger)materialId 
                             image:(UIImage * _Nullable)image 
                          createIds:(NSString *)createIds 
                  uploadedImagePath:(NSString * _Nullable)uploadedImagePath 
                   templateImageUrl:(NSString * _Nullable)templateImageUrl {
    self = [super init];
    if (self) {
        _materialId = materialId;
        _createIds = createIds;
        _uploadedImagePath = uploadedImagePath;
        self.templateImageUrl = templateImageUrl; // 使用属性设置
        _isCancelled = NO;
        _isPolling = NO;
        _pollingFailCount = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalString(@"创建灵感中...");
    // 使用bg_login作为背景
    UIImage *bgLogin = [UIImage imageNamed:@"bg_login"];
    if (bgLogin) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:bgLogin];
    } else {
        self.view.backgroundColor = [UIColor blackColor];
    }
    self.progressStepViews = [NSMutableArray array];
    [self setupUI];
    
    // UploadingActivity只处理轮询，上传在PhotoUploadActivity中完成
    // 如果传入了createIds，直接开始轮询
    if (self.createIds && self.createIds.length > 0) {
        [self startPolling];
    } else {
        // 如果没有createIds，说明流程异常，返回上一页
        BUNNYX_ERROR(@"UploadingViewController初始化时没有createIds，流程异常");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self bringBackButtonToFront];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 更新虚线边框路径（strokeDashSize 1dp）
    if (self.dashedBorderLayer && self.backgroundButton) {
        self.dashedBorderLayer.frame = self.backgroundButton.bounds;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.backgroundButton.bounds 
                                                        cornerRadius:CORNER_RADIUS_12];
        self.dashedBorderLayer.path = path.CGPath;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopPolling];
}

- (void)dealloc {
    [self stopPolling];
    [self stopProgressStepsAnimation];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 标题栏（高度60dp，marginTop 30dp，paddingHorizontal 16dp，文字18sp bold，居中）
    UIView *titleBar = [[UIView alloc] init];
    titleBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:titleBar];
    
    [titleBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(30);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(60);
    }];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"灵感创建中...");
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = BOLD_FONT(18); // 18sp bold
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleBar addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(titleBar);
        make.left.right.equalTo(titleBar).insets(UIEdgeInsetsMake(0, 16, 0, 16));
    }];
    
    // 主要内容区域（marginTop 60dp，paddingHorizontal 20dp，paddingTop 40dp）
    UIView *contentView = [[UIView alloc] init];
    [self.view addSubview:contentView];
    
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleBar.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    // 三个图片区域（水平排列，居中）
    UIView *imagesContainer = [[UIView alloc] init];
    [contentView addSubview:imagesContainer];
    
    [imagesContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView).offset(40); // paddingTop 40dp
        make.left.right.equalTo(contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20)); // paddingHorizontal 20dp
        make.height.mas_equalTo(220); // 模板图片高度220dp
    }];
    
    // 上传的图片（左侧，100x100dp，marginStart 15dp，marginEnd 5dp，背景bg_image_rounded）
    // 使用bg_image_rounded作为背景，实际图片显示在上面
    UIView *uploadedImageContainer = [[UIView alloc] init];
    UIImage *bgImageRounded = [UIImage imageNamed:@"bg_image_rounded"];
    if (bgImageRounded) {
        uploadedImageContainer.backgroundColor = [UIColor colorWithPatternImage:bgImageRounded];
    } else {
        uploadedImageContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    }
    uploadedImageContainer.layer.cornerRadius = 10; // bg_image_rounded圆角
    uploadedImageContainer.layer.masksToBounds = YES;
    [imagesContainer addSubview:uploadedImageContainer];
    
    self.uploadedImageView = [[UIImageView alloc] init];
    self.uploadedImageView.contentMode = UIViewContentModeScaleAspectFill; // centerCrop
    self.uploadedImageView.clipsToBounds = YES;
    self.uploadedImageView.layer.cornerRadius = 10; // bg_image_rounded圆角
    self.uploadedImageView.layer.masksToBounds = YES;
    [uploadedImageContainer addSubview:self.uploadedImageView];
    
    [self.uploadedImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(uploadedImageContainer);
    }];
    
    // 箭头图标（中间，75x75dp，icon_photo_arrow）
    self.arrowImageView = [[UIImageView alloc] init];
    self.arrowImageView.image = [UIImage imageNamed:@"icon_photo_arrow"];
    self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    [imagesContainer addSubview:self.arrowImageView];
    
    // 模板图片（右侧，175x220dp，marginStart 5dp，marginEnd 15dp，背景bg_image_rounded）
    // 使用bg_image_rounded作为背景，实际图片显示在上面
    UIView *templateImageContainer = [[UIView alloc] init];
    UIImage *bgImageRoundedTemplate = [UIImage imageNamed:@"bg_image_rounded"];
    if (bgImageRoundedTemplate) {
        templateImageContainer.backgroundColor = [UIColor colorWithPatternImage:bgImageRoundedTemplate];
    } else {
        templateImageContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    }
    templateImageContainer.layer.cornerRadius = 10; // bg_image_rounded圆角
    templateImageContainer.layer.masksToBounds = YES;
    [imagesContainer addSubview:templateImageContainer];
    
    self.templateImageView = [[UIImageView alloc] init];
    self.templateImageView.contentMode = UIViewContentModeScaleAspectFill; // centerCrop
    self.templateImageView.clipsToBounds = YES;
    self.templateImageView.layer.cornerRadius = 10; // bg_image_rounded圆角
    self.templateImageView.layer.masksToBounds = YES;
    [templateImageContainer addSubview:self.templateImageView];
    
    [self.templateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(templateImageContainer);
    }];
    
    // 动态设置图片尺寸（setupDynamicImageSizes）
    CGFloat uploadedImageSize = [self getUploadedImageSize];
    NSArray *templateImageSize = [self getTemplateImageSize];
    CGFloat templateWidth = [templateImageSize[0] floatValue];
    CGFloat templateHeight = [templateImageSize[1] floatValue];
    
    [uploadedImageContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imagesContainer).offset(15); // marginStart 15dp
        make.centerY.equalTo(imagesContainer);
        make.width.height.mas_equalTo(uploadedImageSize);
    }];
    
    [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(uploadedImageContainer.mas_right).offset(5); // marginEnd 5dp（上传图片的marginEnd）
        make.centerY.equalTo(imagesContainer);
        make.width.height.mas_equalTo(75); // 75x75dp
    }];
    
    [templateImageContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.arrowImageView.mas_right).offset(5); // marginStart 5dp（模板图片的marginStart）
        make.right.equalTo(imagesContainer).offset(-15); // marginEnd 15dp
        make.centerY.equalTo(imagesContainer);
        make.width.mas_equalTo(templateWidth);
        make.height.mas_equalTo(templateHeight);
    }];
    
    // 设置图片内容
    [self setupImages];
    
    // 渐变进度条（GradientProgressView，90x20dp，marginTop 80dp，居中）
    self.progressStepsContainer = [[UIView alloc] init];
    [contentView addSubview:self.progressStepsContainer];
    
    [self.progressStepsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imagesContainer.mas_bottom).offset(80); // marginTop 80dp
        make.centerX.equalTo(contentView);
        make.width.mas_equalTo(90); // 90dp
        make.height.mas_equalTo(20); // 20dp
    }];
    
    [self setupProgressSteps];
    
    // 进度条（CustomProgressBar，高度8dp，marginHorizontal 50dp，marginTop 24dp）
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progressTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.5 alpha:1.0];
    self.progressView.trackTintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    self.progressView.layer.cornerRadius = 4; // 高度8dp，圆角4dp
    self.progressView.layer.masksToBounds = YES;
    self.progressView.progress = 0.0;
    [contentView addSubview:self.progressView];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressStepsContainer.mas_bottom).offset(24); // marginTop 24dp
        make.left.right.equalTo(contentView).insets(UIEdgeInsetsMake(0, 50, 0, 50)); // marginHorizontal 50dp
        make.height.mas_equalTo(8); // 8dp
    }];
    
    // 队列信息标签（文字12sp，颜色#999999，marginTop 16dp，居中）
    self.queueInfoLabel = [[UILabel alloc] init];
    self.queueInfoLabel.text = @"";
    self.queueInfoLabel.textColor = HEX_COLOR(0x999999); // uploading_queue_text
    self.queueInfoLabel.font = FONT(12); // 12sp
    self.queueInfoLabel.textAlignment = NSTextAlignmentCenter;
    self.queueInfoLabel.hidden = YES;
    [contentView addSubview:self.queueInfoLabel];
    
    [self.queueInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressView.mas_bottom).offset(16); // marginTop 16dp
        make.centerX.equalTo(contentView);
    }];
    
    // 占位View（layout_weight=1，用于撑开空间）
    UIView *spacerView = [[UIView alloc] init];
    [contentView addSubview:spacerView];
    
    [spacerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.queueInfoLabel.mas_bottom);
        make.left.right.equalTo(contentView);
        make.height.greaterThanOrEqualTo(@1);
    }];
    
    // 底部按钮区域（marginTop 100dp，marginBottom 20dp）
    UIView *buttonsContainer = [[UIView alloc] init];
    [contentView addSubview:buttonsContainer];
    
    [buttonsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(spacerView.mas_bottom).offset(100); // marginTop 100dp
        make.left.right.equalTo(contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.bottom.equalTo(contentView.mas_safeAreaLayoutGuideBottom).offset(-20); // marginBottom 20dp
    }];
    
    // VIP加速按钮（高度48dp，圆角12dp，渐变#0AEA6F到#1CB3C1，文字16sp）
    self.vipButton = [GradientButton buttonWithTitle:LocalString(@"开通会员加速生成")
                                             startColor:RGB(10, 234, 111)  // #0AEA6F
                                               endColor:RGB(28, 179, 193)]; // #1CB3C1
    [self.vipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.vipButton.titleLabel.font = FONT(16); // 16sp
    self.vipButton.cornerRadius = CORNER_RADIUS_12;
    self.vipButton.buttonHeight = 48;
    [self.vipButton addTarget:self action:@selector(vipButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [buttonsContainer addSubview:self.vipButton];
    
    // 移到后台按钮（高度48dp，圆角12dp，背景色#0F2A29，边框色#1AB8B9，虚线边框，marginTop 12dp）
    self.backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backgroundButton setTitle:LocalString(@"列入后台") forState:UIControlStateNormal];
    [self.backgroundButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.backgroundButton.titleLabel.font = FONT(16); // 16sp
    self.backgroundButton.backgroundColor = HEX_COLOR(0x0F2A29); // color_0F2A29
    self.backgroundButton.layer.cornerRadius = CORNER_RADIUS_12;
    self.backgroundButton.layer.masksToBounds = YES;
    [self.backgroundButton addTarget:self action:@selector(backgroundButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [buttonsContainer addSubview:self.backgroundButton];
    
    // 虚线边框（strokeColor #1AB8B9，strokeDashSize 1dp）
    // 使用CAShapeLayer实现虚线边框
    self.dashedBorderLayer = [CAShapeLayer layer];
    self.dashedBorderLayer.strokeColor = HEX_COLOR(0x1AB8B9).CGColor; // uploading_button_border
    self.dashedBorderLayer.fillColor = [UIColor clearColor].CGColor;
    self.dashedBorderLayer.lineWidth = 1; // strokeDashSize 1dp
    self.dashedBorderLayer.lineDashPattern = @[@2, @2]; // 虚线样式
    self.dashedBorderLayer.cornerRadius = CORNER_RADIUS_12;
    [self.backgroundButton.layer addSublayer:self.dashedBorderLayer];
    
    // TODO: 根据用户VIP状态显示/隐藏VIP按钮
    BOOL isVip = NO; // 需要从用户信息获取
    self.vipButton.hidden = isVip;
    
    [self.vipButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(buttonsContainer);
        make.left.right.equalTo(buttonsContainer);
        make.height.mas_equalTo(48);
    }];
    
    [self.backgroundButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vipButton.mas_bottom).offset(12); // marginTop 12dp
        make.left.right.equalTo(buttonsContainer);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(buttonsContainer);
    }];
}

- (void)setupImages {
    // placeholder使用icon_photo_upload，error使用image_error_ic
    UIImage *placeholderImage = [UIImage imageNamed:@"icon_photo_upload"];
    UIImage *errorImage = [UIImage imageNamed:@"image_error_ic"];
    if (!placeholderImage) {
        placeholderImage = [UIImage systemImageNamed:@"photo"];
    }
    if (!errorImage) {
        errorImage = placeholderImage;
    }
    
    // 设置上传的图片（setupImages方法）
    if (self.uploadedImagePath && self.uploadedImagePath.length > 0) {
        // 从历史记录传入的图片路径
        if ([self.uploadedImagePath hasPrefix:@"http://"] || [self.uploadedImagePath hasPrefix:@"https://"]) {
            [self.uploadedImageView sd_setImageWithURL:[NSURL URLWithString:self.uploadedImagePath] 
                                       placeholderImage:placeholderImage
                                                options:SDWebImageRetryFailed | SDWebImageHighPriority
                                              completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (error || !image) {
                    // 加载失败显示错误图片
                    self.uploadedImageView.image = errorImage;
                    self.uploadedImageView.contentMode = UIViewContentModeScaleAspectFit;
                } else {
                    self.uploadedImageView.contentMode = UIViewContentModeScaleAspectFill;
                }
            }];
        } else {
            // 本地路径（支持文件路径）
            UIImage *localImage = [UIImage imageWithContentsOfFile:self.uploadedImagePath];
            if (localImage) {
                self.uploadedImageView.image = localImage;
                self.uploadedImageView.contentMode = UIViewContentModeScaleAspectFill;
            } else {
                // 加载失败显示错误图片
                self.uploadedImageView.image = errorImage;
                self.uploadedImageView.contentMode = UIViewContentModeScaleAspectFit;
            }
        }
    } else {
        // 上传图片路径为空，使用默认图片icon_photo_upload
        self.uploadedImageView.image = placeholderImage;
        self.uploadedImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    // 设置模板图片（支持WebP动图，placeholder使用icon_photo_upload，error使用image_error_ic）
    if (self.templateImageUrl && self.templateImageUrl.length > 0) {
        [self.templateImageView sd_setImageWithURL:[NSURL URLWithString:self.templateImageUrl] 
                                  placeholderImage:placeholderImage
                                           options:SDWebImageRetryFailed | SDWebImageHighPriority
                                         completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (error || !image) {
                // 加载失败显示错误图片
                self.templateImageView.image = errorImage;
                self.templateImageView.contentMode = UIViewContentModeScaleAspectFit;
            } else {
                self.templateImageView.contentMode = UIViewContentModeScaleAspectFill;
            }
        }];
        BUNNYX_LOG(@"设置模板图片URL: %@", self.templateImageUrl);
    } else {
        // 模板图片URL为空，使用默认图片icon_photo_upload
        self.templateImageView.image = placeholderImage;
        self.templateImageView.contentMode = UIViewContentModeScaleAspectFit;
        BUNNYX_LOG(@"模板图片URL为空，使用占位图");
    }
}

- (void)setupProgressSteps {
    // 创建5个小方块进度指示器（GradientProgressView内部有5个小方块）
    // 容器宽度90dp，高度20dp，需要居中排列5个小方块
    CGFloat stepSize = 12;
    CGFloat spacing = 8;
    CGFloat totalWidth = stepSize * 5 + spacing * 4;
    CGFloat startX = (90 - totalWidth) / 2; // 容器宽度90dp
    
    for (NSInteger i = 0; i < 5; i++) {
        UIView *stepView = [[UIView alloc] init];
        stepView.frame = CGRectMake(startX + i * (stepSize + spacing), (20 - stepSize) / 2, stepSize, stepSize); // 垂直居中
        stepView.layer.cornerRadius = 2;
        stepView.layer.masksToBounds = YES;
        stepView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0]; // 默认未完成
        stepView.layer.borderWidth = 1;
        stepView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:1.0].CGColor;
        [self.progressStepsContainer addSubview:stepView];
        [self.progressStepViews addObject:stepView];
    }
    
    // 初始化动画索引
    self.currentAnimatedStepIndex = 0;
}

/// 计算上传图片的动态尺寸（ScreenUtils.getUploadedImageSize）
- (CGFloat)getUploadedImageSize {
    CGFloat screenWidth = SCREEN_WIDTH;
    CGFloat screenWidthDp = screenWidth / ([UIScreen mainScreen].scale > 2 ? 3 : 2); // 简化计算
    CGFloat scale = [UIScreen mainScreen].scale;
    
    CGFloat imageSizeRatio;
    if (screenWidthDp < 360) {
        imageSizeRatio = scale < 2.0 ? 0.28 : 0.25;
    } else if (screenWidthDp <= 414) {
        imageSizeRatio = scale < 2.0 ? 0.25 : 0.22;
    } else if (screenWidthDp <= 480) {
        imageSizeRatio = scale < 3.0 ? 0.22 : 0.20;
    } else {
        imageSizeRatio = scale < 3.0 ? 0.20 : 0.18;
    }
    
    CGFloat imageSize = screenWidth * imageSizeRatio;
    
    // 最小和最大尺寸限制
    CGFloat minSize = scale < 2.0 ? 70 : 80;
    CGFloat maxSize = scale < 3.0 ? 120 : 140;
    
    return MAX(minSize, MIN(maxSize, imageSize));
}

/// 计算模板图片的动态尺寸（ScreenUtils.getTemplateImageSize）
- (NSArray<NSNumber *> *)getTemplateImageSize {
    CGFloat screenWidth = SCREEN_WIDTH;
    CGFloat screenWidthDp = screenWidth / ([UIScreen mainScreen].scale > 2 ? 3 : 2);
    CGFloat scale = [UIScreen mainScreen].scale;
    
    CGFloat imageWidthRatio;
    if (screenWidthDp < 360) {
        imageWidthRatio = scale < 2.0 ? 0.45 : 0.40;
    } else if (screenWidthDp <= 414) {
        imageWidthRatio = scale < 2.0 ? 0.42 : 0.38;
    } else if (screenWidthDp <= 480) {
        imageWidthRatio = scale < 3.0 ? 0.40 : 0.35;
    } else {
        imageWidthRatio = scale < 3.0 ? 0.38 : 0.32;
    }
    
    CGFloat imageWidth = screenWidth * imageWidthRatio;
    
    // 最小和最大宽度限制
    CGFloat minWidth = scale < 2.0 ? 120 : 140;
    CGFloat maxWidth = scale < 3.0 ? 200 : 220;
    
    imageWidth = MAX(minWidth, MIN(maxWidth, imageWidth));
    
    // 计算高度，保持宽高比约 0.8:1（高度比宽度大25%）
    CGFloat imageHeight = imageWidth * 1.25;
    
    return @[@(imageWidth), @(imageHeight)];
}

- (void)updateProgressSteps:(NSInteger)completedSteps {
    // 不再根据进度更新，改为循环闪动动画
    // 此方法保留以兼容旧代码，但不再使用
}

/// 启动进度点循环闪动动画
- (void)startProgressStepsAnimation {
    [self stopProgressStepsAnimation];
    
    // 重置所有点为默认状态
    for (UIView *stepView in self.progressStepViews) {
        stepView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        stepView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:1.0].CGColor;
        stepView.alpha = 0.5; // 默认半透明
    }
    
    self.currentAnimatedStepIndex = 0;
    
    // 创建定时器，每0.3秒切换一次
    self.progressStepsAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                                         target:self
                                                                       selector:@selector(animateProgressSteps)
                                                                       userInfo:nil
                                                                        repeats:YES];
    // 立即执行一次
    [self animateProgressSteps];
}

/// 停止进度点循环闪动动画
- (void)stopProgressStepsAnimation {
    if (self.progressStepsAnimationTimer) {
        [self.progressStepsAnimationTimer invalidate];
        self.progressStepsAnimationTimer = nil;
    }
    
    // 重置所有点为默认状态
    for (UIView *stepView in self.progressStepViews) {
        stepView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        stepView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:1.0].CGColor;
        stepView.alpha = 0.5;
    }
}

/// 执行进度点闪动动画
- (void)animateProgressSteps {
    // 重置所有点
    for (UIView *stepView in self.progressStepViews) {
        stepView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        stepView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:1.0].CGColor;
        stepView.alpha = 0.5;
    }
    
    // 高亮当前点
    if (self.currentAnimatedStepIndex < self.progressStepViews.count) {
        UIView *currentStepView = self.progressStepViews[self.currentAnimatedStepIndex];
        currentStepView.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
        currentStepView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor;
        currentStepView.alpha = 1.0;
    }
    
    // 移动到下一个点
    self.currentAnimatedStepIndex = (self.currentAnimatedStepIndex + 1) % self.progressStepViews.count;
}

#pragma mark - Upload Flow
// 上传逻辑已移到PhotoUploadActivity（iOS的UploadMaterialViewController）中
// UploadingActivity（iOS的UploadingViewController）只负责轮询

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
    
    // 启动进度点循环闪动动画
    [self startProgressStepsAnimation];
    
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
    
    // 停止进度点动画
    [self stopProgressStepsAnimation];
}

- (void)requestCreateStatus {
    if (!self.isPolling || self.isCancelled) {
        return;
    }
    
    if (!self.createIds || self.createIds.length == 0) {
        [self stopPolling];
        return;
    }
    
    // GetCreateByIdsApi参数名是ids（虽然方法名是setCreateIds）
    NSDictionary *parameters = @{
        @"ids": self.createIds  // 参数名是ids
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
    
    // 安全提取字段值，处理NSNull情况
    NSInteger status = 0;
    CGFloat progress = 0.0;
    NSInteger position = 0;
    
    id statusValue = statusData[@"status"];
    if (statusValue && ![statusValue isKindOfClass:[NSNull class]]) {
        status = [statusValue integerValue];
    }
    
    id progressValue = statusData[@"progress"];
    if (progressValue && ![progressValue isKindOfClass:[NSNull class]]) {
        progress = [progressValue doubleValue];
    }
    
    id positionValue = statusData[@"position"];
    if (positionValue && ![positionValue isKindOfClass:[NSNull class]]) {
        position = [positionValue integerValue];
    }
    
    BUNNYX_LOG(@"收到进度值: %.2f, 状态: %ld, 位置: %ld", progress, (long)status, (long)position);
    
    // 更新进度条
    self.progressView.progress = progress;
    
    // 进度点不再根据进度更新，而是循环闪动（动画在startPolling时已启动）
    
    // 根据状态更新UI
    if (status == 1) {
        // 排队中，显示队列信息
        self.queueInfoLabel.text = [NSString stringWithFormat:LocalString(@"当前队列号：%ld，请等待"), (long)position];
        self.queueInfoLabel.hidden = NO;
        self.titleLabel.text = LocalString(@"创建灵感中...");
    } else if (status == 2) {
        // 处理中（status==2时queueInfoView.setVisibility(View.GONE)，但会设置文本"进行中... %d%%"）
        NSInteger progressPercent = (NSInteger)(progress * 100);
        self.queueInfoLabel.text = [NSString stringWithFormat:LocalString(@"进行中... %ld%%"), (long)progressPercent];
        self.queueInfoLabel.hidden = YES; // status==2时隐藏队列信息
        self.titleLabel.text = LocalString(@"创建灵感中...");
    } else if (status == 3) {
        // 完成
        self.queueInfoLabel.hidden = YES;
        self.progressView.progress = 1.0;
        // 停止动画，所有点显示为完成状态
        [self stopProgressStepsAnimation];
        for (UIView *stepView in self.progressStepViews) {
            stepView.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
            stepView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor;
            stepView.alpha = 1.0;
        }
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
    // 延迟2秒后跳转到生成详情页，并携带必要ID参数
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.isCancelled) {
            // 从statusData中提取createId、resultVideoUrl、resultImageUrl、videoUrl、imageUrl（安全提取，处理NSNull）
            NSString *createId = nil;
            NSString *resultVideoUrl = nil;
            NSString *resultImageUrl = nil;
            NSString *videoUrl = nil;
            NSString *imageUrl = nil;
            
            id createIdValue = statusData[@"createId"];
            if (createIdValue && ![createIdValue isKindOfClass:[NSNull class]] && [createIdValue isKindOfClass:[NSString class]]) {
                createId = (NSString *)createIdValue;
            }
            
            // 优先检查resultVideoUrl，如果没有则检查videoUrl
            id resultVideoUrlValue = statusData[@"resultVideoUrl"];
            if (resultVideoUrlValue && ![resultVideoUrlValue isKindOfClass:[NSNull class]] && [resultVideoUrlValue isKindOfClass:[NSString class]]) {
                resultVideoUrl = (NSString *)resultVideoUrlValue;
            }
            
            // 如果没有resultVideoUrl，检查videoUrl字段
            if (!resultVideoUrl || resultVideoUrl.length == 0) {
                id videoUrlValue = statusData[@"videoUrl"];
                if (videoUrlValue && ![videoUrlValue isKindOfClass:[NSNull class]] && [videoUrlValue isKindOfClass:[NSString class]]) {
                    videoUrl = (NSString *)videoUrlValue;
                }
            }
            
            // 检查resultImageUrl
            id resultImageUrlValue = statusData[@"resultImageUrl"];
            if (resultImageUrlValue && ![resultImageUrlValue isKindOfClass:[NSNull class]] && [resultImageUrlValue isKindOfClass:[NSString class]]) {
                resultImageUrl = (NSString *)resultImageUrlValue;
            }
            
            // 如果没有resultImageUrl，检查imageUrl字段
            if (!resultImageUrl || resultImageUrl.length == 0) {
                id imageUrlValue = statusData[@"imageUrl"];
                if (imageUrlValue && ![imageUrlValue isKindOfClass:[NSNull class]] && [imageUrlValue isKindOfClass:[NSString class]]) {
                    imageUrl = (NSString *)imageUrlValue;
                }
            }
            
            // 优先使用resultVideoUrl或videoUrl，其次使用resultImageUrl或imageUrl
            NSString *finalVideoUrl = resultVideoUrl ?: videoUrl;
            NSString *finalImageUrl = resultImageUrl ?: imageUrl;
            
            BUNNYX_LOG(@"生成完成，准备跳转到详情页 - createId: %@, videoUrl: %@, imageUrl: %@, materialId: %ld", 
                      createId, finalVideoUrl, finalImageUrl, (long)self.materialId);
            
            // 跳转到生成详情页（VideoDetailActivity.startForGenerate）
            if (createId && createId.length > 0) {
                // 创建CreateTaskModel对象（CreateTask）
                CreateTaskModel *createTask = [[CreateTaskModel alloc] init];
                createTask.createId = createId;
                // 优先设置videoUrl，如果没有则设置imageUrl
                if (finalVideoUrl && finalVideoUrl.length > 0) {
                    createTask.videoUrl = finalVideoUrl;
                }
                if (finalImageUrl && finalImageUrl.length > 0) {
                    createTask.imageUrl = finalImageUrl;
                }
                createTask.materialId = self.materialId;
                
                // 跳转到生成详情页（MaterialDetailPageTypeGenerateFromUploading）
                MaterialDetailViewController *detailVC = [[MaterialDetailViewController alloc] initWithMaterialId:self.materialId 
                                                                                                         pageType:MaterialDetailPageTypeGenerateFromUploading 
                                                                                                        createTask:createTask];
                detailVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:detailVC animated:YES];
            } else {
                // createId为空，返回上一页
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    });
}

- (void)handleGenerationFailed:(NSDictionary *)statusData {
    // 安全提取error字段，处理NSNull情况
    NSString *errorMessage = nil;
    id errorValue = statusData[@"error"];
    if (errorValue && ![errorValue isKindOfClass:[NSNull class]] && [errorValue isKindOfClass:[NSString class]]) {
        errorMessage = (NSString *)errorValue;
    }
    
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
    
    // 进度点不再根据进度更新，而是循环闪动
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
    // 跳转到VIP订阅页面（第三个tab）
    UITabBarController *tabBarController = self.tabBarController;
    if (tabBarController && tabBarController.viewControllers.count > 2) {
        tabBarController.selectedIndex = 2;
    }
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
