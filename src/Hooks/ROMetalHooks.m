//
//  ROMetalHooks.m
//  RobloxOptimizer
//
//  Crash-resilient Metal texture clamping hook to eliminate iOS Jetsam OOM crashes.
//

#import "ROMetalHooks.h"
#import "../Config/ROConfig.h"
#import <Metal/Metal.h>
#import <objc/runtime.h>
#import <math.h>

static id<MTLTexture> (*orig_newTextureWithDescriptor)(id self, SEL _cmd, MTLTextureDescriptor *descriptor) = NULL;

static inline BOOL ROIsDepthOrStencilPixelFormat(MTLPixelFormat format) {
    switch (format) {
        case MTLPixelFormatDepth16Unorm:
        case MTLPixelFormatDepth32Float:
        case MTLPixelFormatStencil8:
        case MTLPixelFormatDepth24Unorm_Stencil8:
        case MTLPixelFormatDepth32Float_Stencil8:
        case MTLPixelFormatX32_Stencil8:
        case MTLPixelFormatX24_Stencil8:
            return YES;
        default:
            return NO;
    }
}

static inline BOOL ROIsClampableTextureType(MTLTextureType type) {
    switch (type) {
        case MTLTextureType2D:
        case MTLTextureType2DMultisample:
        case MTLTextureTypeCube:
        case MTLTextureType2DArray:
        case MTLTextureType3D:
            return YES;
        default:
            return NO;
    }
}

static id<MTLTexture> hooked_newTextureWithDescriptor(id self, SEL _cmd, MTLTextureDescriptor *descriptor) {
    if (!descriptor || !orig_newTextureWithDescriptor) {
        return nil;
    }

    // Safety guard 1: Never clamp render targets to prevent viewport distortion & assertion crashes
    if ((descriptor.usage & MTLTextureUsageRenderTarget) != 0) {
        return orig_newTextureWithDescriptor(self, _cmd, descriptor);
    }

    // Safety guard 2: Never modify depth or stencil textures
    if (ROIsDepthOrStencilPixelFormat(descriptor.pixelFormat)) {
        return orig_newTextureWithDescriptor(self, _cmd, descriptor);
    }

    // Safety guard 3: Never modify texture buffers or non-2D/3D surface types
    if (!ROIsClampableTextureType(descriptor.textureType)) {
        return orig_newTextureWithDescriptor(self, _cmd, descriptor);
    }

    // Safety guard 4: Guard against zero dimensions
    if (descriptor.width == 0 || descriptor.height == 0) {
        return orig_newTextureWithDescriptor(self, _cmd, descriptor);
    }

    ROConfig *config = [ROConfig sharedConfig];
    if (!config.textureClampingEnabled) {
        return orig_newTextureWithDescriptor(self, _cmd, descriptor);
    }

    NSUInteger maxAllowed = config.maxTextureDimension;
    if (maxAllowed == 0) {
        maxAllowed = 512;
    }

    NSUInteger maxDim = MAX(descriptor.width, descriptor.height);
    if (maxDim <= maxAllowed) {
        return orig_newTextureWithDescriptor(self, _cmd, descriptor);
    }

    // Dimension clamping preserving original aspect ratio
    double scale = (double)maxAllowed / (double)maxDim;
    NSUInteger clampedW = MAX((NSUInteger)1, (NSUInteger)floor((double)descriptor.width * scale));
    NSUInteger clampedH = MAX((NSUInteger)1, (NSUInteger)floor((double)descriptor.height * scale));

    MTLTextureDescriptor *clampedDesc = [descriptor copy];
    clampedDesc.width = clampedW;
    clampedDesc.height = clampedH;

    // CRITICAL: Recalculate mipmapLevelCount to prevent fatal Metal driver assertion crashes
    NSUInteger maxAllowedMips = (NSUInteger)floor(log2((double)MAX(clampedW, clampedH))) + 1;
    clampedDesc.mipmapLevelCount = MIN(descriptor.mipmapLevelCount, maxAllowedMips);

    id<MTLTexture> texture = orig_newTextureWithDescriptor(self, _cmd, clampedDesc);
    if (!texture) {
        // Fallback to original descriptor if allocation fails
        texture = orig_newTextureWithDescriptor(self, _cmd, descriptor);
    }

    return texture;
}

void ROInstallMetalHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            NSLog(@"[RobloxOptimizer] Warning: Default MTLDevice not found during hook installation.");
            return;
        }

        Class deviceClass = [device class];
        Method method = class_getInstanceMethod(deviceClass, @selector(newTextureWithDescriptor:));
        if (method) {
            orig_newTextureWithDescriptor = (id<MTLTexture>(*)(id, SEL, MTLTextureDescriptor *))method_getImplementation(method);
            method_setImplementation(method, (IMP)hooked_newTextureWithDescriptor);
            NSLog(@"[RobloxOptimizer] Installed Metal texture clamping hook on %@", NSStringFromClass(deviceClass));
        } else {
            NSLog(@"[RobloxOptimizer] Error: Method newTextureWithDescriptor: not found on %@", NSStringFromClass(deviceClass));
        }
    });
}
