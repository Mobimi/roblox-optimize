#pragma once
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface ShadowPass : NSObject
+ (void)apply;
+ (void)processDescriptor:(MTLRenderPassDescriptor *)descriptor;
@end