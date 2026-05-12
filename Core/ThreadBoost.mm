#import "ThreadBoost.h"
#import "Settings.h"
#import <Foundation/Foundation.h>
#import <pthread.h>
#import <objc/runtime.h>

// ─── Hook NSThread để boost thread priority ────────────────────────────────
@interface NSThread (ThreadBoostHook)
- (void)tb_start;
@end

@implementation NSThread (ThreadBoostHook)

- (void)tb_start {
    [self tb_start]; // original trước

    // Boost nếu là render/game thread
    NSString *name = self.name ?: @"";
    BOOL isRenderThread = (
        [name containsString:@"render"] ||
        [name containsString:@"Render"] ||
        [name containsString:@"metal"]  ||
        [name containsString:@"Metal"]  ||
        [name containsString:@"GPU"]    ||
        [name containsString:@"gpu"]    ||
        [name containsString:@"game"]   ||
        [name containsString:@"Game"]   ||
        [name containsString:@"main"]   ||
        [name containsString:@"Main"]
    );

    if (isRenderThread && [Settings threadBoostEnabled]) {
        // Boost lên QOS_CLASS_USER_INTERACTIVE — cao nhất
        pthread_t pt = self.value ? (__bridge pthread_t)self.value : pthread_self();
        struct sched_param param;
        param.sched_priority = sched_get_priority_max(SCHED_FIFO);
        pthread_setschedparam(pt, SCHED_FIFO, &param);
        NSLog(@"[GameOptimizer] ThreadBoost: boosted thread '%@' to SCHED_FIFO max",
              name);
    }
}

@end

// ─── Boost main thread và current thread ngay lập tức ─────────────────────
static void BoostCurrentThread(void) {
    // Dùng QoS class để boost main thread
    pthread_t mainThread = pthread_self();
    struct sched_param param;
    int policy;

    pthread_getschedparam(mainThread, &policy, &param);
    NSLog(@"[GameOptimizer] ThreadBoost: current policy=%d priority=%d",
          policy, param.sched_priority);

    // Set QOS_CLASS_USER_INTERACTIVE cho main thread
    pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);

    // Cũng boost via NSThread
    [NSThread.mainThread setThreadPriority:1.0];

    NSLog(@"[GameOptimizer] ThreadBoost: main thread → QOS_USER_INTERACTIVE priority=1.0");
}

// ─── Hook GCD queue để boost dispatch queues ──────────────────────────────
static void BoostDispatchQueues(void) {
    // Boost main queue
    dispatch_set_target_queue(
        dispatch_get_main_queue(),
        dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
    );
    NSLog(@"[GameOptimizer] ThreadBoost: main dispatch queue boosted");
}

// ─── ThreadBoost main ──────────────────────────────────────────────────────
@implementation ThreadBoost

+ (void)apply {
    BOOL enabled = [Settings threadBoostEnabled];
    NSLog(@"[GameOptimizer] ThreadBoost: %@", enabled ? @"ON" : @"OFF");

    if (!enabled) return;

    // 1. Boost main thread ngay lập tức
    BoostCurrentThread();

    // 2. Boost GCD queues
    BoostDispatchQueues();

    // 3. Hook NSThread start để auto-boost render threads
    Class threadClass = NSClassFromString(@"NSThread");
    if (threadClass) {
        Method orig = class_getInstanceMethod(threadClass, @selector(start));
        Method repl = class_getInstanceMethod(threadClass, @selector(tb_start));
        if (orig && repl) {
            method_exchangeImplementations(orig, repl);
            NSLog(@"[GameOptimizer] ThreadBoost: NSThread hooked");
        }
    }

    // 4. Boost Metal command queue sau khi game init
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            // Re-boost main thread sau khi game đã setup xong
            pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
            NSLog(@"[GameOptimizer] ThreadBoost: re-applied after game init");
        }
    );
}

@end