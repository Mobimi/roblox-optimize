#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RenderScale : NSObject
+ (void)apply;
+ (void)updateForOrientation:(UIInterfaceOrientation)orientation;
@end