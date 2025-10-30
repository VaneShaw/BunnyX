//
//  MaterialCollectionViewCell.h
//  Bunnyx
//

#import <UIKit/UIKit.h>

@class MaterialItemModel;

@interface MaterialCollectionViewCell : UICollectionViewCell

- (void)configureWithModel:(MaterialItemModel *)model;

@end


