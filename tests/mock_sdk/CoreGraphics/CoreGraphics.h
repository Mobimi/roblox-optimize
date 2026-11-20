#ifndef MOCK_COREGRAPHICS_H
#define MOCK_COREGRAPHICS_H

#import <stddef.h>
#import <stdint.h>
#import <stdbool.h>

typedef double CGFloat;

typedef struct CGPoint {
    CGFloat x;
    CGFloat y;
} CGPoint;

typedef struct CGSize {
    CGFloat width;
    CGFloat height;
} CGSize;

typedef struct CGRect {
    CGPoint origin;
    CGSize size;
} CGRect;

typedef struct CGAffineTransform {
    CGFloat a, b, c, d;
    CGFloat tx, ty;
} CGAffineTransform;

typedef struct CGColor *CGColorRef;

static inline CGPoint CGPointMake(CGFloat x, CGFloat y) {
    CGPoint p = {x, y};
    return p;
}

static inline CGSize CGSizeMake(CGFloat width, CGFloat height) {
    CGSize s = {width, height};
    return s;
}

static inline CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    CGRect r = {{x, y}, {width, height}};
    return r;
}

static const CGPoint CGPointZero = {0.0, 0.0};
static const CGSize CGSizeZero = {0.0, 0.0};
static const CGRect CGRectZero = {{0.0, 0.0}, {0.0, 0.0}};
static const CGAffineTransform CGAffineTransformIdentity = {1, 0, 0, 1, 0, 0};

static inline CGAffineTransform CGAffineTransformMakeScale(CGFloat sx, CGFloat sy) {
    CGAffineTransform t = {sx, 0, 0, sy, 0, 0};
    return t;
}

#endif
