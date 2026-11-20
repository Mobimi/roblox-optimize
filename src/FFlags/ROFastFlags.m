//
//  ROFastFlags.m
//  RobloxOptimizer
//
//  Automated Roblox ClientAppSettings.json generation and sandbox injection.
//

#import "ROFastFlags.h"
#import "../Config/ROConfig.h"

@implementation ROFastFlags

+ (NSDictionary<NSString *, id> *)currentFlagsDictionary {
    ROConfig *config = [ROConfig sharedConfig];

    NSMutableDictionary<NSString *, id> *flags = [NSMutableDictionary dictionary];

    // Real-time dynamic shadows: 0 turns off shadow map generation
    if (config.disableShadows) {
        flags[@"FIntRenderShadowIntensity"] = @(0);
    } else {
        flags[@"FIntRenderShadowIntensity"] = @(1);
    }

    // Bypass deferred shading for forward rendering pipeline
    flags[@"FFlagDebugDisableDeferredShading"] = @YES;

    // Post-FX passes (Bloom, SunRays, Blur, Depth of Field)
    flags[@"DFFlagDisablePostFx"] = config.disablePostFX ? @YES : @NO;

    // Low graphics override (removes terrain tessellation & reflections)
    flags[@"FIntFRMQualityLevelOverride"] = @(1);

    // Global wind physics simulation loop
    flags[@"FFlagGlobalWindActive"] = @NO;

    // Task scheduler target framerate
    // If targetFPS == 0 (Unlocked), set to 0 (or 240) which uncaps the Roblox task scheduler
    flags[@"DFIntTaskSchedulerTargetFps"] = @(config.targetFPS);

    return [flags copy];
}

+ (NSString *)bundleSettingsPath {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    return [bundlePath stringByAppendingPathComponent:@"ClientSettings/ClientAppSettings.json"];
}

+ (NSString *)documentsSettingsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths.firstObject ?: NSTemporaryDirectory();
    return [documentsPath stringByAppendingPathComponent:@"ClientSettings/ClientAppSettings.json"];
}

+ (NSString *)applicationSupportSettingsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupportPath = paths.firstObject ?: NSTemporaryDirectory();
    return [appSupportPath stringByAppendingPathComponent:@"ClientSettings/ClientAppSettings.json"];
}

+ (BOOL)writeFastFlagsConfigurationWithError:(NSError * _Nullable * _Nullable)error {
    NSDictionary<NSString *, id> *flags = [self currentFlagsDictionary];

    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:flags
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError];
    if (!jsonData) {
        if (error) *error = jsonError;
        NSLog(@"[RobloxOptimizer] Error serializing FastFlags JSON: %@", jsonError);
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL atLeastOneSuccess = NO;
    NSError *lastError = nil;

    NSArray<NSString *> *targetPaths = @[
        [self bundleSettingsPath],
        [self documentsSettingsPath],
        [self applicationSupportSettingsPath]
    ];

    for (NSString *targetPath in targetPaths) {
        NSString *dir = [targetPath stringByDeletingLastPathComponent];
        NSError *dirError = nil;
        if (![fm fileExistsAtPath:dir]) {
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&dirError];
        }

        NSError *writeError = nil;
        BOOL success = [jsonData writeToFile:targetPath options:NSDataWritingAtomic error:&writeError];
        if (success) {
            NSLog(@"[RobloxOptimizer] Successfully wrote ClientAppSettings.json to %@", targetPath);
            atLeastOneSuccess = YES;
        } else {
            lastError = writeError;
            NSLog(@"[RobloxOptimizer] Note: Could not write to %@ (%@)", targetPath, writeError.localizedDescription);
        }
    }

    if (!atLeastOneSuccess && error) {
        *error = lastError;
    }

    return atLeastOneSuccess;
}

@end
