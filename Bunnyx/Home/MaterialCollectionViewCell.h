//
//  MaterialCollectionViewCell.h
//  Bunnyx
//

#import <UIKit/UIKit.h>

@class MaterialItemModel;
@class MaterialCollectionViewCell;
@protocol MaterialCollectionViewCellDelegate <NSObject>

- (void)materialCollectionViewCell:(MaterialCollectionViewCell *)cell didTapLikeWithModel:(MaterialItemModel *)model;

@end

@interface MaterialCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<MaterialCollectionViewCellDelegate> delegate;
@property (nonatomic, assign) BOOL showLikeButton; // 是否显示点赞按钮，默认为YES

- (void)configureWithModel:(MaterialItemModel *)model;

@end


