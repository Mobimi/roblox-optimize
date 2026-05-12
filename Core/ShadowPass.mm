#import "ShadowPass.h"
#import "Settings.h"
#import <Metal/Metal.h>
#import <objc/runtime.h>

// ─── Heuristic nhận diện shadow pass ──────────────────────────────────────
// Shadow map thường có đặc điểm:
// 1. Chỉ có depth attachment, không có color attachment
// 2. Texture nhỏ hơn màn hình (512x512, 1024x1024, 2048x2048)
// 3. PixelFormat là Depth32Float hoặc Depth16Unorm

static BOOL IsShadowPass(MTLRenderPassDescriptor *desc) {
    if (!desc) return NO;

    // Kiểm tra không có color attachment
    BOOL hasColor = NO;
    for (int i = 0; i < 8; i++) {
        MTLRenderPassColorAttachmentDescriptor *att = desc.colorAttachments[i];
        if (att && att.texture) {
            hasColor = YES;
            break;
        }
    }

    // Có depth attachment
    BOOL hasDepth = (desc.depthAttachment && desc.depthAttachment.texture);

    if (!hasDepth) return NO;

    // Shadow pass thường không có color, chỉ có depth
    if (!hasColor && hasDepth) {
        id<MTLTexture> depthTex = desc.depthAttachment.texture;
        MTLPixelFormat fmt = depthTex.pixelFormat;

        // Depth-only format → shadow map
        if (fmt == MTLPixelFormatDepth32Float      ||
            fmt == MTLPixelFormatDepth16Unorm      ||
            fmt == MTLPixelFormatDepth32Float_Stencil8) {

            NSUInteger w = depthTex.width;
            NSUInteger h = depthTex.height;

            // Shadow map thường vuông và nhỏ hơn hoặc bằng 4096
            if (w == h && w <= 4096) {
                NSLog(@"[GameOptimizer] Shadow pass detected: %lux%lu fmt:%lu",
                      (unsigned long)w, (unsigned long)h, (unsigned long)fmt);
                return YES;
            }
        }
    }

    return NO;
}

// ─── Skip shadow pass bằng cách redirect sang dummy texture ───────────────
static id<MTLTexture> _dummyDepthTexture = nil;

static id<MTLTexture> GetDummyDepthTexture(id<MTLDevice> device, NSUInteger size) {
    if (_dummyDepthTexture &&
        _dummyDepthTexture.width == size) {
        return _dummyDepthTexture;
    }

    MTLTextureDescriptor *desc = [MTLTextureDescriptor
        texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
        width:size
        height:size
        mipmapped:NO];
    desc.usage        = MTLTextureUsageRenderTarget;
    desc.storageMode  = MTLStorageModePrivate;

    _dummyDepthTexture = [device newTextureWithDescriptor:desc];
    NSLog(@"[GameOptimizer] Dummy depth texture created: %lux%lu",
          (unsigned long)size, (unsigned long)size);
    return _dummyDepthTexture;
}

// ─── Swizzle newRenderCommandEncoderWithDescriptor ────────────────────────
@interface NSObject (ShadowPassHook)
- (id)opt_newRenderCommandEncoderWithDescriptor:(MTLRenderPassDescriptor *)desc;
@end

@implementation NSObject (ShadowPassHook)

- (id)opt_newRenderCommandEncoderWithDescriptor:(MTLRenderPassDescriptor *)desc {
    if (![Settings shadowEnabled] && IsShadowPass(desc)) {
        // Redirect depth attachment sang dummy texture → shadow pass bị skip
        id<MTLDevice> device = [self valueForKey:@"device"];
        if (device && desc.depthAttachment.texture) {
            NSUInteger size = desc.depthAttachment.texture.width;
            id<MTLTexture> dummy = GetDummyDepthTexture(device, size);
            if (dummy) {
                desc.depthAttachment.texture     = dummy;
                desc.depthAttachment.loadAction  = MTLLoadActionDontCare;
                desc.depthAttachment.storeAction = MTLStoreActionDontCare;
                NSLog(@"[GameOptimizer] Shadow pass skipped → dummy texture");
            }
        }
    }
    return [self opt_newRenderCommandEncoderWithDescriptor:desc];
}

@end

// ─── ShadowPass main ───────────────────────────────────────────────────────
@implementation ShadowPass

+ (void)apply {
    BOOL shadowOn = [Settings shadowEnabled];
    NSLog(@"[GameOptimizer] Shadow: %@", shadowOn ? @"ON" : @"OFF");

    if (!shadowOn) {
        // Hook newRenderCommandEncoderWithDescriptor trên MTLCommandBuffer
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                // Thử các tên internal class của MTLCommandBuffer
                NSArray *classNames = @[
                    @"_MTLCommandBuffer",
                    @"MTLCommandBufferInternal",
                    @"AGXCommandBuffer",
                    @"AGXA14FamilyCommandBuffer"  // A14 specific
                ];

                for (NSString *name in classNames) {
                    Class cls = NSClassFromString(name);
                    if (!cls) continue;

                    Method orig = class_getInstanceMethod(cls,
                        @selector(newRenderCommandEncoderWithDescriptor:));
                    Method repl = class_getInstanceMethod(NSObject.class,
                        @selector(opt_newRenderCommandEncoderWithDescriptor:));

                    if (orig && repl) {
                        method_exchangeImplementations(orig, repl);
                        NSLog(@"[GameOptimizer] ShadowPass hooked on: %@", name);
                        break;
                    }
                }
            }
        );
    }
}

// Được gọi từ MetalHooks → renderPassDescriptor
+ (void)processDescriptor:(MTLRenderPassDescriptor *)descriptor {
    if (!descriptor) return;
    if (![Settings shadowEnabled] && IsShadowPass(descriptor)) {
        descriptor.depthAttachment.loadAction  = MTLLoadActionDontCare;
        descriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
        NSLog(@"[GameOptimizer] ShadowPass: descriptor cleared");
    }
}

@end