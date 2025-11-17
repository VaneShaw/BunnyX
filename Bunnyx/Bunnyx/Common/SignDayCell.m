//
//  SignDayCell.m
//  Bunnyx
//
//  签到天列表Cell（对齐安卓item_sign_day.xml）
//

#import "SignDayCell.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"

@interface SignDayCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *coinLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer; // 渐变背景层（参考GradientButton）

@end

@implementation SignDayCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 外层容器（对齐安卓：padding 6dp）
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // 内层容器（对齐安卓：圆角10dp，padding 8dp）
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.layer.cornerRadius = 10; // 对齐安卓：10dp
    self.containerView.layer.masksToBounds = YES;
    
    [self.contentView addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 6, 6, 6));
    }];
    
    // 创建渐变背景层（参考GradientButton实现）
    // 起始颜色：#F4FFCB，终止颜色：#BDFFE2，从左往右渐变
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.startPoint = CGPointMake(0, 0.5); // 左边中间（从左往右）
    self.gradientLayer.endPoint = CGPointMake(1, 0.5); // 右边中间（从左往右）
    self.gradientLayer.cornerRadius = 10; // 对齐安卓：10dp
    self.gradientLayer.colors = @[
        (__bridge id)HEX_COLOR(0xF4FFCB).CGColor, // 起始颜色：#F4FFCB
        (__bridge id)HEX_COLOR(0xBDFFE2).CGColor  // 终止颜色：#BDFFE2
    ];
    [self.containerView.layer insertSublayer:self.gradientLayer atIndex:0];
    
    // 金币文本（对齐安卓：18sp bold，颜色#0AE971，marginTop 3dp，带图标）
    self.coinLabel = [[UILabel alloc] init];
    self.coinLabel.textColor = HEX_COLOR(0x0AE971); // 对齐安卓：#0AE971
    self.coinLabel.font = BOLD_FONT(18); // 对齐安卓：18sp bold
    self.coinLabel.textAlignment = NSTextAlignmentCenter;
    
    // 添加金币图标（对齐安卓：drawableStartCompat="@drawable/icon_mine_coin_default"）
    UIImage *coinIcon = [UIImage imageNamed:@"icon_mine_coin_default"];
    if (coinIcon) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = coinIcon;
        attachment.bounds = CGRectMake(0, -2, 16, 16); // 调整图标位置
        NSAttributedString *iconString = [NSAttributedString attributedStringWithAttachment:attachment];
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
        [attributedText appendAttributedString:iconString];
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        self.coinLabel.attributedText = attributedText;
    }
    
    [self.containerView addSubview:self.coinLabel];
    
    [self.coinLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(8 + 3); // padding 8dp + marginTop 3dp
    }];
    
    // 日期文本（对齐安卓：11sp，颜色@color/black1，marginTop 3dp）
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.textColor = HEX_COLOR(0x333333); // 对齐安卓：@color/black1（使用#333333）
    self.dateLabel.font = FONT(11); // 对齐安卓：11sp
    self.dateLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.dateLabel];
    
    [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.coinLabel.mas_bottom).offset(3);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新渐变层的frame和圆角（参考GradientButton实现）
    // 直接使用containerView.bounds，即使为0也会在后续layout中更新
    if (self.gradientLayer) {
        self.gradientLayer.frame = self.containerView.bounds;
        self.gradientLayer.cornerRadius = 10; // 对齐安卓：10dp
    }
    
    // 确保containerView的圆角正确应用（对齐安卓：四个角都有圆角）
    self.containerView.layer.cornerRadius = 10; // 对齐安卓：10dp
    self.containerView.layer.masksToBounds = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)configureWithCoinText:(NSString *)coinText dateText:(NSString *)dateText {
    // 更新金币文本（对齐安卓）
    UIImage *coinIcon = [UIImage imageNamed:@"icon_mine_coin_default"];
    if (coinIcon) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = coinIcon;
        attachment.bounds = CGRectMake(0, -2, 16, 16);
        NSAttributedString *iconString = [NSAttributedString attributedStringWithAttachment:attachment];
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
        [attributedText appendAttributedString:iconString];
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", coinText ?: @""]]];
        self.coinLabel.attributedText = attributedText;
    } else {
        self.coinLabel.text = coinText;
    }
    
    // 更新日期文本
    self.dateLabel.text = dateText ?: @"";
    
    // 强制更新布局，确保渐变层frame正确（避免首次显示时背景色不显示）
    [self setNeedsLayout];
    [self layoutIfNeeded];
}


@end

