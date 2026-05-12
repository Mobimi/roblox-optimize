#pragma once
#import <UIKit/UIKit.h>

@interface SliderCell : UIView
@property (nonatomic, copy) void (^onChanged)(float value);

- (instancetype)initWithTitle:(NSString *)title
                     minValue:(float)min
                     maxValue:(float)max
                 defaultValue:(float)defaultVal
                         unit:(NSString *)unit
                 needsRestart:(BOOL)needsRestart;
@end