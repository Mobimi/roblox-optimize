#import "MainPanel.h"
#import "SliderCell.h"
#import "ToggleCell.h"
#import "Settings.h"
#import "FPSCap.h"
#import "RenderScale.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface MainPanel ()
@property (nonatomic, strong) UIScrollView  *scrollView;
@property (nonatomic, strong) UIStackView   *stackView;
@property (nonatomic, strong) UILabel       *titleLabel;
@property (nonatomic, strong) UIButton      *restartBtn;
@property (nonatomic, strong) SliderCell    *scaleSlider;
@property (nonatomic, strong) ToggleCell    *msaaToggle;
@property (nonatomic, strong) ToggleCell    *fxaaToggle;
@property (nonatomic, strong) ToggleCell    *shadowToggle;
@property (nonatomic, strong) ToggleCell    *framebufferToggle;
@property (nonatomic, strong) ToggleCell    *metalFXToggle;
@property (nonatomic, strong) UISegmentedControl *fpsSegment;
@property (nonatomic, strong) UISegmentedControl *metalFXSegment;
@property (nonatomic, assign) BOOL needsRestart;
@end

@implementation MainPanel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupAppearance];
        [self setupSubviews];
        [self loadCurrentSettings];
    }
    return self;
}

// ─── Appearance ────────────────────────────────────────────────────────────
- (void)setupAppearance {
    self.backgroundColor    = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:0.94];
    self.layer.cornerRadius = 18;
    self.layer.borderWidth  = 1.0;
    self.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.12].CGColor;

    // Shadow
    self.layer.shadowColor   = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowRadius  = 12;
    self.layer.shadowOffset  = CGSizeMake(0, 4);
    self.clipsToBounds = NO;
}

// ─── Subviews ──────────────────────────────────────────────────────────────
- (void)setupSubviews {
    // Title
    _titleLabel = [UILabel new];
    _titleLabel.text          = @"⚡ Game Optimizer";
    _titleLabel.textColor     = UIColor.whiteColor;
    _titleLabel.font          = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    _titleLabel.textAlignment = NSTextAlignmentCenter;

    // Divider
    UIView *divider = [UIView new];
    divider.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];

    // ScrollView
    _scrollView = [UIScrollView new];
    _scrollView.showsVerticalScrollIndicator   = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.alwaysBounceVertical           = YES;

    // StackView bên trong scroll
    _stackView = [[UIStackView alloc] init];
    _stackView.axis         = UILayoutConstraintAxisVertical;
    _stackView.spacing      = 10;
    _stackView.alignment    = UIStackViewAlignmentFill;
    _stackView.distribution = UIStackViewDistributionEqualSpacing;

    // ── Render Scale ──
    _scaleSlider = [[SliderCell alloc]
        initWithTitle:@"Render Scale"
        minValue:1.0f maxValue:3.0f
        defaultValue:[Settings renderScale]
        unit:@"×"
        needsRestart:YES];
    __weak typeof(self) ws = self;
    _scaleSlider.onChanged = ^(float val) {
        [Settings setRenderScale:val];
        [Settings save];
        [ws markNeedsRestart];
    };

    // ── MSAA ──
    _msaaToggle = [[ToggleCell alloc]
        initWithTitle:@"MSAA"
        subtitle:@"Multi-sample anti-aliasing"
        isOn:[Settings msaaEnabled]
        needsRestart:YES];
    _msaaToggle.onToggle = ^(BOOL on) {
        [Settings setMsaaEnabled:on];
        [Settings save];
        [ws markNeedsRestart];
    };

    // ── FXAA ──
    _fxaaToggle = [[ToggleCell alloc]
        initWithTitle:@"FXAA"
        subtitle:@"Fast approximate anti-aliasing"
        isOn:[Settings fxaaEnabled]
        needsRestart:YES];
    _fxaaToggle.onToggle = ^(BOOL on) {
        [Settings setFxaaEnabled:on];
        [Settings save];
        [ws markNeedsRestart];
    };

    // ── FPS Cap ──
    UILabel *fpsLabel = [self sectionLabelWithText:@"FPS Cap"];
    _fpsSegment = [[UISegmentedControl alloc]
        initWithItems:@[@"30", @"60", @"120"]];
    _fpsSegment.selectedSegmentIndex = [self indexForFPS:[Settings fpsCap]];
    [_fpsSegment setTitleTextAttributes:
        @{NSForegroundColorAttributeName: UIColor.whiteColor}
        forState:UIControlStateNormal];
    [_fpsSegment setTitleTextAttributes:
        @{NSForegroundColorAttributeName: UIColor.blackColor}
        forState:UIControlStateSelected];
    _fpsSegment.selectedSegmentTintColor = [UIColor colorWithRed:0.3
        green:0.8 blue:0.4 alpha:1.0];
    [_fpsSegment addTarget:self
                    action:@selector(fpsChanged:)
          forControlEvents:UIControlEventValueChanged];

    // ── Shadow ──
    _shadowToggle = [[ToggleCell alloc]
        initWithTitle:@"Shadows"
        subtitle:@"Disable shadow render pass"
        isOn:[Settings shadowEnabled]
        needsRestart:YES];
    _shadowToggle.onToggle = ^(BOOL on) {
        [Settings setShadowEnabled:on];
        [Settings save];
        [ws markNeedsRestart];
    };

    // ── Framebuffer ──
    _framebufferToggle = [[ToggleCell alloc]
        initWithTitle:@"Framebuffer Opt"
        subtitle:@"RGBA16F → RGBA8 (-50% bandwidth)"
        isOn:[Settings framebufferOptEnabled]
        needsRestart:YES];
    _framebufferToggle.onToggle = ^(BOOL on) {
        [Settings setFramebufferOptEnabled:on];
        [Settings save];
        [ws markNeedsRestart];
    };

    // ── MetalFX ──
    _metalFXToggle = [[ToggleCell alloc]
        initWithTitle:@"MetalFX Upscaling"
        subtitle:@"A14 spatial upscaler"
        isOn:[Settings metalFXEnabled]
        needsRestart:YES];
    _metalFXToggle.onToggle = ^(BOOL on) {
        [Settings setMetalFXEnabled:on];
        [Settings save];
        [ws markNeedsRestart];
    };

    // MetalFX Quality segment
    UILabel *mfxLabel = [self sectionLabelWithText:@"MetalFX Quality"];
    _metalFXSegment = [[UISegmentedControl alloc]
        initWithItems:@[@"Performance", @"Balanced", @"Quality"]];
    _metalFXSegment.selectedSegmentIndex = (NSInteger)[Settings metalFXQuality];
    [_metalFXSegment setTitleTextAttributes:
        @{NSForegroundColorAttributeName: UIColor.whiteColor}
        forState:UIControlStateNormal];
    [_metalFXSegment setTitleTextAttributes:
        @{NSForegroundColorAttributeName: UIColor.blackColor}
        forState:UIControlStateSelected];
    _metalFXSegment.selectedSegmentTintColor = [UIColor colorWithRed:0.2
        green:0.5 blue:1.0 alpha:1.0];
    [_metalFXSegment addTarget:self
                        action:@selector(metalFXQualityChanged:)
              forControlEvents:UIControlEventValueChanged];

    // ── Restart button ──
    _restartBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_restartBtn setTitle:@"↺  Restart to Apply" forState:UIControlStateNormal];
    [_restartBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    _restartBtn.titleLabel.font     = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    _restartBtn.backgroundColor     = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    _restartBtn.layer.cornerRadius  = 10;
    _restartBtn.hidden              = YES;
    [_restartBtn addTarget:self
                    action:@selector(restartApp)
          forControlEvents:UIControlEventTouchUpInside];

    // ── Add vào stack ──
    [_stackView addArrangedSubview:_scaleSlider];
    [_stackView addArrangedSubview:[self separatorView]];
    [_stackView addArrangedSubview:_msaaToggle];
    [_stackView addArrangedSubview:_fxaaToggle];
    [_stackView addArrangedSubview:[self separatorView]];
    [_stackView addArrangedSubview:fpsLabel];
    [_stackView addArrangedSubview:_fpsSegment];
    [_stackView addArrangedSubview:[self separatorView]];
    [_stackView addArrangedSubview:_shadowToggle];
    [_stackView addArrangedSubview:_framebufferToggle];
    [_stackView addArrangedSubview:_metalFXToggle];
    [_stackView addArrangedSubview:[self separatorView]];
    [_stackView addArrangedSubview:mfxLabel];
    [_stackView addArrangedSubview:_metalFXSegment];
    [_stackView addArrangedSubview:_restartBtn];

    [_scrollView addSubview:_stackView];

    [self addSubview:_titleLabel];
    [self addSubview:divider];
    [self addSubview:_scrollView];

    // Store divider ref
    objc_setAssociatedObject(self, "divider", divider,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// ─── Layout ────────────────────────────────────────────────────────────────
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    CGFloat pad = 14;

    _titleLabel.frame = CGRectMake(pad, 12, W - pad*2, 22);

    UIView *divider = objc_getAssociatedObject(self, "divider");
    divider.frame = CGRectMake(pad, 40, W - pad*2, 0.5);

    _scrollView.frame = CGRectMake(0, 46, W, H - 46);

    CGFloat stackW = W - pad*2;
    [_stackView sizeToFit];
    CGFloat stackH = [_stackView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    _stackView.frame = CGRectMake(pad, 10, stackW, MAX(stackH, H - 66));

    _scrollView.contentSize = CGSizeMake(W, stackH + 30);

    // FPS segment height
    _fpsSegment.frame = CGRectMake(0, 0, stackW, 34);
    _metalFXSegment.frame = CGRectMake(0, 0, stackW, 34);
    _restartBtn.frame = CGRectMake(0, 0, stackW, 40);
}

// ─── Helpers ───────────────────────────────────────────────────────────────
- (UILabel *)sectionLabelWithText:(NSString *)text {
    UILabel *l = [UILabel new];
    l.text      = text;
    l.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    l.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    return l;
}

- (UIView *)separatorView {
    UIView *v = [UIView new];
    v.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    v.frame = CGRectMake(0, 0, 0, 1);
    return v;
}

- (NSInteger)indexForFPS:(NSInteger)fps {
    if (fps == 30)  return 0;
    if (fps == 60)  return 1;
    if (fps == 120) return 2;
    return 1;
}

- (void)loadCurrentSettings {
    // Sudah di-set via initWithTitle
}

// ─── Actions ───────────────────────────────────────────────────────────────
- (void)fpsChanged:(UISegmentedControl *)seg {
    NSInteger fps = seg.selectedSegmentIndex == 0 ? 30 :
                    seg.selectedSegmentIndex == 1 ? 60 : 120;
    [FPSCap setFPS:fps];
    NSLog(@"[GameOptimizer] UI: FPS cap → %ld", (long)fps);
}

- (void)metalFXQualityChanged:(UISegmentedControl *)seg {
    MetalFXQuality q = (MetalFXQuality)seg.selectedSegmentIndex;
    [Settings setMetalFXQuality:q];
    [Settings save];
    [self markNeedsRestart];
}

- (void)markNeedsRestart {
    if (!_needsRestart) {
        _needsRestart = YES;
        [UIView animateWithDuration:0.2 animations:^{
            self.restartBtn.hidden = NO;
            self.restartBtn.alpha  = 1.0;
        }];
    }
}

- (void)restartApp {
    // Confirm trước khi restart
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Restart App"
        message:@"App sẽ tắt để apply settings. Mở lại để thấy hiệu quả."
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction
        actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel
        handler:nil]];

    [alert addAction:[UIAlertAction
        actionWithTitle:@"Restart"
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *a) {
            [Settings save];
            // Thoát app sạch
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                dispatch_get_main_queue(),
                ^{ exit(0); }
            );
        }]];

    UIViewController *vc = self.window.rootViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

@end