//
//  ROPassThroughWindow.m
//  RobloxOptimizer
//
//  Transparent overlay UIWindow allowing touches outside UI subviews to pass to Roblox.
//

#import "ROPassThroughWindow.h"
#import "ROFloatingButton.h"
#import "ROMenuViewController.h"

@interface ROOverlayContainerViewController : UIViewController
@end

@implementation ROOverlayContainerViewController

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

@end

@interface ROPassThroughWindow ()
@property (nonatomic, strong) ROFloatingButton *floatingButton;
@property (nonatomic, strong, nullable) ROMenuViewController *menuViewController;
@end

@implementation ROPassThroughWindow

+ (instancetype)sharedWindow {
    static ROPassThroughWindow *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIWindowScene *activeScene = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive &&
                    [scene isKindOfClass:[UIWindowScene class]]) {
                    activeScene = (UIWindowScene *)scene;
                    break;
                }
            }
        }

        if (activeScene) {
            sharedInstance = [[ROPassThroughWindow alloc] initWithWindowScene:activeScene];
        } else {
            sharedInstance = [[ROPassThroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        sharedInstance.windowLevel = UIWindowLevelAlert + 100.0;
        sharedInstance.backgroundColor = [UIColor clearColor];

        ROOverlayContainerViewController *rootVC = [[ROOverlayContainerViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        rootVC.view.userInteractionEnabled = YES;
        sharedInstance.rootViewController = rootVC;

        // Add Draggable Floating Action Button
        ROFloatingButton *btn = [[ROFloatingButton alloc] initWithFrame:CGRectMake(20, 100, 50, 50)];
        sharedInstance.floatingButton = btn;
        [rootVC.view addSubview:btn];

        __weak typeof(sharedInstance) weakWindow = sharedInstance;
        btn.tapHandler = ^{
            [weakWindow toggleMenu];
        };

        sharedInstance.hidden = NO;
    });
    return sharedInstance;
}

+ (void)initializeOverlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ROPassThroughWindow sharedWindow];
    });
}

- (void)toggleMenu {
    if (self.menuViewController) {
        [self.menuViewController dismissMenu];
    } else {
        ROMenuViewController *menu = [[ROMenuViewController alloc] init];
        self.menuViewController = menu;
        __weak typeof(self) weakSelf = self;
        menu.onDismiss = ^{
            weakSelf.menuViewController = nil;
        };
        [menu presentInParent:self.rootViewController];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    // If the touch lands on the window itself or on the root transparent view,
    // return nil so that touches pass through seamlessly to the underlying game.
    if (hitView == self || hitView == self.rootViewController.view) {
        return nil;
    }
    return hitView;
}

@end

void ROInitializeUI(void) {
    [ROPassThroughWindow initializeOverlay];
}
