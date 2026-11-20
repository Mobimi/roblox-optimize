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

@property (nonatomic, assign) ROPresetMode presetMode;
@property (nonatomic, assign) CGFloat resolutionScale;
@property (nonatomic, assign) BOOL textureClampingEnabled;
@property (nonatomic, assign) NSUInteger maxTextureDimension;
@property (nonatomic, assign) BOOL disableShadows;
@property (nonatomic, assign) BOOL disablePostFX;
@property (nonatomic, assign) NSInteger targetFPS; // 30, 60, 0 (Unlocked)

+ (instancetype)sharedConfig;

- (void)applyPreset:(ROPresetMode)mode;
- (void)save;
- (void)load;

@end

NS_ASSUME_NONNULL_END
