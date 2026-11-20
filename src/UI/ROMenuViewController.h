//
//  ROMenuViewController.h
//  RobloxOptimizer
//
//  Landscape-friendly modal configuration popup with preset switching and input validation.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ROMenuViewController : UIViewController

@property (nonatomic, copy, nullable) void (^onDismiss)(void);

- (void)presentInParent:(UIViewController *)parent;
- (void)dismissMenu;

@end

NS_ASSUME_NONNULL_END
