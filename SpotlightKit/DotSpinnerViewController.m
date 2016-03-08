//
//  DotSpinnerViewController.m
//  Spinner
//
//  Created by Xi Huang on 3/8/16.
//  Copyright © 2016 Xi Huang. All rights reserved.
//

#import "DotSpinnerViewController.h"
#import "DotSpinnerView.h"

@implementation DotSpinnerViewController

+ (instancetype)sharedInstance {
    static DotSpinnerViewController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(){
        sharedInstance = [[DotSpinnerViewController alloc] initWithNibName:@"DotSpinnerViewController"
                                                                    bundle:[NSBundle bundleForClass:[DotSpinnerViewController class]]];
        sharedInstance.providesPresentationContextTransitionStyle = YES;
        sharedInstance.definesPresentationContext = YES;
        sharedInstance.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    });
    return sharedInstance;
}

+ (void)show {
    
    DotSpinnerViewController *sharedDotSpinnerViewController = [DotSpinnerViewController sharedInstance];
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *topViewController = [DotSpinnerViewController topViewControllerWithRootViewController:rootViewController];
    [topViewController presentViewController:sharedDotSpinnerViewController animated:NO completion:nil];
}

+ (void)dismiss {
    
    DotSpinnerViewController *sharedDotSpinnerViewController = [DotSpinnerViewController sharedInstance];
    [sharedDotSpinnerViewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - helper method
+ (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isMemberOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    }
    else if ([rootViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    }
    else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    }
    else {
        return rootViewController;
    }
}

@end
