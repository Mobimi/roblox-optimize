#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import "Settings.h"
#import "MetalHooks.h"
#import "RenderScale.h"
#import "MSAA_FXAA.h"
#import "ShadowPass.h"
#import "Framebuffer.h"
#import "MetalFX.h"
#import "FPSCap.h"
#import "ThreadBoost.h"
#import "../UI/OverlayWindow.h"

// ─── Chạy ngay khi dylib được load vào process game ───────────────────────
__attribute__((constructor))
static void GameOptimizerInit(void) {
    // Đảm bảo chỉ init 1 lần
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSLog(@"[GameOptimizer] Dylib loaded into process: %@",
              [[NSBundle mainBundle] bundleIdentifier]);

        // 1. Load settings từ UserDefaults trước tiên
        [Settings load];

        // 2. Apply các tính năng cần thiết ngay khi khởi động
        //    (trước khi game init Metal pipeline)
        [ThreadBoost apply];   // Boost thread priority ngay lập tức
        [FPSCap apply];        // Set FPS cap
        [RenderScale apply];   // Apply render scale
        [MSAA_FXAA apply];     // MSAA off / FXAA
        [ShadowPass apply];    // Shadow toggle
        [Framebuffer apply];   // Framebuffer format
        [MetalFXModule apply]; // MetalFX upscaling
        [MetalHooks install];  // Hook Metal pipeline

        NSLog(@"[GameOptimizer] All modules applied");
        NSLog(@"[GameOptimizer] Settings: scale=%.2f fps=%ld msaa=%d fxaa=%d shadow=%d framebuffer=%d metalfx=%d thread=%d",
              [Settings renderScale],
              (long)[Settings fpsCap],
              [Settings msaaEnabled],
              [Settings fxaaEnabled],
              [Settings shadowEnabled],
              [Settings framebufferOptEnabled],
              [Settings metalFXEnabled],
              [Settings threadBoostEnabled]);

        // 3. Show overlay UI sau khi app đã fully launch
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                [OverlayWindow show];
                NSLog(@"[GameOptimizer] Overlay UI shown");
            }
        );
    });
}

// ─── Cleanup khi dylib unload ──────────────────────────────────────────────
__attribute__((destructor))
static void GameOptimizerDeinit(void) {
    NSLog(@"[GameOptimizer] Dylib unloaded");
    [Settings save];
}