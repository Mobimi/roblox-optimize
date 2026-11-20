//
//  ROMenuViewController.m
//  RobloxOptimizer
//
//  Landscape-friendly modal configuration popup with preset switching and input validation.
//

#import "ROMenuViewController.h"
#import <stdlib.h>
#import "../Config/ROConfig.h"
#import "../FFlags/ROFastFlags.h"

@interface ROMenuViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *subControlsContainer;
@property (nonatomic, strong) UIButton *saveExitButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UISelectionFeedbackGenerator *selectionFeedback;
@property (nonatomic, strong) UIImpactFeedbackGenerator *impactLight;
@property (nonatomic, strong) UIImpactFeedbackGenerator *impactMedium;

@end

@implementation ROMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViewHierarchy];
    [self loadConfigIntoUI];

    // Initialize cached haptic feedback generators
    if (@available(iOS 10.0, *)) {
        if ([UISelectionFeedbackGenerator class]) {
            self.selectionFeedback = [[UISelectionFeedbackGenerator alloc] init];
            [self.selectionFeedback prepare];
        }
        if ([UIImpactFeedbackGenerator class]) {
            self.impactLight = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            self.impactMedium = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        }
    }
}

- (void)setupViewHierarchy {
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];

    // Modern blur backdrop for gameplay immersion
    UIBlurEffect *backdropBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *backdropBlurView = [[UIVisualEffectView alloc] initWithEffect:backdropBlur];
    backdropBlurView.frame = self.view.bounds;
    backdropBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:backdropBlurView];

    // Tap backdrop outside the dialog card to dismiss
    UITapGestureRecognizer *backdropTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeTapped)];
    [self.view addGestureRecognizer:backdropTap];

    // Dialog card with frosted glass styling and rounded corners
    self.dialogCard = [[UIView alloc] init];
    self.dialogCard.backgroundColor = [UIColor colorWithRed:0.08 green:0.11 blue:0.17 alpha:0.68]; // Apple Liquid Glass translucent tint
    self.dialogCard.layer.cornerRadius = 20.0;
    if (@available(iOS 13.0, *)) {
        if ([self.dialogCard.layer respondsToSelector:@selector(setCornerCurve:)]) {
            self.dialogCard.layer.cornerCurve = kCACornerCurveContinuous;
        }
    }
    // Specular highlight rim border
    self.dialogCard.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.20].CGColor;
    self.dialogCard.layer.borderWidth = 1.0;
    // Ambient luminescence glow shadow
    self.dialogCard.layer.shadowColor = [UIColor colorWithRed:0.15 green:0.45 blue:0.95 alpha:0.35].CGColor;
    self.dialogCard.layer.shadowOffset = CGSizeMake(0, 8);
    self.dialogCard.layer.shadowRadius = 24.0;
    self.dialogCard.layer.shadowOpacity = 0.55;
    self.dialogCard.layer.masksToBounds = NO;
    self.dialogCard.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.dialogCard];

    // Dialog card frosted glass blur effect
    UIBlurEffect *cardBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *cardBlurView = [[UIVisualEffectView alloc] initWithEffect:cardBlur];
    cardBlurView.frame = self.dialogCard.bounds;
    cardBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    cardBlurView.layer.cornerRadius = 20.0;
    cardBlurView.layer.masksToBounds = YES;
    if (@available(iOS 13.0, *)) {
        if ([cardBlurView.layer respondsToSelector:@selector(setCornerCurve:)]) {
            cardBlurView.layer.cornerCurve = kCACornerCurveContinuous;
        }
    }
    cardBlurView.userInteractionEnabled = NO;
    [self.dialogCard addSubview:cardBlurView];

    // Card tap recognizer absorbs taps so card touches don't trigger backdropTap
    UITapGestureRecognizer *cardTap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
    [self.dialogCard addGestureRecognizer:cardTap];

    // Scroll view for landscape orientation safety
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.dialogCard addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    // Title label
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"⚡ Roblox iOS Optimizer";
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:titleLabel];

    // Preset Segmented Control
    self.presetControl = [[UISegmentedControl alloc] initWithItems:@[@"Potato", @"Balanced", @"Manual"]];
    self.presetControl.selectedSegmentTintColor = [UIColor colorWithRed:0.15 green:0.40 blue:0.95 alpha:1.0];
    NSDictionary *attr = @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]
    };
    [self.presetControl setTitleTextAttributes:attr forState:UIControlStateNormal];
    [self.presetControl setTitleTextAttributes:attr forState:UIControlStateSelected];
    [self.presetControl addTarget:self action:@selector(presetChanged:) forControlEvents:UIControlEventValueChanged];
    self.presetControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.presetControl];

    // Sub-controls container
    self.subControlsContainer = [[UIView alloc] init];
    self.subControlsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.subControlsContainer];

    // 1. Resolution Scale Row (Slider & Textfield)
    UILabel *scaleLabel = [[UILabel alloc] init];
    scaleLabel.text = @"Resolution Scale:";
    scaleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    scaleLabel.textColor = [UIColor whiteColor];
    scaleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:scaleLabel];

    self.scaleSlider = [[UISlider alloc] init];
    self.scaleSlider.minimumValue = 0.25f;
    self.scaleSlider.maximumValue = 3.0f;
    self.scaleSlider.minimumTrackTintColor = [UIColor colorWithRed:0.15 green:0.40 blue:0.95 alpha:1.0];
    [self.scaleSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.scaleSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:self.scaleSlider];

    self.scaleTextField = [[UITextField alloc] init];
    self.scaleTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.scaleTextField.backgroundColor = [UIColor colorWithRed:0.04 green:0.06 blue:0.10 alpha:1.0];
    self.scaleTextField.textColor = [UIColor whiteColor];
    self.scaleTextField.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.scaleTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.scaleTextField.delegate = self;
    [self.scaleTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.scaleTextField.translatesAutoresizingMaskIntoConstraints = NO;

    // Keyboard toolbar with Done button
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.barStyle = UIBarStyleBlack;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self.scaleTextField action:@selector(resignFirstResponder)];
    toolbar.items = @[flex, done];
    self.scaleTextField.inputAccessoryView = toolbar;
    [self.subControlsContainer addSubview:self.scaleTextField];

    // 2. Texture Clamping Row
    UILabel *textureLabel = [[UILabel alloc] init];
    textureLabel.text = @"Texture Clamping (Jetsam fix):";
    textureLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    textureLabel.textColor = [UIColor whiteColor];
    textureLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:textureLabel];

    self.textureClampingSwitch = [[UISwitch alloc] init];
    self.textureClampingSwitch.onTintColor = [UIColor colorWithRed:0.15 green:0.40 blue:0.95 alpha:1.0];
    [self.textureClampingSwitch addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    self.textureClampingSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:self.textureClampingSwitch];

    // 3. Shadows Row
    UILabel *shadowsLabel = [[UILabel alloc] init];
    shadowsLabel.text = @"Disable Shadows:";
    shadowsLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    shadowsLabel.textColor = [UIColor whiteColor];
    shadowsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:shadowsLabel];

    self.shadowsSwitch = [[UISwitch alloc] init];
    self.shadowsSwitch.onTintColor = [UIColor colorWithRed:0.15 green:0.40 blue:0.95 alpha:1.0];
    [self.shadowsSwitch addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    self.shadowsSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:self.shadowsSwitch];

    // 4. Post-FX Row
    UILabel *postFxLabel = [[UILabel alloc] init];
    postFxLabel.text = @"Disable Post-FX (Bloom/Blur):";
    postFxLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    postFxLabel.textColor = [UIColor whiteColor];
    postFxLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:postFxLabel];

    self.postFxSwitch = [[UISwitch alloc] init];
    self.postFxSwitch.onTintColor = [UIColor colorWithRed:0.15 green:0.40 blue:0.95 alpha:1.0];
    [self.postFxSwitch addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    self.postFxSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:self.postFxSwitch];

    // 5. FPS Row
    UILabel *fpsLabel = [[UILabel alloc] init];
    fpsLabel.text = @"Target FPS:";
    fpsLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    fpsLabel.textColor = [UIColor whiteColor];
    fpsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:fpsLabel];

    self.fpsControl = [[UISegmentedControl alloc] initWithItems:@[@"30", @"60", @"Unlocked"]];
    self.fpsControl.selectedSegmentTintColor = [UIColor colorWithRed:0.15 green:0.40 blue:0.95 alpha:1.0];
    [self.fpsControl setTitleTextAttributes:attr forState:UIControlStateNormal];
    [self.fpsControl setTitleTextAttributes:attr forState:UIControlStateSelected];
    [self.fpsControl addTarget:self action:@selector(fpsChanged:) forControlEvents:UIControlEventValueChanged];
    self.fpsControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.subControlsContainer addSubview:self.fpsControl];

    // Action Buttons with refined Liquid Glass styling
    self.saveExitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveExitButton setTitle:@"Save & Exit" forState:UIControlStateNormal];
    [self.saveExitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.saveExitButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.saveExitButton.backgroundColor = [UIColor colorWithRed:0.86 green:0.24 blue:0.24 alpha:0.90]; // Red
    self.saveExitButton.layer.cornerRadius = 10.0;
    self.saveExitButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
    self.saveExitButton.layer.borderWidth = 0.5;
    [self.saveExitButton addTarget:self action:@selector(saveAndExitTapped) forControlEvents:UIControlEventTouchUpInside];
    self.saveExitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.saveExitButton];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:@"Close Menu" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.closeButton.backgroundColor = [UIColor colorWithRed:0.20 green:0.26 blue:0.35 alpha:0.85];
    self.closeButton.layer.cornerRadius = 10.0;
    self.closeButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.20].CGColor;
    self.closeButton.layer.borderWidth = 0.5;
    [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.closeButton];

    if (@available(iOS 13.0, *)) {
        if ([self.saveExitButton.layer respondsToSelector:@selector(setCornerCurve:)]) {
            self.saveExitButton.layer.cornerCurve = kCACornerCurveContinuous;
            self.closeButton.layer.cornerCurve = kCACornerCurveContinuous;
        }
    }

    // Auto Layout
    [NSLayoutConstraint activateConstraints:@[
        [self.dialogCard.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.dialogCard.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.dialogCard.widthAnchor constraintLessThanOrEqualToConstant:400],
        [self.dialogCard.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor constant:-32],
        [self.dialogCard.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor constant:-32],

        [self.scrollView.topAnchor constraintEqualToAnchor:self.dialogCard.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.dialogCard.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.dialogCard.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.dialogCard.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],

        [titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],

        [self.presetControl.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:12],
        [self.presetControl.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.presetControl.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.presetControl.heightAnchor constraintEqualToConstant:32],

        [self.subControlsContainer.topAnchor constraintEqualToAnchor:self.presetControl.bottomAnchor constant:12],
        [self.subControlsContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.subControlsContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],

        // Scale row (slider & textfield)
        [scaleLabel.topAnchor constraintEqualToAnchor:self.subControlsContainer.topAnchor constant:8],
        [scaleLabel.leadingAnchor constraintEqualToAnchor:self.subControlsContainer.leadingAnchor],
        [self.scaleSlider.centerYAnchor constraintEqualToAnchor:scaleLabel.centerYAnchor],
        [self.scaleSlider.leadingAnchor constraintEqualToAnchor:scaleLabel.trailingAnchor constant:8],
        [self.scaleSlider.trailingAnchor constraintEqualToAnchor:self.scaleTextField.leadingAnchor constant:-8],
        [self.scaleTextField.centerYAnchor constraintEqualToAnchor:scaleLabel.centerYAnchor],
        [self.scaleTextField.trailingAnchor constraintEqualToAnchor:self.subControlsContainer.trailingAnchor],
        [self.scaleTextField.widthAnchor constraintEqualToConstant:70],

        // Texture Clamping row
        [textureLabel.topAnchor constraintEqualToAnchor:scaleLabel.bottomAnchor constant:14],
        [textureLabel.leadingAnchor constraintEqualToAnchor:self.subControlsContainer.leadingAnchor],
        [self.textureClampingSwitch.centerYAnchor constraintEqualToAnchor:textureLabel.centerYAnchor],
        [self.textureClampingSwitch.trailingAnchor constraintEqualToAnchor:self.subControlsContainer.trailingAnchor],

        // Shadows row
        [shadowsLabel.topAnchor constraintEqualToAnchor:textureLabel.bottomAnchor constant:14],
        [shadowsLabel.leadingAnchor constraintEqualToAnchor:self.subControlsContainer.leadingAnchor],
        [self.shadowsSwitch.centerYAnchor constraintEqualToAnchor:shadowsLabel.centerYAnchor],
        [self.shadowsSwitch.trailingAnchor constraintEqualToAnchor:self.subControlsContainer.trailingAnchor],

        // Post-FX row
        [postFxLabel.topAnchor constraintEqualToAnchor:shadowsLabel.bottomAnchor constant:14],
        [postFxLabel.leadingAnchor constraintEqualToAnchor:self.subControlsContainer.leadingAnchor],
        [self.postFxSwitch.centerYAnchor constraintEqualToAnchor:postFxLabel.centerYAnchor],
        [self.postFxSwitch.trailingAnchor constraintEqualToAnchor:self.subControlsContainer.trailingAnchor],

        // FPS row
        [fpsLabel.topAnchor constraintEqualToAnchor:postFxLabel.bottomAnchor constant:14],
        [fpsLabel.leadingAnchor constraintEqualToAnchor:self.subControlsContainer.leadingAnchor],
        [self.fpsControl.centerYAnchor constraintEqualToAnchor:fpsLabel.centerYAnchor],
        [self.fpsControl.trailingAnchor constraintEqualToAnchor:self.subControlsContainer.trailingAnchor],
        [self.fpsControl.widthAnchor constraintEqualToConstant:150],
        [self.fpsControl.bottomAnchor constraintEqualToAnchor:self.subControlsContainer.bottomAnchor constant:-8],

        // Buttons
        [self.saveExitButton.topAnchor constraintEqualToAnchor:self.subControlsContainer.bottomAnchor constant:16],
        [self.saveExitButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.saveExitButton.heightAnchor constraintEqualToConstant:38],

        [self.closeButton.topAnchor constraintEqualToAnchor:self.subControlsContainer.bottomAnchor constant:16],
        [self.closeButton.leadingAnchor constraintEqualToAnchor:self.saveExitButton.trailingAnchor constant:12],
        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.closeButton.widthAnchor constraintEqualToAnchor:self.saveExitButton.widthAnchor],
        [self.closeButton.heightAnchor constraintEqualToConstant:38],
        [self.closeButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16]
    ]];
}

- (void)loadConfigIntoUI {
    ROConfig *cfg = [ROConfig sharedConfig];
    self.presetControl.selectedSegmentIndex = cfg.presetMode;
    [self applyPresetUIState:cfg.presetMode];
}

- (void)presetChanged:(UISegmentedControl *)sender {
    if (@available(iOS 10.0, *)) {
        if (self.selectionFeedback) {
            [self.selectionFeedback selectionChanged];
        } else if ([UISelectionFeedbackGenerator class]) {
            UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
            [feedback selectionChanged];
        }
    }
    [self applyPresetUIState:(ROPresetMode)sender.selectedSegmentIndex];
}

- (void)sliderValueChanged:(UISlider *)sender {
    float rounded = roundf(sender.value * 100.0f) / 100.0f;
    self.scaleTextField.text = [NSString stringWithFormat:@"%.2f", (double)rounded];
    if (@available(iOS 10.0, *)) {
        if (self.selectionFeedback) {
            [self.selectionFeedback selectionChanged];
        } else if ([UISelectionFeedbackGenerator class]) {
            UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
            [feedback selectionChanged];
        }
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    float val = [textField.text floatValue];
    if (val >= 0.25f && val <= 3.0f) {
        [self.scaleSlider setValue:val animated:YES];
    }
}

- (void)toggleChanged:(UISwitch *)sender {
    (void)sender;
    if (@available(iOS 10.0, *)) {
        if (self.impactLight) {
            [self.impactLight impactOccurred];
        } else if ([UIImpactFeedbackGenerator class]) {
            UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [feedback impactOccurred];
        }
    }
}

- (void)fpsChanged:(UISegmentedControl *)sender {
    (void)sender;
    if (@available(iOS 10.0, *)) {
        if (self.selectionFeedback) {
            [self.selectionFeedback selectionChanged];
        } else if ([UISelectionFeedbackGenerator class]) {
            UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
            [feedback selectionChanged];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    float val = [textField.text floatValue];
    if (val >= 0.25f && val <= 3.0f) {
        self.scaleSlider.value = val;
    } else {
        self.scaleTextField.text = [NSString stringWithFormat:@"%.2f", (double)self.scaleSlider.value];
    }
}

- (void)applyPresetUIState:(ROPresetMode)mode {
    ROConfig *cfg = [ROConfig sharedConfig];
    if (mode == ROPresetModePotato) {
        // Dim and disable sub-controls
        self.subControlsContainer.userInteractionEnabled = NO;
        self.subControlsContainer.alpha = 0.45;
        self.scaleTextField.text = @"0.50";
        self.scaleSlider.value = 0.50f;
        self.textureClampingSwitch.on = YES;
        self.shadowsSwitch.on = YES;
        self.postFxSwitch.on = YES;
        self.fpsControl.selectedSegmentIndex = 1; // 60 FPS
    } else if (mode == ROPresetModeBalanced) {
        // Dim and disable sub-controls
        self.subControlsContainer.userInteractionEnabled = NO;
        self.subControlsContainer.alpha = 0.45;
        self.scaleTextField.text = @"1.00";
        self.scaleSlider.value = 1.00f;
        self.textureClampingSwitch.on = YES;
        self.shadowsSwitch.on = YES;
        self.postFxSwitch.on = NO;
        self.fpsControl.selectedSegmentIndex = 1; // 60 FPS
    } else { // Manual mode
        // Enable sub-controls
        self.subControlsContainer.userInteractionEnabled = YES;
        self.subControlsContainer.alpha = 1.0;
        self.scaleTextField.text = [NSString stringWithFormat:@"%.2f", cfg.resolutionScale];
        self.scaleSlider.value = (float)cfg.resolutionScale;
        self.textureClampingSwitch.on = cfg.textureClampingEnabled;
        self.shadowsSwitch.on = cfg.disableShadows;
        self.postFxSwitch.on = cfg.disablePostFX;
        if (cfg.targetFPS == 30) {
            self.fpsControl.selectedSegmentIndex = 0;
        } else if (cfg.targetFPS == 60) {
            self.fpsControl.selectedSegmentIndex = 1;
        } else {
            self.fpsControl.selectedSegmentIndex = 2; // Unlocked
        }
    }
}

- (void)saveAndExitTapped {
    float scale = [self.scaleTextField.text floatValue];
    if (scale < 0.25f || scale > 3.0f) {
        if (@available(iOS 10.0, *)) {
            if ([UINotificationFeedbackGenerator class]) {
                UINotificationFeedbackGenerator *feedback = [[UINotificationFeedbackGenerator alloc] init];
                [feedback notificationOccurred:UINotificationFeedbackTypeError];
            }
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Resolution Scale"
                                                                       message:@"Scale must be between 0.25 and 3.0 (e.g. 0.75, 1.00)."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    if (@available(iOS 10.0, *)) {
        if (self.impactMedium) {
            [self.impactMedium impactOccurred];
        } else if ([UIImpactFeedbackGenerator class]) {
            UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [feedback impactOccurred];
        }
    }

    ROConfig *cfg = [ROConfig sharedConfig];
    ROPresetMode selectedMode = (ROPresetMode)self.presetControl.selectedSegmentIndex;
    cfg.presetMode = selectedMode;

    if (selectedMode == ROPresetModeManual) {
        cfg.resolutionScale = (CGFloat)scale;
        cfg.textureClampingEnabled = self.textureClampingSwitch.on;
        cfg.maxTextureDimension = 512;
        cfg.disableShadows = self.shadowsSwitch.on;
        cfg.disablePostFX = self.postFxSwitch.on;
        NSInteger fpsIdx = self.fpsControl.selectedSegmentIndex;
        cfg.targetFPS = (fpsIdx == 0) ? 30 : (fpsIdx == 1) ? 60 : 0;
    } else {
        [cfg applyPreset:selectedMode];
    }
    [cfg save];

    // Write updated ClientAppSettings.json
    [ROFastFlags writeFastFlagsConfigurationWithError:nil];

    UIAlertController *exitAlert = [UIAlertController alertControllerWithTitle:@"Settings Saved"
                                                                       message:@"Roblox needs to exit to apply your resolution scale and FastFlags. Reopen the game afterwards."
                                                                preferredStyle:UIAlertControllerStyleAlert];
    [exitAlert addAction:[UIAlertAction actionWithTitle:@"Exit Now" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        (void)action;
        exit(0);
    }]];
    __weak typeof(self) weakSelf = self;
    [exitAlert addAction:[UIAlertAction actionWithTitle:@"Later" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        (void)action;
        [weakSelf dismissMenu];
    }]];
    [self presentViewController:exitAlert animated:YES completion:nil];
}

- (void)closeTapped {
    if (@available(iOS 10.0, *)) {
        if (self.impactLight) {
            [self.impactLight impactOccurred];
        } else if ([UIImpactFeedbackGenerator class]) {
            UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [feedback impactOccurred];
        }
    }
    [self dismissMenu];
}

- (void)presentInParent:(UIViewController *)parent {
    self.view.alpha = 0.0;
    self.dialogCard.transform = CGAffineTransformMakeScale(0.86, 0.86);
    [parent addChildViewController:self];
    [parent.view addSubview:self.view];
    self.view.frame = parent.view.bounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self didMoveToParentViewController:parent];

    [UIView animateWithDuration:0.35
                          delay:0
         usingSpringWithDamping:0.80
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.view.alpha = 1.0;
        self.dialogCard.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismissMenu {
    [UIView animateWithDuration:0.25
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.view.alpha = 0.0;
        self.dialogCard.transform = CGAffineTransformMakeScale(0.90, 0.90);
    } completion:^(BOOL finished) {
        (void)finished;
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        if (self.onDismiss) {
            self.onDismiss();
        }
    }];
}

@end
