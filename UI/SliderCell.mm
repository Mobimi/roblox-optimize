#import "SliderCell.h"
#import <UIKit/UIKit.h>

@interface SliderCell ()
@property (nonatomic, strong) UILabel   *titleLabel;
@property (nonatomic, strong) UILabel   *valueLabel;
@property (nonatomic, strong) UISlider  *slider;
@property (nonatomic, strong) UILabel   *restartBadge;
@property (nonatomic, strong) UILabel   *minLabel;
@property (nonatomic, strong) UILabel   *maxLabel;
@property (nonatomic, copy)   NSString  *unit;
@property (nonatomic, assign) float      snapStep;
@end

@implementation SliderCell

- (instancetype)initWithTitle:(NSString *)title
                     minValue:(float)min
                     maxValue:(float)max
                 defaultValue:(float)defaultVal
                         unit:(NSString *)unit
                 needsRestart:(BOOL)needsRestart {
    self = [super initWithFrame:CGRectMake(0, 0, 280, 72)];
    if (self) {
        _unit     = unit;
        _snapStep = 0.25f; // snap mỗi 0.25

        self.backgroundColor    = [UIColor colorWithWhite:1 alpha:0.04];
        self.layer.cornerRadius = 10;

        // Title
        _titleLabel = [UILabel new];
        _titleLabel.text      = title;
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];

        // Value label
        _valueLabel = [UILabel new];
        _valueLabel.textColor     = [UIColor colorWithRed:0.3 green:0.85 blue:0.5 alpha:1.0];
        _valueLabel.font          = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        _valueLabel.textAlignment = NSTextAlignmentRight;

        // Restart badge
        _restartBadge = [UILabel new];
        _restartBadge.text            = @"RESTART";
        _restartBadge.textColor       = [UIColor colorWithRed:1.0 green:0.75 blue:0.0 alpha:1.0];
        _restartBadge.font            = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];
        _restartBadge.hidden          = !needsRestart;

        // Min label
        _minLabel = [UILabel new];
        _minLabel.text      = [NSString stringWithFormat:@"%.0f%@", min, unit];
        _minLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        _minLabel.font      = [UIFont systemFontOfSize:10];

        // Max label
        _maxLabel = [UILabel new];
        _maxLabel.text      = [NSString stringWithFormat:@"%.0f%@", max, unit];
        _maxLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        _maxLabel.font      = [UIFont systemFontOfSize:10];
        _maxLabel.textAlignment = NSTextAlignmentRight;

        // Slider
        _slider = [[UISlider alloc] init];
        _slider.minimumValue          = min;
        _slider.maximumValue          = max;
        _slider.value                 = defaultVal;
        _slider.minimumTrackTintColor = [UIColor colorWithRed:0.3
                                            green:0.85 blue:0.5 alpha:1.0];
        _slider.maximumTrackTintColor = [UIColor colorWithWhite:0.3 alpha:1.0];

        [_slider addTarget:self
                    action:@selector(sliderChanged:)
          forControlEvents:UIControlEventValueChanged];

        [_slider addTarget:self
                    action:@selector(sliderTouchUp:)
          forControlEvents:UIControlEventTouchUpInside |
                           UIControlEventTouchUpOutside];

        [self addSubview:_titleLabel];
        [self addSubview:_valueLabel];
        [self addSubview:_restartBadge];
        [self addSubview:_minLabel];
        [self addSubview:_maxLabel];
        [self addSubview:_slider];

        // Init value label
        [self updateValueLabel:defaultVal];
    }
    return self;
}

// ─── Layout ────────────────────────────────────────────────────────────────
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W   = self.bounds.size.width;
    CGFloat pad = 12;

    // Row 1: title + restart badge + value
    _titleLabel.frame    = CGRectMake(pad, 10, W * 0.45, 18);
    _restartBadge.frame  = CGRectMake(CGRectGetMaxX(_titleLabel.frame) + 6, 12, 52, 14);
    _valueLabel.frame    = CGRectMake(W - 80 - pad, 10, 80, 18);

    // Row 2: slider
    _slider.frame        = CGRectMake(pad, 32, W - pad*2, 22);

    // Row 3: min/max labels
    _minLabel.frame      = CGRectMake(pad, 56, 40, 14);
    _maxLabel.frame      = CGRectMake(W - 40 - pad, 56, 40, 14);
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, 76);
}

// ─── Slider actions ────────────────────────────────────────────────────────
- (void)sliderChanged:(UISlider *)s {
    // Snap về bước gần nhất
    float snapped = roundf(s.value / _snapStep) * _snapStep;
    s.value = snapped;
    [self updateValueLabel:snapped];
}

- (void)sliderTouchUp:(UISlider *)s {
    float snapped = roundf(s.value / _snapStep) * _snapStep;
    s.value = snapped;
    [self updateValueLabel:snapped];

    if (self.onChanged) {
        self.onChanged(snapped);
    }
}

- (void)updateValueLabel:(float)val {
    _valueLabel.text = [NSString stringWithFormat:@"%.2f%@", val, _unit];

    // Đổi màu theo giá trị
    // 1.0-1.5: đỏ (thấp), 1.75-2.25: vàng (trung), 2.5-3.0: xanh (cao)
    if (val <= 1.5f) {
        _valueLabel.textColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
    } else if (val <= 2.25f) {
        _valueLabel.textColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0];
    } else {
        _valueLabel.textColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.5 alpha:1.0];
    }
}

@end