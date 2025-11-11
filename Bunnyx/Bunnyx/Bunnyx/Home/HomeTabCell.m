//
//  HomeTabCell.m
//  Bunnyx
//
//

#import "HomeTabCell.h"
#import "BunnyxMacros.h"

@interface HomeTabCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;

@end

@implementation HomeTabCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = @"";
}

- (void)setupViews {
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // 外层容器：左右 padding 25pt（对齐安卓 paddingHorizontal="25dp"）
    UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
    container.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:container];
    self.containerView = container;
    
    // 文字标签：上下 padding 12pt（对齐安卓 paddingVertical="12dp"）
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = HEX_COLOR(0x999999); // 未选中时 #999999（对齐安卓 black9）
    label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightRegular]; // 20pt（对齐安卓 20sp）
    label.textAlignment = NSTextAlignmentCenter;
    [container addSubview:label];
    self.titleLabel = label;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 外层容器：左右 padding 25pt
    CGFloat horizontalPadding = 25.0;
    self.containerView.frame = CGRectMake(horizontalPadding, 0, 
                                         self.contentView.bounds.size.width - horizontalPadding * 2,
                                         self.contentView.bounds.size.height);
    // 文字标签：上下 padding 12pt
    CGFloat verticalPadding = 12.0;
    self.titleLabel.frame = CGRectMake(0, verticalPadding,
                                      self.containerView.bounds.size.width,
                                      self.containerView.bounds.size.height - verticalPadding * 2);
}

- (void)configureWithTitle:(NSString *)title selected:(BOOL)selected {
    self.titleLabel.text = title;
    // 对齐安卓样式：选中和未选中都是 20sp，选中时白色，未选中时 #999999
    if (selected) {
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightRegular];
    } else {
        self.titleLabel.textColor = HEX_COLOR(0x999999); // black9
        self.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightRegular];
    }
}

@end


