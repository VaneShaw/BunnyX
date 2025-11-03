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

@interface MaterialDetailViewController ()

@property (nonatomic, assign) NSInteger materialId;
@property (nonatomic, strong) MaterialDetailModel *detailModel;
@property (nonatomic, strong) UIImageView *materialImageView;
@property (nonatomic, strong) UIButton *moreButton; // 右上角三个点按钮
@property (nonatomic, strong) UIButton *favoriteButton; // 收藏按钮
@property (nonatomic, strong) UILabel *favoriteCountLabel;
@property (nonatomic, strong) GradientButton *generateButton; // 生成按钮
@property (nonatomic, strong) UILabel *disclaimerLabel; // 免责声明

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
    [self bringBackButtonToFront];
    [self.view bringSubviewToFront:self.moreButton];
    [self.view bringSubviewToFront:self.favoriteButton.superview];
    [self.view bringSubviewToFront:self.generateButton];
    [self.view bringSubviewToFront:self.disclaimerLabel];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    // 素材图片作为背景
    self.materialImageView = [[UIImageView alloc] init];
    self.materialImageView.contentMode = UIViewContentModeScaleAspectFill; // 填充整个区域，不拉伸
    self.materialImageView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.materialImageView.clipsToBounds = YES;
    [self.view addSubview:self.materialImageView];
    [self.materialImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 右上角更多按钮
    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.moreButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    self.moreButton.tintColor = [UIColor whiteColor];
    self.moreButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    self.moreButton.layer.cornerRadius = 20;
    self.moreButton.layer.masksToBounds = YES;
    [self.moreButton addTarget:self action:@selector(moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.moreButton];
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.width.height.mas_equalTo(40);
    }];
    
    // 收藏按钮容器
    UIView *favoriteContainer = [[UIView alloc] init];
    favoriteContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    favoriteContainer.layer.cornerRadius = 25;
    favoriteContainer.layer.masksToBounds = YES;
    [self.view addSubview:favoriteContainer];
    [favoriteContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-120);
        make.height.mas_equalTo(50);
    }];
    
    // 收藏图标和数量
    UIImageView *heartIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"heart"]];
    heartIcon.tintColor = [UIColor whiteColor];
    [favoriteContainer addSubview:heartIcon];
    [heartIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(favoriteContainer).offset(15);
        make.centerY.equalTo(favoriteContainer);
        make.width.height.mas_equalTo(20);
    }];
    
    self.favoriteCountLabel = [[UILabel alloc] init];
    self.favoriteCountLabel.textColor = [UIColor whiteColor];
    self.favoriteCountLabel.font = MEDIUM_FONT(FONT_SIZE_14);
    self.favoriteCountLabel.text = @"0";
    [favoriteContainer addSubview:self.favoriteCountLabel];
    [self.favoriteCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(heartIcon.mas_right).offset(8);
        make.centerY.equalTo(favoriteContainer);
        make.right.equalTo(favoriteContainer).offset(-15);
    }];
    
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.favoriteButton addTarget:self action:@selector(favoriteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [favoriteContainer addSubview:self.favoriteButton];
    [self.favoriteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(favoriteContainer);
    }];
    
    // 生成按钮
    self.generateButton = [GradientButton buttonWithTitle:[NSString stringWithFormat:@"%@(0Coins)", LocalString(@"生成")]];
    self.generateButton.gradientStartColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    self.generateButton.gradientEndColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.7 alpha:1.0];
    [self.generateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.generateButton addTarget:self action:@selector(generateButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.generateButton];
    [self.generateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.height.mas_equalTo(50);
    }];
    
    // 免责声明
    self.disclaimerLabel = [[UILabel alloc] init];
    self.disclaimerLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.disclaimerLabel.font = FONT(FONT_SIZE_12);
    self.disclaimerLabel.numberOfLines = 0;
    self.disclaimerLabel.textAlignment = NSTextAlignmentCenter;
    self.disclaimerLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    self.disclaimerLabel.layer.cornerRadius = 8;
    self.disclaimerLabel.layer.masksToBounds = YES;
    [self.view addSubview:self.disclaimerLabel];
    [self.disclaimerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.generateButton.mas_top).offset(-15);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    
    // 加载免责声明
    [self loadDisclaimer];
}

- (void)loadDisclaimer {
    AppConfigModel *config = [[AppConfigManager sharedManager] currentConfig];
    if (config && config.disclaimerTips && config.disclaimerTips.length > 0) {
        // 解析JSON格式的免责声明
        NSError *error = nil;
        NSData *jsonData = [config.disclaimerTips dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (!error && [dict isKindOfClass:[NSDictionary class]]) {
            // 根据当前语言获取对应的文本
            NSString *currentLanguage = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] firstObject];
            NSString *disclaimerText = nil;
            if ([currentLanguage hasPrefix:@"zh"]) {
                disclaimerText = dict[@"zh_CN"] ?: dict[@"en_US"];
            } else {
                disclaimerText = dict[@"en_US"] ?: dict[@"zh_CN"];
            }
            if (disclaimerText && disclaimerText.length > 0) {
                self.disclaimerLabel.text = disclaimerText;
            }
        } else {
            // 如果不是JSON格式，直接显示
            self.disclaimerLabel.text = config.disclaimerTips;
        }
    }
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
    
    // 加载图片
    if (self.detailModel.materialUrl && self.detailModel.materialUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:self.detailModel.materialUrl];
        [self.materialImageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRetryFailed];
    }
    
    // 更新收藏数量和状态
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.detailModel.favoriteQty];
    UIImageView *heartIcon = (UIImageView *)[self.favoriteButton.superview.subviews firstObject];
    if ([heartIcon isKindOfClass:[UIImageView class]]) {
        heartIcon.image = self.detailModel.isFavorite ? 
            [UIImage systemImageNamed:@"heart.fill"] : 
            [UIImage systemImageNamed:@"heart"];
        heartIcon.tintColor = self.detailModel.isFavorite ? [UIColor systemRedColor] : [UIColor whiteColor];
    }
    
    // 更新生成按钮
    NSString *generateTitle = [NSString stringWithFormat:@"%@(%ldCoins)", LocalString(@"生成"), (long)self.detailModel.generatePrice];
    [self.generateButton setTitle:generateTitle forState:UIControlStateNormal];
}

#pragma mark - Actions

- (void)moreButtonTapped:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil 
                                                                     message:nil 
                                                              preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *reportAction = [UIAlertAction actionWithTitle:LocalString(@"举报") 
                                                           style:UIAlertActionStyleDestructive 
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self showReportConfirmation];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消") 
                                                           style:UIAlertActionStyleCancel 
                                                         handler:nil];
    
    [alert addAction:reportAction];
    [alert addAction:cancelAction];
    
    // iPad支持
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = sender;
        alert.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showReportConfirmation {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalString(@"操作确认")
                                                                     message:LocalString(@"确定要举报此素材吗？")
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:LocalString(@"确定")
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [self reportMaterial];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalString(@"取消")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reportMaterial {
    // TODO: 实现举报接口
    [SVProgressHUD showSuccessWithStatus:LocalString(@"举报成功")];
}

- (void)favoriteButtonTapped:(UIButton *)sender {
    if (!self.detailModel) { return; }
    
    BOOL willFavorite = !self.detailModel.isFavorite;
    NSString *api = willFavorite ? BUNNYX_API_MATERIAL_FAVORITE_ADD : BUNNYX_API_MATERIAL_FAVORITE_REMOVE;
    NSDictionary *params = @{ @"materialId": @(self.detailModel.materialId) };
    
    [SVProgressHUD show];
    [[NetworkManager sharedManager] POST:api parameters:params success:^(id  _Nonnull responseObject) {
        [SVProgressHUD dismiss];
        self.detailModel.isFavorite = willFavorite;
        if (willFavorite) {
            self.detailModel.favoriteQty += 1;
        } else {
            self.detailModel.favoriteQty = MAX(0, self.detailModel.favoriteQty - 1);
        }
        [self updateUI];
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LocalString(@"操作失败")];
    }];
}

- (void)generateButtonTapped:(UIButton *)sender {
    if (!self.detailModel) { return; }
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
            // 余额足够，继续生成流程
            [self navigateToUploadMaterial];
        } else {
            // 余额不足，提醒去充值
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

@end
