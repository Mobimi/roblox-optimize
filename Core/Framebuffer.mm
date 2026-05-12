#import "Framebuffer.h"
#import "Settings.h"
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <objc/runtime.h>

// ─── Map các format HDR/float sang format nhẹ hơn ─────────────────────────
static MTLPixelFormat DowngradeFormat(MTLPixelFormat fmt) {
    switch (fmt) {
        // HDR / Float formats → BGRA8
        case MTLPixelFormatRGBA16Float:
            NSLog(@"[GameOptimizer] Framebuffer: RGBA16Float → BGRA8Unorm");
            return MTLPixelFormatBGRA8Unorm;

        case MTLPixelFormatRGBA32Float:
            NSLog(@"[GameOptimizer] Framebuffer: RGBA32Float → BGRA8Unorm");
            return MTLPixelFormatBGRA8Unorm;

        case MTLPixelFormatRG11B10Float:
            NSLog(@"[GameOptimizer] Framebuffer: RG11B10Float → BGRA8Unorm");
            return MTLPixelFormatBGRA8Unorm;

        case MTLPixelFormatRGB9E5Float:
            NSLog(@"[GameOptimizer] Framebuffer: RGB9E5Float → BGRA8Unorm");
            return MTLPixelFormatBGRA8Unorm;

        // sRGB → linear BGRA8 nhẹ hơn
        case MTLPixelFormatBGRA8Unorm_sRGB:
            NSLog(@"[GameOptimizer] Framebuffer: BGRA8sRGB → BGRA8Unorm");
            return MTLPixelFormatBGRA8Unorm;

        case MTLPixelFormatRGBA8Unorm_sRGB:
            NSLog(@"[GameOptimizer] Framebuffer: RGBA8sRGB → BGRA8Unorm");
            return MTLPixelFormatBGRA8Unorm;

        // Đã là format nhẹ → giữ nguyên
        default:
            return fmt;
    }
}

// ─── Hook CAMetalLayer pixelFormat ────────────────────────────────────────
@interface CAMetalLayer (FramebufferOpt)
- (void)fb_setPixelFormat:(MTLPixelFormat)format;
@end

@implementation CAMetalLayer (FramebufferOpt)

- (void)fb_setPixelFormat:(MTLPixelFormat)format {
    if ([Settings framebufferOptEnabled]) {
        format = DowngradeFormat(format);
    }
    [self fb_setPixelFormat:format]; // original
}

@end

// ─── Hook MTLRenderPassColorAttachmentDescriptor ──────────────────────────
// Để catch các game set format qua renderPass thay vì CAMetalLayer
@interface NSObject (FramebufferPassOpt)
- (void)fb_setPixelFormatOnAttachment:(MTLPixelFormat)format;
@end

// ─── Hook MTLTextureDescriptor pixelFormat ────────────────────────────────
// Catch các game tạo framebuffer texture thủ công
@interface MTLTextureDescriptor (FramebufferOpt)
- (void)fb_setPixelFormat:(MTLPixelFormat)format;
@end

@implementation MTLTextureDescriptor (FramebufferOpt)

- (void)fb_setPixelFormat:(MTLPixelFormat)format {
    if ([Settings framebufferOptEnabled]) {
        // Chỉ downgrade render target texture, không đụng depth/stencil
        BOOL isDepth = (format == MTLPixelFormatDepth32Float      ||
                        format == MTLPixelFormatDepth16Unorm      ||
                        format == MTLPixelFormatDepth32Float_Stencil8 ||
                        format == MTLPixelFormatStencil8);
        if (!isDepth) {
            format = DowngradeFormat(format);
        }
    }
    [self fb_setPixelFormat:format]; // original
}

@end

// ─── Framebuffer main ─────────────────────────────────────────────────────
@implementation Framebuffer

+ (void)apply {
    BOOL enabled = [Settings framebufferOptEnabled];
    NSLog(@"[GameOptimizer] Framebuffer optimization: %@",
          enabled ? @"ON" : @"OFF");

    if (!enabled) return;

    // Hook CAMetalLayer setPixelFormat
    Class metalLayerClass = NSClassFromString(@"CAMetalLayer");
    if (metalLayerClass) {
        Method orig = class_getInstanceMethod(metalLayerClass,
            @selector(setPixelFormat:));
        Method repl = class_getInstanceMethod(metalLayerClass,
            @selector(fb_setPixelFormat:));
        if (orig && repl) {
            method_exchangeImplementations(orig, repl);
            NSLog(@"[GameOptimizer] Framebuffer: CAMetalLayer hooked");
        }
    }

    // Hook MTLTextureDescriptor setPixelFormat
    Class texDescClass = NSClassFromString(@"MTLTextureDescriptor");
    if (texDescClass) {
        Method orig = class_getInstanceMethod(texDescClass,
            @selector(setPixelFormat:));
        Method repl = class_getInstanceMethod(texDescClass,
            @selector(fb_setPixelFormat:));
        if (orig && repl) {
            method_exchangeImplementations(orig, repl);
            NSLog(@"[GameOptimizer] Framebuffer: MTLTextureDescriptor hooked");
        }
    }

    NSLog(@"[GameOptimizer] Framebuffer hooks installed");
}

@end