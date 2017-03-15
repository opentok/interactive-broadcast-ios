//
//  EventView.m
//  IBDemo
//
//  Created by Andrea Phillips on 5/20/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "EventView.h"
#import "UIColor+AppAdditions.h"

//#import <OTTextChatKit/OTTextChatKit.h>
#import <DGActivityIndicatorView/DGActivityIndicatorView.h>

@interface EventView()
@property (nonatomic) DGActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *internalHolder;
@property (weak, nonatomic) IBOutlet UIView *notificationBar;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;

//@property (nonatomic) OTTextChatView *textChatView;
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

- (void)showError:(NSString *)text
        useColor:(UIColor *)nColor {
    [self showNotification:text useColor:nColor];
    [self performSelector:@selector(hideNotification) withObject:nil afterDelay:10.0];
}

#pragma mark - loader
- (void)showLoader {
    
    if (!self.activityIndicatorView) {
        self.activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeFiveDots
                                                                 tintColor:[UIColor SLBlueColor] size:50.0f];
        self.activityIndicatorView.frame = CGRectMake(0.0f, 100.0f, CGRectGetWidth([UIScreen mainScreen].bounds), 100.0f);
        [self addSubview:self.activityIndicatorView];
        [self bringSubviewToFront:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
    }
}

- (void)stopLoader {
    [self.activityIndicatorView stopAnimating];
    [self.activityIndicatorView removeFromSuperview];
    self.activityIndicatorView = nil;
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

#pragma mark - subscriber views
- (void)adjustSubscriberViewsFrameWithSubscribers:(NSMutableDictionary *)subscribers {
    CGFloat c = 0;
    CGFloat new_width = 1;
    CGFloat new_height = self.internalHolder.bounds.size.height;
    
    if(subscribers.count == 0){
        self.eventImage.hidden = NO;
    }
    else{
        self.eventImage.hidden = YES;
        new_width = CGRectGetWidth([UIScreen mainScreen].bounds) / subscribers.count;
    }
    
    NSArray *viewNames = @[@"host",@"celebrity",@"fan"];
    
    for(NSString *viewName in viewNames){
        
        UIView *view = [self valueForKey:[NSString stringWithFormat:@"%@ViewHolder", viewName]];
        if(subscribers[viewName]){
            [view setHidden:NO];
            OTSubscriber *temp = subscribers[viewName];
            
            [view setFrame:CGRectMake((c*new_width), 0, new_width, new_height)];
            temp.view.frame = CGRectMake(0, 0, new_width,new_height);
            c++;
        }
        else{
            [view setHidden:YES];
            [view setFrame:CGRectMake(0, 0, 5,new_height)];
        }
    }
    
    for (UIView *view in self.hostViewHolder.subviews) {
        view.frame = self.hostViewHolder.bounds;
    }
    
    for (UIView *view in self.fanViewHolder.subviews) {
        view.frame = self.fanViewHolder.bounds;
    }
    
    for (UIView *view in self.celebrityViewHolder.subviews) {
        view.frame = self.celebrityViewHolder.bounds;
    }
}

#pragma chat Bar

//- (void)loadTextChat {
//    _textChatView = [OTTextChatView textChatView];
//    [_textChatView setMaximumTextMessageLength:1050];
//    [_textChatView setAlias:@"You"];
//    
//    
//    CGFloat newY = self.statusBar.layer.frame.size.height + self.chatBar.layer.frame.size.height;
//    
//    CGRect r = self.bounds;
//    r.origin.y += newY;
//    r.size.height -= newY;
//    _textChatView.frame = r;
//    [self insertSubview:_textChatView belowSubview:self.chatBar];
//    self.chatBar.hidden = YES;
//}

- (void)userIsChatting{
    self.chatBtn.hidden = YES;
    self.chatBar.hidden = NO;
}

- (void)hideChatBar{
    self.chatBar.hidden = YES;
}


#pragma fan status changes

- (void) fanIsInline{
    _closeEvenBtn.hidden = YES;
    _leaveLineBtn.hidden = NO;
    _getInLineBtn.hidden = YES;
}
- (void)fanIsOnStage{
    _statusLabel.text = @"\u2022 You are live";
    _statusLabel.hidden = NO;
    _leaveLineBtn.hidden = YES;
    _getInLineBtn.hidden = YES;
    [self hideNotification];
    _chatBtn.hidden = YES;
    _closeEvenBtn.hidden = YES;
    [self hideVideoPreview];
}
- (void)fanLeaveLine{
    _leaveLineBtn.hidden = YES;
    _chatBtn.hidden = YES;
    _closeEvenBtn.hidden = NO;
    _statusLabel.text = @"";
    _getInLineBtn.hidden = NO;
    _inLineHolder.hidden = YES;
}

#pragma status changes
- (void)eventIsClosed{
    _eventImage.hidden = NO;
    _getInLineBtn.hidden = YES;
    _leaveLineBtn.hidden = YES;
    _statusLabel.hidden = YES;
    _chatBtn.hidden = YES;
    _internalHolder.hidden = YES;
    _closeEvenBtn.hidden = NO;
}

@end
