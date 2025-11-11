//
//  SubscribeVipCell.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <UIKit/UIKit.h>
#import "VipItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@class SubscribeVipCell;

@protocol SubscribeVipCellDelegate <NSObject>

- (void)subscribeVipCell:(SubscribeVipCell *)cell didSelectItem:(VipItemModel *)item;

@end

@interface SubscribeVipCell : UICollectionViewCell

@property (nonatomic, weak) id<SubscribeVipCellDelegate> delegate;
@property (nonatomic, strong) VipItemModel *vipItem;
@property (nonatomic, assign) BOOL isSelected;

- (void)configureWithVipItem:(VipItemModel *)item selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END

