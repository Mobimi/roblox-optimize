#pragma once
#import <Foundation/Foundation.h>

@interface FPSCap : NSObject
+ (void)apply;
+ (void)setFPS:(NSInteger)fps;
@end