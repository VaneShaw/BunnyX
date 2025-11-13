//
//  UploadHistoryDialog.h
//  Bunnyx
//
//  上传历史记录选择弹窗（对齐安卓UploadHistoryDialog）
//

#import <UIKit/UIKit.h>
#import "UploadHistoryManager.h"

NS_ASSUME_NONNULL_BEGIN

@class UploadHistoryDialog;

/// 历史记录动作监听器（对齐安卓OnHistoryActionListener）
@protocol UploadHistoryDialogDelegate <NSObject>

@optional
/// 选择了新图片
/// @param imagePath 图片路径
- (void)uploadHistoryDialog:(UploadHistoryDialog *)dialog didSelectImage:(NSString *)imagePath;

/// 从历史记录生成
/// @param historyItem 历史记录项
- (void)uploadHistoryDialog:(UploadHistoryDialog *)dialog didGenerateFromHistory:(UploadHistoryItem *)historyItem;

/// 请求图片选择（需要打开相册）
- (void)uploadHistoryDialogDidRequestImageSelection:(UploadHistoryDialog *)dialog;

@end

/// 上传历史记录选择弹窗
@interface UploadHistoryDialog : UIView

/// 代理
@property (nonatomic, weak) id<UploadHistoryDialogDelegate> delegate;

/// 显示弹窗（对齐安卓Builder模式）
+ (void)showWithDelegate:(id<UploadHistoryDialogDelegate>)delegate;

/// 关闭弹窗
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

