//
//  ROFloatingButton.m
//  RobloxOptimizer
//
//  Draggable floating action button with magnetic edge snapping and tap disambiguation.
//

#import "ROFloatingButton.h"

@interface ROFloatingButton ()
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, strong) UIImpactFeedbackGenerator *impactLight;
@property (nonatomic, strong) UIImpactFeedbackGenerator *impactMedium;
@end

@implementation ROFloatingButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
    self.layer.masksToBounds = NO;
    self.layer.borderColor = [UIColor colorWithRed:0.35 green:0.62 blue:0.98 alpha:0.90].CGColor; // Cyan-blue specular border
    self.layer.borderWidth = 1.5;

    // Apple Liquid Glass ambient luminescence glow shadow
    self.layer.shadowColor = [UIColor colorWithRed:0.20 green:0.55 blue:1.0 alpha:0.50].CGColor;
    self.layer.shadowOpacity = 0.60;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 10.0;

    // Modern Frosted Glass Blur Background
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurView.layer.cornerRadius = self.bounds.size.width / 2.0;
    blurView.layer.masksToBounds = YES;
    blurView.userInteractionEnabled = NO;
    [self addSubview:blurView];

    // Translucent dark tint overlay inside blur view (Liquid Glass)
    UIView *tintView = [[UIView alloc] initWithFrame:self.bounds];
    tintView.backgroundColor = [UIColor colorWithRed:0.10 green:0.14 blue:0.22 alpha:0.48];
    tintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tintView.layer.cornerRadius = self.bounds.size.width / 2.0;
    tintView.layer.masksToBounds = YES;
    tintView.userInteractionEnabled = NO;
    [blurView.contentView addSubview:tintView];

    self.iconLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.iconLabel.text = @"⚡";
    self.iconLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.iconLabel.textAlignment = NSTextAlignmentCenter;
    self.iconLabel.textColor = [UIColor whiteColor];
    self.iconLabel.userInteractionEnabled = NO;
    [self addSubview:self.iconLabel];

    // Initialize cached haptic feedback generators
    if (@available(iOS 10.0, *)) {
        if ([UIImpactFeedbackGenerator class]) {
            self.impactLight = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            self.impactMedium = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        }
    }

    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:self.panGesture];

    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.tapGesture requireGestureRecognizerToFail:self.panGesture];
    [self addGestureRecognizer:self.tapGesture];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    (void)gesture;
    if (self.isDragging) return;
    if (@available(iOS 10.0, *)) {
        if (self.impactMedium) {
            [self.impactMedium impactOccurred];
        } else if ([UIImpactFeedbackGenerator class]) {
            UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [feedback prepare];
            [feedback impactOccurred];
        }
    }
    if (self.tapHandler) {
        self.tapHandler();
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *superview = self.superview;
    if (!superview) return;

    if (pan.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        if (@available(iOS 10.0, *)) {
            if (self.impactLight) {
                [self.impactLight impactOccurred];
            } else if ([UIImpactFeedbackGenerator class]) {
                UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
                [feedback prepare];
                [feedback impactOccurred];
            }
        }
        [UIView animateWithDuration:0.25
                              delay:0
             usingSpringWithDamping:0.75
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.transform = CGAffineTransformMakeScale(1.10, 1.10);
        } completion:nil];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:superview];
        self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:superview];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.25
                              delay:0
             usingSpringWithDamping:0.75
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];

        UIEdgeInsets insets = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) {
            insets = superview.safeAreaInsets;
        }

        CGFloat radius = self.bounds.size.width / 2.0;
        CGFloat minX = insets.left + radius + 10.0;
        CGFloat maxX = superview.bounds.size.width - insets.right - radius - 10.0;
        CGFloat minY = insets.top + radius + 10.0;
        CGFloat maxY = superview.bounds.size.height - insets.bottom - radius - 10.0;

        CGFloat targetX = (self.center.x < superview.bounds.size.width / 2.0) ? minX : maxX;
        CGFloat targetY = MIN(MAX(self.center.y, minY), maxY);

        [UIView animateWithDuration:0.35
                              delay:0
             usingSpringWithDamping:0.75
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.center = CGPointMake(targetX, targetY);
        } completion:^(BOOL finished) {
            (void)finished;
            self.isDragging = NO;
            if (@available(iOS 10.0, *)) {
                if (self.impactLight) {
                    [self.impactLight impactOccurred];
                } else if ([UIImpactFeedbackGenerator class]) {
                    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
                    [feedback impactOccurred];
                }
            }
        }];
    }
}

@end
