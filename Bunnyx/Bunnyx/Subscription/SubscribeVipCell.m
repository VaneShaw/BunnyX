//
//  SubscribeVipCell.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "SubscribeVipCell.h"
#import <Masonry/Masonry.h>
#import "BunnyxMacros.h"

@interface SubscribeVipCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *discountTagView;
@property (nonatomic, strong) UILabel *discountLabel;
@property (nonatomic, strong) UILabel *typeRemarkLabel;
@property (nonatomic, strong) UILabel *currencySymbolLabel;
@property (nonatomic, strong) UILabel *payMoneyLabel;
@property (nonatomic, strong) UILabel *priceRemarkLabel;

@end

@implementation SubscribeVipCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 卡片容器
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [UIColor whiteColor];
    self.cardView.layer.cornerRadius = 12;
    self.cardView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.cardView];
    
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    // 类型备注
    self.typeRemarkLabel = [[UILabel alloc] init];
    self.typeRemarkLabel.textColor = [UIColor whiteColor];
    self.typeRemarkLabel.font = FONT(15);
    self.typeRemarkLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.typeRemarkLabel];
    
    [self.typeRemarkLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(16);
        make.centerX.equalTo(self.cardView);
        make.left.right.equalTo(self.cardView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
    }];
    
    // 价格容器
    UIView *priceContainer = [[UIView alloc] init];
    [self.cardView addSubview:priceContainer];
    
    [priceContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.typeRemarkLabel.mas_bottom).offset(8);
        make.centerX.equalTo(self.cardView);
        make.height.mas_equalTo(40);
    }];
    
    // 货币符号
    self.currencySymbolLabel = [[UILabel alloc] init];
    self.currencySymbolLabel.text = @"$";
    self.currencySymbolLabel.textColor = [UIColor colorWithRed:0.04 green:0.91 blue:0.44 alpha:1.0]; // #0AE971
    self.currencySymbolLabel.font = BOLD_FONT(18);
    [priceContainer addSubview:self.currencySymbolLabel];
    
    [self.currencySymbolLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(priceContainer);
        make.centerY.equalTo(priceContainer);
    }];
    
    // 价格
    self.payMoneyLabel = [[UILabel alloc] init];
    self.payMoneyLabel.textColor = [UIColor colorWithRed:0.04 green:0.91 blue:0.44 alpha:1.0]; // #0AE971
    self.payMoneyLabel.font = BOLD_FONT(28);
    [priceContainer addSubview:self.payMoneyLabel];
    
    [self.payMoneyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currencySymbolLabel.mas_right).offset(2);
        make.centerY.equalTo(priceContainer);
        make.right.equalTo(priceContainer);
    }];
    
    // 价格说明
    self.priceRemarkLabel = [[UILabel alloc] init];
    self.priceRemarkLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]; // #999999
    self.priceRemarkLabel.font = FONT(12);
    self.priceRemarkLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.priceRemarkLabel];
    
    [self.priceRemarkLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(priceContainer.mas_bottom).offset(4);
        make.centerX.equalTo(self.cardView);
        make.left.right.equalTo(self.cardView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        make.bottom.equalTo(self.cardView).offset(-16);
    }];
    
    // 折扣标签（左上角）
    self.discountTagView = [[UIView alloc] init];
    self.discountTagView.backgroundColor = [UIColor colorWithRed:0.97 green:0.43 blue:0.55 alpha:1.0]; // #F76E8C
    self.discountTagView.layer.cornerRadius = 13;
    self.discountTagView.layer.masksToBounds = YES;
    self.discountTagView.hidden = YES;
    [self.contentView addSubview:self.discountTagView];
    
    [self.discountTagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.contentView);
        make.height.mas_equalTo(26);
    }];
    
    self.discountLabel = [[UILabel alloc] init];
    self.discountLabel.textColor = [UIColor whiteColor];
    self.discountLabel.font = BOLD_FONT(12);
    self.discountLabel.textAlignment = NSTextAlignmentCenter;
    [self.discountTagView addSubview:self.discountLabel];
    
    [self.discountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.discountTagView).insets(UIEdgeInsetsMake(0, 8, 0, 8));
        make.top.bottom.equalTo(self.discountTagView).insets(UIEdgeInsetsMake(4, 0, 4, 0));
    }];
    
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped)];
    [self.contentView addGestureRecognizer:tap];
}

- (void)configureWithVipItem:(VipItemModel *)item selected:(BOOL)selected {
    self.vipItem = item;
    self.isSelected = selected;
    
    // 设置类型备注
    self.typeRemarkLabel.text = item.typeRemark ?: @"";
    
    // 设置价格
    self.payMoneyLabel.text = [NSString stringWithFormat:@"%.2f", item.payMoney];
    
    // 设置价格说明
    self.priceRemarkLabel.text = item.priceRemark ?: @"";
    
    // 设置折扣标签
    if (item.discountRemark && item.discountRemark.length > 0) {
        self.discountLabel.text = item.discountRemark;
        self.discountTagView.hidden = NO;
    } else {
        self.discountTagView.hidden = YES;
    }
    
    // 更新选中状态
    [self updateSelectedState:selected];
}

- (void)updateSelectedState:(BOOL)selected {
    if (selected) {
        // 选中状态：绿色边框
        self.cardView.layer.borderWidth = 1;
        self.cardView.layer.borderColor = [UIColor colorWithRed:0.04 green:0.92 blue:0.44 alpha:1.0].CGColor; // #0AEA6F
        // 背景渐变（深绿色）
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.cardView.bounds;
        gradient.colors = @[
            (id)[UIColor colorWithRed:0.11 green:0.20 blue:0.15 alpha:1.0].CGColor, // #1C3427
            (id)[UIColor colorWithRed:0.04 green:0.12 blue:0.10 alpha:1.0].CGColor  // #091E1A
        ];
        gradient.startPoint = CGPointMake(0, 0);
        gradient.endPoint = CGPointMake(0, 1);
        gradient.cornerRadius = 12;
        [self.cardView.layer insertSublayer:gradient atIndex:0];
    } else {
        // 未选中状态：白色背景，无边框
        self.cardView.layer.borderWidth = 0;
        self.cardView.layer.borderColor = [UIColor clearColor].CGColor;
        // 移除渐变层
        NSArray *sublayers = [self.cardView.layer.sublayers copy];
        for (CALayer *layer in sublayers) {
            if ([layer isKindOfClass:[CAGradientLayer class]]) {
                [layer removeFromSuperlayer];
            }
        }
    }
}

- (void)cellTapped {
    if ([self.delegate respondsToSelector:@selector(subscribeVipCell:didSelectItem:)]) {
        [self.delegate subscribeVipCell:self didSelectItem:self.vipItem];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 更新渐变层frame
    if (self.isSelected) {
        NSArray *sublayers = [self.cardView.layer.sublayers copy];
        for (CALayer *layer in sublayers) {
            if ([layer isKindOfClass:[CAGradientLayer class]]) {
                layer.frame = self.cardView.bounds;
            }
        }
    }
}

@end

