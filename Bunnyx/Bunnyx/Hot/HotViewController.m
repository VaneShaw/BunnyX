//
//  HotViewController.m
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import "HotViewController.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "NetworkManager.h"
#import "BunnyxNetworkMacros.h"
#import "MaterialItemModel.h"
#import "MaterialCollectionViewCell.h"
#import "BottomAlignedCollectionViewFlowLayout.h"
#import <SDWebImage/SDWebImage.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "UploadMaterialViewController.h"
#import "RechargeViewController.h"

static NSString * const kMaterialCellId = @"kMaterialCellId";

@interface HotViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIImageView *backgroundImageView; // 背景图片
@property (nonatomic, strong) UIButton *moreButton; // 右上角报告按钮
@property (nonatomic, strong) UIButton *uploadButton; // 中心上传按钮
@property (nonatomic, strong) UICollectionView *materialCollectionView; // 底部素材列表

@property (nonatomic, strong) NSMutableArray<MaterialItemModel *> *materialList;
@property (nonatomic, strong) MaterialItemModel *currentBackgroundMaterial; // 当前作为背景的素材
@property (nonatomic, assign) NSInteger selectedIndex; // 当前选中的索引
@property (nonatomic, assign) NSInteger lastCenterPosition; // 上次的中心位置（参考安卓代码）
@property (nonatomic, assign) BOOL isPendingUpdate; // 是否有待处理的更新（参考安卓代码）
@property (nonatomic, assign) BOOL isProgrammaticScroll; // 是否是程序化滚动（避免点击时的重复更新）

@end

@implementation HotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.materialList = [NSMutableArray array];
    self.selectedIndex = -1;
    self.lastCenterPosition = -1;
    self.isPendingUpdate = NO;
    self.isProgrammaticScroll = NO;
    
    [self setupUI];
    [self loadMaterialList];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 确保按钮在最上层
    [self.view bringSubviewToFront:self.moreButton];
    [self.view bringSubviewToFront:self.uploadButton];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 背景图片
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.clipsToBounds = YES;
    self.backgroundImageView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    [self.view addSubview:self.backgroundImageView];
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 右上角报告按钮（三个点图标）
    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.moreButton setImage:[UIImage imageNamed:@"icon_home_detail_more_light"] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.moreButton];
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(36);
        make.right.equalTo(self.view).offset(-16);
        make.width.height.mas_equalTo(24);
    }];
    
    // 中心上传按钮（摄像头图标）
    self.uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.uploadButton setImage:[UIImage imageNamed:@"icon_hot_upload"] ?: [UIImage systemImageNamed:@"camera.fill"] forState:UIControlStateNormal];
    self.uploadButton.tintColor = [UIColor whiteColor];
    self.uploadButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0]; // 绿色背景
    self.uploadButton.layer.cornerRadius = 50;
    self.uploadButton.layer.masksToBounds = YES;
    [self.uploadButton addTarget:self action:@selector(uploadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.uploadButton];
    [self.uploadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-15);
        make.bottom.equalTo(self.view).offset(-300);
        make.width.height.mas_equalTo(100);
    }];
    
    // 底部素材列表（使用底部对齐的FlowLayout）
    BottomAlignedCollectionViewFlowLayout *layout = [[BottomAlignedCollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0; // 水平滚动时，行间距为0（因为只有一行）
    layout.minimumInteritemSpacing = 10; // 水平滚动时，item间距为10（图片之间的间距）
    layout.sectionInset = UIEdgeInsetsMake(0, 16, 0, 16);
    
    self.materialCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.materialCollectionView.backgroundColor = [UIColor clearColor];
    self.materialCollectionView.showsHorizontalScrollIndicator = NO;
    self.materialCollectionView.dataSource = self;
    self.materialCollectionView.delegate = self;
    [self.materialCollectionView registerClass:[MaterialCollectionViewCell class] forCellWithReuseIdentifier:kMaterialCellId];
    [self.view addSubview:self.materialCollectionView];
    [self.materialCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-SAFE_AREA_BOTTOM-TAB_BAR_HEIGHT-20);
        make.height.mas_equalTo(144); // 适配选中状态的最大高度144
    }];
}

#pragma mark - Data Loading

- (void)loadMaterialList {
    // 根据安卓代码，使用materialType=1
    NSDictionary *params = @{
        @"index": @(0),
        @"count": @(20),
        @"materialType": @(1) // 对齐安卓：materialType=1
    };
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_MATERIAL_LIST
                              parameters:params
                                 success:^(id responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        if (code == 0) {
            NSArray *data = dict[@"data"];
            if (data && [data isKindOfClass:[NSArray class]]) {
                NSArray *models = [MaterialItemModel modelsFromResponse:data];
                [self.materialList removeAllObjects];
                [self.materialList addObjectsFromArray:models];
                
                // 对齐安卓：设置默认选中中间位置
                if (self.materialList.count > 0) {
                    // 预加载所有图片到缓存
                    [self preloadImages];
                    
                    NSInteger middleIndex = self.materialList.count / 2;
                    MaterialItemModel *middleMaterial = self.materialList[middleIndex];
                    
                    // 在主线程更新UI
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.selectedIndex = middleIndex;
                        self.lastCenterPosition = middleIndex;
                        // 注意：updateBackgroundImage内部会设置currentBackgroundMaterial，这里不需要提前设置
                        [self updateBackgroundImage:middleMaterial];
                        
                        // 刷新数据并更新布局，确保选中状态正确显示
                        [self.materialCollectionView reloadData];
                        
                        // 等待布局完成后再刷新布局，确保选中item正确显示放大效果
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // 强制刷新布局，让选中的item显示为放大状态
                            [self.materialCollectionView.collectionViewLayout invalidateLayout];
                            [self.materialCollectionView layoutIfNeeded];
                            
                            // 对齐安卓：滚动到中间位置
                            NSIndexPath *middlePath = [NSIndexPath indexPathForItem:middleIndex inSection:0];
                            [self.materialCollectionView scrollToItemAtIndexPath:middlePath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                        });
                    });
                }
            }
        }
    } failure:^(NSError *error) {
        BUNNYX_ERROR(@"加载素材列表失败: %@", error.localizedDescription);
    }];
}

- (void)updateBackgroundImage:(MaterialItemModel *)material {
    [self updateBackgroundImage:material forceUpdate:NO];
}

/**
 * 更新背景图片（对齐安卓）
 * @param material 素材对象
 * @param forceUpdate 是否强制更新（即使URL相同也更新）
 */
- (void)updateBackgroundImage:(MaterialItemModel *)material forceUpdate:(BOOL)forceUpdate {
    // 确保在主线程执行
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateBackgroundImage:material forceUpdate:forceUpdate];
        });
        return;
    }
    
    if (!material || !material.materialUrl || material.materialUrl.length == 0) {
        BUNNYX_LOG(@"updateBackgroundImage: material或materialUrl为空");
        return;
    }
    
    // 对齐安卓：避免重复加载同一张图片（除非强制更新）
    if (!forceUpdate) {
        NSString *currentUrl = self.currentBackgroundMaterial ? self.currentBackgroundMaterial.materialUrl : nil;
        if (currentUrl && [currentUrl isEqualToString:material.materialUrl]) {
            BUNNYX_LOG(@"updateBackgroundImage: 跳过重复加载，URL: %@", material.materialUrl);
            return;
        }
    }
    
    BUNNYX_LOG(@"updateBackgroundImage: 加载图片，URL: %@", material.materialUrl);
    
    NSURL *url = [NSURL URLWithString:material.materialUrl];
    if (!url) {
        BUNNYX_ERROR(@"updateBackgroundImage: URL无效，materialUrl: %@", material.materialUrl);
        return;
    }
    
    // 先更新currentBackgroundMaterial，然后加载图片
    self.currentBackgroundMaterial = material;
    
    // 对齐安卓：使用ALL缓存策略，同时缓存原始数据和解码后的图片
    // 对于动态图（GIF/WebP），会优先使用SOURCE缓存，保持动态效果
    [self.backgroundImageView sd_setImageWithURL:url 
                                 placeholderImage:[UIImage imageNamed:@"image_loading_ic"]
                                          options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages
                                          context:@{SDWebImageContextStoreCacheType: @(SDImageCacheTypeAll)}
                                         progress:nil
                                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error) {
            BUNNYX_ERROR(@"updateBackgroundImage: 图片加载失败，URL: %@, Error: %@", imageURL, error.localizedDescription);
            // 对齐安卓：加载失败时显示错误图片
            self.backgroundImageView.image = [UIImage imageNamed:@"image_error_ic"];
        } else {
            BUNNYX_LOG(@"updateBackgroundImage: 图片加载成功，URL: %@", imageURL);
        }
    }];
}

/**
 * 预加载图片到缓存（对齐安卓）
 */
- (void)preloadImages {
    if (self.materialList.count == 0) {
        return;
    }
    
    for (MaterialItemModel *material in self.materialList) {
        if (material.materialUrl && material.materialUrl.length > 0) {
            NSURL *url = [NSURL URLWithString:material.materialUrl];
            if (url) {
                // 使用SDWebImage预加载图片到缓存
                [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[url]];
            }
        }
    }
}

#pragma mark - Actions

- (void)moreButtonTapped:(UIButton *)sender {
    // 对齐安卓：显示底部弹窗（ActionSheet），包含举报和屏蔽选项
    if (!self.currentBackgroundMaterial) {
        // 如果当前背景未设置，尝试从列表中取一个可用的
        if (self.materialList.count > 0 && self.selectedIndex >= 0 && self.selectedIndex < self.materialList.count) {
            self.currentBackgroundMaterial = self.materialList[self.selectedIndex];
        }
    }
    
    if (!self.currentBackgroundMaterial || self.currentBackgroundMaterial.materialId <= 0) {
        return;
    }
    
    // 使用ActionSheet样式，对齐安卓的BottomSheetDialog
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 举报选项
    UIAlertAction *reportAction = [UIAlertAction actionWithTitle:LocalString(@"举报")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self reportMaterialWithType:0]; // 0: 举报
    }];
    
    // 屏蔽选项
    UIAlertAction *blockAction = [UIAlertAction actionWithTitle:LocalString(@"屏蔽")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
        [self reportMaterialWithType:1]; // 1: 屏蔽
    }];
    
    // 取消选项
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:reportAction];
    [alert addAction:blockAction];
    [alert addAction:cancelAction];
    
    // 适配iPad
    if (IS_IPAD) {
        alert.popoverPresentationController.sourceView = sender;
        alert.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reportMaterialWithType:(NSInteger)type {
    // 对齐安卓：type 0=举报, 1=屏蔽
    if (!self.currentBackgroundMaterial || self.currentBackgroundMaterial.materialId <= 0) {
        return;
    }
    
    NSInteger materialId = self.currentBackgroundMaterial.materialId;
    
    // 找到当前素材在列表中的位置（对齐安卓逻辑）
    NSInteger position = -1;
    for (NSInteger i = 0; i < self.materialList.count; i++) {
        if (self.materialList[i].materialId == materialId) {
            position = i;
            break;
        }
    }
    
    if (position == -1) {
        return;
    }
    
    // 使用局部变量，以便在block中使用
    NSInteger finalPosition = position;
    
    [SVProgressHUD show];
    
    // 调用举报接口（type: 0=举报, 1=屏蔽）
    NSDictionary *params = @{
        @"materialId": @(materialId),
        @"type": @(type)
    };
    
    [[NetworkManager sharedManager] POST:BUNNYX_API_MATERIAL_REPORT
                              parameters:params
                                 success:^(id responseObject) {
        [SVProgressHUD dismiss];
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        if (code == 0) {
            NSString *successMessage = type == 0 ? LocalString(@"举报成功") : LocalString(@"屏蔽成功");
            [SVProgressHUD showSuccessWithStatus:successMessage];
            
            // 从列表中删除对应数据
            if (finalPosition >= 0 && finalPosition < self.materialList.count) {
                [self removeMaterialFromList:finalPosition];
            }
        } else {
            [SVProgressHUD showErrorWithStatus:LocalString(@"操作失败")];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"网络错误")];
    }];
}

- (void)removeMaterialFromList:(NSInteger)position {
    // 对齐安卓：完善的删除逻辑，包括滚动监听器的临时移除和恢复
    if (position < 0 || position >= self.materialList.count) {
        return;
    }
    
    NSInteger oldSelectedIndex = self.selectedIndex;
    BOOL isRemovingSelected = (position == oldSelectedIndex);
    
    // 从列表中删除
    [self.materialList removeObjectAtIndex:position];
    
    // 调整选中位置（对齐安卓逻辑）
    NSInteger newSelectedIndex = -1;
    if (position < oldSelectedIndex) {
        // 删除的位置在选中位置之前，选中位置减1
        newSelectedIndex = oldSelectedIndex - 1;
    } else if (isRemovingSelected) {
        // 删除的是选中项，需要选择新的位置
        if (self.materialList.count > 0) {
            // 选择原位置或前一个位置（如果原位置超出范围）
            newSelectedIndex = position >= self.materialList.count ? self.materialList.count - 1 : position;
            if (newSelectedIndex < 0) {
                newSelectedIndex = 0;
            }
        }
    } else {
        // 删除的位置在选中位置之后，不需要调整
        newSelectedIndex = oldSelectedIndex;
    }
    
    // 更新选中索引和背景
    if (newSelectedIndex >= 0 && newSelectedIndex < self.materialList.count) {
        self.selectedIndex = newSelectedIndex;
        MaterialItemModel *newMaterial = self.materialList[newSelectedIndex];
        // 对齐安卓：强制更新背景（因为列表已经变化）
        [self updateBackgroundImage:newMaterial forceUpdate:YES];
        
        // 如果删除的是选中项或删除位置在选中位置之前，需要滚动到新位置
        if (isRemovingSelected || (position < oldSelectedIndex)) {
            // 对齐安卓：暂时移除滚动监听器，避免滚动过程中触发更新
            // 注意：iOS的UICollectionView没有直接的方法移除delegate，我们需要用标志位来控制
            self.isProgrammaticScroll = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.materialCollectionView reloadData];
                
                NSIndexPath *newPath = [NSIndexPath indexPathForItem:newSelectedIndex inSection:0];
                [self.materialCollectionView scrollToItemAtIndexPath:newPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                
                // 对齐安卓：等待滚动动画完成后再恢复监听器，并再次确认背景是正确的
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // 再次检查并更新背景，确保滚动后背景正确
                    if (self.selectedIndex >= 0 && self.selectedIndex < self.materialList.count) {
                        MaterialItemModel *material = self.materialList[self.selectedIndex];
                        [self updateBackgroundImage:material forceUpdate:YES];
                    }
                    self.isProgrammaticScroll = NO;
                });
            });
        } else {
            // 删除的位置在选中位置之后，只需要刷新数据
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.materialCollectionView reloadData];
            });
        }
    } else if (self.materialList.count == 0) {
        // 列表为空，清空背景
        self.currentBackgroundMaterial = nil;
        self.selectedIndex = -1;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.materialCollectionView reloadData];
        });
    } else {
        // 列表不为空但选中位置无效，选择第一个
        NSInteger fallbackIndex = 0;
        self.selectedIndex = fallbackIndex;
        MaterialItemModel *newMaterial = self.materialList[fallbackIndex];
        [self updateBackgroundImage:newMaterial forceUpdate:YES];
        
        self.isProgrammaticScroll = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.materialCollectionView reloadData];
            
            NSIndexPath *fallbackPath = [NSIndexPath indexPathForItem:fallbackIndex inSection:0];
            [self.materialCollectionView scrollToItemAtIndexPath:fallbackPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.selectedIndex >= 0 && self.selectedIndex < self.materialList.count) {
                    MaterialItemModel *material = self.materialList[self.selectedIndex];
                    [self updateBackgroundImage:material forceUpdate:YES];
                }
                self.isProgrammaticScroll = NO;
            });
        });
    }
}

- (void)uploadButtonTapped:(UIButton *)sender {
    // 与素材详情页底部按钮一致：检查金币余额后进入上传页
    if (!self.currentBackgroundMaterial) {
        // 若当前背景未设置，尝试从列表中取一个可用的
        if (self.materialList.count > 0) {
            NSInteger middleIndex = self.materialList.count / 2;
            self.currentBackgroundMaterial = self.materialList[middleIndex];
        }
    }
    
    if (!self.currentBackgroundMaterial || self.currentBackgroundMaterial.materialId <= 0) {
        return;
    }
    
    [self checkCoinAndStartUpload:self.currentBackgroundMaterial.materialId];
}

- (void)checkCoinAndStartUpload:(NSInteger)materialId {
    NSDictionary *params = @{ @"materialId": @(materialId) };
    [SVProgressHUD showWithStatus:LocalString(@"加载中")];
    
    [[NetworkManager sharedManager] GET:BUNNYX_API_CHECK_SURPLUS_MXD
                              parameters:params
                                 success:^(id responseObject) {
        [SVProgressHUD dismiss];
        NSDictionary *dict = (NSDictionary *)responseObject;
        NSInteger code = [dict[@"code"] integerValue];
        BOOL isSufficient = NO;
        if (code == 0) {
            id data = dict[@"data"];
            if ([data isKindOfClass:[NSNumber class]]) {
                isSufficient = [data boolValue];
            } else if ([data isKindOfClass:[NSString class]]) {
                isSufficient = [((NSString *)data) boolValue];
            }
        }
        
        if (isSufficient) {
            // 金币足够，进入上传页
            UploadMaterialViewController *vc = [[UploadMaterialViewController alloc] initWithMaterialId:materialId];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            // 金币不足，显示充值提示
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"余额不足")
                                                                           message:LocalString(@"余额不足，是否前往充值？")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *rechargeAction = [UIAlertAction actionWithTitle:LocalString(@"去充值")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                RechargeViewController *vc = [[RechargeViewController alloc] init];
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.materialList.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MaterialCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kMaterialCellId forIndexPath:indexPath];
    MaterialItemModel *model = self.materialList[indexPath.item];
    
    // 隐藏点赞按钮
    cell.showLikeButton = NO;
    
    [cell configureWithModel:model];
    
    // 选中状态通过sizeForItemAtIndexPath来控制大小，这里不需要额外设置边框
    // 但可以添加一些视觉反馈（可选）
    cell.contentView.layer.borderWidth = 0;
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 选中时放大：115x144，未选中：100x121
    BOOL isSelected = (indexPath.item == self.selectedIndex);
    if (isSelected) {
        return CGSizeMake(115, 144);
    } else {
        return CGSizeMake(100, 121);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.selectedIndex) {
        return;
    }
    
    // 标记为程序化滚动，避免滚动过程中的重复更新
    self.isProgrammaticScroll = YES;
    
    NSInteger oldIndex = self.selectedIndex;
    self.selectedIndex = indexPath.item;
    self.lastCenterPosition = indexPath.item; // 更新lastCenterPosition
    MaterialItemModel *material = self.materialList[indexPath.item];
    // 注意：updateBackgroundImage内部会设置currentBackgroundMaterial，这里不需要提前设置
    [self updateBackgroundImage:material];
    
    // 先滚动到位，等滚动完成后再更新布局，避免多次布局更新导致的抖动
    __weak typeof(self) weakSelf = self;
    [self.materialCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
    // 等待滚动动画完成后再更新布局
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        // 使用动画更新大小，让图片有平滑的动画效果
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            [self.materialCollectionView.collectionViewLayout invalidateLayout];
            [self.materialCollectionView layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.isProgrammaticScroll = NO;
        }];
    });
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 如果是程序化滚动（点击触发），不处理滚动更新，避免重复更新导致的抖动
    if (self.isProgrammaticScroll) {
        return;
    }
    
    // 参考安卓代码：找到最接近中心的item位置
    NSInteger centerPosition = [self findCenterPosition];
    
    // 只有当中心位置真正改变时才更新，减少不必要的重绘（参考安卓代码）
    if (centerPosition != -1 && centerPosition != self.lastCenterPosition) {
        // 先检查位置是否有效
        if (centerPosition >= 0 && centerPosition < self.materialList.count) {
            self.lastCenterPosition = centerPosition;
            
            // 使用 dispatch_async 推迟更新到下一帧，避免在滚动回调中修改 CollectionView
            // 使用 isPendingUpdate 标志避免频繁更新（参考安卓代码）
            if (!self.isPendingUpdate) {
                self.isPendingUpdate = YES;
                __weak typeof(self) weakSelf = self;
                NSInteger finalCenterPosition = centerPosition; // 使用局部变量
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf;
                    if (!self) return;
                    
                    self.isPendingUpdate = NO;
                    
                    // 再次检查位置是否有效（可能在异步期间列表发生了变化）
                    if (self.materialList && finalCenterPosition >= 0 && finalCenterPosition < self.materialList.count) {
                        if (finalCenterPosition != self.selectedIndex) {
                            NSInteger oldIndex = self.selectedIndex;
                            self.selectedIndex = finalCenterPosition;
                            MaterialItemModel *material = self.materialList[finalCenterPosition];
                            // 注意：updateBackgroundImage内部会设置currentBackgroundMaterial，这里不需要提前设置
                            [self updateBackgroundImage:material];
                            
                            // 使用动画更新大小，让图片从大变小或从小变大有平滑的动画效果
                            [UIView animateWithDuration:0.25
                                                  delay:0
                                                options:UIViewAnimationOptionCurveEaseInOut
                                             animations:^{
                                [self.materialCollectionView.collectionViewLayout invalidateLayout];
                                [self.materialCollectionView layoutIfNeeded];
                            } completion:nil];
                        }
                    }
                    
                    // 如果位置无效，重置lastCenterPosition（参考安卓代码）
                    if (finalCenterPosition < 0 || (self.materialList && finalCenterPosition >= self.materialList.count)) {
                        self.lastCenterPosition = -1;
                    }
                });
            }
        } else {
            // 位置无效，重置（参考安卓代码）
            self.lastCenterPosition = -1;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 滚动结束时，确保选中项居中（只在非程序化滚动时执行）
    BOOL wasProgrammatic = self.isProgrammaticScroll;
    
    // 滑动停止时重置lastCenterPosition，确保下次滑动时能正确检测变化（参考安卓代码）
    self.lastCenterPosition = -1;
    self.isPendingUpdate = NO;
    self.isProgrammaticScroll = NO; // 重置程序化滚动标志
    
    // 只在非程序化滚动时执行
    if (!wasProgrammatic) {
        [self adjustToCenterItem];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // 如果不再减速，也调整到中心
    if (!decelerate) {
        BOOL wasProgrammatic = self.isProgrammaticScroll;
        
        self.lastCenterPosition = -1;
        self.isPendingUpdate = NO;
        self.isProgrammaticScroll = NO; // 重置程序化滚动标志
        
        // 只在非程序化滚动时执行
        if (!wasProgrammatic) {
            [self adjustToCenterItem];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 开始拖动时重置状态（用户开始手动拖动，不是程序化滚动）
    self.lastCenterPosition = -1;
    self.isProgrammaticScroll = NO;
}

/**
 * 找到最接近中心的item位置（参考安卓代码）
 */
- (NSInteger)findCenterPosition {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.materialCollectionView.collectionViewLayout;
    CGFloat centerX = self.materialCollectionView.bounds.size.width / 2 + self.materialCollectionView.contentOffset.x;
    
    NSArray *visibleIndexPaths = [self.materialCollectionView indexPathsForVisibleItems];
    if (visibleIndexPaths.count == 0) {
        return -1;
    }
    
    CGFloat minDistance = CGFLOAT_MAX;
    NSInteger centerPosition = -1;
    
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        UICollectionViewCell *cell = [self.materialCollectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            CGFloat cellCenterX = cell.center.x;
            CGFloat distance = fabs(cellCenterX - centerX);
            if (distance < minDistance) {
                minDistance = distance;
                centerPosition = indexPath.item;
            }
        }
    }
    
    return centerPosition;
}

/**
 * 调整到中心item
 */
- (void)adjustToCenterItem {
    NSInteger centerPosition = [self findCenterPosition];
    if (centerPosition >= 0 && centerPosition < self.materialList.count) {
        if (centerPosition != self.selectedIndex) {
            NSInteger oldIndex = self.selectedIndex;
            self.selectedIndex = centerPosition;
            self.lastCenterPosition = centerPosition;
            MaterialItemModel *material = self.materialList[centerPosition];
            // 注意：updateBackgroundImage内部会设置currentBackgroundMaterial，这里不需要提前设置
            [self updateBackgroundImage:material];
            
            // 使用动画更新大小，让图片有平滑的动画效果
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                [self.materialCollectionView.collectionViewLayout invalidateLayout];
                [self.materialCollectionView layoutIfNeeded];
            } completion:nil];
        }
        
        // 滚动到中心位置
        NSIndexPath *centerPath = [NSIndexPath indexPathForItem:centerPosition inSection:0];
        [self.materialCollectionView scrollToItemAtIndexPath:centerPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

@end
