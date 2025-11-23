//
//  ContactUsViewController.m
//  Bunnyx
//
//  联系客服页面（ContactUsActivity）
//

#import "ContactUsViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "GradientButton.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "AWSUploader.h"
#import <SVProgressHUD/SVProgressHUD.h>

static NSString *const kContactUsImageCellId = @"ContactUsImageCellId";
static const NSInteger kMaxImageCount = 3;

@interface ContactUsImageCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, copy) void(^deleteBlock)(void);
- (void)configureWithImage:(UIImage *)image showDelete:(BOOL)showDelete;
@end

@implementation ContactUsImageCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 图片视图（item大小，圆角8dp）
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.cornerRadius = 10;
    [self.contentView addSubview:self.imageView];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    // 删除按钮（右上角删除图标）
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteButton setImage:[UIImage imageNamed:@"icon_photo_delete"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteButton];
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.right.equalTo(self.contentView);
        make.width.mas_equalTo(22);
        make.height.offset(18);
    }];
}

- (void)configureWithImage:(UIImage *)image showDelete:(BOOL)showDelete {
    if (image) {
        self.imageView.image = image;
        self.deleteButton.hidden = !showDelete;
    } else {
        // 添加按钮（icon_add_new）
        self.imageView.image = [UIImage imageNamed:@"icon_photo_add"];
//        self.imageView.contentMode = UIViewContentModeCenter;
        self.deleteButton.hidden = YES;
    }
}

- (void)deleteButtonTapped {
    if (self.deleteBlock) {
        self.deleteBlock();
    }
}

@end

@interface ContactUsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// ScrollView容器
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// 标题标签（TitleBar，19sp，白色）
@property (nonatomic, strong) UILabel *titleLabel;

// 描述标签（16sp，白色，marginTop 20dp，marginBottom 8dp）
@property (nonatomic, strong) UILabel *descriptionLabel;

// 描述输入框（120dp高度，padding 12dp，radius 10dp，背景#0DFFFFFF）
@property (nonatomic, strong) UITextView *descriptionTextView;
@property (nonatomic, strong) UILabel *placeholderLabel;

// 上传图片标签（16sp，白色，marginTop 24dp，marginBottom 12dp）
@property (nonatomic, strong) UILabel *uploadImageCountLabel;

// 图片列表（RecyclerView，4列网格，minHeight 120dp）
@property (nonatomic, strong) UICollectionView *imagesCollectionView;

// 提交按钮（48dp高度，渐变背景#0AEA6F到#1CB3C1，radius 12dp）
@property (nonatomic, strong) GradientButton *submitButton;

// 数据源（mImagePaths）
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;
@property (nonatomic, strong) NSMutableArray<NSString *> *imagePaths; // 本地图片路径数组

// 上传状态跟踪）
@property (nonatomic, assign) NSInteger uploadingCount; // mUploadingCount
@property (nonatomic, strong) NSMutableArray<NSString *> *uploadedRelativePaths; // mUploadedRelativePaths
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *imagePathToRelativePath; // mImagePathToRelativePath

@end

@implementation ContactUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedImages = [NSMutableArray array];
    self.imagePaths = [NSMutableArray array];
    self.uploadingCount = 0;
    self.uploadedRelativePaths = [NSMutableArray array];
    self.imagePathToRelativePath = [NSMutableDictionary dictionary];
    [self setupUI];
    [self updateImageCountDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self bringBackButtonToFront];
}

#pragma mark - UI Setup

- (void)setupUI {
    // ScrollView容器（ScrollView包裹所有内容）
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
    
    // 标题标签（TitleBar，19sp，白色，paddingHorizontal 16dp）
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalString(@"联系我们");
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = FONT(19); // 19sp
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.customBackButton.mas_centerY);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 16, 0, 16)); // paddingHorizontal 16dp
        make.height.mas_equalTo(44); // 标题栏高度
    }];
    
    // 描述标签（16sp，白色，marginTop 20dp，marginBottom 8dp）
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.text = LocalString(@"描述:");
    self.descriptionLabel.textColor = [UIColor whiteColor];
    self.descriptionLabel.font = FONT(16); // 16sp
    [self.contentView addSubview:self.descriptionLabel];
    
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(STATUS_BAR_HEIGHT+NAVIGATION_BAR_HEIGHT+30); // marginTop 20dp
        make.left.equalTo(self.contentView).offset(16); // paddingHorizontal 16dp
        make.right.equalTo(self.contentView).offset(-16);
    }];
    
    // 描述输入框（120dp高度，padding 12dp，radius 10dp，背景#0DFFFFFF）
    self.descriptionTextView = [[UITextView alloc] init];
    self.descriptionTextView.backgroundColor = RGBA(255, 255, 255, 13.0/255.0); // #0DFFFFFF
    self.descriptionTextView.textColor = [UIColor whiteColor];
    self.descriptionTextView.font = FONT(16); // 16sp
    self.descriptionTextView.layer.cornerRadius = 10.0; // radius 10dp
    self.descriptionTextView.layer.masksToBounds = YES;
    self.descriptionTextView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12); // padding 12dp
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChange:) name:UITextViewTextDidChangeNotification object:self.descriptionTextView];
    [self.contentView addSubview:self.descriptionTextView];
    
    // 占位符标签（textColorHint #80FFFFFF）
    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = LocalString(@"请输入您的问题或建议");
    self.placeholderLabel.textColor = RGBA(255, 255, 255, 0.5); // #80FFFFFF
    self.placeholderLabel.font = FONT(16); // 16sp
    self.placeholderLabel.numberOfLines = 0;
    [self.descriptionTextView addSubview:self.placeholderLabel];
    
    [self.placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descriptionTextView).offset(12); // 对齐padding
        make.left.equalTo(self.descriptionTextView).offset(12);
        make.right.equalTo(self.descriptionTextView).offset(-12);
    }];
    
    [self.descriptionTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descriptionLabel.mas_bottom).offset(8); // marginBottom 8dp
        make.left.equalTo(self.contentView).offset(16); // paddingHorizontal 16dp
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(120); // 120dp
    }];
    
    // 上传图片标签（16sp，白色，marginTop 24dp，marginBottom 12dp）
    self.uploadImageCountLabel = [[UILabel alloc] init];
    [self updateImageCountDisplay];
    self.uploadImageCountLabel.textColor = [UIColor whiteColor];
    self.uploadImageCountLabel.font = FONT(16); // 16sp
    [self.contentView addSubview:self.uploadImageCountLabel];
    
    [self.uploadImageCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descriptionTextView.mas_bottom).offset(24); // marginTop 24dp
        make.left.equalTo(self.contentView).offset(16); // paddingHorizontal 16dp
        make.right.equalTo(self.contentView).offset(-16);
    }];
    
    // 图片列表（RecyclerView，4列网格，minHeight 120dp）
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 12.0; // 行间距
    layout.minimumInteritemSpacing = 12.0; // 列间距
    layout.sectionInset = UIEdgeInsetsZero;
    
    self.imagesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.imagesCollectionView.backgroundColor = [UIColor clearColor];
    self.imagesCollectionView.dataSource = self;
    self.imagesCollectionView.delegate = self;
    [self.imagesCollectionView registerClass:[ContactUsImageCell class] forCellWithReuseIdentifier:kContactUsImageCellId];
    [self.contentView addSubview:self.imagesCollectionView];
    
    [self.imagesCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.uploadImageCountLabel.mas_bottom).offset(12); // marginBottom 12dp
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 16, 0, 16)); // paddingHorizontal 16dp
        make.height.mas_greaterThanOrEqualTo(120); // minHeight 120dp
    }];
    
    // 提交按钮（48dp高度，渐变背景#0AEA6F到#1CB3C1，radius 12dp）
    self.submitButton = [GradientButton buttonWithTitle:LocalString(@"提交")
                                               startColor:HEX_COLOR(0x0AEA6F) // #0AEA6F
                                                 endColor:HEX_COLOR(0x1CB3C1)]; // #1CB3C1
    self.submitButton.cornerRadius = 12.0; // radius 12dp
    self.submitButton.buttonHeight = 48.0; // 48dp
    [self.submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = FONT(16); // 16sp
    [self.submitButton addTarget:self action:@selector(submitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.submitButton];
    
    [self.submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imagesCollectionView.mas_bottom).offset(50); // marginTop 50dp
        make.left.equalTo(self.contentView).offset(16); // paddingHorizontal 16dp
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(48); // 48dp
        make.bottom.equalTo(self.contentView).offset(-24); // marginBottom 24dp
    }];
}

- (void)updateImageCountDisplay {
    NSString *text = [NSString stringWithFormat:LocalString(@"上传图片(%@)"), [NSString stringWithFormat:@"%ld/%ld", (long)self.selectedImages.count, (long)kMaxImageCount]];
    self.uploadImageCountLabel.text = text;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // 显示已选图片 + 添加按钮（如果未达到最大数量）
    NSInteger count = self.selectedImages.count;
    if (count < kMaxImageCount) {
        return count + 1; // 添加按钮
    }
    return count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ContactUsImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kContactUsImageCellId forIndexPath:indexPath];
    
    // 添加按钮始终在第一个位置（如果未达到最大数量）
    BOOL showAddButton = (self.selectedImages.count < kMaxImageCount);
    if (showAddButton && indexPath.item == 0) {
        // 显示添加按钮
        [cell configureWithImage:nil showDelete:NO];
        cell.deleteBlock = nil; // 添加按钮不需要删除功能
    } else {
        // 显示已选图片（需要调整索引，因为第一个位置是添加按钮）
        NSInteger imageIndex = showAddButton ? (indexPath.item - 1) : indexPath.item;
        if (imageIndex >= 0 && imageIndex < self.selectedImages.count) {
            UIImage *image = self.selectedImages[imageIndex];
            [cell configureWithImage:image showDelete:YES];
            
            __weak typeof(self) weakSelf = self;
            NSInteger finalIndex = imageIndex; // 保存索引用于删除
            cell.deleteBlock = ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf deleteImageAtIndex:finalIndex];
                }
            };
        }
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 4列网格布局
    CGFloat width = collectionView.bounds.size.width;
    CGFloat spacing = 12.0; // 列间距
    CGFloat itemWidth = (width - spacing * 3) / 4.0; // 4列，3个间距
    CGFloat itemHeight = itemWidth; // 正方形
    return CGSizeMake(itemWidth, itemHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 添加按钮始终在第一个位置（如果未达到最大数量）
    BOOL showAddButton = (self.selectedImages.count < kMaxImageCount);
    if (showAddButton && indexPath.item == 0) {
        // 点击添加按钮
        [self selectPhoto];
    } else {
        // 点击已选图片，不做处理（删除通过删除按钮）
    }
}

#pragma mark - Actions

- (void)selectPhoto {
    if (self.selectedImages.count >= kMaxImageCount) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"最多只能上传3张图片")];
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)submitButtonTapped {
    // 提交工单（submitWorkOrder）
    NSString *description = [self.descriptionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (description.length == 0) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"请输入问题或建议")];
        return;
    }
    
    if (self.uploadingCount > 0) {
        [SVProgressHUD showErrorWithStatus:LocalString(@"图片正在上传中，请稍候")];
        return;
    }
    
    // 根据当前图片列表，构建上传路径列表）
    NSMutableArray<NSString *> *currentUploadedPaths = [NSMutableArray array];
    for (NSString *imagePath in self.imagePaths) {
        NSString *relativePath = self.imagePathToRelativePath[imagePath];
        if (relativePath && relativePath.length > 0) {
            [currentUploadedPaths addObject:relativePath];
        }
    }
    
    // 构建图片路径字符串（用逗号分隔）
    NSString *imagePaths = [currentUploadedPaths componentsJoinedByString:@","];
    
    BUNNYX_LOG(@"当前图片数量: %ld", (long)self.imagePaths.count);
    BUNNYX_LOG(@"已上传路径数量: %ld", (long)currentUploadedPaths.count);
    BUNNYX_LOG(@"图片路径: %@", imagePaths);
    
    // 调用提交接口（SubmitWorkOrderApi）
    [SVProgressHUD show];
    
    NSDictionary *params = @{
        @"orderDescribe": description,
        @"image": imagePaths ?: @""
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_WORK_ORDER_SUBMIT
                               parameters:params
                                  success:^(id responseObject) {
        [SVProgressHUD dismiss];
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        
        if (code == 0) {
            [SVProgressHUD showSuccessWithStatus:LocalString(@"提交成功")];
            // 延迟返回上一页（finish()）
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        } else {
            NSString *errorMsg = dict[@"promptType"] ?: LocalString(@"提交失败");
            [SVProgressHUD showErrorWithStatus:errorMsg];
        }
    } failure:^(NSError *error) {
        // 错误提示由 NetworkManager 自动显示
    }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image && self.selectedImages.count < kMaxImageCount) {
        // 保存图片到临时目录（copyUriToPrivateFile）
        NSString *imagePath = [self saveImageToTempDirectory:image];
        if (imagePath) {
            [self.selectedImages addObject:image];
            [self.imagePaths addObject:imagePath];
            [self.imagesCollectionView reloadData];
            [self updateImageCountDisplay];
            
            // 开始上传到AWS（uploadImageToAws）
            [self uploadImageToAws:imagePath];
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"处理图片失败")];
        }
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Image Upload

- (NSString *)saveImageToTempDirectory:(UIImage *)image {
    // 保存图片到临时目录（copyUriToPrivateFile）
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) {
        return nil;
    }
    
    NSString *fileName = [NSString stringWithFormat:@"contact_us_image_%ld.jpg", (long)([[NSDate date] timeIntervalSince1970] * 1000)];
    NSString *tempDir = NSTemporaryDirectory();
    NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
    
    BOOL success = [imageData writeToFile:filePath atomically:YES];
    if (success) {
        return filePath;
    }
    return nil;
}

- (void)uploadImageToAws:(NSString *)imagePath {
    // 上传图片到AWS（uploadImageToAws）
    [SVProgressHUD show];
    self.uploadingCount++;
    
    // 获取文件后缀）
    NSString *fileName = [imagePath lastPathComponent];
    NSString *suffix = [fileName pathExtension];
    if (suffix.length == 0) {
        suffix = @"jpg";
    }
    
    // 调用AWS上传接口获取配置（AwsUploadApi，typeCode=WORK_ORDER）
    NSDictionary *params = @{
        @"typeCode": @"workOrder", // AwsUploadApi.TypeCode.WORK_ORDER
        @"suffix": suffix
    };
    
    BUNNYX_LOG(@"开始上传图片，typeCode=workOrder, suffix=%@", suffix);
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_AWS_UPLOAD
                               parameters:params
                                  success:^(id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        
        if (code == 0 && dict[@"data"]) {
            NSDictionary *uploadData = dict[@"data"];
            NSString *poolId = uploadData[@"poolId"];
            NSString *region = uploadData[@"region"];
            NSString *bucket = uploadData[@"bucket"];
            NSString *filePathName = uploadData[@"filePathName"];
            
            if (poolId && region && bucket && filePathName) {
                // 上传到S3（uploadToS3）
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                if (image) {
                    [[AWSUploader sharedUploader] uploadImage:image
                                                       poolId:poolId
                                                       region:region
                                                       bucket:bucket
                                                  filePathName:filePathName
                                                      progress:nil
                                                       success:^(NSString *fullUrl, NSString *relativePath) {
                        // 上传成功，保存相对路径）
                        [self.uploadedRelativePaths addObject:relativePath];
                        self.imagePathToRelativePath[imagePath] = relativePath;
                        self.uploadingCount--;
                        
                        BUNNYX_LOG(@"图片上传成功: %@", relativePath);
                        BUNNYX_LOG(@"原始路径: %@", imagePath);
                        
                        if (self.uploadingCount == 0) {
                            [SVProgressHUD dismiss];
                        }
                    } failure:^(NSError *error) {
                        self.uploadingCount--;
                        if (self.uploadingCount == 0) {
                            [SVProgressHUD dismiss];
                        }
                        BUNNYX_ERROR(@"上传到S3失败: %@", error.localizedDescription);
                        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:LocalString(@"上传图片失败: %@"), error.localizedDescription]];
                    }];
                } else {
                    self.uploadingCount--;
                    if (self.uploadingCount == 0) {
                        [SVProgressHUD dismiss];
                    }
                    [SVProgressHUD showErrorWithStatus:LocalString(@"图片加载失败")];
                }
            } else {
                self.uploadingCount--;
                if (self.uploadingCount == 0) {
                    [SVProgressHUD dismiss];
                }
                [SVProgressHUD showErrorWithStatus:LocalString(@"AWS配置信息不完整")];
            }
        } else {
            self.uploadingCount--;
            if (self.uploadingCount == 0) {
                [SVProgressHUD dismiss];
            }
            NSString *errorMsg = dict[@"message"] ?: LocalString(@"获取上传配置失败");
            [SVProgressHUD showErrorWithStatus:errorMsg];
        }
    } failure:^(NSError *error) {
        self.uploadingCount--;
        if (self.uploadingCount == 0) {
            [SVProgressHUD dismiss];
        }
        BUNNYX_ERROR(@"上传图片失败: %@", error.localizedDescription);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:LocalString(@"上传图片失败: %@"), error.localizedDescription]];
    }];
}

#pragma mark - Delete Image

- (void)deleteImageAtIndex:(NSInteger)index {
    // 删除图片（onDeleteClick）
    if (index >= 0 && index < self.imagePaths.count) {
        NSString *imagePath = self.imagePaths[index];
        // 同时移除对应的上传路径
        NSString *relativePath = self.imagePathToRelativePath[imagePath];
        if (relativePath && [self.uploadedRelativePaths containsObject:relativePath]) {
            [self.uploadedRelativePaths removeObject:relativePath];
        }
        [self.imagePathToRelativePath removeObjectForKey:imagePath];
        
        [self.selectedImages removeObjectAtIndex:index];
        [self.imagePaths removeObjectAtIndex:index];
        [self.imagesCollectionView reloadData];
        [self updateImageCountDisplay];
    }
}

#pragma mark - UITextView Notification

- (void)textViewDidChange:(NSNotification *)notification {
    self.placeholderLabel.hidden = (self.descriptionTextView.text.length > 0);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

