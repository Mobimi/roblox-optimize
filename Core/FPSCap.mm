#import "FPSCap.h"
#import "Settings.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// ─── Hook CADisplayLink để control frame rate ──────────────────────────────
@interface CADisplayLink (FPSCapHook)
- (void)fpscap_setPreferredFramesPerSecond:(NSInteger)fps;
- (void)fpscap_setPreferredFrameRateRange:(CAFrameRateRange)range;
@end

@implementation CADisplayLink (FPSCapHook)

// iOS 15 trở xuống dùng preferredFramesPerSecond
- (void)fpscap_setPreferredFramesPerSecond:(NSInteger)fps {
    NSInteger cap = [Settings fpsCap];
    if (fps == 0 || fps > cap) fps = cap;
    NSLog(@"[GameOptimizer] FPSCap: preferredFramesPerSecond → %ld", (long)fps);
    [self fpscap_setPreferredFramesPerSecond:fps]; // original
}

// iOS 16+ dùng preferredFrameRateRange
- (void)fpscap_setPreferredFrameRateRange:(CAFrameRateRange)range {
    NSInteger cap = [Settings fpsCap];
    // Clamp maximum và preferred xuống cap
    if (range.maximum > cap)   range.maximum   = (float)cap;
    if (range.preferred > cap) range.preferred = (float)cap;
    if (range.minimum > cap)   range.minimum   = (float)cap;
    NSLog(@"[GameOptimizer] FPSCap: frameRateRange → %.0f-%.0f (preferred: %.0f)",
          range.minimum, range.maximum, range.preferred);
    [self fpscap_setPreferredFrameRateRange:range]; // original
}

@end

// ─── FPSCap main ───────────────────────────────────────────────────────────
@implementation FPSCap

+ (void)apply {
    NSInteger cap = [Settings fpsCap];
    NSLog(@"[GameOptimizer] FPSCap: %ld fps", (long)cap);

    Class displayLinkClass = NSClassFromString(@"CADisplayLink");
    if (!displayLinkClass) {
        NSLog(@"[GameOptimizer] FPSCap: CADisplayLink not found");
        return;
    }

    // Hook preferredFramesPerSecond (iOS 15 trở xuống)
    Method orig1 = class_getInstanceMethod(displayLinkClass,
        @selector(setPreferredFramesPerSecond:));
    Method repl1 = class_getInstanceMethod(displayLinkClass,
        @selector(fpscap_setPreferredFramesPerSecond:));
    if (orig1 && repl1) {
        method_exchangeImplementations(orig1, repl1);
        NSLog(@"[GameOptimizer] FPSCap: preferredFramesPerSecond hooked");
    }

    // Hook preferredFrameRateRange (iOS 16+)
    Method orig2 = class_getInstanceMethod(displayLinkClass,
        @selector(setPreferredFrameRateRange:));
    Method repl2 = class_getInstanceMethod(displayLinkClass,
        @selector(fpscap_setPreferredFrameRateRange:));
    if (orig2 && repl2) {
        method_exchangeImplementations(orig2, repl2);
        NSLog(@"[GameOptimizer] FPSCap: preferredFrameRateRange hooked");
    }

    // Apply ngay vào tất cả CADisplayLink đang chạy
    [self applyToExistingDisplayLinks];
}

+ (void)setFPS:(NSInteger)fps {
    [Settings setFpsCap:fps];
    [Settings save];
    [self applyToExistingDisplayLinks];
    NSLog(@"[GameOptimizer] FPSCap updated: %ld fps", (long)fps);
}

+ (void)applyToExistingDisplayLinks {
    // Không thể enumerate CADisplayLink trực tiếp
    // Hook đã cover mọi displayLink mới được tạo
    // Với displayLink cũ, game thường recreate khi resume
    NSLog(@"[GameOptimizer] FPSCap: hooks active for new displayLinks");
}

@end