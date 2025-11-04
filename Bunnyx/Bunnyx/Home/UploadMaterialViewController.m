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
#import <TZImagePickerController/TZImagePickerController.h>
#import "ImageUploadManager.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface UploadMaterialViewController () <TZImagePickerControllerDelegate>

@property (nonatomic, assign) NSInteger materialId;

// 预览与指导
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIView *checkBadgeView;
@property (nonatomic, strong) UILabel *tipLine1Label;
@property (nonatomic, strong) UILabel *tipLine2Label;

// 缩略图列表
@property (nonatomic, strong) UIScrollView *thumbsScrollView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;

// 免责声明
@property (nonatomic, strong) UIView *disclaimerCardView;
@property (nonatomic, strong) UILabel *disclaimerTitleLabel;
@property (nonatomic, strong) UILabel *disclaimerContentLabel;

// 上传按钮
@property (nonatomic, strong) GradientButton *uploadButton;

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
    self.title = @"";
    self.view.backgroundColor = [UIColor blackColor];
    self.selectedImages = [NSMutableArray array];
    [self setupUI];
    [self loadDisclaimerFromConfig];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self bringBackButtonToFront];
}

#pragma mark - UI

- (void)setupUI {
    // 预览
    self.previewImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"upload_preview_placeholder"] ?: [UIImage systemImageNamed:@"person.crop.square"]];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.previewImageView.layer.cornerRadius = 16;
    self.previewImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.previewImageView];
    
    [self.previewImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(MARGIN_20 + 10);
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(0.7);
        make.height.equalTo(self.previewImageView.mas_width).multipliedBy(1.0);
    }];
    
    // 勾选徽章
    self.checkBadgeView = [[UIView alloc] init];
    self.checkBadgeView.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.5 alpha:1.0];
    self.checkBadgeView.layer.cornerRadius = 16;
    self.checkBadgeView.layer.masksToBounds = YES;
    UIImageView *checkIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark"]];
    checkIcon.tintColor = [UIColor whiteColor];
    [self.checkBadgeView addSubview:checkIcon];
    [checkIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.checkBadgeView);
        make.width.height.mas_equalTo(16);
    }];
    [self.view addSubview:self.checkBadgeView];
    [self.checkBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.previewImageView.mas_right).offset(-10);
        make.bottom.equalTo(self.previewImageView.mas_bottom).offset(-10);
        make.width.height.mas_equalTo(32);
    }];
    
    // 指导文案
    self.tipLine1Label = [[UILabel alloc] init];
    self.tipLine1Label.text = LocalString(@"使用单人正脸照片");
    self.tipLine1Label.textColor = [UIColor whiteColor];
    self.tipLine1Label.font = BOLD_FONT(FONT_SIZE_16);
    self.tipLine1Label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.tipLine1Label];
    
    self.tipLine2Label = [[UILabel alloc] init];
    self.tipLine2Label.text = LocalString(@"确保清晰、正面、无遮挡");
    self.tipLine2Label.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.tipLine2Label.font = FONT(FONT_SIZE_14);
    self.tipLine2Label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.tipLine2Label];
    
    [self.tipLine1Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.previewImageView.mas_bottom).offset(MARGIN_15);
        make.centerX.equalTo(self.view);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    [self.tipLine2Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLine1Label.mas_bottom).offset(4);
        make.centerX.equalTo(self.view);
        make.left.right.equalTo(self.tipLine1Label);
    }];
    
    // 缩略图横向列表
    self.thumbsScrollView = [[UIScrollView alloc] init];
    self.thumbsScrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.thumbsScrollView];
    [self.thumbsScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLine2Label.mas_bottom).offset(MARGIN_15);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(76);
    }];
    [self reloadThumbs];
    
    // 免责声明卡片
    self.disclaimerCardView = [[UIView alloc] init];
    self.disclaimerCardView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
    self.disclaimerCardView.layer.cornerRadius = 12;
    self.disclaimerCardView.layer.masksToBounds = YES;
    [self.view addSubview:self.disclaimerCardView];
    
    self.disclaimerTitleLabel = [[UILabel alloc] init];
    self.disclaimerTitleLabel.text = @"Disclaimer";
    self.disclaimerTitleLabel.textColor = [UIColor whiteColor];
    self.disclaimerTitleLabel.font = BOLD_FONT(FONT_SIZE_14);
    [self.disclaimerCardView addSubview:self.disclaimerTitleLabel];
    
    self.disclaimerContentLabel = [[UILabel alloc] init];
    self.disclaimerContentLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.disclaimerContentLabel.font = FONT(FONT_SIZE_12);
    self.disclaimerContentLabel.numberOfLines = 0;
    [self.disclaimerCardView addSubview:self.disclaimerContentLabel];
    
    [self.disclaimerCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-90);
    }];
    [self.disclaimerTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.disclaimerCardView).offset(12);
        make.left.equalTo(self.disclaimerCardView).offset(12);
        make.right.equalTo(self.disclaimerCardView).offset(-12);
    }];
    [self.disclaimerContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.disclaimerTitleLabel.mas_bottom).offset(6);
        make.left.right.equalTo(self.disclaimerTitleLabel);
        make.bottom.equalTo(self.disclaimerCardView).offset(-12);
    }];
    
    // 上传按钮
    self.uploadButton = [GradientButton buttonWithTitle:LocalString(@"上传")];
    [self.uploadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.uploadButton.cornerRadius = 20;
    [self.uploadButton addTarget:self action:@selector(uploadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.uploadButton];
    [self.uploadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.height.mas_equalTo(50);
    }];
}

- (void)reloadThumbs {
    // 清空
    for (UIView *v in self.thumbsScrollView.subviews) { [v removeFromSuperview]; }
    CGFloat margin = 16;
    CGFloat x = margin;
    CGFloat itemSize = 60;
    NSInteger maxCount = 4;
    
    // 已选缩略图
    for (NSInteger i = 0; i < self.selectedImages.count; i++) {
        UIImage *img = self.selectedImages[i];
        UIView *wrap = [[UIView alloc] initWithFrame:CGRectMake(x, 8, itemSize, itemSize)];
        wrap.layer.cornerRadius = 10; wrap.layer.masksToBounds = YES;
        wrap.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        UIImageView *iv = [[UIImageView alloc] initWithImage:img];
        iv.contentMode = UIViewContentModeScaleAspectFill; iv.frame = wrap.bounds; iv.clipsToBounds = YES;
        [wrap addSubview:iv];
        
        // 删除按钮
        UIButton *del = [UIButton buttonWithType:UIButtonTypeCustom];
        del.backgroundColor = [UIColor colorWithRed:1.0 green:0.25 blue:0.25 alpha:1.0];
        del.layer.cornerRadius = 10; del.layer.masksToBounds = YES;
        [del setTitle:@"✕" forState:UIControlStateNormal];
        del.titleLabel.font = BOLD_FONT(12);
        del.frame = CGRectMake(itemSize-18, -2, 20, 20);
        del.tag = i; [del addTarget:self action:@selector(onDeleteThumb:) forControlEvents:UIControlEventTouchUpInside];
        [wrap addSubview:del];
        
        [self.thumbsScrollView addSubview:wrap];
        x += itemSize + margin;
    }
    
    // 添加按钮
    if (self.selectedImages.count < maxCount) {
        UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        addBtn.frame = CGRectMake(x, 8, itemSize, itemSize);
        addBtn.layer.cornerRadius = 10; addBtn.layer.masksToBounds = YES;
        addBtn.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        [addBtn setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
        addBtn.tintColor = [UIColor whiteColor];
        [addBtn addTarget:self action:@selector(onAddTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.thumbsScrollView addSubview:addBtn];
        x += itemSize + margin;
    }
    self.thumbsScrollView.contentSize = CGSizeMake(MAX(x, self.view.bounds.size.width), 76);
}

#pragma mark - Data

- (void)loadDisclaimerFromConfig {
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    NSString *tips = config.disclaimerTips;
    if (BUNNYX_IS_EMPTY_STRING(tips)) {
        tips = LocalString(@"请上传本人照片，上传他人照片需获得其明确授权。未经授权上传可能侵犯他人隐私并承担法律责任。");
    }
    self.disclaimerContentLabel.text = tips;
}

#pragma mark - Actions

- (void)onAddTapped {
    TZImagePickerController *picker = [[TZImagePickerController alloc] initWithMaxImagesCount:(4 - self.selectedImages.count) delegate:self];
    picker.allowPickingVideo = NO; picker.allowTakeVideo = NO; picker.allowTakePicture = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)onDeleteThumb:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx >= 0 && idx < self.selectedImages.count) {
        [self.selectedImages removeObjectAtIndex:idx];
        [self reloadThumbs];
    }
}

- (void)uploadButtonTapped:(UIButton *)sender {
    if (self.selectedImages.count == 0) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"请先选择图片")];
        return;
    }
    
    // 使用第一张图片进行上传和生成
    UIImage *image = self.selectedImages.firstObject;
    [self startUploadAndGenerateWithImage:image];
}

#pragma mark - Upload & Generate Flow

- (void)startUploadAndGenerateWithImage:(UIImage *)image {
    BUNNYX_LOG(@"开始上传生成流程，materialId: %ld", (long)self.materialId);
    
    // 使用 ImageUploadManager 上传图片（按照安卓版逻辑）
    [[ImageUploadManager sharedManager] uploadImage:self.materialId
                                              image:image
                                            progress:^(CGFloat progress, NSString *status) {
        // 显示进度
        [SVProgressHUD showProgress:progress status:status];
    } success:^(NSString *initImage) {
        // 上传成功，提交生成任务
        BUNNYX_LOG(@"图片上传成功，initImage: %@", initImage);
        [SVProgressHUD showProgress:0.8 status:LocalString(@"正在提交生成任务...")];
        [self submitGenerateTaskWithImagePath:initImage];
    } failure:^(NSError *error) {
        // 上传失败
        [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: LocalString(@"图片上传失败")];
        BUNNYX_ERROR(@"图片上传失败: %@", error.localizedDescription);
    }];
}

- (void)submitGenerateTaskWithImagePath:(NSString *)imagePath {
    NSDictionary *parameters = @{
        @"materialId": @(self.materialId),
        @"initImage": imagePath
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_GENERATE_CREATE
                                parameters:parameters
                                   success:^(id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        
        if (code == 0) {
            NSString *createId = dict[@"data"];
            if (createId && createId.length > 0) {
                BUNNYX_LOG(@"提交生成任务成功，createId: %@", createId);
                [SVProgressHUD showSuccessWithStatus:LocalString(@"提交成功")];
                
                // TODO: 可以跳转到生成结果页面或返回上一页
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });
            } else {
                [SVProgressHUD showErrorWithStatus:LocalString(@"提交生成任务失败")];
            }
        } else {
            // 与安卓版一致：显示promptType
            NSString *promptType = dict[@"promptType"];
            NSString *errorMessage = promptType ?: dict[@"message"] ?: LocalString(@"提交生成任务失败");
            [SVProgressHUD showErrorWithStatus:errorMessage];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"网络错误")];
        BUNNYX_ERROR(@"提交生成任务失败: %@", error.localizedDescription);
    }];
}

#pragma mark - TZImagePickerControllerDelegate

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    [self.selectedImages addObjectsFromArray:photos];
    // 设置第一张作为预览
    if (self.selectedImages.count > 0) {
        self.previewImageView.image = self.selectedImages.firstObject;
    }
    [self reloadThumbs];
}

@end


