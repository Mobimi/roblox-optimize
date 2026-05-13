#import "MetalFX.h"
#import "Settings.h"
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ─── MetalFX framework load động ──────────────────────────────────────────
static Class  _spatialScalerDescClass = nil;
static Class  _spatialScalerClass     = nil;
static BOOL   _metalFXAvailable       = NO;

static void LoadMetalFXClasses(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSBundle *metalFXBundle = [NSBundle bundleWithPath:
            @"/System/Library/Frameworks/MetalFX.framework"];
        if ([metalFXBundle load]) {
            _spatialScalerDescClass = NSClassFromString(
                @"MTLFXSpatialScalerDescriptor");
            _spatialScalerClass = NSClassFromString(
                @"MTLFXSpatialScaler");
            _metalFXAvailable = (_spatialScalerDescClass != nil);
            NSLog(@"[GameOptimizer] MetalFX available: %@",
                  _metalFXAvailable ? @"YES" : @"NO");
        } else {
            NSLog(@"[GameOptimizer] MetalFX framework not available on this iOS");
        }
    });
}

// ─── Input/Output resolution theo quality ─────────────────────────────────
static float GetInputScale(MetalFXQuality quality) {
    switch (quality) {
        case MetalFXQualityPerformance: return 0.5f;
        case MetalFXQualityBalanced:    return 0.667f;
        case MetalFXQualityQuality:     return 0.77f;
        default:                        return 0.667f;
    }
}

// ─── MetalFX Scaler state ──────────────────────────────────────────────────
static id             _spatialScaler  = nil;
static id<MTLTexture> _inputTexture   = nil;
static id<MTLTexture> _outputTexture  = nil;
static id<MTLDevice>  _metalFXDevice  = nil;

static BOOL BuildSpatialScaler(id<MTLDevice> device) {
    if (!_metalFXAvailable) return NO;
    if (_spatialScaler && _metalFXDevice == device) return YES;

    MetalFXQuality quality   = [Settings metalFXQuality];
    float inputScale         = GetInputScale(quality);
    float renderScale        = [Settings renderScale];

    // Lấy screen size qua UIWindowScene thay vì UIScreen deprecated
    CGSize screenSize = CGSizeMake(390, 844); // fallback iPhone 12 Pro Max
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            screenSize = ws.screen.bounds.size;
            break;
        }
    }

    NSUInteger outW = (NSUInteger)(screenSize.width  * renderScale);
    NSUInteger outH = (NSUInteger)(screenSize.height * renderScale);
    NSUInteger inW  = (NSUInteger)(outW * inputScale);
    NSUInteger inH  = (NSUInteger)(outH * inputScale);

    // Build descriptor qua runtime
    id desc = [_spatialScalerDescClass new];
    if (!desc) return NO;

    [desc setValue:@(inW)  forKey:@"inputWidth"];
    [desc setValue:@(inH)  forKey:@"inputHeight"];
    [desc setValue:@(outW) forKey:@"outputWidth"];
    [desc setValue:@(outH) forKey:@"outputHeight"];
    [desc setValue:@(MTLPixelFormatBGRA8Unorm) forKey:@"colorTextureFormat"];
    [desc setValue:@(MTLPixelFormatBGRA8Unorm) forKey:@"outputTextureFormat"];

    // Tạo scaler qua performSelector thay vì direct call
    SEL scalerSel = NSSelectorFromString(@"newSpatialScalerWithDevice:");
    if (![desc respondsToSelector:scalerSel]) {
        NSLog(@"[GameOptimizer] MetalFX: newSpatialScalerWithDevice not found");
        return NO;
    }
    _spatialScaler = ((id(*)(id,SEL,id))objc_msgSend)(desc, scalerSel, device);
    if (!_spatialScaler) {
        NSLog(@"[GameOptimizer] MetalFX: Failed to create spatial scaler");
        return NO;
    }

    // Input texture
    MTLTextureDescriptor *inDesc = [MTLTextureDescriptor
        texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
        width:inW height:inH mipmapped:NO];
    inDesc.usage       = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    inDesc.storageMode = MTLStorageModePrivate;
    _inputTexture      = [device newTextureWithDescriptor:inDesc];

    // Output texture
    MTLTextureDescriptor *outDesc = [MTLTextureDescriptor
        texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
        width:outW height:outH mipmapped:NO];
    outDesc.usage       = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    outDesc.storageMode = MTLStorageModePrivate;
    _outputTexture      = [device newTextureWithDescriptor:outDesc];

    _metalFXDevice = device;

    NSLog(@"[GameOptimizer] MetalFX Spatial Scaler built: %lux%lu → %lux%lu (%@)",
          (unsigned long)inW, (unsigned long)inH,
          (unsigned long)outW, (unsigned long)outH,
          quality == MetalFXQualityPerformance ? @"Performance" :
          quality == MetalFXQualityBalanced    ? @"Balanced"    : @"Quality");

    return YES;
}

// ─── Hook MTLCommandBuffer để inject upscale pass ─────────────────────────
@interface NSObject (MetalFXHook)
- (void)mfx_presentDrawable:(id<MTLDrawable>)drawable;
@end

@implementation NSObject (MetalFXHook)

- (void)mfx_presentDrawable:(id<MTLDrawable>)drawable {
    if ([Settings metalFXEnabled] && _spatialScaler && _outputTexture) {
        @try {
            [_spatialScaler setValue:_inputTexture  forKey:@"colorTexture"];
            [_spatialScaler setValue:_outputTexture forKey:@"outputTexture"];

            SEL encodeSel = NSSelectorFromString(@"encodeToCommandBuffer:");
            if ([_spatialScaler respondsToSelector:encodeSel]) {
                ((void(*)(id,SEL,id))objc_msgSend)(
                    _spatialScaler, encodeSel, self);
            }
        } @catch (NSException *e) {
            NSLog(@"[GameOptimizer] MetalFX encode error: %@", e);
        }
    }
    [self mfx_presentDrawable:drawable];
}

@end

// ─── MetalFXModule main ────────────────────────────────────────────────────
@implementation MetalFXModule

+ (void)apply {
    BOOL enabled = [Settings metalFXEnabled];
    NSLog(@"[GameOptimizer] MetalFX: %@", enabled ? @"ON" : @"OFF");

    if (!enabled) return;

    LoadMetalFXClasses();

    if (!_metalFXAvailable) {
        NSLog(@"[GameOptimizer] MetalFX not available — skipping");
        return;
    }

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            id<MTLDevice> device = MTLCreateSystemDefaultDevice();
            if (!device) return;

            if (!BuildSpatialScaler(device)) return;

            NSArray *classNames = @[
                @"_MTLCommandBuffer",
                @"MTLCommandBufferInternal",
                @"AGXCommandBuffer",
                @"AGXA14FamilyCommandBuffer"
            ];

            for (NSString *name in classNames) {
                Class cls = NSClassFromString(name);
                if (!cls) continue;

                Method orig = class_getInstanceMethod(cls,
                    @selector(presentDrawable:));
                Method repl = class_getInstanceMethod(NSObject.class,
                    @selector(mfx_presentDrawable:));

                if (orig && repl) {
                    method_exchangeImplementations(orig, repl);
                    NSLog(@"[GameOptimizer] MetalFX hooked on: %@", name);
                    break;
                }
            }
        }
    );
}

@end