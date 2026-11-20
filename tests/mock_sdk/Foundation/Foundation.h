#ifndef MOCK_FOUNDATION_H
#define MOCK_FOUNDATION_H

#import <stddef.h>
#import <stdint.h>
#import <stdbool.h>
#import <objc/objc.h>
#import <objc/runtime.h>

#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#define nullable
#define nonnull

#ifndef MIN
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef MAX
#define MAX(a, b) (((a) > (b)) ? (a) : (b))
#endif

typedef unsigned long NSUInteger;
typedef long NSInteger;

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

typedef NS_ENUM(NSInteger, NSComparisonResult) {
    NSOrderedAscending = -1L,
    NSOrderedSame,
    NSOrderedDescending
};

@class NSString, NSArray, NSDictionary, NSData, NSError;

@protocol NSObject
- (BOOL)isEqual:(id)object;
- (Class)class;
- (BOOL)isKindOfClass:(Class)aClass;
- (id)copy;
@end

typedef struct {
    unsigned long state;
    id __unsafe_unretained *itemsPtr;
    unsigned long *mutationsPtr;
    unsigned long extra[5];
} NSFastEnumerationState;

@protocol NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer count:(NSUInteger)len;
@end

@protocol NSCopying
- (id)copyWithZone:(void *)zone;
@end

__attribute__((objc_root_class))
@interface NSObject <NSObject>
+ (instancetype)alloc;
- (instancetype)init;
+ (instancetype)new;
+ (Class)class;
- (Class)class;
- (BOOL)isKindOfClass:(Class)aClass;
- (id)copy;
@end

@interface NSString : NSObject <NSCopying>
+ (instancetype)stringWithFormat:(NSString *)format, ...;
- (NSString *)stringByAppendingPathComponent:(NSString *)str;
- (NSString *)stringByDeletingLastPathComponent;
- (float)floatValue;
- (double)doubleValue;
@end

@interface NSNumber : NSObject <NSCopying>
+ (NSNumber *)numberWithInt:(int)value;
+ (NSNumber *)numberWithInteger:(NSInteger)value;
+ (NSNumber *)numberWithBool:(BOOL)value;
+ (NSNumber *)numberWithDouble:(double)value;
- (NSInteger)integerValue;
- (BOOL)boolValue;
@end

@interface NSArray<ObjectType> : NSObject <NSCopying, NSFastEnumeration>
+ (instancetype)array;
+ (instancetype)arrayWithObjects:(const id [])objects count:(NSUInteger)cnt;
- (NSUInteger)count;
- (ObjectType)firstObject;
- (ObjectType)objectAtIndex:(NSUInteger)index;
@end

@interface NSMutableArray<ObjectType> : NSArray<ObjectType>
- (void)addObject:(ObjectType)anObject;
@end

@interface NSDictionary<KeyType, ObjectType> : NSObject <NSCopying>
+ (instancetype)dictionary;
+ (instancetype)dictionaryWithObjects:(const id [])objects forKeys:(const id <NSCopying> [])keys count:(NSUInteger)cnt;
- (nullable ObjectType)objectForKey:(KeyType)aKey;
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
@end

@interface NSMutableDictionary<KeyType, ObjectType> : NSDictionary<KeyType, ObjectType>
- (void)setObject:(ObjectType)anObject forKey:(KeyType <NSCopying>)aKey;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;
@end

@interface NSData : NSObject <NSCopying>
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;
- (BOOL)writeToFile:(NSString *)path options:(NSUInteger)writeOptionsMask error:(NSError **)errorPtr;
@end

typedef NS_ENUM(NSUInteger, NSDataWritingOptions) {
    NSDataWritingAtomic = 1UL << 0
};

@interface NSError : NSObject
@property (readonly, copy) NSString *localizedDescription;
@end

@interface NSUserDefaults : NSObject
+ (NSUserDefaults *)standardUserDefaults;
- (BOOL)boolForKey:(NSString *)defaultName;
- (NSInteger)integerForKey:(NSString *)defaultName;
- (double)doubleForKey:(NSString *)defaultName;
- (nullable NSString *)stringForKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;
- (void)setDouble:(double)value forKey:(NSString *)defaultName;
- (void)setObject:(nullable id)value forKey:(NSString *)defaultName;
- (BOOL)synchronize;
@end

@interface NSBundle : NSObject
+ (NSBundle *)mainBundle;
- (NSString *)bundlePath;
@end

@interface NSFileManager : NSObject
+ (NSFileManager *)defaultManager;
- (BOOL)fileExistsAtPath:(NSString *)path;
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(nullable NSDictionary *)attributes error:(NSError **)error;
@end

typedef NS_ENUM(NSUInteger, NSSearchPathDirectory) {
    NSDocumentDirectory = 9,
    NSLibraryDirectory = 11,
    NSApplicationSupportDirectory = 14
};

typedef NS_ENUM(NSUInteger, NSSearchPathDomainMask) {
    NSUserDomainMask = 1
};

static inline NSArray<NSString *> *NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde) {
    return (NSArray<NSString *> *)@[@"/var/mobile/Documents"];
}

static inline NSString *NSTemporaryDirectory(void) {
    return @"/tmp";
}

typedef NS_ENUM(NSUInteger, NSJSONWritingOptions) {
    NSJSONWritingPrettyPrinted = (1UL << 0)
};

@interface NSJSONSerialization : NSObject
+ (nullable NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error;
+ (nullable id)JSONObjectWithData:(NSData *)data options:(NSUInteger)opt error:(NSError **)error;
@end

@interface NSNotification : NSObject
@end

@interface NSOperationQueue : NSObject
+ (NSOperationQueue *)mainQueue;
@end

@interface NSNotificationCenter : NSObject
+ (NSNotificationCenter *)defaultCenter;
- (id)addObserverForName:(nullable NSString *)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block;
@end

static inline Class NSClassFromString(NSString *aClassName) {
    return nil;
}

static inline NSString *NSStringFromClass(Class aClass) {
    return @"MockClass";
}

void NSLog(NSString *format, ...);

typedef void* dispatch_once_t;
typedef void* dispatch_queue_t;
static inline dispatch_queue_t dispatch_get_main_queue(void) { return (dispatch_queue_t)0; }
void dispatch_once(dispatch_once_t *predicate, void (^block)(void));
void dispatch_async(dispatch_queue_t queue, void (^block)(void));

#endif
