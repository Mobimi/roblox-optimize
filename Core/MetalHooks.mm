#import "MetalHooks.h"
#import "Settings.h"
#import "RenderScale.h"
#import "MSAA_FXAA.h"
#import "Framebuffer.h"
#import "ShadowPass.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/CAMetalLayer.h>

// ─── Swizzle helper ────────────────────────────────────────────────────────
static void SwizzleMethod(Class cls, SEL original, SEL replacement) {
    Method origMethod = class_getInstanceMethod(cls, original);
    Method replMethod = class_getInstanceMethod(cls, replacement);
    if (!origMethod || !replMethod) {
        NSLog(@"[GameOptimizer] SwizzleMethod failed: %@ -> %@",
              NSStringFromSelector(original),
              NSStringFromSelector(replacement));
        return;
    }
    method_exchangeImplementations(origMethod, replMethod);
    NSLog(@"[GameOptimizer] Swizzled: %@", NSStringFromSelector(original));
}

// ─── CAMetalLayer category ─────────────────────────────────────────────────
@interface CAMetalLayer (GameOptimizer)
- (void)opt_setDrawableSize:(CGSize)size;
- (void)opt_setSampleCount:(NSUInteger)count;
- (void)opt_setPixelFormat:(MTLPixelFormat)format;
- (void)opt_setContentsScale:(CGFloat)scale;
@end

@implementation CAMetalLayer (GameOptimizer)

// Hook drawableSize → apply render scale
- (void)opt_setDrawableSize:(CGSize)size {
    if ([Settings renderScale] > 0) {
        UIScreen *screen = UIScreen.mainScreen;
        float scale = [Settings renderScale];
        size = CGSizeMake(
            screen.bounds.size.width  * scale,
            screen.bounds.size.height * scale
        );
    }
    [self opt_setDrawableSize:size]; // gọi original (đã swap)
}

// Hook sampleCount → MSAA control
- (void)opt_setSampleCount:(NSUInteger)count {
    if (![Settings msaaEnabled]) {
        count = 1; // tắt MSAA
    }
    [self opt_setSampleCount:count];
}

// Hook pixelFormat → Framebuffer format
- (void)opt_setPixelFormat:(MTLPixelFormat)format {
    if ([Settings framebufferOptEnabled]) {
        // RGBA16Float → RGBA8Unorm giảm 50% bandwidth
        if (format == MTLPixelFormatRGBA16Float) {
            format = MTLPixelFormatBGRA8Unorm;
            NSLog(@"[GameOptimizer] Framebuffer: RGBA16F → BGRA8");
        }
    }
    [self opt_setPixelFormat:format];
}

// Hook contentsScale → sync với render scale
- (void)opt_setContentsScale:(CGFloat)scale {
    if ([Settings renderScale] > 0) {
        scale = (CGFloat)[Settings renderScale];
    }
    [self opt_setContentsScale:scale];
}

@end

// ─── MTLRenderPassDescriptor category ─────────────────────────────────────
@interface MTLRenderPassDescriptor (GameOptimizer)
+ (MTLRenderPassDescriptor *)opt_renderPassDescriptor;
@end

@implementation MTLRenderPassDescriptor (GameOptimizer)

+ (MTLRenderPassDescriptor *)opt_renderPassDescriptor {
    MTLRenderPassDescriptor *desc = [self opt_renderPassDescriptor]; // original
    if (!desc) return desc;

    // Tắt shadow pass nếu cần
    if (![Settings shadowEnabled]) {
        [ShadowPass processDescriptor:desc];
    }

    // TBDR optimization — dùng storeActionDontCare khi không cần đọc lại
    for (int i = 0; i < 8; i++) {
        MTLRenderPassColorAttachmentDescriptor *att = desc.colorAttachments[i];
        if (att && att.texture) {
            if (att.storeAction == MTLStoreActionStore) {
                att.storeAction = MTLStoreActionStoreAndMultisampleResolve;
            }
        }
    }

    return desc;
}

@end

// ─── MetalHooks main ───────────────────────────────────────────────────────
@implementation MetalHooks

+ (void)install {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // Hook CAMetalLayer
        Class metalLayerClass = NSClassFromString(@"CAMetalLayer");
        if (metalLayerClass) {
            SwizzleMethod(metalLayerClass,
                @selector(setDrawableSize:),
                @selector(opt_setDrawableSize:));

            SwizzleMethod(metalLayerClass,
                @selector(setSampleCount:),
                @selector(opt_setSampleCount:));

            SwizzleMethod(metalLayerClass,
                @selector(setPixelFormat:),
                @selector(opt_setPixelFormat:));

            SwizzleMethod(metalLayerClass,
                @selector(setContentsScale:),
                @selector(opt_setContentsScale:));
        } else {
            NSLog(@"[GameOptimizer] CAMetalLayer not found");
        }

        // Hook MTLRenderPassDescriptor
        Class renderPassClass = NSClassFromString(@"MTLRenderPassDescriptor");
        if (renderPassClass) {
            // class method swizzle
            Method orig = class_getClassMethod(renderPassClass,
                @selector(renderPassDescriptor));
            Method repl = class_getClassMethod(renderPassClass,
                @selector(opt_renderPassDescriptor));
            if (orig && repl) {
                method_exchangeImplementations(orig, repl);
                NSLog(@"[GameOptimizer] Swizzled: renderPassDescriptor");
            }
        }

        NSLog(@"[GameOptimizer] MetalHooks installed");
    });
}

+ (void)uninstall {
    // Swap lại về original nếu cần
    Class metalLayerClass = NSClassFromString(@"CAMetalLayer");
    if (metalLayerClass) {
        SwizzleMethod(metalLayerClass,
            @selector(setDrawableSize:),
            @selector(opt_setDrawableSize:));
        SwizzleMethod(metalLayerClass,
            @selector(setSampleCount:),
            @selector(opt_setSampleCount:));
        SwizzleMethod(metalLayerClass,
            @selector(setPixelFormat:),
            @selector(opt_setPixelFormat:));
        SwizzleMethod(metalLayerClass,
            @selector(setContentsScale:),
            @selector(opt_setContentsScale:));
    }
    NSLog(@"[GameOptimizer] MetalHooks uninstalled");
}

@end