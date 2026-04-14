//
//  UILabel+BXLocalization.h
//  Bunnyx
//
//  自动根据语言刷新 UILabel 文案
//

#import <UIKit/UIKit.h>

@interface UILabel (BXLocalization)

@property (nonatomic, copy) NSString *bx_localizedKey; // 设置后会自动根据当前语言设置 text 并在语言切换时刷新

@end


