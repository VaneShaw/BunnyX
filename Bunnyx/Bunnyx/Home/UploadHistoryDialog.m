//
//  UploadHistoryDialog.m
//  Bunnyx
//
//  上传历史记录选择弹窗（对齐安卓UploadHistoryDialog）
//

#import "UploadHistoryDialog.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "GradientButton.h"
#import "UploadHistoryManager.h"
#import <SDWebImage/SDWebImage.h>

static NSString *const kHistoryItemCellId = @"HistoryItemCell";
static NSString *const kAddNewCellId = @"AddNewCell";

/// 添加新项数据模型（对齐安卓AddNewItem）
@interface AddNewItem : NSObject
@end
@implementation AddNewItem
@end

/// 历史记录项Cell（对齐安卓HistoryItemViewHolder）
@interface HistoryItemCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIView *selectedView;
@property (nonatomic, assign) BOOL isSelected;

- (void)configureWithHistoryItem:(UploadHistoryItem *)item;
- (void)setSelectedState:(BOOL)selected;

@end

@implementation HistoryItemCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 历史记录图片（对齐安卓：60x60dp，scaleType centerCrop）
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 10; // 对齐安卓：圆角10dp
    self.imageView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.imageView];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
        make.width.height.mas_equalTo(60);
    }];
    
    // 删除按钮（对齐安卓：icon_photo_delete，在右下角，padding 5dp）
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteButton setImage:[UIImage imageNamed:@"icon_photo_delete"] forState:UIControlStateNormal];
    self.deleteButton.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.deleteButton];
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(self.contentView);
        make.width.mas_equalTo(22);
        make.height.offset(18);
    }];
    
    // 选中状态指示器（对齐安卓：bg_image_selected，覆盖整个item）
    self.selectedView = [[UIView alloc] init];
    // TODO: 使用切图bg_image_selected，暂时使用边框表示选中
    self.selectedView.layer.borderWidth = 2;
    self.selectedView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.5 alpha:1.0].CGColor;
    self.selectedView.layer.cornerRadius = 10;
    self.selectedView.hidden = YES;
    [self.contentView addSubview:self.selectedView];
    
    [self.selectedView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}

- (void)configureWithHistoryItem:(UploadHistoryItem *)item {
    if (!item || !item.imageUri || item.imageUri.length == 0) {
        self.imageView.image = [UIImage systemImageNamed:@"photo"];
        return;
    }
    
    // 对齐安卓：优先使用AWS URL显示图片（如果本地文件不存在）
    // 1. 如果是HTTP/HTTPS URL，直接使用
    if ([item.imageUri hasPrefix:@"http://"] || [item.imageUri hasPrefix:@"https://"]) {
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:item.imageUri]
                           placeholderImage:[UIImage systemImageNamed:@"photo"]];
        return;
    }
    
    // 2. 尝试加载本地路径
    UIImage *localImage = [UIImage imageWithContentsOfFile:item.imageUri];
    if (localImage) {
        self.imageView.image = localImage;
        return;
    }
    
    // 3. 本地文件不存在，尝试使用AWS路径（对齐安卓：如果本地文件不存在，使用AWS URL）
    if (item.awsFullPath && item.awsFullPath.length > 0) {
        // 如果awsFullPath是完整URL，直接使用
        if ([item.awsFullPath hasPrefix:@"http://"] || [item.awsFullPath hasPrefix:@"https://"]) {
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:item.awsFullPath]
                               placeholderImage:[UIImage systemImageNamed:@"photo"]];
            return;
        }
        // 如果awsFullPath是相对路径，需要拼接完整URL（这里可以根据实际情况调整）
        // 暂时先尝试使用awsFullPath作为URL
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:item.awsFullPath]
                           placeholderImage:[UIImage systemImageNamed:@"photo"]];
        return;
    }
    
    // 4. 如果awsFullPath也不可用，尝试使用awsRelativePath
    if (item.awsRelativePath && item.awsRelativePath.length > 0) {
        if ([item.awsRelativePath hasPrefix:@"http://"] || [item.awsRelativePath hasPrefix:@"https://"]) {
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:item.awsRelativePath]
                               placeholderImage:[UIImage systemImageNamed:@"photo"]];
            return;
        }
    }
    
    // 5. 所有方式都失败，显示占位图
    self.imageView.image = [UIImage systemImageNamed:@"photo"];
}

- (void)setSelectedState:(BOOL)selected {
    self.isSelected = selected;
    self.selectedView.hidden = !selected;
}

@end

/// 添加新项Cell（对齐安卓AddNewViewHolder）
@interface AddNewCell : UICollectionViewCell

@end

@implementation AddNewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 背景（对齐安卓：bg_image_rounded）
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.contentView.layer.cornerRadius = 10;
    self.contentView.layer.masksToBounds = YES;
    
    // 添加图标（对齐安卓：icon_photo_add，60x60dp）
    UIImageView *addIcon = [[UIImageView alloc] init];
    addIcon.image = [UIImage imageNamed:@"icon_photo_add"];
    addIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:addIcon];
    
    [addIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.contentView);
        make.width.height.mas_equalTo(60);
    }];
}

@end

@interface UploadHistoryDialog () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *dialogView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) GradientButton *uploadButton;
@property (nonatomic, strong) GradientButton *generateButton;

@property (nonatomic, strong) UploadHistoryManager *historyManager;
@property (nonatomic, strong) NSMutableArray *dataList; // 包含AddNewItem和UploadHistoryItem
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation UploadHistoryDialog

+ (void)showWithDelegate:(id<UploadHistoryDialogDelegate>)delegate {
    UploadHistoryDialog *dialog = [[UploadHistoryDialog alloc] init];
    dialog.delegate = delegate;
    [dialog setupUI];
    [dialog show];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.historyManager = [UploadHistoryManager sharedManager];
        self.dataList = [NSMutableArray array];
        self.selectedIndex = -1;
    }
    return self;
}

- (void)setupUI {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.frame = window.bounds;
    [window addSubview:self];
    
    // 背景遮罩（对齐安卓：点击关闭）
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:self.backgroundView];
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [self.backgroundView addGestureRecognizer:tap];
    
    // 对话框（对齐安卓：从底部弹出，padding 20dp，背景bottom_sheet_background）
    self.dialogView = [[UIView alloc] init];
    // TODO: 使用切图bottom_sheet_background，暂时使用黑色背景
    self.dialogView.backgroundColor = HEX_COLOR(0x00191A);
    self.dialogView.layer.cornerRadius = 20; // 顶部圆角
    self.dialogView.layer.masksToBounds = YES;
    [self addSubview:self.dialogView];
    
    [self.dialogView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        // 高度自适应，但需要设置最大高度
    }];
    
    // 标题栏（对齐安卓：关闭按钮在右上角，marginBottom 20dp）
    UIView *titleBar = [[UIView alloc] init];
    [self.dialogView addSubview:titleBar];
    
    [titleBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.dialogView).offset(20);
        make.left.right.equalTo(self.dialogView);
        make.height.mas_equalTo(44);
    }];
    
    // 关闭按钮（对齐安卓：icon_popup_delete，padding 5dp）
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setImage:[UIImage imageNamed:@"icon_popup_delete"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:self.closeButton];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(titleBar).offset(-20);
        make.centerY.equalTo(titleBar);
        make.width.height.mas_equalTo(23);
    }];
    
    // 历史记录列表（对齐安卓：RecyclerView，GridLayoutManager 4列，高度120dp，marginBottom 20dp，paddingHorizontal 4dp）
    // 注意：安卓GridLayoutManager(4)表示垂直方向4列，水平滚动。RecyclerView高度120dp，item高度60dp，所以可以显示2行
    // 在iOS中，水平滚动时：垂直方向是"行"，水平方向是"列"。要实现4列，需要让垂直方向有2行，每行2列（或者用自定义布局）
    // 简化实现：使用水平滚动，垂直方向显示2行，每行可以水平滚动多个item
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 15; // 水平方向间距：每个item间距15px
    layout.minimumInteritemSpacing = 5; // 垂直方向间距（行间距）
    layout.sectionInset = UIEdgeInsetsMake(0, 32, 0, 0); // 第一个item左边空32px
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[HistoryItemCell class] forCellWithReuseIdentifier:kHistoryItemCellId];
    [self.collectionView registerClass:[AddNewCell class] forCellWithReuseIdentifier:kAddNewCellId];
    [self.dialogView addSubview:self.collectionView];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleBar.mas_bottom).offset(20);
        make.left.right.equalTo(self.dialogView);
        make.height.mas_equalTo(120); // 对齐安卓：高度120dp
    }];
    
    // Upload按钮（对齐安卓：高度48dp，圆角12dp，渐变#0AEA6F到#1CB3C1，marginBottom 12dp）
    self.uploadButton = [GradientButton buttonWithTitle:LocalString(@"上传")
                                               startColor:RGB(10, 234, 111)
                                                 endColor:RGB(28, 179, 193)];
    [self.uploadButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal]; // 对齐安卓：black3
    self.uploadButton.titleLabel.font = FONT(16); // 对齐安卓：16sp
    self.uploadButton.cornerRadius = CORNER_RADIUS_12;
    self.uploadButton.buttonHeight = 48;
    [self.uploadButton addTarget:self action:@selector(uploadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.dialogView addSubview:self.uploadButton];
    
    [self.uploadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.collectionView.mas_bottom).offset(20);
        make.left.right.equalTo(self.dialogView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(48);
    }];
    
    // Generate按钮（对齐安卓：高度48dp，圆角12dp，渐变#85FAFF到#E7FCC4）
    self.generateButton = [GradientButton buttonWithTitle:LocalString(@"生成")
                                                startColor:RGB(133, 250, 255)  // #85FAFF
                                                  endColor:RGB(231, 252, 196)]; // #E7FCC4
    [self.generateButton setTitleColor:HEX_COLOR(0x333333) forState:UIControlStateNormal]; // 对齐安卓：black3
    self.generateButton.titleLabel.font = FONT(16); // 对齐安卓：16sp
    self.generateButton.cornerRadius = CORNER_RADIUS_12;
    self.generateButton.buttonHeight = 48;
    [self.generateButton addTarget:self action:@selector(generateButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.dialogView addSubview:self.generateButton];
    
    [self.generateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.uploadButton.mas_bottom).offset(12); // 对齐安卓：marginBottom 12dp
        make.left.right.equalTo(self.dialogView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.dialogView).offset(-20);
    }];
    
    // 加载数据
    [self loadHistoryData];
}

- (void)loadHistoryData {
    [self.dataList removeAllObjects];
    
    // 添加"添加新图片"项（对齐安卓：第一个是AddNewItem）
    [self.dataList addObject:[[AddNewItem alloc] init]];
    
    // 添加历史记录项
    NSArray<UploadHistoryItem *> *historyList = [self.historyManager getUploadHistoryList];
    [self.dataList addObjectsFromArray:historyList];
    
    // 自动选中最新的历史记录（如果有的话，对齐安卓逻辑）
    if (self.dataList.count > 1) {
        // 第一个是添加按钮，第二个是最新的历史记录
        self.selectedIndex = 1;
    }
    
    [self.collectionView reloadData];
}

- (void)show {
    // 动画显示（从底部弹出）
    self.alpha = 0;
    self.dialogView.transform = CGAffineTransformMakeTranslation(0, self.dialogView.bounds.size.height);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
        self.dialogView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
        self.dialogView.transform = CGAffineTransformMakeTranslation(0, self.dialogView.bounds.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - Actions

- (void)uploadButtonTapped:(UIButton *)sender {
    // 对齐安卓：点击Upload按钮，打开相册选择新图片
    if ([self.delegate respondsToSelector:@selector(uploadHistoryDialogDidRequestImageSelection:)]) {
        [self.delegate uploadHistoryDialogDidRequestImageSelection:self];
    }
    [self dismiss];
}

- (void)generateButtonTapped:(UIButton *)sender {
    // 对齐安卓：点击Generate按钮，使用选中的历史记录生成
    UploadHistoryItem *selectedItem = nil;
    if (self.selectedIndex >= 0 && self.selectedIndex < self.dataList.count) {
        id item = self.dataList[self.selectedIndex];
        if ([item isKindOfClass:[UploadHistoryItem class]]) {
            selectedItem = (UploadHistoryItem *)item;
        }
    }
    
    if (!selectedItem) {
        // 如果没有选中任何项，使用最新的历史记录（对齐安卓逻辑）
        selectedItem = [self.historyManager getLatestHistoryItem];
        if (!selectedItem) {
            // TODO: 显示提示
            return;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(uploadHistoryDialog:didGenerateFromHistory:)]) {
        [self.delegate uploadHistoryDialog:self didGenerateFromHistory:selectedItem];
    }
    [self dismiss];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id item = self.dataList[indexPath.item];
    
    if ([item isKindOfClass:[AddNewItem class]]) {
        // 添加新项
        AddNewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kAddNewCellId forIndexPath:indexPath];
        return cell;
    } else if ([item isKindOfClass:[UploadHistoryItem class]]) {
        // 历史记录项
        HistoryItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kHistoryItemCellId forIndexPath:indexPath];
        [cell configureWithHistoryItem:(UploadHistoryItem *)item];
        [cell setSelectedState:(indexPath.item == self.selectedIndex)];
        
        // 删除按钮点击事件
        __weak typeof(self) weakSelf = self;
        cell.deleteButton.tag = indexPath.item;
        [cell.deleteButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.deleteButton addTarget:weakSelf action:@selector(deleteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
    
    return [[UICollectionViewCell alloc] init];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id item = self.dataList[indexPath.item];
    
    if ([item isKindOfClass:[AddNewItem class]]) {
        // 点击添加新图片（对齐安卓逻辑）
        if ([self.delegate respondsToSelector:@selector(uploadHistoryDialogDidRequestImageSelection:)]) {
            [self.delegate uploadHistoryDialogDidRequestImageSelection:self];
        }
        [self dismiss];
    } else if ([item isKindOfClass:[UploadHistoryItem class]]) {
        // 点击历史记录项，选中状态由内部处理（对齐安卓逻辑）
        NSInteger oldIndex = self.selectedIndex;
        self.selectedIndex = indexPath.item;
        
        // 更新选中状态
        if (oldIndex >= 0 && oldIndex < self.dataList.count) {
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForItem:oldIndex inSection:0];
            HistoryItemCell *oldCell = (HistoryItemCell *)[collectionView cellForItemAtIndexPath:oldIndexPath];
            [oldCell setSelectedState:NO];
        }
        
        HistoryItemCell *cell = (HistoryItemCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [cell setSelectedState:YES];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 对齐安卓：历史记录项60x60dp，添加新项也是60x60dp
    // RecyclerView高度120dp，可以显示2行，每行item高度60dp
    // 由于是水平滚动，item宽度和高度都是60
    return CGSizeMake(60, 60);
}

- (void)deleteButtonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= self.dataList.count) {
        return;
    }
    
    id item = self.dataList[index];
    if (![item isKindOfClass:[UploadHistoryItem class]]) {
        return;
    }
    
    UploadHistoryItem *historyItem = (UploadHistoryItem *)item;
    
    // 删除历史记录（对齐安卓逻辑）
    [self.historyManager removeUploadHistory:historyItem.imageUri];
    
    // 重新加载数据
    [self loadHistoryData];
}

@end

