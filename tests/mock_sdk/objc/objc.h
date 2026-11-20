#ifndef _OBJC_OBJC_H_
#define _OBJC_OBJC_H_

#import <stddef.h>
#import <stdint.h>
#import <stdbool.h>

#ifndef nil
#define nil ((id)0)
#endif

#ifndef Nil
#define Nil ((Class)0)
#endif

#ifndef YES
#define YES ((BOOL)1)
#endif

#ifndef NO
#define NO  ((BOOL)0)
#endif

typedef struct objc_class *Class;
typedef struct objc_object {
    Class isa;
} *id;

typedef struct objc_selector *SEL;
typedef id (*IMP)(id, SEL, ...);
typedef signed char BOOL;

#endif /* _OBJC_OBJC_H_ */
