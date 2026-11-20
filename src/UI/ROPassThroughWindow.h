//
//  ROPassThroughWindow.h
//  RobloxOptimizer
//
//  Transparent overlay UIWindow allowing touches outside UI subviews to pass to Roblox.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ROPassThroughWindow : UIWindow

+ (instancetype)sharedWindow;
+ (void)initializeOverlay;

@end

#ifdef __cplusplus
extern "C" {
#endif

void ROInitializeUI(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
