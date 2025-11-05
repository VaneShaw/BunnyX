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
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import <SDWebImage/SDWebImage.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface UploadMaterialViewController () <TZImagePickerControllerDelegate>

@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, strong) NSString *templateImageUrl; // 模板图片URL

// 预览与指导
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIView *checkBadgeView;
@property (nonatomic, strong) UILabel *tipLine1Label;
@property (nonatomic, strong) UILabel *tipLine2Label;

// 无效示例（4个小图，带X标记）
@property (nonatomic, strong) UIView *invalidExamplesContainer;
@property (nonatomic, strong) NSMutableArray<UIView *> *invalidExampleViews;

// 当前选择的图片（新增或历史）
@property (nonatomic, strong) UIImage *currentSelectedImage;
@property (nonatomic, strong) NSString *currentSelectedImageUrl; // 历史记录的URL

// 历史记录
@property (nonatomic, strong) UIView *historyContainer;
@property (nonatomic, strong) UIScrollView *historyScrollView;
@property (nonatomic, strong) NSArray<UploadHistoryItem *> *historyItems;
@property (nonatomic, strong) UploadHistoryItem *selectedHistoryItem;
@property (nonatomic, strong) UploadHistoryManager *historyManager;

// 缩略图列表（已选择的图片）
@property (nonatomic, strong) UIScrollView *thumbsScrollView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;

// 免责声明
@property (nonatomic, strong) UIView *disclaimerCardView;
@property (nonatomic, strong) UILabel *disclaimerTitleLabel;
@property (nonatomic, strong) UILabel *disclaimerContentLabel;

// 按钮
@property (nonatomic, strong) GradientButton *uploadButton;
@property (nonatomic, strong) GradientButton *generateButton;

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
    self.title = LocalString(@"上传素材");
    self.view.backgroundColor = [UIColor blackColor];
    self.selectedImages = [NSMutableArray array];
    self.historyItems = @[];
    self.invalidExampleViews = [NSMutableArray array];
    self.historyManager = [UploadHistoryManager sharedManager];
    [self setupUI];
    [self loadDisclaimerFromConfig];
    [self loadHistory];
    [self loadMaterialInfo]; // 加载素材信息，获取模板图片URL
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
    
    // 无效示例容器（4个小图，带X标记）
    [self setupInvalidExamples];
    
    // 历史记录容器（在有历史记录时显示）
    self.historyContainer = [[UIView alloc] init];
    [self.view addSubview:self.historyContainer];
    
    self.historyScrollView = [[UIScrollView alloc] init];
    self.historyScrollView.showsHorizontalScrollIndicator = NO;
    [self.historyContainer addSubview:self.historyScrollView];
    
    [self.historyContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.invalidExamplesContainer.mas_bottom).offset(MARGIN_15);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(76);
    }];
    
    [self.historyScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.historyContainer);
    }];
    
    self.historyContainer.hidden = YES;
    
    // 缩略图横向列表（当前选择的图片）
    self.thumbsScrollView = [[UIScrollView alloc] init];
    self.thumbsScrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.thumbsScrollView];
    [self.thumbsScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.invalidExamplesContainer.mas_bottom).offset(MARGIN_15);
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
    
    // 上传按钮（带图标）
    self.uploadButton = [GradientButton buttonWithTitle:LocalString(@"上传")];
    [self.uploadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.uploadButton.cornerRadius = 20;
    // TODO: 添加上传图标（切图占位） - [self.uploadButton setImage:[UIImage imageNamed:@"icon_upload"] forState:UIControlStateNormal];
    [self.uploadButton addTarget:self action:@selector(uploadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.uploadButton];
    
    // 生成按钮（历史记录存在时显示）
    self.generateButton = [GradientButton buttonWithTitle:LocalString(@"生成")];
    [self.generateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.generateButton.cornerRadius = 20;
    // TODO: 生成按钮使用不同的渐变色（切图占位）
    [self.generateButton addTarget:self action:@selector(generateButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.generateButton];
    self.generateButton.hidden = YES;
    
    [self updateButtonLayout];
}

- (void)updateButtonLayout {
    if (self.historyItems.count > 0 && self.selectedHistoryItem) {
        // 有历史记录且已选中，显示两个按钮
        self.uploadButton.hidden = NO;
        self.generateButton.hidden = NO;
        
        [self.uploadButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-70);
            make.height.mas_equalTo(50);
        }];
        
        [self.generateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
            make.height.mas_equalTo(50);
        }];
    } else {
        // 没有历史记录，只显示上传按钮
        self.uploadButton.hidden = NO;
        self.generateButton.hidden = YES;
        
        [self.uploadButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
            make.height.mas_equalTo(50);
        }];
    }
}

- (void)setupInvalidExamples {
    self.invalidExamplesContainer = [[UIView alloc] init];
    [self.view addSubview:self.invalidExamplesContainer];
    
    [self.invalidExamplesContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLine2Label.mas_bottom).offset(MARGIN_15);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(60);
    }];
    
    // 创建4个无效示例
    CGFloat itemSize = 50;
    CGFloat spacing = (self.view.bounds.size.width - 40 - itemSize * 4) / 3;
    
    for (NSInteger i = 0; i < 4; i++) {
        UIView *exampleView = [[UIView alloc] init];
        exampleView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        exampleView.layer.cornerRadius = 8;
        exampleView.layer.masksToBounds = YES;
        [self.invalidExamplesContainer addSubview:exampleView];
        [self.invalidExampleViews addObject:exampleView];
        
        // 占位图片
        UIImageView *placeholderIV = [[UIImageView alloc] init];
        // TODO: 使用切图占位 - placeholderIV.image = [UIImage imageNamed:[NSString stringWithFormat:@"invalid_example_%ld", (long)i]];
        placeholderIV.image = [UIImage systemImageNamed:@"person.crop.square"];
        placeholderIV.contentMode = UIViewContentModeScaleAspectFill;
        placeholderIV.clipsToBounds = YES;
        placeholderIV.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        [exampleView addSubview:placeholderIV];
        
        // X标记
        UIImageView *xMark = [[UIImageView alloc] init];
        // TODO: 使用切图占位 - xMark.image = [UIImage imageNamed:@"icon_invalid_x"];
        xMark.image = [UIImage systemImageNamed:@"xmark.circle.fill"];
        xMark.tintColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
        [exampleView addSubview:xMark];
        
        [exampleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.invalidExamplesContainer).offset(i * (itemSize + spacing));
            make.top.equalTo(self.invalidExamplesContainer);
            make.width.height.mas_equalTo(itemSize);
        }];
        
        [placeholderIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(exampleView);
        }];
        
        [xMark mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.right.equalTo(exampleView).insets(UIEdgeInsetsMake(-4, -4, 0, 0));
            make.width.height.mas_equalTo(16);
        }];
    }
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

- (void)loadHistory {
    // 加载历史记录
    self.historyItems = [self.historyManager getUploadHistoryList];
    
    // 默认选中最新的历史记录
    if (self.historyItems.count > 0) {
        self.selectedHistoryItem = self.historyItems.firstObject;
    }
    
    // 更新UI
    [self reloadHistoryUI];
    [self updateButtonLayout];
}

- (void)reloadHistoryUI {
    // 清空历史记录视图
    for (UIView *view in self.historyScrollView.subviews) {
        [view removeFromSuperview];
    }
    
    if (self.historyItems.count == 0) {
        self.historyContainer.hidden = YES;
        return;
    }
    
    self.historyContainer.hidden = NO;
    
    CGFloat margin = 16;
    CGFloat x = margin;
    CGFloat itemSize = 60;
    
    // 添加"+"按钮（添加新图片）
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(x, 8, itemSize, itemSize);
    addBtn.layer.cornerRadius = 10;
    addBtn.layer.masksToBounds = YES;
    addBtn.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    // TODO: 使用切图占位 - [addBtn setImage:[UIImage imageNamed:@"icon_add_history"] forState:UIControlStateNormal];
    [addBtn setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
    addBtn.tintColor = [UIColor whiteColor];
    [addBtn addTarget:self action:@selector(selectPhoto) forControlEvents:UIControlEventTouchUpInside];
    [self.historyScrollView addSubview:addBtn];
    x += itemSize + margin;
    
    // 添加历史记录项
    for (NSInteger i = 0; i < self.historyItems.count; i++) {
        UploadHistoryItem *item = self.historyItems[i];
        UIView *wrap = [[UIView alloc] initWithFrame:CGRectMake(x, 8, itemSize, itemSize)];
        wrap.layer.cornerRadius = 10;
        wrap.layer.masksToBounds = YES;
        wrap.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        wrap.tag = i;
        
        // 添加点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onHistoryItemTapped:)];
        [wrap addGestureRecognizer:tap];
        
        // 图片视图
        UIImageView *iv = [[UIImageView alloc] init];
        iv.frame = wrap.bounds;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        
        // 加载图片（从Uri或URL）
        if ([item.imageUri hasPrefix:@"http://"] || [item.imageUri hasPrefix:@"https://"]) {
            [iv sd_setImageWithURL:[NSURL URLWithString:item.imageUri] 
                   placeholderImage:[UIImage systemImageNamed:@"photo"]];
        } else {
            // 本地路径
            UIImage *localImage = [UIImage imageWithContentsOfFile:item.imageUri];
            if (localImage) {
                iv.image = localImage;
            } else {
                iv.image = [UIImage systemImageNamed:@"photo"];
            }
        }
        [wrap addSubview:iv];
        
        // 选中标记
        if (item == self.selectedHistoryItem) {
            wrap.layer.borderWidth = 2;
            wrap.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.5 alpha:1.0].CGColor;
        }
        
        // 删除按钮
        UIButton *del = [UIButton buttonWithType:UIButtonTypeCustom];
        del.backgroundColor = [UIColor colorWithRed:1.0 green:0.25 blue:0.25 alpha:1.0];
        del.layer.cornerRadius = 10;
        del.layer.masksToBounds = YES;
        // TODO: 使用切图占位 - [del setImage:[UIImage imageNamed:@"icon_delete_history"] forState:UIControlStateNormal];
        [del setTitle:@"✕" forState:UIControlStateNormal];
        del.titleLabel.font = BOLD_FONT(12);
        del.frame = CGRectMake(itemSize-18, -2, 20, 20);
        del.tag = i;
        [del addTarget:self action:@selector(onDeleteHistoryItem:) forControlEvents:UIControlEventTouchUpInside];
        [wrap addSubview:del];
        
        [self.historyScrollView addSubview:wrap];
        x += itemSize + margin;
    }
    
    self.historyScrollView.contentSize = CGSizeMake(MAX(x, self.view.bounds.size.width), 76);
}

- (void)onHistoryItemTapped:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    if (index >= 0 && index < self.historyItems.count) {
        self.selectedHistoryItem = self.historyItems[index];
        [self reloadHistoryUI];
        [self updateButtonLayout];
    }
}

- (void)onDeleteHistoryItem:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < self.historyItems.count) {
        UploadHistoryItem *item = self.historyItems[index];
        [self.historyManager removeUploadHistory:item.imageUri];
        [self loadHistory];
    }
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
    // 参考安卓逻辑：如果有历史记录，显示选择弹窗；否则直接打开相册
    if ([self.historyManager hasHistory]) {
        // 有历史记录，显示选择界面（iOS直接显示在页面上，不弹窗）
        [self showHistorySelection];
    } else {
        // 没有历史记录，直接打开相册
        [self selectPhoto];
    }
}

- (void)generateButtonTapped:(UIButton *)sender {
    // 使用选中的历史记录直接生成
    if (!self.selectedHistoryItem) {
        // 如果没有选中，使用最新的历史记录
        self.selectedHistoryItem = [self.historyManager getLatestHistoryItem];
    }
    
    if (!self.selectedHistoryItem) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"没有可用的历史记录")];
        return;
    }
    
    // 使用历史记录的AWS路径直接生成
    [self callGenerateCreateWithImagePath:self.selectedHistoryItem.awsRelativePath 
                          compressedImagePath:self.selectedHistoryItem.imageUri];
}

- (void)selectPhoto {
    TZImagePickerController *picker = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
    picker.allowPickingVideo = NO;
    picker.allowTakeVideo = NO;
    picker.allowTakePicture = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)showHistorySelection {
    // iOS版本：直接在页面上显示历史记录，不弹窗
    // 历史记录已经在loadHistory中加载并显示
    // 用户点击历史记录项即可选择
}

#pragma mark - TZImagePickerControllerDelegate

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    if (photos.count == 0) {
        return;
    }
    
    // 清空之前的选择，只保留新选择的图片
    [self.selectedImages removeAllObjects];
    [self.selectedImages addObject:photos.firstObject];
    
    // 设置第一张作为预览
    self.previewImageView.image = self.selectedImages.firstObject;
    self.currentSelectedImage = self.selectedImages.firstObject;
    self.currentSelectedImageUrl = nil; // 新选择的图片，不是历史记录
    
    [self reloadThumbs];
    
    // 选择图片后，直接开始上传流程（参考安卓逻辑）
    UIImage *image = self.selectedImages.firstObject;
    [self startUploadWithImage:image];
}

- (void)startUploadWithImage:(UIImage *)image {
    if (!image) {
        return;
    }
    
    // 跳转到上传中页面（传入模板图片URL）
    UploadingViewController *uploadingVC = [[UploadingViewController alloc] initWithMaterialId:self.materialId image:image];
    uploadingVC.templateImageUrl = self.templateImageUrl; // 设置模板图片URL
    [self.navigationController pushViewController:uploadingVC animated:YES];
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

- (void)callGenerateCreateWithImagePath:(NSString *)imagePath compressedImagePath:(NSString *)compressedImagePath {
    // 使用历史记录的AWS路径直接生成（参考安卓逻辑）
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
            NSString *createIds = dict[@"data"];
            if (createIds && createIds.length > 0) {
                BUNNYX_LOG(@"提交生成任务成功，createIds: %@", createIds);
                
                // 跳转到上传中页面（使用历史记录的图片路径）
                UploadingViewController *uploadingVC = [[UploadingViewController alloc] initWithMaterialId:self.materialId 
                                                                                                     image:nil 
                                                                                            createIds:createIds 
                                                                                      uploadedImagePath:compressedImagePath 
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

@end


