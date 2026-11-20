//
//  ROConfig.h
//  RobloxOptimizer
//
//  Crash-resilient configuration and preset management for Roblox iOS Optimizer.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ROPresetMode) {
    ROPresetModePotato = 0,
    ROPresetModeBalanced = 1,
    ROPresetModeManual = 2
};

@interface ROConfig : NSObject

@property (atomic, assign) ROPresetMode presetMode;
@property (atomic, assign) CGFloat resolutionScale;
@property (atomic, assign) BOOL textureClampingEnabled;
@property (atomic, assign) NSUInteger maxTextureDimension;
@property (atomic, assign) BOOL disableShadows;
@property (atomic, assign) BOOL disablePostFX;
@property (atomic, assign) NSInteger targetFPS; // 30, 60, 0 (Unlocked)

+ (instancetype)sharedConfig;

- (void)applyPreset:(ROPresetMode)mode;
- (void)save;
- (void)load;

@end

NS_ASSUME_NONNULL_END
