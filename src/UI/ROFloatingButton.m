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
    self.backgroundColor = [UIColor colorWithRed:0.12 green:0.16 blue:0.23 alpha:0.85]; // Slate dark
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
    self.layer.masksToBounds = NO;
    self.layer.borderColor = [UIColor colorWithRed:0.23 green:0.51 blue:0.96 alpha:0.90].CGColor; // Blue accent
    self.layer.borderWidth = 1.5;

    // Drop shadow
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.45;
    self.layer.shadowOffset = CGSizeMake(0, 3);
    self.layer.shadowRadius = 5.0;

    self.iconLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.iconLabel.text = @"⚡";
    self.iconLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.iconLabel.textAlignment = NSTextAlignmentCenter;
    self.iconLabel.textColor = [UIColor whiteColor];
    self.iconLabel.userInteractionEnabled = NO;
    [self addSubview:self.iconLabel];

    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:self.panGesture];

    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.tapGesture requireGestureRecognizerToFail:self.panGesture];
    [self addGestureRecognizer:self.tapGesture];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (self.isDragging) return;
    if (self.tapHandler) {
        self.tapHandler();
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *superview = self.superview;
    if (!superview) return;

    if (pan.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformMakeScale(1.10, 1.10);
        }];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:superview];
        self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:superview];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];

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
            self.isDragging = NO;
        }];
    }
}

@end
