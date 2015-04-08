//
//  TSAnimatedRootViewSwitcher.m
//

#import "TSAnimatedRootViewSwitcher.h"

typedef void (^TSSwitcherCompletionBlock)(BOOL didComplete);

__strong static TSAnimatedRootViewSwitcher *sharedContainer;

@interface TSSwitcherContext : NSObject <UIViewControllerContextTransitioning>

@property (nonatomic, copy) TSSwitcherCompletionBlock completionBlock;

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController
                          toViewController:(UIViewController *)toViewController;

@end

@interface TSAnimatedRootViewSwitcher ()

@property (nonatomic, strong) UIViewController *root;

@end

@implementation TSAnimatedRootViewSwitcher

+ (instancetype)setupWithDelegate:(id<TSAnimatedRootViewSwitcherDelegate>)delegate {
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        sharedContainer = [[TSAnimatedRootViewSwitcher alloc] initWithDelegate:delegate];
    });
    return sharedContainer;
}

+ (instancetype)switcherWithRoot:(UIViewController *)root andDelegate:(id<TSAnimatedRootViewSwitcherDelegate>)delegate {
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        sharedContainer = [[TSAnimatedRootViewSwitcher alloc] initWithRoot:root andDelegate:delegate];
    });
    return sharedContainer;
}

+ (void)useRoot:(UIViewController *)root animationType:(TSSwitcherAnimationType)animationType direction:(TSSwitcherAnimationDirection)direction {
    [sharedContainer switchToRoot:root animationType:animationType direction:direction];
}

- (id)initWithDelegate:(id<TSAnimatedRootViewSwitcherDelegate>)delegate {
    return [self initWithRoot:nil andDelegate:delegate];
}

- (id)initWithRoot:(UIViewController *)root andDelegate:(id<TSAnimatedRootViewSwitcherDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.root = root;
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _switchToRoot:self.root animationType:TSSwitcherAnimationTypeNone direction:TSSwitcherAnimationDirectionForward];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.root;
}

- (void)switchToRoot:(UIViewController *)root animationType:(TSSwitcherAnimationType)animationType direction:(TSSwitcherAnimationDirection)direction {
    NSParameterAssert (root);
    [self _switchToRoot:root animationType:animationType direction:(TSSwitcherAnimationDirection)direction];
    self.root = root;
}

#pragma mark Private Methods

- (BOOL)shouldSwitchToViewController:(UIViewController *)viewController {
    
    BOOL shouldSwitch = YES;
    if (!viewController) {
        shouldSwitch = NO;
    } else if (![self isViewLoaded]) {
        shouldSwitch = NO;
    } else if (viewController == self.root && [self.root isViewLoaded] && self.root.view.superview) {
        shouldSwitch = NO;
    }
    return shouldSwitch;
}

- (id<UIViewControllerAnimatedTransitioning>)animatorToViewController:(UIViewController *)viewController
                                                        animationType:(TSSwitcherAnimationType)animationType
                                                            direction:(TSSwitcherAnimationDirection)direction {
    if (!self.root || self.root == viewController) {
        return nil;
    }
    
    SEL animSelector = @selector(switcher:animationControllerForAnimationType:direction:fromViewController:toViewController:);
    id<TSAnimatedRootViewSwitcherDelegate>strongDel = self.delegate;
    
    if ([strongDel respondsToSelector:animSelector]) {
        return [strongDel switcher:self
animationControllerForAnimationType:animationType direction:direction
                fromViewController:self.root
                  toViewController:viewController];
    }
    
    return nil;
}

- (void)_switchToRoot:(UIViewController *)toViewController animationType:(TSSwitcherAnimationType)animationType direction:(TSSwitcherAnimationDirection)direction {
    
    if (![self shouldSwitchToViewController:toViewController]) {
        return;
    }
    
    UIViewController *fromViewController = (toViewController == self.root) ? nil : self.root;
    id<UIViewControllerAnimatedTransitioning>animator = [self animatorToViewController:toViewController
                                                                         animationType:animationType
                                                                             direction:direction];
    
    UIView *toView = toViewController.view;
    [toView setTranslatesAutoresizingMaskIntoConstraints:YES];
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    toView.frame = self.view.bounds;
    
    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];
    TSSwitcherCompletionBlock completionBlock = ^(BOOL didComplete) {
        [fromViewController.view removeFromSuperview];
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
        
        if ([animator respondsToSelector:@selector (animationEnded:)]) {
            [animator animationEnded:didComplete];
        }
    };
    
    if (animator) {
        TSSwitcherContext *transitionContext = [[TSSwitcherContext alloc] initWithFromViewController:fromViewController toViewController:toViewController];
        transitionContext.completionBlock = completionBlock;
        [animator animateTransition:transitionContext];
    } else {
        [self.view addSubview:toViewController.view];
        completionBlock(YES);
    }
}

- (void)viewDidLayoutSubviews {
    [self setNeedsStatusBarAppearanceUpdate];
}

@end

#pragma mark - Private Transitionin Context

@interface TSSwitcherContext ()
@property (nonatomic, strong) NSDictionary *privateViewControllers;
@end

@implementation TSSwitcherContext

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController {
    NSAssert ([fromViewController isViewLoaded] && fromViewController.view.superview, @"The fromViewController view must reside in the container view upon initializing the transition context.");
    
    if ((self = [super init])) {
        self.privateViewControllers = @{
                                        UITransitionContextFromViewControllerKey: fromViewController,
                                        UITransitionContextToViewControllerKey: toViewController,
                                        };
    }
    
    return self;
}

- (UIView *)containerView {
    return [self viewControllerForKey:UITransitionContextFromViewControllerKey].view.superview;
}

- (CGRect)initialFrameForViewController:(UIViewController *)viewController {
    if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
        return viewController.view.frame;
    } else {
        return CGRectZero;
    }
}

- (CGRect)finalFrameForViewController:(UIViewController *)viewController {
    if (viewController == [self viewControllerForKey:UITransitionContextToViewControllerKey]) {
        return [self viewControllerForKey:UITransitionContextFromViewControllerKey].view.frame;
    } else {
        return CGRectZero;
    }
}

- (BOOL)isAnimated {
    return YES;
}

- (BOOL)isInteractive {
    return NO;
}

- (UIModalPresentationStyle)presentationStyle {
    return UIModalPresentationCustom;
}

- (UIViewController *)viewControllerForKey:(NSString *)key {
    return self.privateViewControllers[key];
}

- (void)completeTransition:(BOOL)didComplete {
    if (self.completionBlock) {
        self.completionBlock(didComplete);
    }
}

- (BOOL)transitionWasCancelled { return NO; }

- (void)updateInteractiveTransition:(CGFloat)percentComplete {}
- (void)finishInteractiveTransition {}
- (void)cancelInteractiveTransition {}

@end
