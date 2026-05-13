#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
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

// ─── Debug log ghi ra Documents ───────────────────────────────────────────
static NSString *_logPath = nil;

static void InitLogFile(void) {
    NSString *docs = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    _logPath = [docs stringByAppendingPathComponent:@"GameOptimizer.log"];
    [@"" writeToFile:_logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static void GOLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSString *line = [NSString stringWithFormat:@"[%@] %@\n",
        [NSDate date], msg];

    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:_logPath];
    if (!fh) {
        [line writeToFile:_logPath atomically:YES
               encoding:NSUTF8StringEncoding error:nil];
    } else {
        [fh seekToEndOfFile];
        [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
    }

    NSLog(@"[GameOptimizer] %@", msg);
}

// ─── Safe wrapper ──────────────────────────────────────────────────────────
static void SafeApply(NSString *name, void(^block)(void)) {
    @try {
        block();
        GOLog(@"✓ %@ OK", name);
    } @catch (NSException *e) {
        GOLog(@"✗ %@ EXCEPTION: %@ — %@", name, e.name, e.reason);
    } @catch (...) {
        GOLog(@"✗ %@ UNKNOWN CRASH", name);
    }
}

// ─── Entry point ──────────────────────────────────────────────────────────
__attribute__((constructor))
static void GameOptimizerInit(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{

        InitLogFile();
        GOLog(@"=== GameOptimizer loaded into: %@ ===",
              [[NSBundle mainBundle] bundleIdentifier]);

        SafeApply(@"Settings.load", ^{ [Settings load]; });
        GOLog(@"Scale=%.2f FPS=%ld MSAA=%d FXAA=%d Shadow=%d FB=%d MFX=%d Thread=%d",
              [Settings renderScale],
              (long)[Settings fpsCap],
              [Settings msaaEnabled],
              [Settings fxaaEnabled],
              [Settings shadowEnabled],
              [Settings framebufferOptEnabled],
              [Settings metalFXEnabled],
              [Settings threadBoostEnabled]);

        SafeApply(@"ThreadBoost",  ^{ [ThreadBoost apply]; });
        SafeApply(@"FPSCap",       ^{ [FPSCap apply]; });
        SafeApply(@"RenderScale",  ^{ [RenderScale apply]; });
        SafeApply(@"MSAA_FXAA",    ^{ [MSAA_FXAA apply]; });
        SafeApply(@"ShadowPass",   ^{ [ShadowPass apply]; });
        SafeApply(@"Framebuffer",  ^{ [Framebuffer apply]; });
        SafeApply(@"MetalFX",      ^{ [MetalFXModule apply]; });
        SafeApply(@"MetalHooks",   ^{ [MetalHooks install]; });

        GOLog(@"=== All modules done — waiting for UI ===");

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                SafeApply(@"OverlayWindow", ^{ [OverlayWindow show]; });
                GOLog(@"=== Overlay shown ===");
            }
        );
    });
}

__attribute__((destructor))
static void GameOptimizerDeinit(void) {
    GOLog(@"=== GameOptimizer unloaded ===");
    SafeApply(@"Settings.save", ^{ [Settings save]; });
}
