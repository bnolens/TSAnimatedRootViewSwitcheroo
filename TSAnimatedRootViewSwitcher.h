//
//  TSAnimatedRootViewSwitcher.h
//

@import UIKit;
@import Foundation;

typedef NS_ENUM(NSUInteger, TSSwitcherAnimationDirection) {
    TSSwitcherAnimationDirectionForward,
    TSSwitcherAnimationDirectionReverse
};

typedef NS_ENUM(NSUInteger, TSSwitcherAnimationType) {
    TSSwitcherAnimationTypeNone,
    TSSwitcherAnimationTypePan,
    TSSwitcherAnimationTypeCard,
    TSSwitcherAnimationTypeDissolve
};

@protocol TSAnimatedRootViewSwitcherDelegate;

@interface TSAnimatedRootViewSwitcher : UIViewController

@property (nonatomic, weak) id<TSAnimatedRootViewSwitcherDelegate>delegate;
@property (strong, nonatomic, readonly) UIViewController *root;

+ (instancetype)setupWithDelegate:(id<TSAnimatedRootViewSwitcherDelegate>)delegate;
+ (instancetype)switcherWithRoot:(UIViewController *)root andDelegate:(id<TSAnimatedRootViewSwitcherDelegate>)delegate;
+ (void)useRoot:(UIViewController *)root animationType:(TSSwitcherAnimationType)animationType direction:(TSSwitcherAnimationDirection)direction;

- (id)initWithRoot:(UIViewController *)root andDelegate:(id<TSAnimatedRootViewSwitcherDelegate>)delegate;
- (void)switchToRoot:(UIViewController *)root animationType:(TSSwitcherAnimationType)animationType direction:(TSSwitcherAnimationDirection)direction;

@end


@protocol TSAnimatedRootViewSwitcherDelegate <NSObject>
- (id <UIViewControllerAnimatedTransitioning>)switcher:(TSAnimatedRootViewSwitcher *)switcher animationControllerForAnimationType:(TSSwitcherAnimationType)animationType direction:(TSSwitcherAnimationDirection)direction
                                    fromViewController:(UIViewController *)fromViewController
                                      toViewController:(UIViewController *)toViewController;
@end
