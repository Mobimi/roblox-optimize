#import "ToggleCell.h"
#import <UIKit/UIKit.h>

@interface ToggleCell ()
@property (nonatomic, strong) UILabel   *titleLabel;
@property (nonatomic, strong) UILabel   *subtitleLabel;
@property (nonatomic, strong) UISwitch  *toggle;
@property (nonatomic, strong) UILabel   *restartBadge;
@end

@implementation ToggleCell

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         isOn:(BOOL)isOn
                 needsRestart:(BOOL)needsRestart {
    self = [super initWithFrame:CGRectMake(0, 0, 280, 56)];
    if (self) {
        self.backgroundColor    = [UIColor colorWithWhite:1 alpha:0.04];
        self.layer.cornerRadius = 10;

        // Title
        _titleLabel = [UILabel new];
        _titleLabel.text      = title;
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];

        // Subtitle
        _subtitleLabel = [UILabel new];
        _subtitleLabel.text      = subtitle;
        _subtitleLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
        _subtitleLabel.font      = [UIFont systemFontOfSize:11];

        // Restart badge
        _restartBadge = [UILabel new];
        _restartBadge.text            = @"RESTART";
        _restartBadge.textColor       = [UIColor colorWithRed:1.0 green:0.75 blue:0.0 alpha:1.0];
        _restartBadge.font            = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];
        _restartBadge.hidden          = !needsRestart;

        // Switch
        _toggle = [[UISwitch alloc] init];
        _toggle.on          = isOn;
        _toggle.onTintColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.5 alpha:1.0];
        _toggle.transform   = CGAffineTransformMakeScale(0.8, 0.8);
        [_toggle addTarget:self
                    action:@selector(switchToggled:)
          forControlEvents:UIControlEventValueChanged];

        [self addSubview:_titleLabel];
        [self addSubview:_subtitleLabel];
        [self addSubview:_restartBadge];
        [self addSubview:_toggle];
    }
    return self;
}

// ─── Layout ────────────────────────────────────────────────────────────────
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W   = self.bounds.size.width;
    CGFloat pad = 12;

    // Switch di bên phải
    CGFloat switchW = _toggle.bounds.size.width;
    CGFloat switchH = _toggle.bounds.size.height;
    _toggle.frame = CGRectMake(
        W - switchW - pad,
        (self.bounds.size.height - switchH) / 2.0,
        switchW, switchH
    );

    // Title + badge bên trái
    CGFloat contentW = CGRectGetMinX(_toggle.frame) - pad * 2;
    _titleLabel.frame   = CGRectMake(pad, 10, contentW * 0.65, 17);
    _restartBadge.frame = CGRectMake(
        CGRectGetMaxX(_titleLabel.frame) + 6, 12, 52, 13);
    _subtitleLabel.frame = CGRectMake(pad, 30, contentW, 15);
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, 56);
}

// ─── Actions ───────────────────────────────────────────────────────────────
- (void)switchToggled:(UISwitch *)sw {
    // Haptic feedback nhẹ
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleLight];
    [haptic impactOccurred];

    if (self.onToggle) {
        self.onToggle(sw.isOn);
    }

    NSLog(@"[GameOptimizer] Toggle '%@': %@",
          _titleLabel.text, sw.isOn ? @"ON" : @"OFF");
}

// ─── Public API ────────────────────────────────────────────────────────────
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    [_toggle setOn:on animated:animated];
}

- (BOOL)isOn {
    return _toggle.isOn;
}

@end