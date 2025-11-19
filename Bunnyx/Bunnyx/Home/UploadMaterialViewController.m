//
//  UploadMaterialViewController.m
//  Bunnyx
//

#import "UploadMaterialViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "GradientButton.h"
#import "AppConfigManager.h"
#import "AppConfigModel.h"
#import "MaterialDetailModel.h"
#import <TZImagePickerController/TZImagePickerController.h>
#import "UploadingViewController.h"
#import "UploadHistoryManager.h"
#import "UploadHistoryDialog.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import <SDWebImage/SDWebImage.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "ImageUploadManager.h"

@interface UploadMaterialViewController () <TZImagePickerControllerDelegate, UploadHistoryDialogDelegate>

@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, strong) NSString *templateImageUrl; // 模板图片URL

// 上传相关
@property (nonatomic, strong) NSString *selectedImagePath; // 选择的图片路径（用于历史记录）
@property (nonatomic, strong) NSString *compressedImagePath; // 压缩后的图片路径（用于显示）

// ScrollView容器
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// 顶部图标（对齐安卓：icon_photo_right，202x173dp）
@property (nonatomic, strong) UIImageView *topIconView;

// 描述文字（对齐安卓：photo_upload_description）
@property (nonatomic, strong) UILabel *descriptionLabel;

// 中间图片（对齐安卓：icon_photo_error）
@property (nonatomic, strong) UIImageView *centerImageView;

// 占位View（用于撑开空间，对齐安卓：layout_weight=1）
@property (nonatomic, strong) UIView *spacerView;

// 免责声明卡片（对齐安卓：ShapeLinearLayout，背景色#0DFFFFFF）
@property (nonatomic, strong) UIView *disclaimerCardView;
@property (nonatomic, strong) UILabel *disclaimerTitleLabel;
@property (nonatomic, strong) UILabel *disclaimerContentLabel;

// 上传按钮（对齐安卓：渐变背景#0AEA6F到#1CB3C1，包含图标icon_photo_upload）
@property (nonatomic, strong) GradientButton *uploadButton;
@property (nonatomic, strong) UIImageView *uploadIconView;

// 历史记录管理器
@property (nonatomic, strong) UploadHistoryManager *historyManager;

@end

@implementation UploadMaterialViewController

- (instancetype)initWithMaterialId:(NSInteger)materialId {
    self = [super init];
    if (self) {
        _materialId = materialId;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalString(@"上传");
    self.view.backgroundColor = [UIColor blackColor];
    self.historyManager = [UploadHistoryManager sharedManager];
    [self setupUI];
    [self loadDisclaimerFromConfig];
    [self loadMaterialInfo]; // 加载素材信息，获取模板图片URL
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self bringBackButtonToFront];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 调整上传按钮图标和文字的位置（对齐安卓：图标在文字左侧，间距8dp）
    if (self.uploadButton && self.uploadIconView && self.uploadButton.titleLabel) {
        CGSize textSize = [self.uploadButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.uploadButton.titleLabel.font}];
        CGFloat iconWidth = 20.0;
        CGFloat spacing = 8.0;
        CGFloat totalWidth = iconWidth + spacing + textSize.width;
        
        // 图标距离按钮中心的偏移量（负值表示向左偏移）
        CGFloat iconOffset = -totalWidth / 2.0 + iconWidth / 2.0;
        [self.uploadIconView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.uploadButton).offset(iconOffset);
        }];
        
        // 文字距离按钮中心的偏移量（正值表示向右偏移）
        CGFloat textOffset = totalWidth / 2.0 - textSize.width / 2.0;
        self.uploadButton.titleEdgeInsets = UIEdgeInsetsMake(0, textOffset, 0, -textOffset);
    }
}

#pragma mark - UI

- (void)setupUI {
    // ScrollView容器（对齐安卓：ScrollView包裹所有内容）
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    // 顶部图标（对齐安卓：icon_photo_right，202x173dp，marginTop 20dp，marginBottom 16dp）
    self.topIconView = [[UIImageView alloc] init];
    self.topIconView.image = [UIImage imageNamed:@"icon_photo_right"];
    self.topIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.topIconView];
    
    [self.topIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(STATUS_BAR_HEIGHT+NAVIGATION_BAR_HEIGHT+ MARGIN_20);
        make.centerX.equalTo(self.contentView);
        make.width.mas_equalTo(202);
        make.height.mas_equalTo(173);
    }];
    
    // 描述文字（对齐安卓：photo_upload_description，居中，marginBottom 32dp，17sp，白色）
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.text = LocalString(@"使用一张单人照片\n使用一张正面且清晰的照片");
    self.descriptionLabel.textColor = [UIColor whiteColor];
    self.descriptionLabel.font = FONT(17);
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.numberOfLines = 0;
    [self.contentView addSubview:self.descriptionLabel];
    
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topIconView.mas_bottom).offset(16);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 24, 0, 24));
        make.centerX.equalTo(self.contentView);
    }];
    
    // 中间图片（对齐安卓：icon_photo_error，居中，marginBottom 32dp）
    self.centerImageView = [[UIImageView alloc] init];
    self.centerImageView.image = [UIImage imageNamed:@"icon_photo_error"];
    self.centerImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.centerImageView];
    
    [self.centerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descriptionLabel.mas_bottom).offset(32);
        make.centerX.equalTo(self.contentView);
        make.width.offset(375);
        make.height.offset(66);
    }];
    
    // 占位View（对齐安卓：layout_weight=1，用于撑开空间，让底部内容靠下）
    self.spacerView = [[UIView alloc] init];
    [self.contentView addSubview:self.spacerView];
    
    [self.spacerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.centerImageView.mas_bottom).offset(32);
        make.left.right.equalTo(self.contentView);
        make.height.greaterThanOrEqualTo(@1); // 最小高度1，用于撑开空间
    }];
    
    // 免责声明卡片（对齐安卓：ShapeLinearLayout，padding 16dp，圆角12dp，背景色#0DFFFFFF，marginBottom 32dp）
    self.disclaimerCardView = [[UIView alloc] init];
    // 背景色#0DFFFFFF = RGB(13, 255, 255) = 13/255的白色，即alpha约0.05
    self.disclaimerCardView.backgroundColor = RGBA(255, 255, 255, 13.0/255.0);
    self.disclaimerCardView.layer.cornerRadius = CORNER_RADIUS_12;
    self.disclaimerCardView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.disclaimerCardView];
    
    // 免责声明标题（对齐安卓：居中，marginBottom 8dp，17sp，白色）
    self.disclaimerTitleLabel = [[UILabel alloc] init];
    self.disclaimerTitleLabel.text = LocalString(@"免责声明");
    self.disclaimerTitleLabel.textColor = [UIColor whiteColor];
    self.disclaimerTitleLabel.font = FONT(17);
    self.disclaimerTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.disclaimerCardView addSubview:self.disclaimerTitleLabel];
    
    // 免责声明内容（对齐安卓：14sp，白色，行间距4dp）
    self.disclaimerContentLabel = [[UILabel alloc] init];
    self.disclaimerContentLabel.textColor = [UIColor whiteColor];
    self.disclaimerContentLabel.font = FONT(FONT_SIZE_14);
    self.disclaimerContentLabel.numberOfLines = 0;
    // 设置行间距（对齐安卓：lineSpacingExtra 4dp）
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4.0;
    [self.disclaimerCardView addSubview:self.disclaimerContentLabel];
    
    [self.disclaimerCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.spacerView.mas_bottom);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 24, 0, 24));
    }];
    
    [self.disclaimerTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.disclaimerCardView).offset(16);
        make.left.right.equalTo(self.disclaimerCardView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        make.centerX.equalTo(self.disclaimerCardView);
    }];
    
    [self.disclaimerContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.disclaimerTitleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.disclaimerCardView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        make.bottom.equalTo(self.disclaimerCardView).offset(-16);
    }];
    
    // 上传按钮（对齐安卓：高度48dp，圆角12dp，渐变背景#0AEA6F到#1CB3C1，marginBottom 15dp，包含图标icon_photo_upload）
    // 渐变起始颜色：#0AEA6F (RGB: 10, 234, 111)
    // 渐变结束颜色：#1CB3C1 (RGB: 28, 179, 193)
    self.uploadButton = [GradientButton buttonWithTitle:LocalString(@"上传")
                                               startColor:RGB(10, 234, 111)
                                                 endColor:RGB(28, 179, 193)];
    [self.uploadButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal];
    self.uploadButton.titleLabel.font = FONT(16);
    self.uploadButton.cornerRadius = CORNER_RADIUS_12;
    self.uploadButton.buttonHeight = 48;
    [self.uploadButton addTarget:self action:@selector(uploadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.uploadButton];
    
    // 上传按钮图标（对齐安卓：icon_photo_upload，20x20dp，在文字左侧，marginEnd 8dp）
    self.uploadIconView = [[UIImageView alloc] init];
    self.uploadIconView.image = [UIImage imageNamed:@"icon_photo_upload"];
    self.uploadIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.uploadButton addSubview:self.uploadIconView];
    
    [self.uploadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.disclaimerCardView.mas_bottom).offset(32);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 24, 0, 24));
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.contentView).offset(-24);
    }];
    
    // 图标在文字左侧（对齐安卓布局：图标在文字左侧，间距8dp）
    // 先设置图标约束，让它在按钮中心左侧
    [self.uploadIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.uploadButton);
        make.width.height.mas_equalTo(20);
        // 图标位置会在viewDidLayoutSubviews中调整
    }];
}


#pragma mark - Data

/// 加载订阅VIP提示文字（对齐安卓：loadSubscribeVipTips方法）
- (void)loadDisclaimerFromConfig {
    // 对齐安卓：先尝试从缓存获取配置
    AppConfigModel *cachedConfig = [[AppConfigManager sharedManager] currentConfig];
    if (cachedConfig) {
        // 缓存中有配置，直接使用（对齐安卓逻辑）
        NSString *subscribeVipTips = [self getSubscribeVipTips:cachedConfig];
        if (subscribeVipTips && subscribeVipTips.length > 0) {
            // 设置行间距（对齐安卓：lineSpacingExtra 4dp）
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 4.0;
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:subscribeVipTips];
            [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, subscribeVipTips.length)];
            self.disclaimerContentLabel.attributedText = attributedText;
        } else {
            // 缓存中没有订阅提示文字，使用默认文字（对齐安卓逻辑）
            [self setDefaultDisclaimerContent];
        }
    } else {
        // 缓存中没有配置，请求接口获取（对齐安卓逻辑）
        [[AppConfigManager sharedManager] getAppConfigWithSuccess:^(AppConfigModel *config) {
            // 获取subscribe_vip_tips字段（对齐安卓逻辑）
            NSString *subscribeVipTips = [self getSubscribeVipTips:config];
            if (subscribeVipTips && subscribeVipTips.length > 0) {
                // 设置行间距（对齐安卓：lineSpacingExtra 4dp）
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.lineSpacing = 4.0;
                NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:subscribeVipTips];
                [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, subscribeVipTips.length)];
                self.disclaimerContentLabel.attributedText = attributedText;
            } else {
                // 接口返回中没有订阅提示文字，使用默认文字（对齐安卓逻辑）
                [self setDefaultDisclaimerContent];
            }
        } failure:^(NSError *error) {
            // 接口请求失败，使用默认文字（对齐安卓逻辑）
            [self setDefaultDisclaimerContent];
        }];
    }
}

/// 获取订阅VIP提示文字（对齐安卓：getSubscribeVipTips方法）
- (NSString *)getSubscribeVipTips:(AppConfigModel *)config {
    // 对齐安卓：直接返回subscribe_vip_tips字段（安卓中返回tipsJson）
    if (config && config.subscribeVipTips && config.subscribeVipTips.length > 0) {
        return config.subscribeVipTips;
    }
    return nil;
}

/// 设置默认免责声明内容（对齐安卓：setDefaultDisclaimerContent方法）
- (void)setDefaultDisclaimerContent {
    // 对齐安卓：使用默认文案（disclaimer_content_default）
    NSString *defaultTips = LocalString(@"请上传您自己的照片。如果您使用他人的照片，请先获得他们的明确许可。上传失败可能违反他们的隐私，并可能导致法律责任。感谢您的合作！");
    
    // 设置行间距（对齐安卓：lineSpacingExtra 4dp）
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4.0;
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:defaultTips];
    [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, defaultTips.length)];
    self.disclaimerContentLabel.attributedText = attributedText;
}

#pragma mark - Actions

- (void)uploadButtonTapped:(UIButton *)sender {
    // 对齐安卓逻辑：如果有历史记录，显示选择弹窗；否则直接打开相册
    if ([self.historyManager hasHistory]) {
        // 有历史记录，显示历史记录选择弹窗（对齐安卓UploadHistoryDialog）
        [UploadHistoryDialog showWithDelegate:self];
    } else {
        // 没有历史记录，直接打开相册
        [self selectPhoto];
    }
}

- (void)selectPhoto {
    TZImagePickerController *picker = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
    picker.allowPickingVideo = NO;
    picker.allowTakeVideo = NO;
    picker.allowTakePicture = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - TZImagePickerControllerDelegate

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    if (photos.count == 0) {
        return;
    }
    
    // 对齐安卓：选择图片后，保存图片路径用于历史记录
    UIImage *image = photos.firstObject;
    
    // 保存图片到临时目录，获取路径（对齐安卓：mSelectedImageUri）
    NSString *tempDir = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"selected_image_%ld.jpg", (long)[[NSDate date] timeIntervalSince1970]];
    NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    if ([imageData writeToFile:filePath atomically:YES]) {
        self.selectedImagePath = filePath;
        BUNNYX_LOG(@"保存选择的图片路径: %@", self.selectedImagePath);
    } else {
        // 如果保存失败，使用时间戳作为标识
        self.selectedImagePath = [NSString stringWithFormat:@"upload_%ld", (long)[[NSDate date] timeIntervalSince1970]];
    }
    
    // 开始上传流程（对齐安卓：compressImage -> uploadToAws -> callGenerateCreate）
    [self startUploadWithImage:image];
}

/// 开始上传流程（对齐安卓：compressImage方法）
- (void)startUploadWithImage:(UIImage *)image {
    if (!image) {
        return;
    }
    
    // 显示加载提示（对齐安卓：showDialog）
    [SVProgressHUD showWithStatus:LocalString(@"正在处理图片...")];
    
    // 对齐安卓：使用ImageUploadManager处理完整流程（压缩 -> 上传 -> 返回路径）
    [[ImageUploadManager sharedManager] uploadImage:self.materialId
                                              image:image
                                            progress:^(CGFloat progress, NSString *status) {
        // 更新进度（可选）
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showProgress:progress status:status];
        });
    } success:^(NSString *initImage, NSString *fullUrl) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 上传成功，保存历史记录（对齐安卓：uploadToS3的onSuccess回调）
            if (self.selectedImagePath) {
                UploadHistoryManager *historyManager = [UploadHistoryManager sharedManager];
                // 对齐安卓：使用selectedImagePath作为imageUri，initImage作为awsRelativePath
                // 使用fullUrl作为awsFullPath（完整URL，用于app重启后显示图片）
                NSString *awsFullPath = fullUrl ?: initImage; // 优先使用完整URL，如果没有则使用相对路径
                [historyManager addUploadHistory:self.selectedImagePath 
                                 awsRelativePath:initImage 
                                     awsFullPath:awsFullPath];
                BUNNYX_LOG(@"保存历史记录 - 图片路径: %@, AWS相对路径: %@, AWS完整URL: %@", self.selectedImagePath, initImage, fullUrl);
            }
            
            // 调用生成接口（对齐安卓：callGenerateCreate方法）
            [self callGenerateCreate:initImage];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 上传失败（对齐安卓：uploadToS3的onError回调）
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: LocalString(@"图片上传失败")];
            BUNNYX_ERROR(@"图片上传失败: %@", error.localizedDescription);
        });
    }];
}

/// 调用生成接口（对齐安卓：callGenerateCreate方法）
- (void)callGenerateCreate:(NSString *)relativePath {
    NSDictionary *parameters = @{
        @"materialId": @(self.materialId),
        @"initImage": relativePath
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_GENERATE_CREATE
                                parameters:parameters
                                   success:^(id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            NSDictionary *dict = (NSDictionary *)responseObject;
            NSInteger code = [dict[@"code"] integerValue];
            
            if (code == 0) {
                NSString *createIds = dict[@"data"];
                if (createIds && createIds.length > 0) {
                    BUNNYX_LOG(@"提交生成任务成功，createIds: %@", createIds);
                    
                    // 对齐安卓：跳转到上传中页面，传递createIds、压缩图片路径、模板图片URL、materialId
                    // 注意：iOS中compressedImagePath用于显示，实际使用selectedImagePath
                    UploadingViewController *uploadingVC = [[UploadingViewController alloc] initWithMaterialId:self.materialId 
                                                                                                         image:nil 
                                                                                                    createIds:createIds 
                                                                                              uploadedImagePath:self.selectedImagePath 
                                                                                               templateImageUrl:self.templateImageUrl];
                    [self.navigationController pushViewController:uploadingVC animated:YES];
                } else {
                    [SVProgressHUD showErrorWithStatus:LocalString(@"提交生成任务失败")];
                }
            } else {
                // 对齐安卓：显示promptType
                NSString *promptType = dict[@"promptType"];
                NSString *errorMessage = promptType ?: dict[@"message"] ?: LocalString(@"提交生成任务失败");
                [SVProgressHUD showErrorWithStatus:errorMessage];
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:LocalString(@"网络错误")];
            BUNNYX_ERROR(@"提交生成任务失败: %@", error.localizedDescription);
        });
    }];
}

- (void)loadMaterialInfo {
    // 加载素材信息，获取模板图片URL（参考安卓逻辑）
    NSDictionary *params = @{ @"materialId": @(self.materialId) };
    [[NetworkManager sharedManager] GET:BUNNYX_API_MATERIAL_DETAIL 
                              parameters:params 
                                 success:^(id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        
        if (code == 0) {
            NSDictionary *data = dict[@"data"];
            if (data && [data isKindOfClass:[NSDictionary class]]) {
                MaterialDetailModel *material = [MaterialDetailModel modelFromResponse:data];
                if (material && material.materialUrl && material.materialUrl.length > 0) {
                    self.templateImageUrl = material.materialUrl;
                    BUNNYX_LOG(@"加载素材信息成功，模板图片URL: %@", self.templateImageUrl);
                }
            }
        }
    } failure:^(NSError *error) {
        // 获取素材信息失败，不影响主要功能
        BUNNYX_LOG(@"获取素材信息失败: %@", error.localizedDescription);
    }];
}

#pragma mark - UploadHistoryDialogDelegate

- (void)uploadHistoryDialog:(UploadHistoryDialog *)dialog didSelectImage:(NSString *)imagePath {
    // 对齐安卓：选择了新图片，直接开始上传流程
    // 注意：iOS中通过TZImagePickerController选择，这里不需要处理
    // 图片选择会通过TZImagePickerControllerDelegate回调处理
}

- (void)uploadHistoryDialog:(UploadHistoryDialog *)dialog didGenerateFromHistory:(UploadHistoryItem *)historyItem {
    // 对齐安卓：从历史记录生成，使用历史记录的AWS路径
    if (!historyItem || !historyItem.awsRelativePath || historyItem.awsRelativePath.length == 0) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"历史记录无效")];
        return;
    }
    
    // 调用生成接口（对齐安卓逻辑）
    NSDictionary *parameters = @{
        @"materialId": @(self.materialId),
        @"initImage": historyItem.awsRelativePath
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_GENERATE_CREATE
                                parameters:parameters
                                   success:^(id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        
        if (code == 0) {
            NSString *createIds = dict[@"data"];
            if (createIds && createIds.length > 0) {
                BUNNYX_LOG(@"提交生成任务成功，createIds: %@", createIds);
                
                // 跳转到上传中页面（使用历史记录的图片路径，对齐安卓逻辑）
                UploadingViewController *uploadingVC = [[UploadingViewController alloc] initWithMaterialId:self.materialId 
                                                                                                     image:nil 
                                                                                            createIds:createIds 
                                                                                      uploadedImagePath:historyItem.imageUri 
                                                                                       templateImageUrl:self.templateImageUrl];
                [self.navigationController pushViewController:uploadingVC animated:YES];
            } else {
                [SVProgressHUD showErrorWithStatus:LocalString(@"提交生成任务失败")];
            }
        } else {
            NSString *promptType = dict[@"promptType"];
            NSString *errorMessage = promptType ?: dict[@"message"] ?: LocalString(@"提交生成任务失败");
            [SVProgressHUD showErrorWithStatus:errorMessage];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"网络错误")];
        BUNNYX_ERROR(@"提交生成任务失败: %@", error.localizedDescription);
    }];
}

- (void)uploadHistoryDialogDidRequestImageSelection:(UploadHistoryDialog *)dialog {
    // 对齐安卓：请求图片选择，打开相册
    [self selectPhoto];
}


@end


