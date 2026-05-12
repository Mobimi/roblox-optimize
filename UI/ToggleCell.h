#pragma once
#import <UIKit/UIKit.h>

@interface ToggleCell : UIView
@property (nonatomic, copy) void (^onToggle)(BOOL isOn);

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         isOn:(BOOL)isOn
                 needsRestart:(BOOL)needsRestart;

- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (BOOL)isOn;
@end