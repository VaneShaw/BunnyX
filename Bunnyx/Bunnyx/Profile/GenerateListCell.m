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
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
    self.containerView.layer.cornerRadius = 12;
    self.containerView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, MARGIN_20, 0, MARGIN_20));
        make.top.bottom.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 0, 8, 0));
    }];
    
    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.layer.cornerRadius = 8;
    self.coverImageView.layer.masksToBounds = YES;
    [self.containerView addSubview:self.coverImageView];
    
    [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView).offset(MARGIN_15);
        make.top.bottom.equalTo(self.containerView).insets(UIEdgeInsetsMake(MARGIN_15, 0, MARGIN_15, 0));
        make.width.equalTo(self.coverImageView.mas_height);
    }];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = BOLD_FONT(FONT_SIZE_16);
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.numberOfLines = 1;
    [self.containerView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.coverImageView.mas_right).offset(MARGIN_15);
        make.top.equalTo(self.containerView).offset(MARGIN_15);
        make.right.equalTo(self.containerView).offset(-MARGIN_15);
    }];
    
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = FONT(FONT_SIZE_12);
    self.timeLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    [self.containerView addSubview:self.timeLabel];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
    }];
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = FONT(FONT_SIZE_12);
    self.statusLabel.textColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.3 alpha:1.0];
    self.statusLabel.numberOfLines = 0;
    [self.containerView addSubview:self.statusLabel];
    
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.timeLabel.mas_bottom).offset(8);
        make.right.lessThanOrEqualTo(self.containerView).offset(-MARGIN_15);
        make.bottom.lessThanOrEqualTo(self.containerView).offset(-MARGIN_15);
    }];
    
    self.loadingView = [[UIView alloc] init];
    self.loadingView.backgroundColor = [UIColor clearColor];
    self.loadingView.hidden = YES;
    [self.containerView addSubview:self.loadingView];
    
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.coverImageView);
        make.width.height.mas_equalTo(40);
    }];
    
    for (int i = 0; i < 5; i++) {
        UIView *square = [[UIView alloc] init];
        square.backgroundColor = [UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0];
        square.layer.cornerRadius = 2;
        [self.loadingView addSubview:square];
        
        [square mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(6);
            make.centerY.equalTo(self.loadingView);
            make.left.equalTo(self.loadingView).offset(i * 10);
        }];
    }
}

- (void)configureWithModel:(CreateTaskModel *)model {
    if (model.typeRemark && model.typeRemark.length > 0) {
        self.titleLabel.text = model.typeRemark;
    } else {
        self.titleLabel.text = LocalString(@"生成");
    }
    
    if (model.addDate && model.addDate.length > 0) {
        self.timeLabel.text = model.addDate;
    } else {
        self.timeLabel.text = @"";
    }
    
    NSString *imageUrl = nil;
    if (model.status == 3) {
        if (model.videoUrl && model.videoUrl.length > 0) {
            imageUrl = model.videoUrl;
        } else if (model.imageUrl && model.imageUrl.length > 0) {
            imageUrl = model.imageUrl;
        }
    } else {
        if (model.imageUrl && model.imageUrl.length > 0) {
            imageUrl = model.imageUrl;
        }
    }
    
    if (imageUrl && imageUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:imageUrl];
        [self.coverImageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRetryFailed];
    } else {
        self.coverImageView.image = nil;
    }
    
    if (model.status == 3) {
        self.statusLabel.hidden = YES;
        self.loadingView.hidden = YES;
    } else {
        self.statusLabel.hidden = NO;
        self.loadingView.hidden = NO;
        
        NSMutableString *statusText = [NSMutableString string];
        if (model.statusRemark && model.statusRemark.length > 0) {
            [statusText appendString:model.statusRemark];
        }
        if (model.positionRemark && model.positionRemark.length > 0) {
            if (statusText.length > 0) {
                [statusText appendString:@"\n"];
            }
            [statusText appendString:model.positionRemark];
        }
        self.statusLabel.text = statusText.length > 0 ? statusText : @"";
        
        if (model.status == 2) {
            self.loadingView.hidden = NO;
            [self startLoadingAnimation];
        } else {
            self.loadingView.hidden = YES;
            [self stopLoadingAnimation];
        }
    }
}

- (void)startLoadingAnimation {
    NSArray *subviews = self.loadingView.subviews;
    for (int i = 0; i < subviews.count; i++) {
        UIView *square = subviews[i];
        [UIView animateWithDuration:0.6
                              delay:i * 0.1
                            options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                         animations:^{
            square.alpha = 0.3;
        } completion:nil];
    }
}

- (void)stopLoadingAnimation {
    NSArray *subviews = self.loadingView.subviews;
    for (UIView *square in subviews) {
        [square.layer removeAllAnimations];
        square.alpha = 1.0;
    }
}

@end

