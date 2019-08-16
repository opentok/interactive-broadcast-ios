//
//  EventView.h
//  IBDemo
//
//  Created by Andrea Phillips on 5/20/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>
#import "IBUser.h"


@interface EventView : UIView

@property (weak, nonatomic) IBOutlet UIView *videoHolder;
@property (weak, nonatomic) IBOutlet UIView *statusBar;

@property (weak, nonatomic) IBOutlet UIView *hostViewHolder;
@property (weak, nonatomic) IBOutlet UIView *fanViewHolder;
@property (weak, nonatomic) IBOutlet UIView *celebrityViewHolder;
@property (weak, nonatomic) IBOutlet UIView *internalViewHolder;


@property (weak, nonatomic) IBOutlet UIView *inLineHolder;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventName;

@property (weak, nonatomic) IBOutlet UIButton *getInLineBtn;
@property (weak, nonatomic) IBOutlet UIButton *leaveLineBtn;
@property (weak, nonatomic) IBOutlet UIButton *chatBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeChat;

@property (weak, nonatomic) IBOutlet UIView *chatBar;
@property (weak, nonatomic) IBOutlet UIButton *closeEvenBtn;

@property (weak, nonatomic) IBOutlet UIImageView *eventImage;

#pragma mark - notification bar
- (void)showNotification:(NSString *)text
                useColor:(UIColor *)nColor;
- (void)showError:(NSString *)text
         useColor:(UIColor *)nColor;
- (void)hideNotification;

#pragma mark - loader
- (void)showLoader;
- (void)stopLoader;

#pragma mark - video preview
- (void)showVideoPreviewWithPublisher:(OTPublisher *)publisher;
- (void)hideVideoPreview;

#pragma mark - subscriber views
- (void)adjustSubscriberViewsFrameWithSubscribers:(NSMutableDictionary *)subscribers user:(IBUser *)user;
- (void)addSilhouetteToSubscriber:(NSString *)data;
- (void)removeSilhouetteToSubscriber:(NSString *)data;

#pragma status changes
- (void)eventIsClosed;

#pragma fan status changes
- (void)fanIsInline;
- (void)fanIsOnStage;
- (void)fanLeaveLine;

#pragma chat bar
- (void)userIsChatting;
- (void)hideChatBar;

@end
