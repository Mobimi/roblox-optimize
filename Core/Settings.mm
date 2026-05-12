#import "Settings.h"

// ─── Keys ──────────────────────────────────────────────────────────────────
static NSString *const kSuite           = @"com.gameoptimizer.settings";
static NSString *const kRenderScale     = @"renderScale";
static NSString *const kMSAA            = @"msaaEnabled";
static NSString *const kFXAA            = @"fxaaEnabled";
static NSString *const kFPSCap          = @"fpsCap";
static NSString *const kFramebuffer     = @"framebufferOptEnabled";
static NSString *const kShadow          = @"shadowEnabled";
static NSString *const kMetalFX         = @"metalFXEnabled";
static NSString *const kMetalFXQuality  = @"metalFXQuality";
static NSString *const kThreadBoost     = @"threadBoostEnabled";
static NSString *const kNeedsRestart    = @"needsRestart";

// ─── In-memory cache ───────────────────────────────────────────────────────
static float        _renderScale        = 3.0f;
static BOOL         _msaaEnabled        = NO;
static BOOL         _fxaaEnabled        = NO;
static NSInteger    _fpsCap             = 60;
static BOOL         _framebufferOpt     = YES;
static BOOL         _shadowEnabled      = YES;
static BOOL         _metalFXEnabled     = YES;
static MetalFXQuality _metalFXQuality   = MetalFXQualityBalanced;
static BOOL         _threadBoost        = YES;
static BOOL         _needsRestart       = NO;

@implementation Settings

+ (NSUserDefaults *)defaults {
    return [[NSUserDefaults alloc] initWithSuiteName:kSuite];
}

// ─── Load ──────────────────────────────────────────────────────────────────
+ (void)load {
    NSUserDefaults *d = [self defaults];

    // Nếu chưa có key thì dùng default, không ghi đè
    if ([d objectForKey:kRenderScale])
        _renderScale = [d floatForKey:kRenderScale];

    if ([d objectForKey:kMSAA])
        _msaaEnabled = [d boolForKey:kMSAA];

    if ([d objectForKey:kFXAA])
        _fxaaEnabled = [d boolForKey:kFXAA];

    if ([d objectForKey:kFPSCap])
        _fpsCap = [d integerForKey:kFPSCap];

    if ([d objectForKey:kFramebuffer])
        _framebufferOpt = [d boolForKey:kFramebuffer];

    if ([d objectForKey:kShadow])
        _shadowEnabled = [d boolForKey:kShadow];

    if ([d objectForKey:kMetalFX])
        _metalFXEnabled = [d boolForKey:kMetalFX];

    if ([d objectForKey:kMetalFXQuality])
        _metalFXQuality = (MetalFXQuality)[d integerForKey:kMetalFXQuality];

    if ([d objectForKey:kThreadBoost])
        _threadBoost = [d boolForKey:kThreadBoost];

    _needsRestart = NO;

    NSLog(@"[GameOptimizer] Settings loaded");
}

// ─── Save ──────────────────────────────────────────────────────────────────
+ (void)save {
    NSUserDefaults *d = [self defaults];
    [d setFloat:_renderScale        forKey:kRenderScale];
    [d setBool:_msaaEnabled         forKey:kMSAA];
    [d setBool:_fxaaEnabled         forKey:kFXAA];
    [d setInteger:_fpsCap           forKey:kFPSCap];
    [d setBool:_framebufferOpt      forKey:kFramebuffer];
    [d setBool:_shadowEnabled       forKey:kShadow];
    [d setBool:_metalFXEnabled      forKey:kMetalFX];
    [d setInteger:_metalFXQuality   forKey:kMetalFXQuality];
    [d setBool:_threadBoost         forKey:kThreadBoost];
    [d synchronize];
    NSLog(@"[GameOptimizer] Settings saved");
}

// ─── Getters / Setters ─────────────────────────────────────────────────────
+ (float)renderScale                        { return _renderScale; }
+ (void)setRenderScale:(float)v             { _renderScale = MAX(1.0f, MIN(3.0f, v)); }

+ (BOOL)msaaEnabled                         { return _msaaEnabled; }
+ (void)setMsaaEnabled:(BOOL)v              { _msaaEnabled = v; }

+ (BOOL)fxaaEnabled                         { return _fxaaEnabled; }
+ (void)setFxaaEnabled:(BOOL)v              { _fxaaEnabled = v; }

+ (NSInteger)fpsCap                         { return _fpsCap; }
+ (void)setFpsCap:(NSInteger)v              {
    // Chỉ chấp nhận 30, 60, 120
    if (v == 30 || v == 60 || v == 120) _fpsCap = v;
}

+ (BOOL)framebufferOptEnabled               { return _framebufferOpt; }
+ (void)setFramebufferOptEnabled:(BOOL)v    { _framebufferOpt = v; }

+ (BOOL)shadowEnabled                       { return _shadowEnabled; }
+ (void)setShadowEnabled:(BOOL)v            { _shadowEnabled = v; }

+ (BOOL)metalFXEnabled                      { return _metalFXEnabled; }
+ (void)setMetalFXEnabled:(BOOL)v           { _metalFXEnabled = v; }

+ (MetalFXQuality)metalFXQuality            { return _metalFXQuality; }
+ (void)setMetalFXQuality:(MetalFXQuality)v { _metalFXQuality = v; }

+ (BOOL)threadBoostEnabled                  { return _threadBoost; }
+ (void)setThreadBoostEnabled:(BOOL)v       { _threadBoost = v; }

+ (BOOL)needsRestart                        { return _needsRestart; }
+ (void)setNeedsRestart:(BOOL)v             { _needsRestart = v; }

@end