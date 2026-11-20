//
//  ROMetalHooks.h
//  RobloxOptimizer
//
//  Crash-resilient Metal texture clamping hook to eliminate iOS Jetsam OOM crashes.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

void ROInstallMetalHooks(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
