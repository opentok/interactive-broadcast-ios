//
//  DotSpinnerViewController.m
//  Spinner
//
//  Created by Xi Huang on 3/8/16.
//  Copyright © 2016 Xi Huang. All rights reserved.
//

#import "DotSpinnerViewController.h"

@implementation DotSpinnerViewController

#pragma mark - main class
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

#pragma mark - DotSpinnerDotView
@interface DotSpinnerDotView: UIView
@end

@implementation DotSpinnerDotView
- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithRed:0 / 255.0f green:163 / 255.0f blue:227 / 255.0f alpha:1.0];
    }
    return self;
}
@end


#pragma mark - DotSpinnerView
@interface DotSpinnerView: UIView
@property (nonatomic) NSUInteger number;
@property (nonatomic) NSTimer *spinAnimationTimer;
@property (nonatomic) NSArray <DotSpinnerDotView *> *dots;
@end

@implementation DotSpinnerView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setNumber:10];
    [self drawingDots];
    self.spinAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(applySpinAnimation) userInfo:nil repeats:YES];
}

- (instancetype)initWithFrame:(CGRect)frame
                 numberOfDots:(NSUInteger)number {
    
    if (number == 0 || frame.size.width != frame.size.height) return nil;
    
    // reference from an algorithm for drawing a circle
    //    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //
    //    float angle = 0;
    //
    //    float centerX = self.frame.size.width/2;
    //    float centerY = self.frame.size.width/2;
    //
    //    float startX = 0.0;
    //    float startY = 0.0;
    //    for (int i = 0; i < 10 ; i++) {
    //
    //        startX = centerX +  cos(angle) * (36 + 50);
    //        startY = centerY +  sin(angle) * (36 + 50);
    //        CGContextFillEllipseInRect(ctx, CGRectMake(startX,  startY,  5, 5));
    //        [[UIColor blackColor] setStroke];
    //        angle -= M_PI / 10;
    //    }
    if (self = [super initWithFrame:frame]) {
        
        _number = number;
        
        float centerX = self.bounds.size.width / 2;
        float centerY = self.bounds.size.width / 2;
        float startX = 0.0;
        float startY = 0.0;
        float angle = 0;
        float currentAngle = 0;
        float distance = self.bounds.size.width / 4;
        
        NSMutableArray *dots = [[NSMutableArray alloc] initWithCapacity:_number];
        for (float i = 0; i < _number; i++) {
            
            startX = centerX + cos(angle) * (currentAngle + distance * 1.2) - 5;
            startY = centerY + sin(angle) * (currentAngle + distance * 1.2) - 5;
            
            //            CGRect newRect = CGRectMake(startX, startY, number * (1 + i / 10), number * (1 + i / 10));
            CGRect newRect = CGRectMake(startX, startY, 10, 10);
            DotSpinnerDotView *dotView = [[DotSpinnerDotView alloc] initWithFrame:newRect];
            dotView.alpha = i / 10;
            [dots addObject:dotView];
            [self addSubview:dotView];
            
            // update angle value
            angle -= (2 * M_PI / _number);
        }
        _dots = dots;
    }
    
    return self;
}

- (void)drawingDots {
    if (!self.number) return;
    
    float centerX = self.bounds.size.width / 2;
    float centerY = self.bounds.size.width / 2;
    float startX = 0.0;
    float startY = 0.0;
    float angle = 0;
    float currentAngle = 0;
    float distance = self.bounds.size.width / 4;
    
    NSMutableArray *dots = [[NSMutableArray alloc] initWithCapacity:_number];
    for (float i = 0; i < _number; i++) {
        
        startX = centerX + cos(angle) * (currentAngle + distance * 1.2) - 6;
        startY = centerY + sin(angle) * (currentAngle + distance * 1.2);
        
        //            CGRect newRect = CGRectMake(startX, startY, number * (1 + i / 10), number * (1 + i / 10));
        CGRect newRect = CGRectMake(startX, startY, 10, 10);
        DotSpinnerDotView *dotView = [[DotSpinnerDotView alloc] initWithFrame:newRect];
        dotView.alpha = i / 10;
        [dots addObject:dotView];
        [self addSubview:dotView];
        
        // update angle value
        angle -= (2 * M_PI / _number);
    }
    _dots = dots;
}

- (void)applySpinAnimation {
    
    static int animatedIndex = 0;
    for (int i = 0; i < 10; i++) {
        
        DotSpinnerDotView *dotView = self.dots[(animatedIndex + i) % 10];
        dotView.alpha = (float)i / 10;
    }
    animatedIndex++;
}

@end