#ifndef MOCK_CAMETALLAYER_H
#define MOCK_CAMETALLAYER_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CALayer : NSObject
@property (nullable) CGColorRef backgroundColor;
@property CGFloat cornerRadius;
@property CGFloat borderWidth;
@property (nullable) CGColorRef borderColor;
@property BOOL masksToBounds;
@property (nullable) CGColorRef shadowColor;
@property float shadowOpacity;
@property CGSize shadowOffset;
@property CGFloat shadowRadius;
@end

@interface CAMetalLayer : CALayer
@property (readwrite) CGSize drawableSize;
@property (readwrite) CGFloat contentsScale;
- (void)setDrawableSize:(CGSize)size;
- (void)setContentsScale:(CGFloat)scale;
@end

#endif
