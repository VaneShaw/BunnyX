//
//  SubscribeDialog.h
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import <UIKit/UIKit.h>
#import "ApplePayManager.h"

NS_ASSUME_NONNULL_BEGIN

@class SubscribeDialog;

typedef void(^OnSubscribeListener)(void);

@interface SubscribeDialog : UIView

+ (void)showWithPayMoney:(NSString *)payMoney
           originalPrice:(NSString * _Nullable)originalPrice
              typeRemark:(NSString *)typeRemark
                firstBuy:(BOOL)firstBuy
              rechargeId:(NSInteger)rechargeId
         applePayManager:(ApplePayManager *)applePayManager
             onSubscribe:(OnSubscribeListener)onSubscribe;

@end

NS_ASSUME_NONNULL_END

