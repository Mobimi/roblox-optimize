#pragma once
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface MetalHooks : NSObject
+ (void)install;
+ (void)uninstall;
@end