//
//  EventViewController.h
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>

@interface EventViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *videoHolder;


@property (weak, nonatomic) IBOutlet UIView *statusBar;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventName;
@property (weak, nonatomic) IBOutlet UIButton *getInLineBtn;
@property (weak, nonatomic) IBOutlet UIButton *leaveLineBtn;
@property (weak, nonatomic) IBOutlet UIButton *chatBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeChat;
@property (weak, nonatomic) IBOutlet UIView *chatBar;
@property (weak, nonatomic) IBOutlet UIButton *closeEvenBtn;
@property (weak, nonatomic) IBOutlet UIButton *dismissInline;
@property (weak, nonatomic) IBOutlet UILabel *inlineNotification;

@property (nonatomic) NSMutableDictionary *user;
@property (nonatomic) NSMutableDictionary *eventData;
@property (nonatomic) NSMutableDictionary *connectionData;

@property (nonatomic) NSString *apikey;
@property (nonatomic) NSString *userName;
@property (nonatomic) Boolean isCeleb;
@property (nonatomic) Boolean isHost;
@property (nonatomic) NSString *connectionQuality;

@property (weak, nonatomic) IBOutlet UIView *internalHolder;
@property (weak, nonatomic) IBOutlet UIView *HostViewHolder;
@property (weak, nonatomic) IBOutlet UIView *FanViewHolder;
@property (weak, nonatomic) IBOutlet UIView *CelebrityViewHolder;
@property (weak, nonatomic) IBOutlet UIView *inLineHolder;
@property (weak, nonatomic) IBOutlet UIImageView *eventImage;

@property (weak, nonatomic) IBOutlet UIView *notificationBar;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;

- (id)initEventWithData:(NSDictionary *)aEventData connectionData:(NSMutableDictionary *)aConnectionData user:(NSMutableDictionary *)aUser isSingle:(BOOL)aSingle NS_DESIGNATED_INITIALIZER;

@end
