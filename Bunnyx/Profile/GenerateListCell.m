//
//  GenerateListCell.m
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import "GenerateListCell.h"
#import <Masonry/Masonry.h>
#import "CreateTaskModel.h"
#import "BunnyxMacros.h"
#import <SDWebImage/SDWebImage.h>
#import "LanguageManager.h"
#import "VectorImageHelper.h"

@implementation GenerateListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 外层容器（对应CardView）
    // marginHorizontal: 10dp, marginVertical: 5dp, cornerRadius: 15dp, backgroundColor: #08FFFFFF
    self.outerContainerView = [[UIView alloc] init];
    self.outerContainerView.backgroundColor = RGBA(255, 255, 255, 0.031); // #08FFFFFF
    self.outerContainerView.layer.cornerRadius = 15;
    self.outerContainerView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.outerContainerView];
    
    [self.outerContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(10);
        make.right.equalTo(self.contentView).offset(-10);
        make.top.equalTo(self.contentView).offset(5);
        make.bottom.equalTo(self.contentView).offset(-5);
    }];
    
    // 内层容器（对应LinearLayout）
    // padding: 16dp
    self.innerContainerView = [[UIView alloc] init];
    self.innerContainerView.backgroundColor = [UIColor clearColor];
    [self.outerContainerView addSubview:self.innerContainerView];
    
    [self.innerContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.outerContainerView).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    
    // 标题和时间容器（对应标题时间行的LinearLayout）
    // marginTop: 15dp, orientation: horizontal
    self.titleTimeContainerView = [[UIView alloc] init];
    self.titleTimeContainerView.backgroundColor = [UIColor clearColor];
    [self.innerContainerView addSubview:self.titleTimeContainerView];
    
    [self.titleTimeContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.innerContainerView);
        make.top.equalTo(self.innerContainerView).offset(15);
    }];
    
    // 标题Label
    // textSize: 15sp, textColor: white, marginStart: 15dp, textStyle: bold
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = BOLD_FONT(15);
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.text = @"AI face changing";
    [self.titleTimeContainerView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleTimeContainerView).offset(15);
        make.top.bottom.equalTo(self.titleTimeContainerView);
    }];
    
    // 时间Label
    // textSize: 12sp, textColor: black9 (#999999), marginStart: 15dp
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = FONT(12);
    self.timeLabel.textColor = HEX_COLOR(0x999999); // black9
    self.timeLabel.text = @"2025-10-25 09:22:03";
    [self.titleTimeContainerView addSubview:self.timeLabel];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.titleTimeContainerView).offset(-15);
        make.top.bottom.equalTo(self.titleTimeContainerView);
        make.left.greaterThanOrEqualTo(self.titleLabel.mas_right).offset(15);
    }];
    
    // 图片卡片容器（对应CardView）
    // width: 175dp, height: 220dp, marginTop: 15dp, marginBottom: 12dp, cornerRadius: 10dp
    self.imageCardView = [[UIView alloc] init];
    self.imageCardView.backgroundColor = [UIColor clearColor];
    self.imageCardView.layer.cornerRadius = 10;
    self.imageCardView.layer.masksToBounds = YES;
    [self.innerContainerView addSubview:self.imageCardView];
    
    [self.imageCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.innerContainerView);
        make.width.mas_equalTo(175);
        make.height.mas_equalTo(220);
        make.top.equalTo(self.titleTimeContainerView.mas_bottom).offset(15);
    }];
    
    // 封面图（对应ImageView）
    // scaleType: centerCrop
    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.layer.cornerRadius = 10;
    self.coverImageView.layer.masksToBounds = YES;
    [self.imageCardView addSubview:self.coverImageView];
    
    [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.imageCardView);
    }];
    
    // VIP图标（对应ImageView）
    // alignParentEnd: true, alignParentTop: true, margin: 8dp
    self.vipImageView = [[UIImageView alloc] init];
    self.vipImageView.image = [UIImage imageNamed:@"icon_vip_list_light"];
    self.vipImageView.hidden = YES;
    [self.imageCardView addSubview:self.vipImageView];
    
    [self.vipImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self.imageCardView).insets(UIEdgeInsetsMake(8, 0, 0, 8));
    }];
    
    // 状态标签行容器（对应LinearLayout）
    // visibility: gone (默认隐藏), orientation: horizontal, gravity: center_vertical
    self.statusRowView = [[UIView alloc] init];
    self.statusRowView.backgroundColor = [UIColor clearColor];
    self.statusRowView.hidden = YES;
    [self.innerContainerView addSubview:self.statusRowView];
    
    [self.statusRowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.innerContainerView);
        make.top.equalTo(self.imageCardView.mas_bottom).offset(10);
        make.height.offset(0);
        make.bottom.equalTo(self.innerContainerView);
    }];
    
    // 状态标签（对应ShapeTextView）
    // height: 24dp, marginEnd: 8dp, paddingStart/End: 8dp, textSize: 12sp, textColor: white
    // background: bg_status_gradient (渐变背景 #0AEA6F -> #1CB3C1, 圆角: topLeft/topRight/bottomLeft/bottomRight: 10/5/5/10)
    
    // 创建渐变背景容器
    UIView *statusBackgroundView = [[UIView alloc] init];
    statusBackgroundView.layer.masksToBounds = YES;
    [self.statusRowView addSubview:statusBackgroundView];
    
    [statusBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.statusRowView);
        make.height.mas_equalTo(24);
        make.centerY.equalTo(self.statusRowView);
    }];
    
    // 创建渐变背景layer（在layoutSubviews中设置frame）
    CAGradientLayer *statusGradientLayer = [CAGradientLayer layer];
    statusGradientLayer.colors = @[(__bridge id)HEX_COLOR(0x0AEA6F).CGColor, (__bridge id)HEX_COLOR(0x1CB3C1).CGColor];
    statusGradientLayer.startPoint = CGPointMake(0, 0);
    statusGradientLayer.endPoint = CGPointMake(0, 1);
    // 圆角: topLeft/topRight/bottomLeft/bottomRight: 10/5/5/10
    // 使用CAShapeLayer创建自定义圆角路径
    [statusBackgroundView.layer addSublayer:statusGradientLayer];
    self.statusGradientLayer = statusGradientLayer;
    
    // 状态标签（放在渐变背景容器上）
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = FONT(12);
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.text = LocalString(@"mine_in_queue");
    [statusBackgroundView addSubview:self.statusLabel];
    
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(statusBackgroundView).insets(UIEdgeInsetsMake(0, 8, 0, 8)); // paddingStart/End: 8dp
    }];
    
    // 进度点容器（根据position显示不同数量的点）
    self.progressDotsContainer = [[UIView alloc] init];
    self.progressDotsContainer.backgroundColor = [UIColor clearColor];
    [self.statusRowView addSubview:self.progressDotsContainer];
    
    [self.progressDotsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.statusLabel.mas_right).offset(8);
        make.centerY.equalTo(self.statusRowView);
        make.height.mas_equalTo(8); // 点的高度8dp
    }];
    
    // 初始化进度点视图数组
    self.progressDotViews = [NSMutableArray array];
    
    // 队列信息标签（对应TextView）
    // textSize: 12sp, textColor: white
    self.queueInfoLabel = [[UILabel alloc] init];
    self.queueInfoLabel.font = FONT(12);
    self.queueInfoLabel.textColor = [UIColor whiteColor];
    [self.statusRowView addSubview:self.queueInfoLabel];
    
    [self.queueInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.progressDotsContainer.mas_right).offset(8);
        make.centerY.equalTo(self.statusRowView);
        make.right.lessThanOrEqualTo(self.statusRowView);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新状态标签的渐变背景layer的frame和圆角
    if (self.statusGradientLayer && self.statusGradientLayer.superlayer) {
        CALayer *parentLayer = self.statusGradientLayer.superlayer;
        self.statusGradientLayer.frame = parentLayer.bounds;
        // 创建自定义圆角路径：topLeft/topRight/bottomLeft/bottomRight: 10/5/5/10
        UIBezierPath *path = [UIBezierPath bezierPath];
        CGFloat width = parentLayer.bounds.size.width;
        CGFloat height = parentLayer.bounds.size.height;
        CGFloat topLeft = 10;
        CGFloat topRight = 5;
        CGFloat bottomLeft = 5;
        CGFloat bottomRight = 10;
        
        [path moveToPoint:CGPointMake(topLeft, 0)];
        [path addLineToPoint:CGPointMake(width - topRight, 0)];
        [path addQuadCurveToPoint:CGPointMake(width, topRight) controlPoint:CGPointMake(width, 0)];
        [path addLineToPoint:CGPointMake(width, height - bottomRight)];
        [path addQuadCurveToPoint:CGPointMake(width - bottomRight, height) controlPoint:CGPointMake(width, height)];
        [path addLineToPoint:CGPointMake(bottomLeft, height)];
        [path addQuadCurveToPoint:CGPointMake(0, height - bottomLeft) controlPoint:CGPointMake(0, height)];
        [path addLineToPoint:CGPointMake(0, topLeft)];
        [path addQuadCurveToPoint:CGPointMake(topLeft, 0) controlPoint:CGPointMake(0, 0)];
        [path closePath];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = path.CGPath;
        self.statusGradientLayer.mask = maskLayer;
    }
    
    // 更新封面图的渐变背景layer的frame
    if (self.coverImageView.layer.sublayers.count > 0) {
        for (CALayer *layer in self.coverImageView.layer.sublayers) {
            if ([layer isKindOfClass:[CAGradientLayer class]]) {
                layer.frame = self.coverImageView.bounds;
            }
        }
    }
}

- (void)configureWithModel:(CreateTaskModel *)model {
    if (!model) {
        return;
    }
    
    // 设置标题
    if (model.typeRemark && model.typeRemark.length > 0) {
        self.titleLabel.text = model.typeRemark;
    } else {
        self.titleLabel.text = @"AI face changing";
    }
    
    // 设置时间
    if (model.addDate && model.addDate.length > 0) {
        // 格式化时间：支持多种输入格式，转换为 "yyyy-MM-dd HH:mm"
        self.timeLabel.text = [self formatDateTime:model.addDate];
    } else {
        self.timeLabel.text = @"";
    }
    
    // 设置状态标签
    if (model.statusRemark && model.statusRemark.length > 0) {
        self.statusLabel.text = model.statusRemark;
    } else {
        self.statusLabel.text = LocalString(@"mine_in_queue");
    }
    
    // 设置队列信息
    if (model.positionRemark && model.positionRemark.length > 0) {
        self.queueInfoLabel.text = model.positionRemark;
    } else {
        self.queueInfoLabel.text = @"";
    }
    
    // 设置VIP图标显示/隐藏
    self.vipImageView.hidden = (model.onlyVip != 1);
    
    // 根据status状态显示不同内容
    int status = model.status;
    switch (status) {
        case 1: // 排队中
        case 2: // 生成中
            [self showLoadingState:model];
            break;
        case 3: // 生成成功
            [self showCompletedState:model];
            break;
        case 0: // 等待进入队列
        case 4: // 生成失败
        case 5: // 生成不存在
        default: // 其他状态
            [self showDefaultState:model];
            break;
    }
}

- (void)showLoadingState:(CreateTaskModel *)createTask {
    // 显示渐变背景
    self.coverImageView.hidden = NO;
    // 清除背景色，使用渐变背景
    self.coverImageView.backgroundColor = [UIColor clearColor];
    // 设置渐变背景（bg_generate_gradient: #CECDF5 -> #F0CADB -> #CFCBF5）
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[
        (__bridge id)HEX_COLOR(0xCECDF5).CGColor,
        (__bridge id)HEX_COLOR(0xF0CADB).CGColor,
        (__bridge id)HEX_COLOR(0xCFCBF5).CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
    gradientLayer.cornerRadius = 10;
    gradientLayer.frame = self.coverImageView.bounds;
    // 移除旧的渐变层
    NSArray *sublayers = [self.coverImageView.layer.sublayers copy];
    for (CALayer *layer in sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
    [self.coverImageView.layer insertSublayer:gradientLayer atIndex:0];
    self.coverImageView.image = nil;
    
    // 显示状态标签行
    self.statusRowView.hidden = NO;
    
    // 根据position显示不同数量的进度点
    [self updateProgressDots:createTask];
}

// 根据position显示不同数量的进度点
- (void)updateProgressDots:(CreateTaskModel *)createTask {
    // 清除旧的进度点
    for (UIView *dotView in self.progressDotViews) {
        [dotView removeFromSuperview];
    }
    [self.progressDotViews removeAllObjects];
    
    // 获取position值（排队位置）
    NSInteger position = 0;
    if (createTask.position && [createTask.position isKindOfClass:[NSNumber class]]) {
        position = [createTask.position integerValue];
    }
    
    // 根据position显示不同数量的点（最多5个点）
    // position=1显示1个点，position=2显示2个点，以此类推，最多5个点
    NSInteger dotCount = MIN(MAX(position, 0), 5); // 限制在0-5之间
    
    if (dotCount <= 0) {
        // 没有点，隐藏容器
        self.progressDotsContainer.hidden = YES;
        return;
    }
    
    // 显示容器
    self.progressDotsContainer.hidden = NO;
    
    // 创建进度点（LoadingDotsView的样式）
    // 方块尺寸：8dp，间距：4dp
    CGFloat dotSize = 8;
    CGFloat spacing = 4;
    CGFloat totalWidth = dotCount * dotSize + (dotCount - 1) * spacing;
    
    // 更新容器宽度约束
    [self.progressDotsContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(totalWidth);
    }];
    
    // 创建点视图（颜色从深蓝到浅蓝）
    NSArray *dotColors = @[
        HEX_COLOR(0x1E3A8A), // 深蓝
        HEX_COLOR(0x3B82F6), // 中深蓝
        HEX_COLOR(0x60A5FA), // 中蓝
        HEX_COLOR(0x93C5FD), // 浅蓝
        HEX_COLOR(0xDBEAFE)  // 最浅蓝
    ];
    
    for (NSInteger i = 0; i < dotCount; i++) {
        UIView *dotView = [[UIView alloc] init];
        dotView.backgroundColor = dotColors[MIN(i, dotColors.count - 1)];
        dotView.layer.cornerRadius = 2; // 圆角2dp
        dotView.layer.masksToBounds = YES;
        [self.progressDotsContainer addSubview:dotView];
        [self.progressDotViews addObject:dotView];
        
        [dotView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.progressDotsContainer).offset(i * (dotSize + spacing));
            make.width.height.mas_equalTo(dotSize);
            make.centerY.equalTo(self.progressDotsContainer);
        }];
    }
}

- (void)showCompletedState:(CreateTaskModel *)createTask {
    // 显示图片
    self.coverImageView.hidden = NO;
    // 去掉渐变背景
    NSArray *sublayers = [self.coverImageView.layer.sublayers copy];
    for (CALayer *layer in sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
    // 设置背景色#1D2B2C，让背景色和图片同时可见
    self.coverImageView.backgroundColor = HEX_COLOR(0x1D2B2C);
    
    // 直接使用imageUrl显示封面图
    NSString *imageUrl = createTask.imageUrl;
    
    if (imageUrl && imageUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:imageUrl];
        // 使用SDWebImage加载图片，并添加圆角处理
        [self.coverImageView sd_setImageWithURL:url
                               placeholderImage:[VectorImageHelper defaultLoadingImage]
                                        options:SDWebImageRetryFailed
                                      completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (error) {
                [self setFailureImage];
            } else {
                // 加载成功时，恢复正常的contentMode，保持背景色
                self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
                self.coverImageView.backgroundColor = HEX_COLOR(0x1D2B2C);
            }
        }];
    } else {
        [self setFailureImage];
    }
    
    // 隐藏状态标签行（包括进度点）
    self.statusRowView.hidden = YES;
    self.progressDotsContainer.hidden = YES;
}

- (void)showDefaultState:(CreateTaskModel *)createTask {
    // 显示默认图片
    self.coverImageView.hidden = NO;
    // 去掉渐变背景
    NSArray *sublayers = [self.coverImageView.layer.sublayers copy];
    for (CALayer *layer in sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
    // 设置背景色#1D2B2C，让背景色和图片同时可见
    self.coverImageView.backgroundColor = HEX_COLOR(0x1D2B2C);
    [self setFailureImage];
    
    // 显示状态标签行（除了成功状态，其他状态都要显示）
    self.statusRowView.hidden = NO;
    [self.statusRowView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.innerContainerView);
        make.top.equalTo(self.imageCardView.mas_bottom).offset(10);
        make.height.offset(20);
        make.bottom.equalTo(self.innerContainerView);
    }];
    // 非排队状态，隐藏进度点
    self.progressDotsContainer.hidden = YES;
}

// 设置失败图片：使用icon_failure_default_ image，图片大小145*120，居中显示
- (void)setFailureImage {
    UIImage *failureImage = [UIImage imageNamed:@"icon_failure_default_ image"];
    if (failureImage) {
        // 将图片缩放到145*120
        CGSize targetSize = CGSizeMake(145, 120);
        UIGraphicsBeginImageContextWithOptions(targetSize, NO, [UIScreen mainScreen].scale);
        [failureImage drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.coverImageView.image = scaledImage;
        // 设置contentMode为Center，让图片在imageView中居中显示
        self.coverImageView.contentMode = UIViewContentModeCenter;
        // 设置背景色#1D2B2C，让背景色和图片同时可见
        self.coverImageView.backgroundColor = HEX_COLOR(0x1D2B2C);
    } else {
        // 如果图片不存在，使用默认图片
        self.coverImageView.image = [UIImage imageNamed:@"image_error_ic"];
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        // 设置背景色#1D2B2C，让背景色和图片同时可见
        self.coverImageView.backgroundColor = HEX_COLOR(0x1D2B2C);
    }
}

- (NSString *)formatDateTime:(NSString *)dateTimeStr {
    if (!dateTimeStr || dateTimeStr.length == 0) {
        return @"";
    }
    
    // 输出格式：yyyy-MM-dd HH:mm
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    outputFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    outputFormatter.locale = [NSLocale currentLocale];
    
    // 尝试多种输入格式
    NSArray *inputFormats = @[
        @"yyyy-MM-dd'T'HH:mm:ss.SSSXXX",  // ISO 8601格式: 2025-10-11T07:48:49.000+00:00
        @"yyyy-MM-dd'T'HH:mm:ss.SSS",     // ISO格式不带时区: 2025-10-11T07:48:49.000
        @"yyyy-MM-dd'T'HH:mm:ss",         // ISO格式不带毫秒: 2025-10-11T07:48:49
        @"yyyy-MM-dd HH:mm:ss",            // 简单格式: 2025-11-06 06:46:07
        @"yyyy-MM-dd HH:mm"                // 简单格式不带秒: 2025-11-06 06:46
    ];
    
    for (NSString *format in inputFormats) {
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        inputFormatter.dateFormat = format;
        inputFormatter.locale = [NSLocale currentLocale];
        NSDate *date = [inputFormatter dateFromString:dateTimeStr];
        if (date) {
            return [outputFormatter stringFromDate:date];
        }
    }
    
    // 所有格式都解析失败，返回原字符串
    BUNNYX_LOG(@"无法解析日期格式: %@", dateTimeStr);
    return dateTimeStr;
}

@end
