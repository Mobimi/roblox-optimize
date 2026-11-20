//
//  ROFloatingButton.h
//  RobloxOptimizer
//
//  Draggable floating action button with magnetic edge snapping and tap disambiguation.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ROFloatingButton : UIView

@property (nonatomic, copy, nullable) void (^tapHandler)(void);

- (instancetype)initWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
