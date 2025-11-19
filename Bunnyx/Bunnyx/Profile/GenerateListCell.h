//
//  GenerateListCell.h
//  Bunnyx
//
//  Created by Assistant on 2025/11/30.
//

#import <UIKit/UIKit.h>

@class CreateTaskModel;

@interface GenerateListCell : UITableViewCell

@property (nonatomic, strong) UIView *outerContainerView; // 外层容器（对应CardView）
@property (nonatomic, strong) UIView *innerContainerView; // 内层容器（对应LinearLayout）
@property (nonatomic, strong) UIView *titleTimeContainerView; // 标题和时间容器
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UILabel *timeLabel; // 时间
@property (nonatomic, strong) UIView *imageCardView; // 图片卡片容器
@property (nonatomic, strong) UIImageView *coverImageView; // 封面图
@property (nonatomic, strong) UIImageView *vipImageView; // VIP图标
@property (nonatomic, strong) UIView *statusRowView; // 状态标签行容器
@property (nonatomic, strong) UILabel *statusLabel; // 状态标签（带渐变背景）
@property (nonatomic, strong) UILabel *queueInfoLabel; // 队列信息标签
@property (nonatomic, strong) CAGradientLayer *statusGradientLayer; // 状态标签渐变背景layer
@property (nonatomic, strong) UIView *progressDotsContainer; // 进度点容器（对齐安卓：根据position显示不同数量的点）
@property (nonatomic, strong) NSMutableArray<UIView *> *progressDotViews; // 进度点视图数组

- (void)configureWithModel:(CreateTaskModel *)model;

@end

