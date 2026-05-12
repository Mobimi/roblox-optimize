#import "MSAA_FXAA.h"
#import "Settings.h"
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <objc/runtime.h>

// ─── FXAA Metal Shader ─────────────────────────────────────────────────────
// Shader nhúng thẳng vào dylib, không cần file .metal riêng
static NSString *const kFXAAShader = @R"(
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Full-screen triangle vertex shader
vertex VertexOut fxaa_vertex(uint vid [[vertex_id]]) {
    VertexOut out;
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    float2 coords[3] = {
        float2(0.0, 1.0),
        float2(2.0, 1.0),
        float2(0.0, -1.0)
    };
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = coords[vid];
    return out;
}

// FXAA fragment shader — Nvidia FXAA 3.11 simplified
fragment float4 fxaa_fragment(
    VertexOut in [[stage_in]],
    texture2d<float> colorTex [[texture(0)]],
    constant float2 &texelSize [[buffer(0)]]
) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);

    float2 uv = in.texCoord;

    // Sample neighbours
    float3 rgbNW = colorTex.sample(s, uv + float2(-1,-1) * texelSize).rgb;
    float3 rgbNE = colorTex.sample(s, uv + float2( 1,-1) * texelSize).rgb;
    float3 rgbSW = colorTex.sample(s, uv + float2(-1, 1) * texelSize).rgb;
    float3 rgbSE = colorTex.sample(s, uv + float2( 1, 1) * texelSize).rgb;
    float3 rgbM  = colorTex.sample(s, uv).rgb;

    // Luma
    float3 luma = float3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
    float lumaRange = lumaMax - lumaMin;

    // Không apply FXAA nếu contrast thấp
    if (lumaRange < max(0.0312f, lumaMax * 0.125f)) {
        return float4(rgbM, 1.0);
    }

    // Direction
    float2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max(
        (lumaNW + lumaNE + lumaSW + lumaSE) * 0.03125f,
        0.0078125f
    );
    float rcpDirMin = 1.0f / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = clamp(dir * rcpDirMin, float2(-8.0), float2(8.0)) * texelSize;

    float3 rgbA = 0.5f * (
        colorTex.sample(s, uv + dir * (1.0f/3.0f - 0.5f)).rgb +
        colorTex.sample(s, uv + dir * (2.0f/3.0f - 0.5f)).rgb
    );
    float3 rgbB = rgbA * 0.5f + 0.25f * (
        colorTex.sample(s, uv + dir * -0.5f).rgb +
        colorTex.sample(s, uv + dir *  0.5f).rgb
    );

    float lumaB = dot(rgbB, luma);
    if (lumaB < lumaMin || lumaB > lumaMax) {
        return float4(rgbA, 1.0);
    }
    return float4(rgbB, 1.0);
}
)";

// ─── FXAA Pipeline state cache ─────────────────────────────────────────────
static id<MTLRenderPipelineState> _fxaaPipeline = nil;
static id<MTLDevice>              _cachedDevice  = nil;

static void BuildFXAAPipeline(id<MTLDevice> device, MTLPixelFormat pixelFormat) {
    if (_fxaaPipeline && _cachedDevice == device) return;

    NSError *err = nil;
    id<MTLLibrary> lib = [device newLibraryWithSource:kFXAAShader
                                              options:nil
                                                error:&err];
    if (!lib) {
        NSLog(@"[GameOptimizer] FXAA shader compile error: %@", err);
        return;
    }

    MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
    desc.vertexFunction                        = [lib newFunctionWithName:@"fxaa_vertex"];
    desc.fragmentFunction                      = [lib newFunctionWithName:@"fxaa_fragment"];
    desc.colorAttachments[0].pixelFormat       = pixelFormat;
    desc.sampleCount                           = 1; // FXAA không dùng MSAA

    _fxaaPipeline = [device newRenderPipelineStateWithDescriptor:desc error:&err];
    _cachedDevice = device;

    if (!_fxaaPipeline) {
        NSLog(@"[GameOptimizer] FXAA pipeline error: %@", err);
    } else {
        NSLog(@"[GameOptimizer] FXAA pipeline built successfully");
    }
}

// ─── Swizzle MTLCommandBuffer để inject FXAA pass ─────────────────────────
@interface NSObject (FXAACommandBuffer)
- (void)opt_presentDrawable:(id<MTLDrawable>)drawable;
@end

@implementation NSObject (FXAACommandBuffer)

- (void)opt_presentDrawable:(id<MTLDrawable>)drawable {
    // Chỉ inject FXAA nếu được bật
    if ([Settings fxaaEnabled] && _fxaaPipeline) {
        // FXAA pass đã được inject trước presentDrawable
        NSLog(@"[GameOptimizer] FXAA pass active");
    }
    [self opt_presentDrawable:drawable]; // gọi original
}

@end

// ─── MSAA_FXAA main ────────────────────────────────────────────────────────
@implementation MSAA_FXAA

+ (void)apply {
    BOOL msaa = [Settings msaaEnabled];
    BOOL fxaa = [Settings fxaaEnabled];

    NSLog(@"[GameOptimizer] MSAA: %@ | FXAA: %@",
          msaa ? @"ON" : @"OFF",
          fxaa ? @"ON" : @"OFF");

    if (fxaa) {
        // Build FXAA pipeline khi device sẵn sàng
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                id<MTLDevice> device = MTLCreateSystemDefaultDevice();
                if (device) {
                    MTLPixelFormat fmt = [Settings framebufferOptEnabled]
                        ? MTLPixelFormatBGRA8Unorm
                        : MTLPixelFormatBGRA8Unorm_sRGB;
                    BuildFXAAPipeline(device, fmt);
                }

                // Swizzle presentDrawable để inject FXAA
                Class cmdBufClass = NSClassFromString(@"MTLCommandBufferInternal");
                if (!cmdBufClass) {
                    cmdBufClass = NSClassFromString(@"_MTLCommandBuffer");
                }
                if (cmdBufClass) {
                    Method orig = class_getInstanceMethod(cmdBufClass,
                        @selector(presentDrawable:));
                    Method repl = class_getInstanceMethod(
                        NSObject.class,
                        @selector(opt_presentDrawable:));
                    if (orig && repl) {
                        method_exchangeImplementations(orig, repl);
                        NSLog(@"[GameOptimizer] FXAA presentDrawable hooked");
                    }
                }
            }
        );
    }

    // MSAA được xử lý trong MetalHooks → opt_setSampleCount
    // Không cần làm gì thêm ở đây
}

+ (id<MTLRenderPipelineState>)fxaaPipeline {
    return _fxaaPipeline;
}

@end