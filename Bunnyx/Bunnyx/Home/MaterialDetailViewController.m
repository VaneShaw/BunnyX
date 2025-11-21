//
//  MaterialDetailViewController.m
//  Bunnyx
//

#import "MaterialDetailViewController.h"
#import "MaterialDetailModel.h"
#import "CreateTaskModel.h"
#import "NetworkManager.h"
#import "BunnyxMacros.h"
#import "BunnyxNetworkMacros.h"
#import "GradientButton.h"
#import "AppConfigManager.h"
#import "UserInfoManager.h"
#import "GenerateListViewController.h" // 导入以使用 kGenerateDetailDeletedCreateIdKey
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>
#import "UploadMaterialViewController.h"
#import "RechargeViewController.h"
#import "MainTabBarController.h"
#import "UploadingViewController.h"

// 通知名称：刷新首页列表
NSString *const kRefreshMaterialListNotification = @"RefreshMaterialListNotification";
// 通知名称：素材被举报/屏蔽，需要从列表中移除
NSString *const kMaterialReportedNotification = @"MaterialReportedNotification";

@interface MaterialDetailViewController ()

@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, assign) MaterialDetailPageType pageType; // 页面类型（mPageType）
@property (nonatomic, strong) CreateTaskModel *createTask; // 生成任务（mCreateTask，用于删除功能）
@property (nonatomic, strong) MaterialDetailModel *detailModel;
@property (nonatomic, strong) UIImageView *materialImageView;
@property (nonatomic, strong) UIView *videoContainer; // 视频容器（fl_video_container）
@property (nonatomic, strong) AVPlayer *videoPlayer; // 视频播放器（VideoView）
@property (nonatomic, strong) AVPlayerLayer *videoPlayerLayer; // 视频播放器图层
@property (nonatomic, strong) NSString *currentVideoUrl; // 当前视频URL（mCurrentVideoUrl）
@property (nonatomic, assign) BOOL hasSwitchedToVideo; // 是否已切换到视频显示（mHasSwitchedToVideo）
@property (nonatomic, strong) UIButton *moreButton; // 右上角更多按钮（icon_home_detail_more_light）
@property (nonatomic, strong) GradientButton *favoriteButton; // 点赞按钮（使用按钮自带的image和title）
@property (nonatomic, strong) UIButton *saveToAlbumButton; // 保存到相册按钮（mBtnSaveToAlbum，使用黑色半透明背景）
@property (nonatomic, strong) GradientButton *generateButton; // 生成按钮
@property (nonatomic, assign) BOOL hasFavoriteAction; // 标记是否有收藏操作（mHasFavoriteAction）
@property (nonatomic, assign) BOOL wasPlayingBeforeBackground; // 记录进入后台前是否正在播放

@end

@implementation MaterialDetailViewController

- (instancetype)initWithMaterialId:(NSInteger)materialId {
    return [self initWithMaterialId:materialId pageType:MaterialDetailPageTypeMaterial createTask:nil];
}

- (instancetype)initWithMaterialId:(NSInteger)materialId pageType:(MaterialDetailPageType)pageType {
    return [self initWithMaterialId:materialId pageType:pageType createTask:nil];
}

- (instancetype)initWithMaterialId:(NSInteger)materialId pageType:(MaterialDetailPageType)pageType createTask:(CreateTaskModel *)createTask {
    self = [super init];
    if (self) {
        _materialId = materialId;
        _pageType = pageType;
        _createTask = createTask;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.backgroundImageView.hidden = YES;
    self.currentVideoUrl = nil;
    self.hasSwitchedToVideo = NO;
    self.wasPlayingBeforeBackground = NO;
    [self setupUI];
    [self fetchMaterialDetail];
    
    // 监听应用进入后台和回到前台的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 页面消失时暂停视频播放
    if (self.videoPlayer) {
        [self.videoPlayer pause];
    }
}

- (void)dealloc {
    // 移除应用状态通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // 清理视频播放器
    if (self.videoPlayer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [self.videoPlayer pause];
        self.videoPlayer = nil;
    }
    if (self.videoPlayerLayer) {
        [self.videoPlayerLayer removeFromSuperlayer];
        self.videoPlayerLayer = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 确保返回按钮和最上层控件在最上层
    // 注意：需要先找到 bottomContainer，然后确保按钮在最上层
    [self bringBackButtonToFront];
    UIView *bottomContainer = self.generateButton.superview;
    if (bottomContainer) {
        [self.view bringSubviewToFront:bottomContainer];
    }
    [self.view bringSubviewToFront:self.moreButton];
    [self.view bringSubviewToFront:self.favoriteButton];
    [self.view bringSubviewToFront:self.saveToAlbumButton];
    [self.view bringSubviewToFront:self.generateButton];
    
    // 确保视图层级正确：materialImageView作为背景，videoContainer在materialImageView之上（如果需要），按钮在最上层
    // 注意：不要使用sendSubviewToBack，因为会把视图放到view背景色后面
    // 正确的层级应该是：view背景 < materialImageView < videoContainer < 按钮
    if (self.videoContainer && !self.videoContainer.hidden) {
        // 如果视频容器显示，确保它在materialImageView之上
        [self.view insertSubview:self.videoContainer aboveSubview:self.materialImageView];
    }
    
    // 如果视频容器可见且视频暂停，恢复播放（从其他页面返回时）
    // 注意：应用从后台回到前台时的恢复由 applicationWillEnterForeground 处理
    if (self.videoPlayer && !self.videoContainer.hidden && self.videoPlayer.rate == 0.0) {
        [self.videoPlayer play];
    }
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    // 素材图片作为背景（centerCrop，支持WebP动图）
    self.materialImageView = [[UIImageView alloc] init];
    self.materialImageView.contentMode = UIViewContentModeScaleAspectFill; // centerCrop
    self.materialImageView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.materialImageView.clipsToBounds = YES;
    self.materialImageView.userInteractionEnabled = NO; // 背景图片不拦截点击事件
    [self.view addSubview:self.materialImageView];
    [self.materialImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 视频播放器容器（fl_video_container，初始隐藏）
    self.videoContainer = [[UIView alloc] init];
    self.videoContainer.backgroundColor = [UIColor blackColor];
    self.videoContainer.hidden = YES; // 初始隐藏
    [self.view addSubview:self.videoContainer];
    [self.videoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    

    // 右上角更多按钮（icon_home_detail_more_light，在TitleBar右侧）
    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.moreButton setImage:[UIImage imageNamed:@"icon_home_detail_more_light"] forState:UIControlStateNormal];
    self.moreButton.tintColor = [UIColor whiteColor];
    [self.moreButton addTarget:self action:@selector(moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.moreButton];
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.centerY.equalTo(self.customBackButton.mas_centerY);
        make.right.equalTo(self.view).offset(-20);
        make.width.height.mas_equalTo(22); // 标准导航栏按钮尺寸
    }];
    
    // 底部内容区域容器（LinearLayout，layout_gravity="bottom"，marginBottom 30dp）
    UIView *bottomContainer = [[UIView alloc] init];
    bottomContainer.backgroundColor = [UIColor clearColor];
    bottomContainer.userInteractionEnabled = YES; // 确保容器可以响应点击事件
    [self.view addSubview:bottomContainer];
    [bottomContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-30); // dp_30 = 30dp
        make.height.offset(200);
    }];
    
    // 生成按钮在底部（第一个子视图在LinearLayout中在上方，但marginBottom使其在底部）
    // 生成按钮（高度48dp，marginHorizontal 30dp，marginBottom 20dp，圆角12dp，渐变背景#0AEA6F到#1CB3C1，文字17sp，bold）
    self.generateButton = [GradientButton buttonWithTitle:[NSString stringWithFormat:LocalString(@"生成(%ld金币)"), 0]];
    // 渐变颜色：#0AEA6F到#1CB3C1
    self.generateButton.gradientStartColor = HEX_COLOR(0x0AEA6F);
    self.generateButton.gradientEndColor = HEX_COLOR(0x1CB3C1);
    [self.generateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.generateButton.titleLabel.font = BOLD_FONT(17); // 17sp，bold
    self.generateButton.layer.cornerRadius = 12.0; // dp_12 = 12dp
    self.generateButton.layer.masksToBounds = YES;
    self.generateButton.userInteractionEnabled = YES; // 确保可以响应点击
    self.generateButton.enabled = YES; // 确保按钮启用
    [self.generateButton addTarget:self action:@selector(generateButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [bottomContainer addSubview:self.generateButton];
    [self.generateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(bottomContainer).insets(UIEdgeInsetsMake(0, 30, 0, 30)); // marginHorizontal 30dp
        make.bottom.equalTo(bottomContainer).offset(-20); // marginBottom 20dp（距离底部容器底部20dp）
        make.height.mas_equalTo(48); // dp_48 = 48dp
    }];
    
    // 点赞按钮在生成按钮上方（高度48dp，marginHorizontal 30dp，marginBottom 20dp，背景like_count_bg，圆角10dp）
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.favoriteButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5]; // like_count_bg: #80000000
    self.favoriteButton.layer.cornerRadius = 10.0; // dp_10 = 10dp
    self.favoriteButton.layer.masksToBounds = YES;
    self.favoriteButton.userInteractionEnabled = YES;
    // 设置按钮文字样式
    [self.favoriteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.favoriteButton.titleLabel.font = BOLD_FONT(FONT_SIZE_14); // 14sp，bold
    // 设置图片在文字左边，间距12（图片右移6，文字左移6，总间距12）
    self.favoriteButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6); // 图片右边距6
    self.favoriteButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0); // 文字左边距6
    self.favoriteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter; // 居中对齐
    [self.favoriteButton addTarget:self action:@selector(favoriteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [bottomContainer addSubview:self.favoriteButton];
    [self.favoriteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(bottomContainer).insets(UIEdgeInsetsMake(0, 30, 0, 30)); // marginHorizontal 30dp
        make.bottom.equalTo(self.generateButton.mas_top).offset(-20); // marginBottom 20dp（相对于生成按钮）
        make.height.mas_equalTo(48); // dp_48 = 48dp
    }];
    
    // 保存到相册按钮（生成详情模式显示，素材详情模式隐藏）
    // 注意：在安卓布局中，保存到相册按钮在LinearLayout中位于生成按钮之后（下方），但实际显示时应该在生成按钮上方
    // 布局：btn_video_detail_save_to_album 在 btn_video_detail_generate 之后，但通过约束让它显示在生成按钮上方
    // 保存到相册按钮在生成详情模式下使用黑色半透明背景（like_count_bg: #80000000），圆角10dp
    self.saveToAlbumButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveToAlbumButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5]; // like_count_bg: #80000000
    self.saveToAlbumButton.layer.cornerRadius = 10.0; // dp_10 = 10dp（like_count_bg的圆角）
    self.saveToAlbumButton.layer.masksToBounds = YES;
    [self.saveToAlbumButton setTitle:LocalString(@"保存到相册") forState:UIControlStateNormal];
    [self.saveToAlbumButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.saveToAlbumButton.titleLabel.font = BOLD_FONT(17); // 17sp，bold（sp_17）
    self.saveToAlbumButton.userInteractionEnabled = YES;
    [self.saveToAlbumButton addTarget:self action:@selector(saveToAlbumButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [bottomContainer addSubview:self.saveToAlbumButton];
    [self.saveToAlbumButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(bottomContainer).insets(UIEdgeInsetsMake(0, 30, 0, 30)); // marginHorizontal 30dp
        make.bottom.equalTo(self.generateButton.mas_top).offset(-20); // marginBottom 20dp（相对于生成按钮，在生成按钮上方）
        make.height.mas_equalTo(48); // dp_48 = 48dp
    }];
    // 初始状态隐藏（根据pageType在updateUI中显示/隐藏）
    self.saveToAlbumButton.hidden = YES;
}

-(void)performBackAction {
    // 如果有收藏操作，返回首页并刷新列表
    if (self.hasFavoriteAction) {
        // 发送通知刷新首页列表
        [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshMaterialListNotification object:nil];
        // 切换到首页tab（索引0）
        UITabBarController *tabBarController = self.tabBarController;
        if (tabBarController && tabBarController.viewControllers.count > 0) {
            tabBarController.selectedIndex = 0;
        }
    }
    
    // 如果是从生成中页面跳转过来的，返回时跳过生成中页面
    if (self.pageType == MaterialDetailPageTypeGenerateFromUploading) {
//        NSArray *viewControllers = self.navigationController.viewControllers;
//        if (viewControllers.count >= 2) {
//            // 检查前一个视图控制器是否是UploadingViewController
//            UIViewController *previousVC = viewControllers[viewControllers.count - 2];
//            if ([previousVC isKindOfClass:[UploadingViewController class]]) {
//                // 跳过生成中页面，直接返回到更早的页面
//                NSMutableArray *newViewControllers = [NSMutableArray arrayWithArray:viewControllers];
//                [newViewControllers removeObject:previousVC]; // 移除生成中页面
//                [newViewControllers removeLastObject]; // 移除当前页面（生成结果页）
//                [self.navigationController setViewControllers:newViewControllers animated:YES];
//                return;
//            }
//        }
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)fetchMaterialDetail {
    [SVProgressHUD show];
    NSDictionary *params = @{ @"materialId": @(self.materialId) };
    [[NetworkManager sharedManager] GET:BUNNYX_API_MATERIAL_DETAIL parameters:params success:^(id  _Nonnull responseObject) {
        [SVProgressHUD dismiss];
        NSDictionary *data = responseObject[@"data"];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            self.detailModel = [MaterialDetailModel modelFromResponse:data];
            [self updateUI];
        }
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"数据加载失败")];
    }];
}

- (void)updateUI {
    if (!self.detailModel) { return; }
    
    // 根据页面类型显示/隐藏按钮
    if (self.pageType == MaterialDetailPageTypeMaterial) {
        // 素材详情模式：显示点赞按钮，隐藏保存到相册按钮
        self.favoriteButton.hidden = NO;
        self.saveToAlbumButton.hidden = YES;
        
        // 更新收藏数量和状态（使用按钮自带的image和title）
        NSInteger favoriteCount = self.detailModel.favoriteQty ? [self.detailModel.favoriteQty integerValue] : 0;
        NSString *favoriteCountText = [NSString stringWithFormat:@"%ld", (long)favoriteCount];
        [self.favoriteButton setTitle:favoriteCountText forState:UIControlStateNormal];
        
        // 已点赞使用icon_home_collection_light，未点赞使用icon_home_collection_dark
        UIImage *heartImage = nil;
        if (self.detailModel.isFavorite) {
            heartImage = [UIImage imageNamed:@"icon_home_collection_light"];
        } else {
            heartImage = [UIImage imageNamed:@"icon_home_collection_dark"];
        }
        // 调整图片大小为20x20
        heartImage = [self resizeImage:heartImage toSize:CGSizeMake(20, 20)];
        [self.favoriteButton setImage:heartImage forState:UIControlStateNormal];
    } else {
        // 生成详情模式：隐藏点赞按钮，显示保存到相册按钮
        self.favoriteButton.hidden = YES;
        self.saveToAlbumButton.hidden = NO;
        
        // 生成按钮保持绿色渐变（不改变颜色）
        // 注意：虽然安卓代码中设置了like_count_bg，但用户要求生成按钮保持绿色
        // 保持原有的绿色渐变颜色
        self.generateButton.gradientStartColor = HEX_COLOR(0x0AEA6F);
        self.generateButton.gradientEndColor = HEX_COLOR(0x1CB3C1);
    }
    
    // 加载图片（支持WebP动图，使用AUTOMATIC缓存策略）
    // 注意：只有从"我的"生成列表进入（PAGE_TYPE_GENERATE）时才判断materialMode == 2
    // 从其他列表进入（PAGE_TYPE_MATERIAL）时默认执行图片逻辑
    BOOL shouldCheckVideoMode = (self.pageType == MaterialDetailPageTypeGenerate || self.pageType == MaterialDetailPageTypeGenerateFromUploading);
    
    // 生成详情模式：优先使用createTask的videoUrl或imageUrl（生成结果），而不是detailModel.materialUrl（原素材）
    // 素材详情模式：使用detailModel.materialUrl
    NSString *displayVideoUrl = nil;
    NSString *displayImageUrl = nil;
    BOOL isVideoType = NO;
    
    if (shouldCheckVideoMode && self.createTask) {
        // 生成详情模式：优先使用createTask的URL
        // 判断是否是视频类型：如果有videoUrl就是视频类型
        if (self.createTask.videoUrl && self.createTask.videoUrl.length > 0) {
            displayVideoUrl = self.createTask.videoUrl;
            isVideoType = YES;
        }
        // 无论是否有videoUrl，都使用imageUrl作为封面
        if (self.createTask.imageUrl && self.createTask.imageUrl.length > 0) {
            displayImageUrl = self.createTask.imageUrl;
        }
    }
    
    // 如果createTask没有URL，或者不是生成详情模式，使用detailModel的URL
    if (!displayVideoUrl && !displayImageUrl) {
        if (shouldCheckVideoMode && self.detailModel.materialMode == 2 && self.detailModel.materialUrl && self.detailModel.materialUrl.length > 0) {
            displayVideoUrl = self.detailModel.materialUrl;
            isVideoType = YES;
        } else if (self.detailModel.materialUrl && self.detailModel.materialUrl.length > 0) {
            displayImageUrl = self.detailModel.materialUrl;
        }
    }
    
    // 显示逻辑：
    // 1. 如果是视频类型：先显示封面imageUrl，如果videoUrl有值，接着加载播放videoUrl内容(.mp4)
    // 2. 非视频类型：直接显示封面imageUrl
    if (isVideoType && displayVideoUrl && displayVideoUrl.length > 0) {
        // 视频类型，先显示封面图（imageUrl），等视频加载完成后再显示视频
        self.materialImageView.hidden = NO;
        self.videoContainer.hidden = YES;
        
        // 先显示封面图（imageUrl）
        if (displayImageUrl && displayImageUrl.length > 0) {
            NSURL *coverUrl = [NSURL URLWithString:displayImageUrl];
            // 优化选项：自动缩放大图，减少内存占用，防止WebP图片导致内存过载
            [self.materialImageView sd_setImageWithURL:coverUrl 
                                        placeholderImage:[UIImage imageNamed:@"image_error_ic"]
                                                 options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages
                                                 context:@{SDWebImageContextStoreCacheType: @(SDImageCacheTypeAll)}];
        } else {
            // 如果没有封面图，显示占位图
            [self.materialImageView setImage:[UIImage imageNamed:@"image_error_ic"]];
        }
        
        // 如果视频URL和当前加载的相同，不重复设置
        if (!self.currentVideoUrl || ![self.currentVideoUrl isEqualToString:displayVideoUrl]) {
            self.currentVideoUrl = displayVideoUrl;
            self.hasSwitchedToVideo = NO;
            // 准备视频播放（加载完成后会自动切换到视频显示）
            [self prepareVideoDisplay];
        }
    } else if (displayImageUrl && displayImageUrl.length > 0) {
        // 非视频类型，直接显示封面imageUrl
        self.materialImageView.hidden = NO;
        self.videoContainer.hidden = YES;
        
        NSURL *url = [NSURL URLWithString:displayImageUrl];
        // 优化选项：自动缩放大图，减少内存占用，防止WebP图片导致内存过载
        [self.materialImageView sd_setImageWithURL:url 
                                    placeholderImage:[UIImage imageNamed:@"image_error_ic"]
                                             options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages
                                             context:@{SDWebImageContextStoreCacheType: @(SDImageCacheTypeAll)}];
    }
    
    // 更新生成按钮（Generate(XXCoins)，17sp，bold）
    NSString *generateTitle = [NSString stringWithFormat:LocalString(@"生成(%ld金币)"), (long)self.detailModel.generatePrice];
    [self.generateButton setTitle:generateTitle forState:UIControlStateNormal];
}

#pragma mark - Application State

// 应用进入后台
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    // 记录进入后台前的播放状态
    if (self.videoPlayer) {
        self.wasPlayingBeforeBackground = (self.videoPlayer.rate > 0.0);
        if (self.wasPlayingBeforeBackground) {
            [self.videoPlayer pause];
            NSLog(@"[MaterialDetailViewController] 应用进入后台，暂停视频播放");
        }
    }
}

// 应用回到前台
- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // 如果进入后台前正在播放，则恢复播放
    if (self.videoPlayer && self.wasPlayingBeforeBackground && !self.videoContainer.hidden) {
        // 延迟一点再恢复播放，确保应用完全激活
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.videoPlayer && !self.videoContainer.hidden) {
                [self.videoPlayer play];
                NSLog(@"[MaterialDetailViewController] 应用回到前台，恢复视频播放");
            }
        });
    }
    self.wasPlayingBeforeBackground = NO;
}

#pragma mark - Video Playback

// prepareVideoDisplay - 准备视频显示
- (void)prepareVideoDisplay {
    if (!self.currentVideoUrl || self.currentVideoUrl.length == 0) {
        return;
    }
    
    // 清理旧的播放器
    if (self.videoPlayer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [self.videoPlayer pause];
        self.videoPlayer = nil;
    }
    if (self.videoPlayerLayer) {
        [self.videoPlayerLayer removeFromSuperlayer];
        self.videoPlayerLayer = nil;
    }
    
    // 创建AVPlayer
    NSURL *videoURL = [NSURL URLWithString:self.currentVideoUrl];
    if (!videoURL) {
        NSLog(@"[MaterialDetailViewController] 视频URL无效: %@", self.currentVideoUrl);
        return;
    }
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
    self.videoPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    
    // 创建AVPlayerLayer
    self.videoPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
    self.videoPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // centerCrop效果
    [self.videoContainer.layer addSublayer:self.videoPlayerLayer];
    
    // 设置图层frame（在viewDidLayoutSubviews中更新）
    [self.view setNeedsLayout];
    
    // 监听播放完成，实现循环播放（OnCompletionListener）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoDidPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    // 监听播放状态，当视频准备好后切换到视频显示
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    // 延迟一点再开始播放，确保设置完成（post延迟）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.videoPlayer && self.currentVideoUrl) {
            [self.videoPlayer play];
            NSLog(@"[MaterialDetailViewController] 视频开始播放: %@", self.currentVideoUrl);
        }
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            // 视频准备好后，切换到视频显示（切换到VideoView）
            if (!self.hasSwitchedToVideo) {
                self.hasSwitchedToVideo = YES;
                self.materialImageView.hidden = YES;
                self.videoContainer.hidden = NO;
                NSLog(@"[MaterialDetailViewController] 切换到视频显示");
            }
            // 移除观察者
            [playerItem removeObserver:self forKeyPath:@"status"];
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            NSLog(@"[MaterialDetailViewController] 视频加载失败: %@", playerItem.error);
            // 移除观察者
            [playerItem removeObserver:self forKeyPath:@"status"];
        }
    }
}

// 视频播放完成，循环播放
- (void)videoDidPlayToEnd:(NSNotification *)notification {
    if (self.videoPlayer) {
        // 重新开始播放（seekTo(0) + start()）
        [self.videoPlayer seekToTime:kCMTimeZero];
        [self.videoPlayer play];
        NSLog(@"[MaterialDetailViewController] 视频循环播放");
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 更新视频播放器图层frame
    if (self.videoPlayerLayer) {
        self.videoPlayerLayer.frame = self.videoContainer.bounds;
    }
}

#pragma mark - Actions

- (void)moreButtonTapped:(UIButton *)sender {
    // 根据页面类型显示不同的弹窗
    if (self.pageType == MaterialDetailPageTypeGenerate || self.pageType == MaterialDetailPageTypeGenerateFromUploading) {
        // 生成详情模式：显示删除底部弹窗
        [self showDeleteActionSheet];
    } else {
        // 素材详情模式：显示底部弹窗（举报和屏蔽）
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil 
                                                                         message:nil 
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
        
        // 举报选项（type: 0）
        UIAlertAction *reportAction = [UIAlertAction actionWithTitle:LocalString(@"举报") 
                                                                   style:UIAlertActionStyleDestructive 
                                                                 handler:^(UIAlertAction * _Nonnull action) {
            [self reportMaterialWithType:0]; // 0: report
        }];
        
        // 屏蔽选项（type: 1）
        UIAlertAction *blockAction = [UIAlertAction actionWithTitle:LocalString(@"屏蔽") 
                                                                  style:UIAlertActionStyleDestructive 
                                                                handler:^(UIAlertAction * _Nonnull action) {
            [self reportMaterialWithType:1]; // 1: block
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消") 
                                                                   style:UIAlertActionStyleCancel 
                                                                 handler:nil];
        
        [alert addAction:reportAction];
        [alert addAction:blockAction];
        [alert addAction:cancelAction];
        
        // iPad支持
        if (IS_IPAD) {
            alert.popoverPresentationController.sourceView = sender;
            alert.popoverPresentationController.sourceRect = sender.bounds;
        }
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)reportMaterialWithType:(NSInteger)type {
    // 调用reportMaterial API，参数materialId和type（0:report, 1:block）
    if (self.materialId <= 0) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"素材ID无效")];
        return;
    }
    
    NSDictionary *params = @{
        @"materialId": @(self.materialId),
        @"type": @(type)
    };
    
    [SVProgressHUD show];
    [[NetworkManager sharedManager] POST:BUNNYX_API_MATERIAL_REPORT parameters:params success:^(id  _Nonnull responseObject) {
        [SVProgressHUD dismiss];
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 成功后关闭当前页面，通知列表页移除对应item（对应material_reported）
            // 发送通知，通知列表页移除对应item
            [[NSNotificationCenter defaultCenter] postNotificationName:kMaterialReportedNotification
                                                                object:nil
                                                              userInfo:@{
                                                                  @"materialId": @(self.materialId)
                                                              }];
            // 切换到首页tab（索引0）
            UITabBarController *tabBarController = self.tabBarController;
            if (tabBarController && tabBarController.viewControllers.count > 0) {
                tabBarController.selectedIndex = 0;
            }
            // 关闭当前页面
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"操作失败")];
        }
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"操作失败")];
    }];
}

- (void)favoriteButtonTapped:(UIButton *)sender {
    NSLog(@"[MaterialDetailViewController] 点赞按钮被点击");
    if (!self.detailModel) {
        NSLog(@"[MaterialDetailViewController] detailModel 为空");
        return;
    }
    
    BOOL willFavorite = !self.detailModel.isFavorite;
    NSLog(@"[MaterialDetailViewController] 将要设置为收藏状态: %@", willFavorite ? @"YES" : @"NO");
    // 使用FavoriteMaterialApi，参数materialId和add
    NSDictionary *params = @{
        @"materialId": @(self.detailModel.materialId),
        @"add": @(willFavorite)
    };
    
    [SVProgressHUD show];
    [[NetworkManager sharedManager] POST:BUNNYX_API_MATERIAL_FAVORITE_ADD parameters:params success:^(id  _Nonnull responseObject) {
        [SVProgressHUD dismiss];
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 标记有收藏操作
            self.hasFavoriteAction = YES;
            
            // 更新本地状态和数量
            self.detailModel.isFavorite = willFavorite;
            NSInteger currentCount = self.detailModel.favoriteQty ? [self.detailModel.favoriteQty integerValue] : 0;
            if (willFavorite) {
                self.detailModel.favoriteQty = @(currentCount + 1);
            } else {
                self.detailModel.favoriteQty = @(MAX(0, currentCount - 1));
            }
            [self updateUI];
            
            // 发送通知，通知列表页更新对应item的收藏状态（对应ActivityResultLauncher）
            NSInteger likeCount = self.detailModel.favoriteQty ? [self.detailModel.favoriteQty integerValue] : 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MaterialDetailFavoriteChangedNotification"
                                                                object:nil
                                                              userInfo:@{
                                                                  @"materialId": @(self.detailModel.materialId),
                                                                  @"isFavorite": @(willFavorite),
                                                                  @"likeCount": @(likeCount)
                                                              }];
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"操作失败")];
        }
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"操作失败")];
    }];
}

- (void)generateButtonTapped:(UIButton *)sender {
    NSLog(@"[MaterialDetailViewController] 生成按钮被点击");
    if (!self.detailModel) {
        NSLog(@"[MaterialDetailViewController] detailModel 为空");
        return;
    }
    NSLog(@"[MaterialDetailViewController] 开始检查金币余额，materialId: %ld", (long)self.detailModel.materialId);
    [self checkSurplusAndProceed:self.detailModel.materialId];
}

- (void)navigateToRecharge {
    RechargeViewController *vc = [[RechargeViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)navigateToUploadMaterial {
    UploadMaterialViewController *vc = [[UploadMaterialViewController alloc] initWithMaterialId:self.detailModel.materialId];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Check Surplus API

- (void)checkSurplusAndProceed:(NSInteger)materialId {
    // 先检查金币余额
    NSDictionary *params = @{ @"materialId": @(materialId) };
    [SVProgressHUD showWithStatus:LocalString(@"加载中")];
    [[NetworkManager sharedManager] GET:BUNNYX_API_CHECK_SURPLUS_MXD
                               parameters:params
                                  success:^(id responseObject) {
        [SVProgressHUD dismiss];
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        BOOL ok = NO;
        if (code == 0) {
            id data = dict[@"data"];
            if ([data isKindOfClass:[NSNumber class]]) {
                ok = [data boolValue];
            } else if ([data isKindOfClass:[NSString class]]) {
                ok = [((NSString *)data) boolValue];
            }
        }
        if (ok) {
            // 余额足够，检查VIP权限（checkVipAndGenerate）
            [self checkVipAndGenerate];
        } else {
            // 余额不足，提醒去充值（showRechargeDialog）
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"金币不足")
                                                                           message:LocalString(@"您的金币不足，是否前往充值？")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *rechargeAction = [UIAlertAction actionWithTitle:LocalString(@"去充值")
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * _Nonnull action) {
                [self navigateToRecharge];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消")
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:nil];
            [alert addAction:rechargeAction];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"网络错误")];
    }];
}

// 检查VIP权限并继续生成流程
- (void)checkVipAndGenerate {
    if (!self.detailModel) {
        // 如果Material对象不存在，需要先获取（loadMaterialForVipCheck）
        [self loadMaterialForVipCheck];
        return;
    }
    
    // 检查onlyVip字段
    NSInteger onlyVip = self.detailModel.onlyVip;
    if (onlyVip == 1) {
        // 检查用户是否是VIP（UserInfoManager.getInstance(this).isVip()）
        BOOL isVip = [[UserInfoManager sharedManager] isVip];
        if (!isVip) {
            // 不是VIP，显示VIP提示弹窗（showVipRequiredDialog）
            [self showVipRequiredDialog];
            return;
        }
    }
    
    // VIP检查通过，继续生成流程（proceedToGenerate）
    [self proceedToGenerate];
}

// 加载素材信息用于VIP检查
- (void)loadMaterialForVipCheck {
    [SVProgressHUD show];
    NSDictionary *params = @{ @"materialId": @(self.materialId) };
    [[NetworkManager sharedManager] GET:BUNNYX_API_MATERIAL_DETAIL parameters:params success:^(id  _Nonnull responseObject) {
        [SVProgressHUD dismiss];
        NSDictionary *data = responseObject[@"data"];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            // 更新Material对象
            self.detailModel = [MaterialDetailModel modelFromResponse:data];
            
            // 检查onlyVip字段
            NSInteger onlyVip = self.detailModel.onlyVip;
            if (onlyVip == 1) {
                // 检查用户是否是VIP
                BOOL isVip = [[UserInfoManager sharedManager] isVip];
                if (!isVip) {
                    // 不是VIP，显示VIP提示弹窗
                    [self showVipRequiredDialog];
                    return;
                }
            }
            
            // VIP检查通过，继续生成流程
            [self proceedToGenerate];
        } else {
            // 获取素材信息失败，直接继续生成流程
            [self proceedToGenerate];
        }
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        // 获取素材信息失败，直接继续生成流程
        [self proceedToGenerate];
    }];
}

// 显示VIP要求弹窗
- (void)showVipRequiredDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"仅VIP可用")
                                                                     message:LocalString(@"此素材仅VIP用户可用，是否前往订阅？")
                                                              preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *subscribeAction = [UIAlertAction actionWithTitle:LocalString(@"去订阅")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        // 关闭当前页面并跳转到首页第三个tab（订阅页面，索引2）
        UITabBarController *tabBarController = self.tabBarController;
        if (tabBarController && tabBarController.viewControllers.count > 2) {
            tabBarController.selectedIndex = 2; // 第三个tab索引为2
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:subscribeAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

// 继续生成流程
- (void)proceedToGenerate {
    [self navigateToUploadMaterial];
}

#pragma mark - Save to Album

// 保存到相册
- (void)saveToAlbumButtonTapped:(UIButton *)sender {
    // 从CreateTask获取videoUrl或imageUrl（生成详情模式）
    // 或者从detailModel获取materialUrl（素材详情模式，但生成详情不应该走这个分支）
    NSString *saveUrl = nil;
    BOOL isVideo = NO;
    
    if (self.pageType == MaterialDetailPageTypeGenerate || self.pageType == MaterialDetailPageTypeGenerateFromUploading) {
        // 生成详情模式：优先使用CreateTask的videoUrl，其次使用imageUrl（mGenerateImageUrl）
        if (self.createTask && self.createTask.videoUrl && self.createTask.videoUrl.length > 0) {
            saveUrl = self.createTask.videoUrl;
            isVideo = YES;
        } else if (self.createTask && self.createTask.imageUrl && self.createTask.imageUrl.length > 0) {
            saveUrl = self.createTask.imageUrl;
            isVideo = NO;
        } else {
            // 如果CreateTask没有URL，尝试从detailModel获取（可能已经通过接口更新了）
            saveUrl = self.detailModel.materialUrl;
            isVideo = (self.detailModel.materialMode == 2);
        }
    } else {
        // 素材详情模式：使用materialUrl（但这种情况不应该显示保存按钮）
        saveUrl = self.detailModel.materialUrl;
        isVideo = (self.detailModel.materialMode == 2);
    }
    
    if (!saveUrl || saveUrl.length == 0) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"URL无效")];
        return;
    }
    
    [SVProgressHUD showWithStatus:LocalString(@"保存中...")];
    
    // 如果还没有确定是视频，通过检查URL或当前显示状态来判断
    if (!isVideo) {
        // 方法1: 检查当前显示的是否是视频（最准确的方法）
        if (self.videoContainer && !self.videoContainer.hidden) {
            isVideo = YES;
        } else {
            // 方法2: 检查URL的扩展名或路径
            NSString *urlLower = [saveUrl lowercaseString];
            if ([urlLower containsString:@".mp4"] || [urlLower containsString:@".mov"] ||
                [urlLower containsString:@".avi"] || [urlLower containsString:@"video"]) {
                isVideo = YES;
            }
        }
    }
    
    if (isVideo) {
        // 保存视频（使用mGenerateImageUrl）
        NSString *videoUrl = saveUrl;
        if (!videoUrl || videoUrl.length == 0) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:LocalString(@"视频URL无效")];
            return;
        }
        
        // 检查相册访问权限
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelAddOnly];
        if (status == PHAuthorizationStatusNotDetermined) {
            // 请求权限
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly handler:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
                        // 权限已授予，继续下载和保存
                        [self downloadAndSaveVideo:videoUrl];
                    } else {
                        [SVProgressHUD dismiss];
                        [SVProgressHUD showErrorWithStatus:LocalString(@"需要相册访问权限才能保存视频")];
                    }
                });
            }];
        } else if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
            // 已有权限，直接下载和保存
            [self downloadAndSaveVideo:videoUrl];
        } else {
            // 权限被拒绝
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:LocalString(@"需要相册访问权限才能保存视频")];
        }
    } else {
        // 保存图片（使用mGenerateImageUrl）
        NSString *imageUrl = saveUrl;
        NSURL *url = [NSURL URLWithString:imageUrl];
        [[SDWebImageManager sharedManager] loadImageWithURL:url
                                                     options:SDWebImageRetryFailed
                                                    progress:nil
                                                   completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            [SVProgressHUD dismiss];
            if (image && finished) {
                UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            } else {
                [SVProgressHUD showErrorWithStatus:LocalString(@"保存失败")];
            }
        }];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"保存失败")];
    } else {
        [SVProgressHUD showSuccessWithStatus:LocalString(@"保存成功")];
    }
}

// 下载并保存视频到相册
- (void)downloadAndSaveVideo:(NSString *)videoUrl {
    [SVProgressHUD showWithStatus:LocalString(@"保存中...")];
    
    NSURL *url = [NSURL URLWithString:videoUrl];
    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || !location) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [SVProgressHUD showErrorWithStatus:LocalString(@"下载视频失败")];
            });
            return;
        }
        
        // 将临时文件复制到持久位置（Documents目录）
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
        NSString *fileName = [NSString stringWithFormat:@"video_%ld_%d.mp4", (long)[[NSDate date] timeIntervalSince1970], arc4random() % 10000];
        NSURL *destinationURL = [documentsDirectory URLByAppendingPathComponent:fileName];
        
        NSError *copyError = nil;
        BOOL success = [fileManager copyItemAtURL:location toURL:destinationURL error:&copyError];
        
        if (!success || copyError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [SVProgressHUD showErrorWithStatus:LocalString(@"保存失败")];
            });
            return;
        }
        
        // 保存视频到相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:destinationURL];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            // 清理临时文件
            [fileManager removeItemAtURL:destinationURL error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [SVProgressHUD showSuccessWithStatus:LocalString(@"保存成功")];
                } else {
                    NSString *errorMsg = error.localizedDescription ?: LocalString(@"保存失败");
                    [SVProgressHUD showErrorWithStatus:errorMsg];
                }
            });
        }];
    }];
    [downloadTask resume];
}

#pragma mark - Delete Action

// 显示删除底部弹窗
- (void)showDeleteActionSheet {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil 
                                                                     message:nil 
                                                              preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 删除选项
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LocalString(@"删除") 
                                                           style:UIAlertActionStyleDestructive 
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self showDeleteConfirmDialog];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消") 
                                                           style:UIAlertActionStyleCancel 
                                                         handler:nil];
    
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    
    // iPad支持
    if (IS_IPAD) {
        alert.popoverPresentationController.sourceView = self.moreButton;
        alert.popoverPresentationController.sourceRect = self.moreButton.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 显示删除确认对话框
- (void)showDeleteConfirmDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"删除素材")
                                                                     message:LocalString(@"确定要删除这个素材吗？")
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:LocalString(@"确定") 
                                                             style:UIAlertActionStyleDestructive 
                                                           handler:^(UIAlertAction * _Nonnull action) {
        [self deleteGenerateMaterial];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消") 
                                                           style:UIAlertActionStyleCancel 
                                                         handler:nil];
    
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 删除生成的素材
- (void)deleteGenerateMaterial {
    if (!self.createTask || !self.createTask.createId || self.createTask.createId.length == 0) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"删除失败：素材信息无效")];
        return;
    }
    
    [SVProgressHUD show];
    // DeleteCreateApi，参数ids（多个用,号分隔）
    NSDictionary *params = @{
        @"ids": self.createTask.createId
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_DELETE_CREATE parameters:params success:^(id  _Nonnull responseObject) {
        [SVProgressHUD dismiss];
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 删除成功后返回并通知列表刷新
            [[NSNotificationCenter defaultCenter] postNotificationName:kGenerateDetailDeletedNotification 
                                                                object:nil 
                                                              userInfo:@{kGenerateDetailDeletedCreateIdKey: self.createTask.createId}];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"删除失败")];
        }
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"删除失败")];
    }];
}

#pragma mark - Helper Methods

// 调整图片大小
- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    if (!image) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

@end
