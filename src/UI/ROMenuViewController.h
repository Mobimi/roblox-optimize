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
@property (nonatomic, strong) UIView *dialogCard;
@property (nonatomic, strong) UITextField *scaleTextField;
@property (nonatomic, strong) UISlider *scaleSlider;
@property (nonatomic, strong) UISegmentedControl *presetControl;
@property (nonatomic, strong) UISegmentedControl *fpsControl;
@property (nonatomic, strong) UISwitch *textureClampingSwitch;
@property (nonatomic, strong) UISwitch *shadowsSwitch;
@property (nonatomic, strong) UISwitch *postFxSwitch;
@property (nonatomic, assign, readonly) BOOL isDismissing;

- (void)presentInParent:(UIViewController *)parent;
- (void)dismissMenu;

@end

NS_ASSUME_NONNULL_END
