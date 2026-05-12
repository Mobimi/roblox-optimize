#import "RenderScale.h"
#import "Settings.h"
#import <QuartzCore/CAMetalLayer.h>
#import <UIKit/UIKit.h>

// ─── Helper lấy tất cả CAMetalLayer trong view hierarchy ──────────────────
static void ApplyScaleToLayer(CALayer *layer, float scale) {
    if (!layer) return;

    if ([layer isKindOfClass:NSClassFromString(@"CAMetalLayer")]) {
        CAMetalLayer *ml = (CAMetalLayer *)layer;
        UIScreen *screen = UIScreen.mainScreen;

        // Lấy bounds đúng theo orientation hiện tại
        CGSize screenSize = screen.bounds.size;

        // Tính drawable size theo orientation
        UIInterfaceOrientation orientation = UIApplication.sharedApplication
            .windows.firstObject
            .windowScene
            .interfaceOrientation;

        CGFloat width  = screenSize.width;
        CGFloat height = screenSize.height;

        // Đảm bảo width > height khi landscape
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            width  = MAX(screenSize.width, screenSize.height);
            height = MIN(screenSize.width, screenSize.height);
        } else {
            width  = MIN(screenSize.width, screenSize.height);
            height = MAX(screenSize.width, screenSize.height);
        }

        CGSize newSize = CGSizeMake(width * scale, height * scale);

        // Chỉ update nếu thực sự thay đổi tránh loop vô tận
        if (!CGSizeEqualToSize(ml.drawableSize, newSize)) {
            ml.drawableSize  = newSize;
            ml.contentsScale = scale;
            NSLog(@"[GameOptimizer] RenderScale: %.2f× → drawableSize: %.0f×%.0f",
                  scale, newSize.width, newSize.height);
        }
    }

    // Đệ quy xuống sublayers
    for (CALayer *sub in layer.sublayers) {
        ApplyScaleToLayer(sub, scale);
    }
}

// ─── Apply lên toàn bộ windows ────────────────────────────────────────────
static void ApplyScaleToAllWindows(float scale) {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIWindow *win in UIApplication.sharedApplication.windows) {
            ApplyScaleToLayer(win.layer, scale);
        }
    });
}

@implementation RenderScale

+ (void)apply {
    float scale = [Settings renderScale];
    NSLog(@"[GameOptimizer] RenderScale apply: %.2f×", scale);

    // Apply ngay lập tức
    ApplyScaleToAllWindows(scale);

    // Lắng nghe orientation change
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIDeviceOrientationDidChangeNotification
        object:nil
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *note) {
            UIDeviceOrientation deviceOri = UIDevice.currentDevice.orientation;

            // Bỏ qua face up/down/unknown — không ảnh hưởng render
            if (deviceOri == UIDeviceOrientationFaceUp   ||
                deviceOri == UIDeviceOrientationFaceDown ||
                deviceOri == UIDeviceOrientationUnknown) {
                return;
            }

            float currentScale = [Settings renderScale];
            NSLog(@"[GameOptimizer] Orientation changed → re-apply scale: %.2f×",
                  currentScale);

            // Delay nhỏ để đợi game xử lý orientation xong mới apply
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                dispatch_get_main_queue(),
                ^{
                    ApplyScaleToAllWindows(currentScale);
                }
            );
        }
    ];

    NSLog(@"[GameOptimizer] RenderScale orientation observer registered");
}

+ (void)updateForOrientation:(UIInterfaceOrientation)orientation {
    float scale = [Settings renderScale];
    ApplyScaleToAllWindows(scale);
    NSLog(@"[GameOptimizer] RenderScale updated for orientation: %ld scale: %.2f×",
          (long)orientation, scale);
}

@end