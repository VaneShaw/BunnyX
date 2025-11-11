//
//  HomeTabCell.h
//  Bunnyx
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HomeTabCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (void)configureWithTitle:(NSString *)title selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END


