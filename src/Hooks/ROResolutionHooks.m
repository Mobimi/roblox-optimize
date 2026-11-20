//
//  ROResolutionHooks.m
//  RobloxOptimizer
//
//  Dynamic resolution scaling hook for CAMetalLayer and MTKView.
//

#import "ROResolutionHooks.h"
#import "../Config/ROConfig.h"
#import <QuartzCore/CAMetalLayer.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <math.h>

static void (*orig_setDrawableSize)(id self, SEL _cmd, CGSize size) = NULL;
static void (*orig_setContentsScale)(id self, SEL _cmd, CGFloat scale) = NULL;
static void (*orig_setContentScaleFactor)(id self, SEL _cmd, CGFloat factor) = NULL;

static void hooked_setDrawableSize(CAMetalLayer *self, SEL _cmd, CGSize size) {
    if (!orig_setDrawableSize) return;

    ROConfig *config = [ROConfig sharedConfig];
    CGFloat scale = config.resolutionScale;

    if (scale > 0.05 && fabs(scale - 1.0) > 0.001 && size.width > 0 && size.height > 0) {
        CGSize scaledSize = CGSizeMake(MAX(1.0, round(size.width * scale)),
                                       MAX(1.0, round(size.height * scale)));
        orig_setDrawableSize(self, _cmd, scaledSize);
        return;
    }

    orig_setDrawableSize(self, _cmd, size);
}

static void hooked_setContentsScale(CAMetalLayer *self, SEL _cmd, CGFloat contentsScale) {
    if (!orig_setContentsScale) return;

    ROConfig *config = [ROConfig sharedConfig];
    CGFloat scale = config.resolutionScale;

    if (scale > 0.05 && fabs(scale - 1.0) > 0.001 && contentsScale > 0.01) {
        CGFloat scaled = MAX(0.25, contentsScale * scale);
        orig_setContentsScale(self, _cmd, scaled);
        return;
    }

    orig_setContentsScale(self, _cmd, contentsScale);
}

static void hooked_setContentScaleFactor(UIView *self, SEL _cmd, CGFloat factor) {
    if (!orig_setContentScaleFactor) return;

    // Only apply scale override to Metal-backed views (CAMetalLayer or MTKView)
    // so that UIKit controls, text fields, and overlays remain crisp
    BOOL isMetalView = NO;
    if ([self.layer isKindOfClass:[CAMetalLayer class]]) {
        isMetalView = YES;
    } else {
        Class mtkViewClass = NSClassFromString(@"MTKView");
        if (mtkViewClass && [self isKindOfClass:mtkViewClass]) {
            isMetalView = YES;
        }
    }

    if (isMetalView) {
        ROConfig *config = [ROConfig sharedConfig];
        CGFloat scale = config.resolutionScale;
        if (scale > 0.05 && fabs(scale - 1.0) > 0.001 && factor > 0.01) {
            CGFloat scaledFactor = MAX(0.25, factor * scale);
            orig_setContentScaleFactor(self, _cmd, scaledFactor);
            return;
        }
    }

    orig_setContentScaleFactor(self, _cmd, factor);
}

void ROInstallResolutionHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class metalLayerClass = [CAMetalLayer class];
        if (metalLayerClass) {
            Method mDrawable = class_getInstanceMethod(metalLayerClass, @selector(setDrawableSize:));
            if (mDrawable) {
                orig_setDrawableSize = (void (*)(id, SEL, CGSize))method_getImplementation(mDrawable);
                method_setImplementation(mDrawable, (IMP)hooked_setDrawableSize);
            }

            Method mScale = class_getInstanceMethod(metalLayerClass, @selector(setContentsScale:));
            if (mScale) {
                orig_setContentsScale = (void (*)(id, SEL, CGFloat))method_getImplementation(mScale);
                method_setImplementation(mScale, (IMP)hooked_setContentsScale);
            }
            NSLog(@"[RobloxOptimizer] Installed CAMetalLayer resolution hooks.");
        }

        Class viewClass = [UIView class];
        if (viewClass) {
            Method mContentScale = class_getInstanceMethod(viewClass, @selector(setContentScaleFactor:));
            if (mContentScale) {
                orig_setContentScaleFactor = (void (*)(id, SEL, CGFloat))method_getImplementation(mContentScale);
                method_setImplementation(mContentScale, (IMP)hooked_setContentScaleFactor);
                NSLog(@"[RobloxOptimizer] Installed UIView contentScaleFactor hook.");
            }
        }
    });
}
