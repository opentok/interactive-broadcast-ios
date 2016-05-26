//
//  EventView.m
//  IBDemo
//
//  Created by Andrea Phillips on 5/20/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "EventView.h"
#import "UIColor+AppAdditions.h"

#import <DGActivityIndicatorView/DGActivityIndicatorView.h>

@interface EventView()
@property (nonatomic) DGActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UIView *notificationBar;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@end

@implementation EventView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.eventName.hidden = NO;
    
    [self.statusBar setBackgroundColor: [UIColor BarColor]];
    [self.getInLineBtn setBackgroundColor:[UIColor SLGreenColor]];
    [self.leaveLineBtn setBackgroundColor:[UIColor SLRedColor]];
    
    self.closeEvenBtn.layer.cornerRadius = 3;
    self.statusLabel.layer.borderWidth = 2.0;
    self.statusLabel.layer.borderColor = [UIColor SLGreenColor].CGColor;
    self.statusLabel.layer.cornerRadius = 3;
    self.getInLineBtn.layer.cornerRadius = 3;
    self.leaveLineBtn.layer.cornerRadius = 3;
    self.inLineHolder.layer.cornerRadius = 3;
    self.inLineHolder.layer.borderColor = [UIColor SLGrayColor].CGColor;;
    self.inLineHolder.layer.borderWidth = 3.0f;
}

#pragma mark - notification bar
- (void)showNotification:(NSString *)text
                useColor:(UIColor *)nColor {
    
    self.notificationLabel.text = text;
    self.notificationBar.backgroundColor = nColor;
    self.notificationBar.hidden = NO;
}

- (void)hideNotification {
    self.notificationBar.hidden = YES;
}

#pragma mark - loader
- (void)showLoader {
    self.activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeFiveDots
                                                                 tintColor:[UIColor SLBlueColor] size:50.0f];
    self.activityIndicatorView.frame = CGRectMake(0.0f, 100.0f, CGRectGetWidth([UIScreen mainScreen].bounds), 100.0f);
    [self addSubview:self.activityIndicatorView];
    [self bringSubviewToFront:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
}

- (void)stopLoader {
    [self.activityIndicatorView stopAnimating];
    [self.activityIndicatorView removeFromSuperview];
}

#pragma mark - video preview
- (void)showVideoPreviewWithPublisher:(OTPublisher *)publisher {
    if (!publisher) return;
    
    publisher.view.layer.cornerRadius = 0.5;
    [self.inLineHolder addSubview:publisher.view];
    [self.inLineHolder sendSubviewToBack:publisher.view];
    self.inLineHolder.hidden = NO;
}

-(void)hideVideoPreview {
    [UIView animateWithDuration:3 animations:^{
        self.inLineHolder.hidden = YES;
    }];
}

@end
