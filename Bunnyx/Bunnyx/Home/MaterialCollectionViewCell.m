//
//  MaterialCollectionViewCell.m
//  Bunnyx
//

#import "MaterialCollectionViewCell.h"
#import "MaterialItemModel.h"
#import <SDWebImage/SDWebImage.h>

@interface MaterialCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) UILabel *favoriteLabel;

@end

@implementation MaterialCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        self.contentView.layer.cornerRadius = 10.0;
        self.contentView.clipsToBounds = YES;

        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];

        _overlay = [[UIView alloc] initWithFrame:CGRectZero];
        _overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
        [self.contentView addSubview:_overlay];

        _favoriteLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _favoriteLabel.textColor = [UIColor whiteColor];
        _favoriteLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [self.contentView addSubview:_favoriteLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.contentView.bounds;
    CGFloat padding = 8.0;
    _favoriteLabel.frame = CGRectMake(self.contentView.bounds.size.width - 60 - padding,
                                     self.contentView.bounds.size.height - 20 - padding,
                                     60,
                                     20);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.favoriteLabel.text = @"";
}

- (void)configureWithModel:(MaterialItemModel *)model {
    NSURL *url = [NSURL URLWithString:model.materialUrl];
    [self.imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRetryFailed context:nil];
    if (model.favoriteQty != nil) {
        self.favoriteLabel.text = [NSString stringWithFormat:@"❤ %@", model.favoriteQty];
    } else {
        self.favoriteLabel.text = model.isFavorite ? @"❤" : @"";
    }
}

@end


