//
//  MaterialCollectionViewCell.m
//  Bunnyx
//

#import "MaterialCollectionViewCell.h"
#import "MaterialItemModel.h"
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"
#import "VectorImageHelper.h"

@interface MaterialCollectionViewCell ()

@property (nonatomic, strong) UIView *containerView; // RelativeLayout，背景白色，圆角5dp
@property (nonatomic, strong) UIImageView *imageView; // 素材图片
@property (nonatomic, strong) UIImageView *vipIconView; // VIP图标，右上角
@property (nonatomic, strong) UIView *likeContainerView; // 点赞容器，右下角
@property (nonatomic, strong) UIImageView *likeIconView; // 点赞图标
@property (nonatomic, strong) UILabel *likeCountLabel; // 点赞数量
@property (nonatomic, strong) MaterialItemModel *currentModel; // 当前绑定的model

@end

@implementation MaterialCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 设置cell背景色为透明
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 外层容器：透明背景，圆角5dp
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.layer.cornerRadius = 5.0; // dp_5 = 5dp
    self.containerView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    // 素材图片：match_parent，centerCrop，圆角10dp
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 10.0; // dp_10 = 10dp
    self.imageView.layer.masksToBounds = YES;
    // 设置背景色#1D2B2C，让背景色和图片同时可见
    self.imageView.backgroundColor = HEX_COLOR(0x1D2B2C);
    [self.containerView addSubview:self.imageView];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    
    // VIP图标：右上角，margin 8dp
    self.vipIconView = [[UIImageView alloc] init];
    self.vipIconView.image = [UIImage imageNamed:@"icon_vip_list_light"];
    self.vipIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.vipIconView.hidden = YES; // 默认隐藏，根据onlyVip显示
    [self.containerView addSubview:self.vipIconView];
    
    [self.vipIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView).offset(8); // dp_8 = 8dp
        make.right.equalTo(self.containerView).offset(-8); // dp_8 = 8dp
        make.width.offset(27);
        make.height.offset(20);
    }];
    
    // 点赞容器：右下角，margin 10dp，背景黑色50%透明度，圆角12dp
    self.likeContainerView = [[UIView alloc] init];
    self.likeContainerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5]; // black50
    self.likeContainerView.layer.cornerRadius = 12.0; // dp_12 = 12dp
    self.likeContainerView.layer.masksToBounds = YES;
    [self.containerView addSubview:self.likeContainerView];
    
    [self.likeContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.containerView).offset(-10); // dp_10 = 10dp
        make.bottom.equalTo(self.containerView).offset(-10); // dp_10 = 10dp
    }];
    
    // 默认显示点赞按钮
    self.showLikeButton = YES;
    
    // 点赞图标：16dp x 16dp，marginEnd 4dp
    self.likeIconView = [[UIImageView alloc] init];
    self.likeIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.likeContainerView addSubview:self.likeIconView];
    
    [self.likeIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.likeContainerView).offset(8); // paddingHorizontal 8dp
        make.top.equalTo(self.likeContainerView).offset(4); // paddingVertical 4dp
        make.bottom.equalTo(self.likeContainerView).offset(-4);
        make.width.height.mas_equalTo(16); // dp_16 = 16dp
    }];
    
    // 点赞数量：12sp，白色
    self.likeCountLabel = [[UILabel alloc] init];
    self.likeCountLabel.textColor = [UIColor whiteColor];
    self.likeCountLabel.font = FONT(FONT_SIZE_12); // 12sp
    [self.likeContainerView addSubview:self.likeCountLabel];
    
    [self.likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.likeIconView.mas_right).offset(4); // marginEnd 4dp
        make.right.equalTo(self.likeContainerView).offset(-8); // paddingHorizontal 8dp
        make.centerY.equalTo(self.likeIconView); // 与图标垂直居中对齐
    }];
    
    // 添加点赞容器点击事件（点击点赞区域触发点赞）
    UITapGestureRecognizer *likeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(likeContainerTapped:)];
    [self.likeContainerView addGestureRecognizer:likeTap];
    self.likeContainerView.userInteractionEnabled = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    // 对于动态图，需要确保ViewHolder复用时不会停止动画
    // 不清除图片，让SDWebImage自己管理缓存和动画
    // 只清除其他UI状态
    self.likeCountLabel.text = @"";
    self.vipIconView.hidden = YES;
    // 重置点赞按钮显示状态为默认值
    self.showLikeButton = YES;
    // 取消可能存在的视图动画（onViewDetachedFromWindow中的处理）
    [self.imageView.layer removeAllAnimations];
    // 保持背景色#1D2B2C
    self.imageView.backgroundColor = HEX_COLOR(0x1D2B2C);
}

- (void)configureWithModel:(MaterialItemModel *)model {
    self.currentModel = model;
    
    // 加载图片（添加placeholder和error图片）
    NSURL *url = [NSURL URLWithString:model.materialUrl];
    if (!url) {
        self.imageView.image = [UIImage imageNamed:@"image_error_ic"];
        // 保持背景色#1D2B2C，让背景色和图片同时可见
        self.imageView.backgroundColor = HEX_COLOR(0x1D2B2C);
        return;
    }
    
 
    SDWebImageOptions options = SDWebImageRetryFailed | SDWebImageContinueInBackground | SDWebImageQueryMemoryData;
    // 使用SDWebImage加载图片，它会自动处理：
    // 1. 先检查内存缓存，如果有立即显示（通过上面的cachedImage）
    // 2. 如果没有，SDWebImage会异步从磁盘缓存读取（不会阻塞主线程）
    // 3. 如果磁盘也没有，从网络下载
    [self.imageView sd_setImageWithURL:url 
                       placeholderImage:[VectorImageHelper defaultLoadingImage]
                                options:options 
                                context:@{SDWebImageContextStoreCacheType: @(SDImageCacheTypeAll)}
                              progress:nil
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error) {
            self.imageView.image = [UIImage imageNamed:@"image_error_ic"];
        }
        // 保持背景色#1D2B2C，让背景色和图片同时可见
        self.imageView.backgroundColor = HEX_COLOR(0x1D2B2C);
    }];
    
    // 根据showLikeButton属性控制点赞按钮的显示/隐藏
    self.likeContainerView.hidden = !self.showLikeButton;
    
    // 设置点赞状态和图标（选中时用light图标，未选中用dark图标）
    BOOL isFavorite = model.isFavorite;
    // 使用与安卓相同的图片资源命名：icon_home_collection_light / icon_home_collection_dark
    self.likeIconView.image = [UIImage imageNamed:isFavorite ? @"icon_home_collection_light" : @"icon_home_collection_dark"];
    
    // 设置点赞数量
    if (model.favoriteQty != nil) {
        self.likeCountLabel.text = [NSString stringWithFormat:@"%@", model.favoriteQty];
    } else {
        self.likeCountLabel.text = @"0";
    }
    
    // 设置VIP图标显示/隐藏（onlyVip == 1时显示）
    self.vipIconView.hidden = (model.onlyVip != 1);
}

- (void)likeContainerTapped:(UITapGestureRecognizer *)gesture {
    if (self.currentModel && [self.delegate respondsToSelector:@selector(materialCollectionViewCell:didTapLikeWithModel:)]) {
        [self.delegate materialCollectionViewCell:self didTapLikeWithModel:self.currentModel];
    }
}

@end


