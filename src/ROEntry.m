//
//  ROEntry.m
//  RobloxOptimizer
//
//  Dynamic library constructor entry point.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Config/ROConfig.h"
#import "Hooks/ROMetalHooks.h"
#import "Hooks/ROResolutionHooks.h"
#import "FFlags/ROFastFlags.h"
#import "UI/ROPassThroughWindow.h"

__attribute__((constructor))
static void ROOptimizerEntry(void) {
    NSLog(@"[RobloxOptimizer] Initializing Roblox iOS Optimizer dynamic library...");

    // 1. Initialize & load configuration
    ROConfig *config = [ROConfig sharedConfig];
    NSLog(@"[RobloxOptimizer] Configuration loaded. Preset mode: %ld, Resolution scale: %.2f, Max texture: %lu",
          (long)config.presetMode, (double)config.resolutionScale, (unsigned long)config.maxTextureDimension);

    // 2. Install hooks for Metal and Resolution scaling
    ROInstallMetalHooks();
    ROInstallResolutionHooks();

    // 3. Write FastFlags ClientAppSettings.json
    NSError *error = nil;
    BOOL fflagsWritten = [ROFastFlags writeFastFlagsConfigurationWithError:&error];
    if (fflagsWritten) {
        NSLog(@"[RobloxOptimizer] ClientAppSettings.json FastFlags successfully synchronized.");
    } else {
        NSLog(@"[RobloxOptimizer] Warning: Could not write FastFlags: %@", error);
    }

    // 4. Attach UI overlay once the application has launched and window scene is available
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        ROInitializeUI();
    }];

    // Fallback: in case dylib was loaded after UIApplicationDidFinishLaunchingNotification had fired
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].keyWindow != nil ||
            [UIApplication sharedApplication].windows.count > 0) {
            ROInitializeUI();
        }
    });
}
