#pragma once
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MetalFXQuality) {
    MetalFXQualityPerformance = 0,
    MetalFXQualityBalanced    = 1,
    MetalFXQualityQuality     = 2,
};

@interface Settings : NSObject

// Load & Save
+ (void)load;
+ (void)save;

// Render Scale — default 3.0
+ (float)renderScale;
+ (void)setRenderScale:(float)scale;

// MSAA — default OFF
+ (BOOL)msaaEnabled;
+ (void)setMsaaEnabled:(BOOL)enabled;

// FXAA — default OFF
+ (BOOL)fxaaEnabled;
+ (void)setFxaaEnabled:(BOOL)enabled;

// FPS Cap — default 60
+ (NSInteger)fpsCap;
+ (void)setFpsCap:(NSInteger)fps;

// Framebuffer Optimization — default ON
+ (BOOL)framebufferOptEnabled;
+ (void)setFramebufferOptEnabled:(BOOL)enabled;

// Shadow — default ON (tức là tắt shadow mặc định bật = tắt shadow)
+ (BOOL)shadowEnabled;
+ (void)setShadowEnabled:(BOOL)enabled;

// MetalFX — default Balanced
+ (BOOL)metalFXEnabled;
+ (void)setMetalFXEnabled:(BOOL)enabled;
+ (MetalFXQuality)metalFXQuality;
+ (void)setMetalFXQuality:(MetalFXQuality)quality;

// Thread Boost — default ON
+ (BOOL)threadBoostEnabled;
+ (void)setThreadBoostEnabled:(BOOL)enabled;

// Cần restart để apply không
+ (BOOL)needsRestart;
+ (void)setNeedsRestart:(BOOL)needs;

@end