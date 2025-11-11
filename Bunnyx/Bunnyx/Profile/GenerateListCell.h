//
//  GenerateListCell.h
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import <UIKit/UIKit.h>

@class CreateTaskModel;

@interface GenerateListCell : UITableViewCell

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *containerView;

- (void)configureWithModel:(CreateTaskModel *)model;

@end

