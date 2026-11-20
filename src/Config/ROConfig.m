//
//  ROConfig.m
//  RobloxOptimizer
//
//  Crash-resilient configuration and preset management for Roblox iOS Optimizer.
//

#import "ROConfig.h"

static NSString * const kROConfigInitializedKey        = @"RO_ConfigInitialized";
static NSString * const kROConfigPresetModeKey          = @"RO_PresetMode";
static NSString * const kROConfigResolutionScaleKey     = @"RO_ResolutionScale";
static NSString * const kROConfigTextureClampingKey     = @"RO_TextureClamping";
static NSString * const kROConfigMaxTextureDimensionKey = @"RO_MaxTextureDimension";
static NSString * const kROConfigDisableShadowsKey      = @"RO_DisableShadows";
static NSString * const kROConfigDisablePostFXKey       = @"RO_DisablePostFX";
static NSString * const kROConfigTargetFPSKey           = @"RO_TargetFPS";

@implementation ROConfig

+ (instancetype)sharedConfig {
    static ROConfig *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ROConfig alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self load];
    }
    return self;
}

- (void)applyPreset:(ROPresetMode)mode {
    @synchronized(self) {
        _presetMode = mode;
        switch (mode) {
            case ROPresetModePotato:
                _resolutionScale = 0.50f;
                _textureClampingEnabled = YES;
                _maxTextureDimension = 256;
                _disableShadows = YES;
                _disablePostFX = YES;
                _targetFPS = 60;
                break;

            case ROPresetModeBalanced:
                _resolutionScale = 1.0f;
                _textureClampingEnabled = YES;
                _maxTextureDimension = 512;
                _disableShadows = YES;
                _disablePostFX = NO;
                _targetFPS = 60;
                break;

            case ROPresetModeManual:
                // In manual mode, validate existing bounds without overwriting custom choices
                if (_resolutionScale < 0.25f || _resolutionScale > 3.0f) {
                    _resolutionScale = 1.0f;
                }
                if (_maxTextureDimension == 0) {
                    _maxTextureDimension = 512;
                }
                if (_targetFPS != 30 && _targetFPS != 60 && _targetFPS != 0) {
                    _targetFPS = 60;
                }
                break;
        }
    }
}

- (void)load {
    @synchronized(self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:kROConfigInitializedKey]) {
            // First run defaults: Balanced mode
            [self applyPreset:ROPresetModeBalanced];
            [self save];
            return;
        }

        _presetMode = (ROPresetMode)[defaults integerForKey:kROConfigPresetModeKey];
        _resolutionScale = (CGFloat)[defaults doubleForKey:kROConfigResolutionScaleKey];
        _textureClampingEnabled = [defaults boolForKey:kROConfigTextureClampingKey];
        _maxTextureDimension = (NSUInteger)[defaults integerForKey:kROConfigMaxTextureDimensionKey];
        _disableShadows = [defaults boolForKey:kROConfigDisableShadowsKey];
        _disablePostFX = [defaults boolForKey:kROConfigDisablePostFXKey];
        _targetFPS = [defaults integerForKey:kROConfigTargetFPSKey];

        // Ensure sanity of loaded properties
        if (_presetMode == ROPresetModePotato || _presetMode == ROPresetModeBalanced) {
            // Re-enforce preset values in case defaults were corrupted
            [self applyPreset:_presetMode];
        } else {
            if (_resolutionScale < 0.25f || _resolutionScale > 3.0f) {
                _resolutionScale = 1.0f;
            }
            if (_maxTextureDimension == 0) {
                _maxTextureDimension = 512;
            }
            if (_targetFPS != 30 && _targetFPS != 60 && _targetFPS != 0) {
                _targetFPS = 60;
            }
        }
    }
}

- (void)save {
    @synchronized(self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:kROConfigInitializedKey];
        [defaults setInteger:(NSInteger)_presetMode forKey:kROConfigPresetModeKey];
        [defaults setDouble:(double)_resolutionScale forKey:kROConfigResolutionScaleKey];
        [defaults setBool:_textureClampingEnabled forKey:kROConfigTextureClampingKey];
        [defaults setInteger:(NSInteger)_maxTextureDimension forKey:kROConfigMaxTextureDimensionKey];
        [defaults setBool:_disableShadows forKey:kROConfigDisableShadowsKey];
        [defaults setBool:_disablePostFX forKey:kROConfigDisablePostFXKey];
        [defaults setInteger:_targetFPS forKey:kROConfigTargetFPSKey];
        [defaults synchronize];
    }
}

@end
