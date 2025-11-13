//
//  MaterialDetailViewController.m
//  Bunnyx
//

#import "MaterialDetailViewController.h"
#import "MaterialDetailModel.h"
#import "NetworkManager.h"
#import "BunnyxMacros.h"
#import "BunnyxNetworkMacros.h"
#import "GradientButton.h"
#import "AppConfigManager.h"
#import "UserInfoManager.h"
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "UploadMaterialViewController.h"
#import "RechargeViewController.h"
#import "MainTabBarController.h"

// 通知名称：刷新首页列表
NSString *const kRefreshMaterialListNotification = @"RefreshMaterialListNotification";

@interface MaterialDetailViewController ()

@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, strong) MaterialDetailModel *detailModel;
@property (nonatomic, strong) UIImageView *materialImageView;
@property (nonatomic, strong) UIButton *moreButton; // 右上角更多按钮（对齐安卓：icon_home_detail_more_light）
@property (nonatomic, strong) UIButton *favoriteButton; // 点赞按钮（使用按钮自带的image和title）
@property (nonatomic, strong) GradientButton *generateButton; // 生成按钮
@property (nonatomic, assign) BOOL hasFavoriteAction; // 标记是否有收藏操作（对齐安卓：mHasFavoriteAction）

@end

@implementation MaterialDetailViewController

- (instancetype)initWithMaterialId:(NSInteger)materialId {
    self = [super init];
    if (self) {
        _materialId = materialId;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self fetchMaterialDetail];
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
    [self.view bringSubviewToFront:self.generateButton];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    // 素材图片作为背景（对齐安卓：centerCrop，支持WebP动图）
    self.materialImageView = [[UIImageView alloc] init];
    self.materialImageView.contentMode = UIViewContentModeScaleAspectFill; // 对应安卓的centerCrop
    self.materialImageView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.materialImageView.clipsToBounds = YES;
    self.materialImageView.userInteractionEnabled = NO; // 背景图片不拦截点击事件
    [self.view addSubview:self.materialImageView];
    [self.materialImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    

    // 右上角更多按钮（对齐安卓：icon_home_detail_more_light，在TitleBar右侧）
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
    
    // 底部内容区域容器（对齐安卓：LinearLayout，layout_gravity="bottom"，marginBottom 30dp）
    UIView *bottomContainer = [[UIView alloc] init];
    bottomContainer.backgroundColor = [UIColor clearColor];
    bottomContainer.userInteractionEnabled = YES; // 确保容器可以响应点击事件
    [self.view addSubview:bottomContainer];
    [bottomContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-30); // dp_30 = 30dp
        make.height.offset(200);
    }];
    
    // 对齐安卓：生成按钮在底部（第一个子视图在LinearLayout中在上方，但marginBottom使其在底部）
    // 生成按钮（对齐安卓：高度48dp，marginHorizontal 30dp，marginBottom 20dp，圆角12dp，渐变背景#0AEA6F到#1CB3C1，文字17sp，bold）
    self.generateButton = [GradientButton buttonWithTitle:[NSString stringWithFormat:@"Generate(0Coins)"]];
    // 对齐安卓渐变颜色：#0AEA6F到#1CB3C1
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
        make.bottom.equalTo(bottomContainer).offset(-20); // marginBottom 20dp（对齐安卓：距离底部容器底部20dp）
        make.height.mas_equalTo(48); // dp_48 = 48dp
    }];
    
    // 对齐安卓：点赞按钮在生成按钮上方（高度48dp，marginHorizontal 30dp，marginBottom 20dp，背景like_count_bg，圆角10dp）
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
}

- (void)backButtonTapped:(UIButton *)sender {
    // 对齐安卓：如果有收藏操作，返回首页并刷新列表
    if (self.hasFavoriteAction) {
        // 发送通知刷新首页列表
        [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshMaterialListNotification object:nil];
        // 切换到首页tab（索引0）
        UITabBarController *tabBarController = self.tabBarController;
        if (tabBarController && tabBarController.viewControllers.count > 0) {
            tabBarController.selectedIndex = 0;
        }
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
    
    // 加载图片（对齐安卓：支持WebP动图，使用AUTOMATIC缓存策略）
    if (self.detailModel.materialUrl && self.detailModel.materialUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:self.detailModel.materialUrl];
        [self.materialImageView sd_setImageWithURL:url 
                                    placeholderImage:[UIImage imageNamed:@"image_error_ic"]
                                             options:SDWebImageRetryFailed
                                             context:@{SDWebImageContextStoreCacheType: @(SDImageCacheTypeAll)}];
    }
    
    // 更新收藏数量和状态（使用按钮自带的image和title）
    NSInteger favoriteCount = self.detailModel.favoriteQty ? [self.detailModel.favoriteQty integerValue] : 0;
    NSString *favoriteCountText = [NSString stringWithFormat:@"%ld", (long)favoriteCount];
    [self.favoriteButton setTitle:favoriteCountText forState:UIControlStateNormal];
    
    // 对齐安卓：已点赞使用icon_home_collection_light，未点赞使用icon_home_collection_dark
    UIImage *heartImage = nil;
    if (self.detailModel.isFavorite) {
        heartImage = [UIImage imageNamed:@"icon_home_collection_light"];
    } else {
        heartImage = [UIImage imageNamed:@"icon_home_collection_dark"];
    }
    // 调整图片大小为20x20
    heartImage = [self resizeImage:heartImage toSize:CGSizeMake(20, 20)];
    [self.favoriteButton setImage:heartImage forState:UIControlStateNormal];
    
    // 更新生成按钮（对齐安卓：Generate(XXCoins)，17sp，bold）
    NSString *generateTitle = [NSString stringWithFormat:@"Generate(%ldCoins)", (long)self.detailModel.generatePrice];
    [self.generateButton setTitle:generateTitle forState:UIControlStateNormal];
}

#pragma mark - Actions

- (void)moreButtonTapped:(UIButton *)sender {
    // 对齐安卓：显示底部弹窗，包含举报和屏蔽两个选项
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

- (void)reportMaterialWithType:(NSInteger)type {
    // 对齐安卓：调用reportMaterial API，参数materialId和type（0:report, 1:block）
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
            // 对齐安卓：成功后关闭当前页面，返回首页并刷新列表
            // 发送通知刷新首页列表
            [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshMaterialListNotification object:nil];
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
    // 对齐安卓：使用FavoriteMaterialApi，参数materialId和add
    NSDictionary *params = @{
        @"materialId": @(self.detailModel.materialId),
        @"add": @(willFavorite)
    };
    
    [SVProgressHUD show];
    [[NetworkManager sharedManager] POST:BUNNYX_API_MATERIAL_FAVORITE_ADD parameters:params success:^(id  _Nonnull responseObject) {
        [SVProgressHUD dismiss];
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 0) {
            // 对齐安卓：标记有收藏操作
            self.hasFavoriteAction = YES;
            
            // 对齐安卓：更新本地状态和数量
            self.detailModel.isFavorite = willFavorite;
            NSInteger currentCount = self.detailModel.favoriteQty ? [self.detailModel.favoriteQty integerValue] : 0;
            if (willFavorite) {
                self.detailModel.favoriteQty = @(currentCount + 1);
            } else {
                self.detailModel.favoriteQty = @(MAX(0, currentCount - 1));
            }
            [self updateUI];
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
    // 对齐安卓：先检查金币余额
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
            // 余额足够，检查VIP权限（对齐安卓：checkVipAndGenerate）
            [self checkVipAndGenerate];
        } else {
            // 余额不足，提醒去充值（对齐安卓：showRechargeDialog）
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

// 对齐安卓：检查VIP权限并继续生成流程
- (void)checkVipAndGenerate {
    if (!self.detailModel) {
        // 如果Material对象不存在，需要先获取（对齐安卓：loadMaterialForVipCheck）
        [self loadMaterialForVipCheck];
        return;
    }
    
    // 检查onlyVip字段（对齐安卓）
    NSInteger onlyVip = self.detailModel.onlyVip;
    if (onlyVip == 1) {
        // 检查用户是否是VIP（对齐安卓：UserInfoManager.getInstance(this).isVip()）
        BOOL isVip = [[UserInfoManager sharedManager] isVip];
        if (!isVip) {
            // 不是VIP，显示VIP提示弹窗（对齐安卓：showVipRequiredDialog）
            [self showVipRequiredDialog];
            return;
        }
    }
    
    // VIP检查通过，继续生成流程（对齐安卓：proceedToGenerate）
    [self proceedToGenerate];
}

// 对齐安卓：加载素材信息用于VIP检查
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

// 对齐安卓：显示VIP要求弹窗
- (void)showVipRequiredDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"仅VIP可用")
                                                                     message:LocalString(@"此素材仅VIP用户可用，是否前往订阅？")
                                                              preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *subscribeAction = [UIAlertAction actionWithTitle:LocalString(@"去订阅")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        // 对齐安卓：关闭当前页面并跳转到首页第三个tab（订阅页面，索引2）
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

// 对齐安卓：继续生成流程
- (void)proceedToGenerate {
    [self navigateToUploadMaterial];
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
