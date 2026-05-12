#import "OverlayWindow.h"
#import "MainPanel.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static OverlayWindow *_sharedWindow = nil;

@interface OverlayWindow ()
@property (nonatomic, strong) MainPanel *panel;
@property (nonatomic, strong) UIButton  *toggleBtn;
@property (nonatomic, assign) BOOL       panelVisible;
@end

@implementation OverlayWindow

+ (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_sharedWindow) return;

        // Lấy windowScene từ app — KHÔNG tạo window riêng biệt
        // để tránh conflict orientation với game
        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] &&
                s.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)s;
                break;
            }
        }

        if (!scene) {
            NSLog(@"[GameOptimizer] OverlayWindow: no active scene found");
            return;
        }

        _sharedWindow = [[OverlayWindow alloc] initWithWindowScene:scene];
        _sharedWindow.windowLevel          = UIWindowLevelStatusBar + 100;
        _sharedWindow.backgroundColor      = UIColor.clearColor;
        _sharedWindow.userInteractionEnabled = YES;

        // Root VC rỗng — KHÔNG override supportedInterfaceOrientations
        // để game tự xoay bình thường
        UIViewController *rootVC = [OverlayRootViewController new];
        _sharedWindow.rootViewController = rootVC;
        [_sharedWindow makeKeyAndVisible];

        [_sharedWindow setupUI];
        [_sharedWindow registerOrientationObserver];

        NSLog(@"[GameOptimizer] OverlayWindow shown");
    });
}

+ (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        _sharedWindow.hidden = YES;
        _sharedWindow = nil;
    });
}

- (void)setupUI {
    // Toggle button — nút nhỏ góc trên phải để show/hide panel
    _toggleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _toggleBtn.frame = CGRectMake(0, 0, 44, 44);
    _toggleBtn.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.85];
    _toggleBtn.layer.cornerRadius = 22;
    _toggleBtn.layer.borderWidth  = 1.5;
    _toggleBtn.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
    [_toggleBtn setTitle:@"⚙️" forState:UIControlStateNormal];
    _toggleBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    [_toggleBtn addTarget:self
                   action:@selector(togglePanel)
         forControlEvents:UIControlEventTouchUpInside];

    // Panel
    _panel = [[MainPanel alloc] initWithFrame:CGRectZero];
    _panel.hidden = YES;

    [self.rootViewController.view addSubview:_toggleBtn];
    [self.rootViewController.view addSubview:_panel];

    // Layout awal
    [self layoutForCurrentOrientation];
}

- (void)togglePanel {
    _panelVisible = !_panelVisible;
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.panel.hidden  = !self->_panelVisible;
        self.panel.alpha   =  self->_panelVisible ? 1.0 : 0.0;
    } completion:nil];
}

// ─── Orientation ──────────────────────────────────────────────────────────
- (void)registerOrientationObserver {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(orientationDidChange:)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];
}

- (void)orientationDidChange:(NSNotification *)note {
    UIDeviceOrientation ori = UIDevice.currentDevice.orientation;
    if (ori == UIDeviceOrientationFaceUp   ||
        ori == UIDeviceOrientationFaceDown ||
        ori == UIDeviceOrientationUnknown) return;

    // Delay để đợi game xử lý orientation trước
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{ [self layoutForCurrentOrientation]; }
    );
}

- (void)layoutForCurrentOrientation {
    CGRect screenBounds = self.rootViewController.view.bounds;
    if (CGRectIsEmpty(screenBounds)) {
        screenBounds = UIScreen.mainScreen.bounds;
    }

    CGFloat W = screenBounds.size.width;
    CGFloat H = screenBounds.size.height;

    // Toggle button — góc trên phải, tránh notch/Dynamic Island
    CGFloat safeTop   = self.rootViewController.view.safeAreaInsets.top;
    CGFloat safeRight = self.rootViewController.view.safeAreaInsets.right;
    _toggleBtn.frame  = CGRectMake(
        W - 44 - 12 - safeRight,
        safeTop + 8,
        44, 44
    );

    // Panel — bên dưới toggle button
    CGFloat panelW = MIN(W - 32, 300);
    CGFloat panelH = 320;
    CGFloat panelX = W - panelW - 12 - safeRight;
    CGFloat panelY = CGRectGetMaxY(_toggleBtn.frame) + 8;

    // Đảm bảo panel không vượt ra ngoài màn hình khi landscape
    if (panelY + panelH > H - 20) {
        panelY = H - panelH - 20;
    }

    _panel.frame = CGRectMake(panelX, panelY, panelW, panelH);
    [_panel setNeedsLayout];

    NSLog(@"[GameOptimizer] Layout updated: screen=%.0fx%.0f panel=%.0f,%.0f",
          W, H, panelX, panelY);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// ─── Root VC — không lock orientation ─────────────────────────────────────
@implementation OverlayRootViewController

- (BOOL)shouldAutorotate {
    // Cho phép xoay hoàn toàn theo game
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // Support tất cả orientation — không can thiệp vào game
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end