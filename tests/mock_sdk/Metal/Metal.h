#ifndef MOCK_METAL_H
#define MOCK_METAL_H

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MTLPixelFormat) {
    MTLPixelFormatInvalid = 0,
    MTLPixelFormatRGBA8Unorm = 70,
    MTLPixelFormatDepth16Unorm = 250,
    MTLPixelFormatDepth32Float = 252,
    MTLPixelFormatStencil8 = 253,
    MTLPixelFormatDepth24Unorm_Stencil8 = 255,
    MTLPixelFormatDepth32Float_Stencil8 = 260,
    MTLPixelFormatX32_Stencil8 = 261,
    MTLPixelFormatX24_Stencil8 = 262
};

typedef NS_ENUM(NSUInteger, MTLTextureType) {
    MTLTextureType1D = 0,
    MTLTextureType1DArray = 1,
    MTLTextureType2D = 2,
    MTLTextureType2DArray = 3,
    MTLTextureType2DMultisample = 4,
    MTLTextureTypeCube = 5,
    MTLTextureTypeCubeArray = 6,
    MTLTextureType3D = 7,
    MTLTextureTypeTextureBuffer = 9
};

typedef NS_ENUM(NSUInteger, MTLTextureUsage) {
    MTLTextureUsageUnknown = 0x0000,
    MTLTextureUsageShaderRead = 0x0001,
    MTLTextureUsageShaderWrite = 0x0002,
    MTLTextureUsageRenderTarget = 0x0004
};

@protocol MTLTexture <NSObject>
@property (readonly) NSUInteger width;
@property (readonly) NSUInteger height;
@end

@interface MTLTextureDescriptor : NSObject <NSCopying>
@property (readwrite, nonatomic) MTLTextureType textureType;
@property (readwrite, nonatomic) MTLPixelFormat pixelFormat;
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@property (readwrite, nonatomic) NSUInteger depth;
@property (readwrite, nonatomic) NSUInteger mipmapLevelCount;
@property (readwrite, nonatomic) MTLTextureUsage usage;
@end

@protocol MTLDevice <NSObject>
- (nullable id<MTLTexture>)newTextureWithDescriptor:(MTLTextureDescriptor *)descriptor;
@end

static inline id<MTLDevice> MTLCreateSystemDefaultDevice(void) {
    return nil;
}

#endif
