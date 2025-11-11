//
//  ProfileViewController.h
//  Bunnyx
//
//  Created by 冯文骁 on 2025/10/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileViewController : UIViewController

/// 刷新用户信息（每次进入页面时调用）
- (void)refreshUserInfo;

@end

NS_ASSUME_NONNULL_END
