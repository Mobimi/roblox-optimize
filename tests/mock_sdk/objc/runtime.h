#ifndef MOCK_OBJC_RUNTIME_H
#define MOCK_OBJC_RUNTIME_H

#import <stddef.h>
#import <stdint.h>
#import <stdbool.h>

#ifndef _OBJC_OBJC_H_
typedef struct objc_class *Class;
typedef struct objc_object {
    Class isa;
} *id;
typedef struct objc_selector *SEL;
typedef id (*IMP)(id, SEL, ...);
typedef signed char BOOL;
#define YES ((BOOL)1)
#define NO  ((BOOL)0)
#endif

typedef struct objc_method *Method;

Method class_getInstanceMethod(Class cls, SEL name);
IMP method_getImplementation(Method m);
IMP method_setImplementation(Method m, IMP imp);
SEL sel_registerName(const char *str);

#endif
