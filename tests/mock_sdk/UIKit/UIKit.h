#ifndef MOCK_UIKIT_H
#define MOCK_UIKIT_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/CAMetalLayer.h>

NS_ASSUME_NONNULL_BEGIN

@class UIWindow, UIViewController, UIEvent, UIScene, UIWindowScene, UILabel;

typedef struct UIEdgeInsets {
    CGFloat top, left, bottom, right;
} UIEdgeInsets;

static const UIEdgeInsets UIEdgeInsetsZero = {0, 0, 0, 0};

typedef double UIWindowLevel;
static const UIWindowLevel UIWindowLevelNormal = 0.0;
static const UIWindowLevel UIWindowLevelAlert = 2000.0;

typedef NS_ENUM(NSInteger, UIInterfaceOrientationMask) {
    UIInterfaceOrientationMaskPortrait = (1 << 1),
    UIInterfaceOrientationMaskLandscapeLeft = (1 << 4),
    UIInterfaceOrientationMaskLandscapeRight = (1 << 3),
    UIInterfaceOrientationMaskAll = 30
};

typedef NS_ENUM(NSInteger, UISceneActivationState) {
    UISceneActivationStateUnattached = -1,
    UISceneActivationStateForegroundActive = 0,
    UISceneActivationStateForegroundInactive = 1,
    UISceneActivationStateBackground = 2
};

typedef NS_ENUM(NSInteger, UIGestureRecognizerState) {
    UIGestureRecognizerStatePossible,
    UIGestureRecognizerStateBegan,
    UIGestureRecognizerStateChanged,
    UIGestureRecognizerStateEnded,
    UIGestureRecognizerStateCancelled,
    UIGestureRecognizerStateFailed,
    UIGestureRecognizerStateRecognized = UIGestureRecognizerStateEnded
};

typedef NS_ENUM(NSInteger, UIControlState) {
    UIControlStateNormal       = 0,
    UIControlStateHighlighted  = 1 << 0,
    UIControlStateDisabled     = 1 << 1,
    UIControlStateSelected     = 1 << 2
};

typedef NS_ENUM(NSInteger, UIControlEvents) {
    UIControlEventTouchDown           = 1 <<  0,
    UIControlEventTouchUpInside       = 1 <<  6,
    UIControlEventValueChanged        = 1 << 12
};

typedef NS_ENUM(NSInteger, UIButtonType) {
    UIButtonTypeCustom = 0,
    UIButtonTypeSystem = 1
};

typedef NS_ENUM(NSInteger, NSTextAlignment) {
    NSTextAlignmentLeft      = 0,
    NSTextAlignmentCenter    = 1,
    NSTextAlignmentRight     = 2
};

typedef NS_ENUM(NSInteger, UIFontWeight) {
    UIFontWeightRegular,
    UIFontWeightMedium,
    UIFontWeightSemibold,
    UIFontWeightBold
};

typedef NS_ENUM(NSInteger, UITextBorderStyle) {
    UITextBorderStyleNone,
    UITextBorderStyleLine,
    UITextBorderStyleBezel,
    UITextBorderStyleRoundedRect
};

typedef NS_ENUM(NSInteger, UIKeyboardType) {
    UIKeyboardTypeDefault,
    UIKeyboardTypeDecimalPad
};

typedef NS_ENUM(NSInteger, UIBarStyle) {
    UIBarStyleDefault = 0,
    UIBarStyleBlack = 1
};

typedef NS_ENUM(NSInteger, UIBarButtonSystemItem) {
    UIBarButtonSystemItemDone,
    UIBarButtonSystemItemCancel,
    UIBarButtonSystemItemFlexibleSpace
};

typedef NS_ENUM(NSInteger, UIAlertControllerStyle) {
    UIAlertControllerStyleActionSheet = 0,
    UIAlertControllerStyleAlert = 1
};

typedef NS_ENUM(NSInteger, UIAlertActionStyle) {
    UIAlertActionStyleDefault = 0,
    UIAlertActionStyleCancel = 1,
    UIAlertActionStyleDestructive = 2
};

typedef NS_ENUM(NSUInteger, UIViewAutoresizing) {
    UIViewAutoresizingNone                 = 0,
    UIViewAutoresizingFlexibleWidth        = 1 << 1,
    UIViewAutoresizingFlexibleHeight       = 1 << 4
};

typedef NS_ENUM(NSInteger, UIViewAnimationOptions) {
    UIViewAnimationOptionCurveEaseOut = 2 << 16
};

static NSString * const NSForegroundColorAttributeName = @"NSForegroundColorAttributeName";
static NSString * const NSFontAttributeName = @"NSFontAttributeName";
static NSString * const UIApplicationDidFinishLaunchingNotification = @"UIApplicationDidFinishLaunchingNotification";

@interface UIColor : NSObject
+ (UIColor *)clearColor;
+ (UIColor *)whiteColor;
+ (UIColor *)blackColor;
+ (UIColor *)colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;
+ (UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
@property (readonly) CGColorRef CGColor;
@end

@interface UIFont : NSObject
+ (UIFont *)systemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)systemFontOfSize:(CGFloat)fontSize weight:(CGFloat)weight;
+ (UIFont *)monospacedDigitSystemFontOfSize:(CGFloat)fontSize weight:(CGFloat)weight;
@end

@interface NSLayoutAnchor<AnchorType> : NSObject
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor;
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)c;
- (id)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)c;
- (id)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)c;
@end

@interface NSLayoutDimension : NSLayoutAnchor
- (id)constraintEqualToConstant:(CGFloat)c;
- (id)constraintGreaterThanOrEqualToConstant:(CGFloat)c;
- (id)constraintLessThanOrEqualToConstant:(CGFloat)c;
@end

@interface NSLayoutConstraint : NSObject
+ (void)activateConstraints:(NSArray<NSLayoutConstraint *> *)constraints;
@end

@interface UIGestureRecognizer : NSObject
- (instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action;
@property (nonatomic, readonly) UIGestureRecognizerState state;
- (void)requireGestureRecognizerToFail:(UIGestureRecognizer *)otherGestureRecognizer;
@end

@interface UIPanGestureRecognizer : UIGestureRecognizer
- (CGPoint)translationInView:(nullable id)view;
- (void)setTranslation:(CGPoint)translation inView:(nullable id)view;
@end

@interface UITapGestureRecognizer : UIGestureRecognizer
@end

@interface UIView : NSObject
- (instancetype)initWithFrame:(CGRect)frame;
@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGFloat alpha;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property (nonatomic, copy, nullable) UIColor *backgroundColor;
@property (nonatomic, readonly, strong) CALayer *layer;
@property (nonatomic, readonly, nullable) UIView *superview;
@property (nonatomic, readonly, copy) NSArray<__kindof UIView *> *subviews;
@property (nonatomic) UIViewAutoresizing autoresizingMask;
@property (nonatomic) BOOL translatesAutoresizingMaskIntoConstraints;
@property (nonatomic, readonly) UIEdgeInsets safeAreaInsets;
@property (nonatomic) CGFloat contentScaleFactor;

@property (nonatomic, readonly, strong) NSLayoutAnchor *leadingAnchor;
@property (nonatomic, readonly, strong) NSLayoutAnchor *trailingAnchor;
@property (nonatomic, readonly, strong) NSLayoutAnchor *topAnchor;
@property (nonatomic, readonly, strong) NSLayoutAnchor *bottomAnchor;
@property (nonatomic, readonly, strong) NSLayoutDimension *widthAnchor;
@property (nonatomic, readonly, strong) NSLayoutDimension *heightAnchor;
@property (nonatomic, readonly, strong) NSLayoutAnchor *centerXAnchor;
@property (nonatomic, readonly, strong) NSLayoutAnchor *centerYAnchor;

- (void)addSubview:(UIView *)view;
- (void)removeFromSuperview;
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;
- (BOOL)isDescendantOfView:(UIView *)view;

+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations;
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithDuration:(double)duration delay:(double)delay usingSpringWithDamping:(CGFloat)dampingRatio initialSpringVelocity:(CGFloat)velocity options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion;
@end

@interface UIScreen : NSObject
+ (UIScreen *)mainScreen;
@property (readonly) CGRect bounds;
@property (readonly) CGFloat scale;
@end

@interface UIScene : NSObject
@property (nonatomic, readonly) UISceneActivationState activationState;
@end

@interface UIWindowScene : UIScene
@end

@protocol UIViewControllerTransitionCoordinatorContext <NSObject>
@end

@protocol UIViewControllerTransitionCoordinator <NSObject>
- (BOOL)animateAlongsideTransition:(void (^ _Nullable)(id <UIViewControllerTransitionCoordinatorContext> context))animation
                        completion:(void (^ _Nullable)(id <UIViewControllerTransitionCoordinatorContext> context))completion;
@end

@interface UIViewController : NSObject
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil;
@property (null_resettable, nonatomic, strong) UIView *view;
- (void)viewDidLoad;
- (void)viewDidLayoutSubviews;
@property (nonatomic, readonly) BOOL shouldAutorotate;
@property (nonatomic, readonly) UIInterfaceOrientationMask supportedInterfaceOrientations;
@property (nonatomic, readonly) BOOL prefersStatusBarHidden;
@property (nonatomic, readonly, nullable) UIViewController *presentedViewController;
@property (nonatomic, readonly, nullable) UIViewController *presentingViewController;

- (void)addChildViewController:(UIViewController *)childController;
- (void)removeFromParentViewController;
- (void)didMoveToParentViewController:(nullable UIViewController *)parent;
- (void)willMoveToParentViewController:(nullable UIViewController *)parent;
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(nullable void (^)(void))completion;
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;
@end

@interface UIWindow : UIView
- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene;
@property (nonatomic) UIWindowLevel windowLevel;
@property (nonatomic, strong, nullable) UIViewController *rootViewController;
@end

@interface UIControl : UIView
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, getter=isSelected) BOOL selected;
- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
@end

@interface UIButton : UIControl
+ (instancetype)buttonWithType:(UIButtonType)buttonType;
@property (nonatomic, readonly, strong, nullable) UILabel *titleLabel;
- (void)setTitle:(nullable NSString *)title forState:(UIControlState)state;
- (void)setTitleColor:(nullable UIColor *)color forState:(UIControlState)state;
@end

@interface UILabel : UIView
@property (nonatomic, copy, nullable) NSString *text;
@property (null_resettable, nonatomic, strong) UIFont *font;
@property (null_resettable, nonatomic, strong) UIColor *textColor;
@property (nonatomic) NSTextAlignment textAlignment;
@end

@interface UISwitch : UIControl
@property (nonatomic, getter=isOn) BOOL on;
@property (nonatomic, strong, nullable) UIColor *onTintColor;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@interface UISegmentedControl : UIControl
- (instancetype)initWithItems:(nullable NSArray *)items;
@property (nonatomic) NSInteger selectedSegmentIndex;
@property (nonatomic, strong, nullable) UIColor *selectedSegmentTintColor;
- (void)setTitleTextAttributes:(nullable NSDictionary *)attributes forState:(UIControlState)state;
@end

@protocol UITextFieldDelegate <NSObject>
@end

@interface UITextField : UIControl
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, nullable) UIColor *textColor;
@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic) UITextBorderStyle borderStyle;
@property (nonatomic) UIKeyboardType keyboardType;
@property (nonatomic, weak, nullable) id<UITextFieldDelegate> delegate;
@property (nonatomic, strong, nullable) UIView *inputAccessoryView;
- (BOOL)resignFirstResponder;
@end

@interface UIScrollView : UIView
@end

@interface UIBarButtonItem : NSObject
- (instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(nullable id)target action:(nullable SEL)action;
@end

@interface UIToolbar : UIView
@property (nonatomic) UIBarStyle barStyle;
@property (nonatomic, copy, nullable) NSArray<UIBarButtonItem *> *items;
@end

@interface UIAlertAction : NSObject
+ (instancetype)actionWithTitle:(nullable NSString *)title style:(UIAlertActionStyle)style handler:(nullable void (^)(UIAlertAction *action))handler;
@end

@interface UIAlertController : UIViewController
+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle;
- (void)addAction:(UIAlertAction *)action;
@end

@interface UIApplication : NSObject
+ (UIApplication *)sharedApplication;
@property (nonatomic, readonly, nullable) UIWindow *keyWindow;
@property (nonatomic, readonly) NSArray<__kindof UIWindow *> *windows;
@property (nonatomic, readonly) id connectedScenes;
@end

NS_ASSUME_NONNULL_END

#endif
