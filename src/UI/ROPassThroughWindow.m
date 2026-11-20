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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    } completion:nil];
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
            if (!activeScene) {
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if ([scene isKindOfClass:[UIWindowScene class]]) {
                        activeScene = (UIWindowScene *)scene;
                        break;
                    }
                }
            }
        }

        if (activeScene) {
            sharedInstance = [[ROPassThroughWindow alloc] initWithWindowScene:activeScene];
            sharedInstance.frame = activeScene.coordinateSpace.bounds;
        } else {
            sharedInstance = [[ROPassThroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        sharedInstance.windowLevel = UIWindowLevelAlert + 100.0;
        sharedInstance.backgroundColor = [UIColor clearColor];
        sharedInstance.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        ROOverlayContainerViewController *rootVC = [[ROOverlayContainerViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        rootVC.view.userInteractionEnabled = YES;
        rootVC.view.frame = sharedInstance.bounds;
        rootVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        sharedInstance.rootViewController = rootVC;

        // Add Draggable Floating Action Button
        ROFloatingButton *btn = [[ROFloatingButton alloc] initWithFrame:CGRectMake(20, 100, 50, 50)];
        sharedInstance.floatingButton = btn;
        [rootVC.view addSubview:btn];

        __weak typeof(sharedInstance) weakWindow = sharedInstance;
        btn.tapHandler = ^{
            [weakWindow toggleMenu];
        };

        if (@available(iOS 13.0, *)) {
            if (!sharedInstance.windowScene) {
                // If scene was not yet foreground active, attach dynamically upon scene activation
                __block id<NSObject> sceneObserver = nil;
                sceneObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UISceneDidActivateNotification
                                                                  object:nil
                                                                   queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification *note) {
                    if (@available(iOS 13.0, *)) {
                        if ([note.object isKindOfClass:[UIWindowScene class]] && !sharedInstance.windowScene) {
                            UIWindowScene *scene = (UIWindowScene *)note.object;
                            sharedInstance.windowScene = scene;
                            sharedInstance.frame = scene.coordinateSpace.bounds;
                            sharedInstance.rootViewController.view.frame = sharedInstance.bounds;
                            sharedInstance.hidden = NO;
                            if (sceneObserver) {
                                [[NSNotificationCenter defaultCenter] removeObserver:sceneObserver];
                                sceneObserver = nil;
                            }
                        }
                    }
                }];
            }
        }

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
    if (@available(iOS 13.0, *)) {
        if (!self.windowScene) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive &&
                    [scene isKindOfClass:[UIWindowScene class]]) {
                    self.windowScene = (UIWindowScene *)scene;
                    break;
                }
            }
        }
        if (self.windowScene) {
            self.frame = self.windowScene.coordinateSpace.bounds;
        }
    } else {
        self.frame = [UIScreen mainScreen].bounds;
    }
    self.rootViewController.view.frame = self.bounds;

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
        [self.rootViewController.view bringSubviewToFront:self.floatingButton];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];

    if (self.menuViewController) {
        UIViewController *presentedVC = self.menuViewController.presentedViewController ?: self.rootViewController.presentedViewController;
        if (presentedVC && (hitView == presentedVC.view || [hitView isDescendantOfView:presentedVC.view])) {
            return hitView;
        }
    }

    // If the touch lands on the window itself or on the root transparent view,
    // return nil so that touches pass through seamlessly to the underlying game.
    if (hitView == self || hitView == self.rootViewController.view) {
        if (self.menuViewController) {
            UIViewController *presentedVC = self.menuViewController.presentedViewController ?: self.rootViewController.presentedViewController;
            if (presentedVC) {
                return hitView;
            }
            [self.menuViewController dismissMenu];
        }
        return nil;
    }

    if (self.menuViewController) {
        UIView *card = self.menuViewController.dialogCard;
        // If touch is outside the menu card and outside the floating button, dismiss menu and pass touch to game
        if (hitView && card &&
            ![hitView isDescendantOfView:card] &&
            hitView != self.floatingButton &&
            ![hitView isDescendantOfView:self.floatingButton]) {
            UIViewController *presentedVC = self.menuViewController.presentedViewController ?: self.rootViewController.presentedViewController;
            if (presentedVC) {
                return hitView;
            }
            [self.menuViewController dismissMenu];
            return nil;
        }
    }

    return hitView;
}

@end

void ROInitializeUI(void) {
    [ROPassThroughWindow initializeOverlay];
}
