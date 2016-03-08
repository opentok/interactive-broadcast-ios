//
//  DotSpinnerView.m
//  Spinner
//
//  Created by Xi Huang on 3/7/16.
//  Copyright © 2016 Xi Huang. All rights reserved.
//

#import "DotSpinnerView.h"

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
@interface DotSpinnerView()
@property (nonatomic) NSUInteger number;
@property (nonatomic) NSTimer *spinAnimationTimer;
@property (nonatomic) NSArray <DotSpinnerDotView *> *dots;
@end

@implementation DotSpinnerView

#pragma mark - life cycle methods
+ (instancetype)sharedInstance {
    static DotSpinnerView *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(){
        sharedInstance = [[DotSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 120, 120) numberOfDots:10];
    });
    return sharedInstance;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.number = 10;
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
            CGRect newRect = CGRectMake(startX, startY, 16, 16);
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

#pragma mark - public methods
//+ (void)show {
//    DotSpinnerView *view = [DotSpinnerView sharedInstance];
////    [view updateFrame];
//    view.spinAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:view selector:@selector(applySpinAnimation) userInfo:nil repeats:YES];
//}
//
//+ (void)dismiss {
//    DotSpinnerView *view = [DotSpinnerView sharedInstance];
//    [view.spinAnimationTimer invalidate];
//    [view removeFromSuperview];
//}

#pragma mark - private methods
//- (void)updateFrame {
//    DotSpinnerView *view = [DotSpinnerView sharedInstance];
//    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
//    view.center = rootViewController.view.center;
//}

- (void)applySpinAnimation {
    
    static int animatedIndex = 0;
    for (int i = 0; i < 10; i++) {
        
        DotSpinnerDotView *dotView = self.dots[(animatedIndex + i) % 10];
        dotView.alpha = (float)i / 10;
    }
    animatedIndex++;
}

@end
