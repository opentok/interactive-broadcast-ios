//
//  EventViewController.m
//  IB-ios
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "OTKTextChatComponent.h"
#import "IBApi.h"
#import "IBApi_Internal.h"
#import "IBEvent_Internal.h"
#import "EventViewController.h"

#import "DotSpinnerViewController.h"

#import "EventView.h"
#import "JSON.h"
#import "OTDefaultAudioDevice.h"
#import "UIColor+AppAdditions.h"
#import "UIImageView+Category.h"

#import "OpenTokManager.h"
#import "OpenTokNetworkTest.h"
#import "IBConstants.h"
#import "IBAVPlayer.h"

#import <Firebase/Firebase.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <OTKAnalytics/OTKAnalytics.h>
#import <Reachability/Reachability.h>

@interface EventViewController () <OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate, OTKTextChatDelegate, OTSubscriberKitNetworkStatsDelegate>
@property (nonatomic) OTKTextChatComponent *textChat;
@property (nonatomic) CGFloat chatYPosition;

@property (nonatomic) EventView *eventView;
@property (nonatomic) BOOL stopGoingLive;
@property (nonatomic) CGFloat unreadCount;

// Reachability
@property (nonatomic) Reachability *internetReachability;

// Data
@property (nonatomic) IBUser *user;
@property (nonatomic) IBEvent *event;

// OpenTok
@property (nonatomic) OpenTokManager *openTokManager;
@property (nonatomic) OpenTokNetworkTest *networkTest;
@property (nonatomic) IBAVPlayer *ibPlayer;

@property (nonatomic) NSArray *userTypes;

@end

@implementation EventViewController

- (instancetype)initWithEvent:(IBEvent *)event
                         user:(IBUser *)user {
    
    if (!event || !user) return nil;
    
    if (self = [super initWithNibName:@"EventViewController" bundle:[NSBundle bundleForClass:[self class]]]) {
        
        OTDefaultAudioDevice *defaultAudioDevice = [[OTDefaultAudioDevice alloc] init];
        [OTAudioDeviceManager setAudioDevice:defaultAudioDevice];
        
        _event = event;
        _user = user;
        
        _openTokManager = [[OpenTokManager alloc] init];
        
        // start necessary services
        [self addObserver:self
               forKeyPath:@"event.status"
                  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                  context:NULL];
        
        [self addObserver:self
               forKeyPath:@"openTokManager.canJoinShow"
                  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                  context:NULL];
        
        [self addObserver:self
               forKeyPath:@"openTokManager.startBroadcast"
                  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                  context:NULL];
        
        [self addObserver:self
               forKeyPath:@"openTokManager.endBroadcast"
                  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                  context:NULL];
        
        _internetReachability = [Reachability reachabilityForInternetConnection];
        [_internetReachability startNotifier];
        
        //Connect the logger
        NSString* sourceId = [NSString stringWithFormat:@"%@-%@-%@", [NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"],self.event.adminName,self.event.identifier];
        [OTKLogger analyticsWithClientVersion:KLogClientVersion
                                       source:sourceId
                                  componentId:kLogComponentIdentifier
                                         guid:[[NSUUID UUID] UUIDString]];
        
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        _userTypes = @[@"backstageFan", @"fan", @"host", @"celebrity", @"producer"];
    }
    return self;
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    self.eventView = (EventView *)self.view;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    if (self.internetReachability.currentReachabilityStatus != NotReachable) {
        [self startEvent];
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"Something went wrong, please try again later."];
    }
}

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reachability = [notification object];
    switch (reachability.currentReachabilityStatus) {
        case NotReachable:
            break;
        case ReachableViaWWAN:
        case ReachableViaWiFi:{
            if (!self.event) {
                [self startEvent];
            }
            break;
        }
    }
}

- (void)startEvent {
    
    [SVProgressHUD show];
    
    __weak EventViewController *weakSelf = (EventViewController *)self;
    
    void (^firebaseSigninBlock)(void) = ^() {
        [[FIRAuth auth]
         signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
             [SVProgressHUD dismiss];
             if (!error) {
                 [weakSelf.openTokManager startEvent:weakSelf.event
                                                user:self.user];
                 [weakSelf eventStatusChanged];
             }
             else {
                 NSLog(@"%@", error.localizedDescription);
                 [self dismissViewControllerAnimated:YES completion:^(){
                     [SVProgressHUD showErrorWithStatus:@"Something's wrong. Please try again"];
                 }];
             }
         }];
    };
    
    [[IBApi sharedManager] getEventTokenWithUser:self.user
                                           event:self.event
                                      completion:^(IBEvent * event, NSError * error) {
                                          if (!error && event) {
                                              dispatch_async(dispatch_get_main_queue(), ^(){
                                                  weakSelf.event = event;
                                                  firebaseSigninBlock();
                                              });
                                          }
                                          else {
                                              NSLog(@"%@", error.localizedDescription);
                                              [self dismissViewControllerAnimated:YES completion:^(){
                                                  [SVProgressHUD showErrorWithStatus:@"Something's wrong. Please try again"];
                                              }];
                                          }
                                      }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.eventView performSelector:@selector(adjustSubscriberViewsFrameWithSubscribers:)
                         withObject:self.openTokManager.subscribers
                         afterDelay:1.0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.openTokManager closeEvent];
    [self.openTokManager disconnectOnstageSession];
    [self.openTokManager disconnectBackstageSession];
    [self.openTokManager cleanupPublisher];
    [self.openTokManager cleanupSubscribers];
    [self endBroadcast];
    [IBApi sharedManager].token = nil;
}

- (void)dealloc {
    @try {
        [self removeObserver:self forKeyPath:@"event.status"];
        [self removeObserver:self forKeyPath:@"openTokManager.startBroadcast"];
        [self removeObserver:self forKeyPath:@"openTokManager.endBroadcast"];
        [self removeObserver:self forKeyPath:@"openTokManager.canJoinShow"];
    }
    @catch (id exception) {
        // do nothing
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startBroadcast {
    self.event.status = live;
    [self.eventView hideNotification];
    [SVProgressHUD show];
    
    self.ibPlayer = [[IBAVPlayer alloc] initWithURL:self.openTokManager.broadcastUrl];
    [self.ibPlayer playBroadcastEvent:^(AVPlayerStatus status, NSError *error) {
        if (!error) {
            if (status == AVPlayerStatusReadyToPlay) {
                [self.ibPlayer.player play];
                self.eventView.getInLineBtn.hidden = YES;
                [self.eventView.layer addSublayer:self.ibPlayer.playerLayer];
                [self.ibPlayer.playerLayer setFrame:self.eventView.videoHolder.frame];
                [SVProgressHUD dismiss];
            }
        }
        else {
            [SVProgressHUD showErrorWithStatus:@"Something went wrong, please try again later."];
        }
    }];
}

- (void)endBroadcast {
    if (self.ibPlayer) {
        [self.ibPlayer stopBroadcastEvent];
        [self.ibPlayer.playerLayer removeFromSuperlayer];
    }
    self.event.status = @"closed";
}

- (void)startSession {
    OTSessionSettings *settings = [[OTSessionSettings alloc] init];
    settings.connectionEventsSuppressed = YES;
    self.openTokManager.onstageSession = [[OTSession alloc] initWithApiKey:self.event.apiKey
                                                                 sessionId:self.event.onstageSession
                                                                  delegate:self
                                                                  settings:settings];
    NSError *error = [self.openTokManager connectOnstageWithToken:self.event.onstageToken];
    if (!error) {
        self.eventView.getInLineBtn.hidden = self.user.role == IBUserRoleFan ? NO :  YES;
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"Something went wrong, please try again later."];
    }
}

- (void)loadChat {
    OTSession *currentSession;
    
    if (self.user.status == IBUserStatusInline) {
        currentSession = self.openTokManager.backstageSession;
    }
    else{
        currentSession = self.openTokManager.onstageSession;
    }
    
    _textChat = [[OTKTextChatComponent alloc] init];
    _textChat.delegate = self;
    [_textChat setMaxLength:1050];
    [_textChat setSenderId:currentSession.connection.connectionId alias:@"You"];
    
    _chatYPosition = self.eventView.statusBar.layer.frame.size.height + self.eventView.chatBar.layer.frame.size.height;
    
    CGRect r = self.view.bounds;
    r.origin.y += _chatYPosition;
    r.size.height -= _chatYPosition;
    (_textChat.view).frame = r;
    [self.eventView insertSubview:_textChat.view belowSubview:self.eventView.chatBar];
    
    if(self.user.role != IBUserRoleFan){
        self.eventView.chatBtn.hidden = NO;
    }
    
    self.textChat.view.hidden = YES;
    [_eventView hideChatBar];
    _unreadCount = 0;
}

- (void)unpublishBackstage {
    [self.openTokManager unpublishFrom:self.openTokManager.backstageSession];
}

- (void)forceDisconnect {
    [self.openTokManager cleanupPublisher];
    [self.openTokManager disconnectOnstageSession];
    
    NSString *text = [NSString stringWithFormat: @"There already is a %@ using this session. If this is you please close all applications or browser sessions and try again.", self.user.role == IBUserRoleFan ? @"celebrity" : @"host"];
    [self.eventView showNotification:text useColor:[UIColor SLBlueColor]];
    self.eventView.videoHolder.hidden = YES;
}

#pragma mark - publishers
- (void)doPublish {
    if (self.user.role == IBUserRoleFan) {

        if (self.user.status == IBUserStatusInline) {
            [self publishTo:self.openTokManager.backstageSession];
            [self.eventView.fanViewHolder addSubview:self.openTokManager.publisher.view];
            self.openTokManager.publisher.view.frame = CGRectMake(0, 0, self.eventView.inLineHolder.bounds.size.width, self.eventView.inLineHolder.bounds.size.height);
            [self.eventView fanIsInline];
            [self.eventView stopLoader];
        }
        
        if (self.user.status == IBUserStatusOnstage) {
            [self publishTo:self.openTokManager.onstageSession];
            [self.eventView.fanViewHolder addSubview:self.openTokManager.publisher.view];
            self.openTokManager.publisher.view.frame = CGRectMake(0, 0, self.eventView.fanViewHolder.bounds.size.width, self.eventView.fanViewHolder.bounds.size.height);
            [self.eventView fanIsOnStage];
        }
    }
    else {
        if(self.user.role == IBUserRoleCelebrity && !self.stopGoingLive){
            [self publishTo:self.openTokManager.onstageSession];
            [self.eventView.celebrityViewHolder addSubview:self.openTokManager.publisher.view];
            (self.openTokManager.publisher.view).frame = CGRectMake(0, 0, self.eventView.celebrityViewHolder.bounds.size.width, self.eventView.celebrityViewHolder.bounds.size.height);
        }
        
        if(self.user.role == IBUserRoleHost && !self.stopGoingLive){
            [self publishTo:self.openTokManager.onstageSession];
            [self.eventView.hostViewHolder addSubview:self.openTokManager.publisher.view];
            (self.openTokManager.publisher.view).frame = CGRectMake(0, 0, self.eventView.hostViewHolder.bounds.size.width, self.eventView.hostViewHolder.bounds.size.height);
        }
        
        if (self.stopGoingLive){
            [self forceDisconnect];
        }
    }
    
    [self.eventView adjustSubscriberViewsFrameWithSubscribers:self.openTokManager.subscribers];
}

- (void)publishTo:(OTSession *)session {
    NSString *session_name = _openTokManager.onstageSession.sessionId == session.sessionId ? @"Onstage" : @"Backstage";
    NSString *logtype = [NSString stringWithFormat:@"%@Publishes%@", [[self.user userRoleName] capitalizedString], session_name];
    [OTKLogger logEventAction:logtype variation:KLogVariationAttempt completion:nil];
    
    if(!self.openTokManager.publisher){
        OTPublisherSettings *settings = [[OTPublisherSettings alloc] init];
        self.openTokManager.publisher = [[OTPublisher alloc] initWithDelegate:self settings:settings];
    }
    
    OTError *error = nil;
    [session publish:self.openTokManager.publisher error:&error];
    
    if (error) {
        NSLog(@"%@", error);
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [OTKLogger logEventAction:logtype variation:KLogVariationFailure completion:nil];
    }
    else{
        [OTKLogger logEventAction:logtype variation:KLogVariationSuccess completion:nil];
    }
}

- (void)setupProducerPrivateCall {

    [self.openTokManager.privateCallRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if ([snapshot.value isEqual:[NSNull null]]) {
            
            // end private call
            [self.openTokManager unsubscribeOnstageProducerCall];
            [self.openTokManager unsubscribeFromPrivateProducerCall];
            if (self.user.status == IBUserStatusBackstage) {
                self.eventView.getInLineBtn.hidden = NO;
                [self.eventView showNotification:@"Going Backstage.You are sharing video." useColor:[UIColor SLBlueColor]];
            }
            else {
                [self.eventView hideVideoPreview];
                [self.eventView hideNotification];
            }
        }
        else if (![snapshot.value isEqual:[NSNull null]]) {
            
            // start private call
            NSString *isWith = snapshot.value[@"isWith"];
            NSString *fanId = snapshot.value[@"fanId"];
            
            if ([fanId isEqualToString:[FIRAuth auth].currentUser.uid]) {
                if ([isWith isEqualToString:@"fan"]) { 
                    [self doSubscribe:self.openTokManager.privateProducerStream];
                }
                else if ([isWith isEqualToString:@"backstageFan"] || [isWith isEqualToString:@"activeFan"]) {
                    [self doSubscribe:self.openTokManager.producerStream];
                }
                self.openTokManager.publisher.publishAudio = YES;
                [self.openTokManager muteOnstageSession:YES];
                [self.eventView showNotification:@"YOU ARE NOW IN PRIVATE CALL WITH PRODUCER" useColor:[UIColor SLBlueColor]];
                [self.eventView showVideoPreviewWithPublisher:self.openTokManager.publisher];
            }
            else {
                [self.openTokManager muteOnstageSession:YES];
                
                if (self.user.status == IBUserStatusOnstage) {
                    [self.eventView showNotification:@"OTHER PARTICIPANTS ARE IN A PRIVATE CALL. THEY MAY NOT BE ABLE TO HEAR YOU." useColor:[UIColor SLBlueColor]];
                }
            }
        }
    }];
}

# pragma mark - OTPublisher delegate callbacks
- (void)publisher:(OTPublisherKit *)publisher streamCreated:(OTStream *)stream {
    
    if (self.user.status == IBUserStatusInline) {
        NSLog(@"stream Created PUBLISHER BACK");
        
        // report get inline
        [self.openTokManager getInLine:self.user];
        
        // observe private call
        [self setupProducerPrivateCall];
        
        self.openTokManager.selfSubscriber = [[OTSubscriber alloc] initWithStream:stream
                                                                         delegate:self];
        self.openTokManager.selfSubscriber.subscribeToAudio = NO;
        
        OTError *error = nil;
        [self.openTokManager.backstageSession subscribe:self.openTokManager.selfSubscriber error:&error];
        if (error) {
            NSLog(@"subscribe self error");
        }
    }
    else{
        [self doSubscribe:stream];
    }
    
    // update stream id property in firebase
    [self.openTokManager getOnstage];
    
    [self performSelector:@selector(startNetworkTest)
               withObject:nil
               afterDelay:5.0];
}

- (void)publisher:(OTPublisherKit*)publisher
  streamDestroyed:(OTStream *)stream {
    
    NSString *me = [self.user userRoleName];
    OTSubscriber *subscriber = self.openTokManager.subscribers[me];
    
    if ([subscriber.stream.streamId isEqualToString:stream.streamId]) {
        NSLog(@"stream DESTROYED ONSTAGE %@", me);
        NSString *logtype = [NSString stringWithFormat:@"%@UnpublishesOnstage",[me capitalizedString]];
        [OTKLogger logEventAction:logtype variation:KLogVariationSuccess completion:nil];
        [self.openTokManager cleanupSubscriber:me];
        [self.eventView adjustSubscriberViewsFrameWithSubscribers:self.openTokManager.subscribers];
    }
    else if ([self.openTokManager.selfSubscriber.stream.streamId isEqualToString:stream.streamId]) {
        [self.openTokManager unsubscribeSelfFromProducerSession];
    }
    [self.openTokManager cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher didFailWithError:(OTError*) error {
    NSLog(@"publisher didFailWithError %@", error);
    [self.openTokManager cleanupPublisher];
}

- (void)doSubscribe:(OTStream *)stream {
    
    if (!stream || !stream.connection) return;
    NSDictionary *connectionData = [JSON parseJSON:stream.connection.data];
    NSString *roleName = connectionData[@"userType"];
    
    if (!roleName) return;
    
    if (stream.session.connection.connectionId != self.openTokManager.backstageSession.connection.connectionId && ![roleName isEqualToString:@"producer"]){
        
        OTSubscriber *subs = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        subs.viewScaleBehavior = OTVideoViewScaleBehaviorFit;
        self.openTokManager.subscribers[roleName] = subs;
        
        if ([self.openTokManager subscribeToOnstageWithType:roleName]) {
            [self.eventView showError:@"You are experiencing network connectivity issues. Please try closing the application and coming back to the event"
                             useColor:[UIColor SLRedColor]];
        }
        subs = nil;
    }
    
    if (stream.session.connection.connectionId == self.openTokManager.backstageSession.connection.connectionId && [roleName isEqualToString:@"producer"]){
        self.openTokManager.producerSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        if ([self.openTokManager backstageSubscribeToProducer]) {
            [self.eventView showError:@"You are experiencing network connectivity issues. Please try closing the application and coming back to the event"
                             useColor:[UIColor SLRedColor]];
        }
        self.openTokManager.producerSubscriber = nil;
    }
    
    if (stream.session.connection.connectionId == self.openTokManager.onstageSession.connection.connectionId && [roleName isEqualToString:@"producer"]){
        NSString *logtype = [NSString stringWithFormat:@"%@SubscribesProducer", [[self.user userRoleName] capitalizedString]];
        [OTKLogger logEventAction:logtype variation:KLogVariationAttempt completion:nil];
        self.openTokManager.privateProducerSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        if ([self.openTokManager onstageSubscribeToProducer]) {
            [self.eventView showError:@"You are experiencing network connectivity issues. Please try closing the application and coming back to the event"
                             useColor:[UIColor SLRedColor]];
        }
        self.openTokManager.privateProducerSubscriber = nil;
    }
}

# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber {
    _networkTest = [[OpenTokNetworkTest alloc] initWithFrameRateAndResolution:@"30" resolution:@"640x480"];
    
    if (subscriber.session.connection.connectionId == self.openTokManager.onstageSession.connection.connectionId &&
        subscriber.stream != self.openTokManager.privateProducerStream){
        
        NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
        
        UIView *holder;
        NSDictionary *connectionData = [JSON parseJSON:subscriber.stream.connection.data];
        NSString *roleName = connectionData[@"userType"];
        if ([roleName isEqualToString:@"backstageFan"]) roleName = @"fan";
        OTSubscriber *_subscriber = self.openTokManager.subscribers[roleName];
        NSString *logtype = [NSString stringWithFormat:@"%@Subscribes%@", [[self.user userRoleName] capitalizedString],[roleName capitalizedString]];
        [OTKLogger logEventAction:logtype variation:KLogVariationSuccess completion:nil];
        
        assert(_subscriber == subscriber);
        
        holder = [self.eventView valueForKey:[NSString stringWithFormat:@"%@ViewHolder", roleName]];
        (_subscriber.view).frame = CGRectMake(0, 0, holder.bounds.size.width,holder.bounds.size.height);
        
        [holder addSubview:_subscriber.view];
        self.eventView.eventImage.hidden = YES;
        [self.eventView adjustSubscriberViewsFrameWithSubscribers:self.openTokManager.subscribers];
    }
    
    if (self.openTokManager.publisher && self.openTokManager.publisher.stream.connection.connectionId == subscriber.stream.connection.connectionId){
        subscriber.subscribeToAudio = NO;
    }
}

- (void)subscriber:(OTSubscriberKit*)subscriber didFailWithError:(OTError*)error {
    NSLog(@"subscriber %@ didFailWithError %@",subscriber.stream.streamId,error);
    [self.eventView showNotification:@"You are experiencing network connectivity issues. Please try closing the application and coming back to the event" useColor:[UIColor SLRedColor]];
}

- (void)subscriberVideoDisabled:(OTSubscriberKit*)subscriber
                         reason:(OTSubscriberVideoEventReason)reason {
    [self.eventView addSilhouetteToSubscriber:subscriber];
}

- (void)subscriberVideoEnabled:(OTSubscriberKit*)subscriber
                        reason:(OTSubscriberVideoEventReason)reason {
    [self.eventView removeSilhouetteToSubscriber:subscriber];
}

- (void)subscriberVideoDisableWarning:(OTSubscriberKit *)subscriber {
    subscriber.subscribeToVideo = NO;
    [self.eventView addSilhouetteToSubscriber:subscriber];
}

- (void)subscriberVideoDisableWarningLifted:(OTSubscriberKit *)subscriber {
    subscriber.subscribeToVideo = YES;
    [self.eventView removeSilhouetteToSubscriber:subscriber];
}

- (void)startNetworkTest {
    if (self.user.status == IBUserStatusInline ||
        self.user.status == IBUserStatusOnstage) {
        
        if (self.openTokManager.hostStream &&
           self.openTokManager.hostStream.hasVideo &&
           [self.event.status isEqualToString:live]) {
            
            OTSubscriber *test = self.openTokManager.subscribers[@"host"];
            test.networkStatsDelegate = self;
        }
        else if (self.openTokManager.celebrityStream &&
                self.openTokManager.celebrityStream.hasVideo &&
                [self.event.status isEqualToString:live]) {
            
            OTSubscriber *test = self.openTokManager.subscribers[@"celebrity"];
            test.networkStatsDelegate = self;
        }
        else if (self.openTokManager.selfSubscriber) {
            self.openTokManager.selfSubscriber.networkStatsDelegate = self;
        }
    }
}

- (void)subscriber:(OTSubscriberKit*)subscriber videoNetworkStatsUpdated:(OTSubscriberKitVideoNetworkStats *)stats {
    if (stats.timestamp - self.networkTest.prevVideoTimestamp >= 3000) {
        subscriber.delegate = nil;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self checkQualityAndSendSignal];
        });
    }
    [self.networkTest setStats:stats];
}

- (void)checkQualityAndSendSignal {
    if (self.openTokManager.publisher && self.openTokManager.publisher.session) {
        [self.openTokManager updateNetworkQuality:[self.networkTest getQuality]];
        [self startNetworkTest];
    }
}

# pragma mark - OTSession delegate callbacks
- (void)sessionDidConnect:(OTSession*)session {
    
    if (self.user.role == IBUserRoleFan) {
        if (session.sessionId == self.openTokManager.onstageSession.sessionId) {
            self.user.status = IBUserStatusOnstage;
            (self.eventView.statusLabel).text = @"";
            self.eventView.closeEvenBtn.hidden = NO;
        }
        
        if (session.sessionId == self.openTokManager.backstageSession.sessionId) {
            self.user.status = IBUserStatusInline;
            [self.eventView fanIsInline];
            [self doPublish];
            [self loadChat];
        }
    }
    else {
        [self.eventView showLoader];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.stopGoingLive) {
                [self forceDisconnect];
            }
            else{
                [self loadChat];
                self.user.status = IBUserStatusOnstage;
                [self doPublish];
            }
            [self.eventView stopLoader];
        });
    }
}

- (void)sessionDidBeginReconnecting:(OTSession *)session {
    [SVProgressHUD showWithStatus:@"Reconnecting..."];
}

- (void)sessionDidReconnect:(OTSession *)session {
    [SVProgressHUD dismiss];
}

- (void)sessionDidDisconnect:(OTSession*)session {
    
    NSLog(@"sessionDidDisconnect (%@)", session.sessionId);
    if (session == self.openTokManager.backstageSession) {

        self.user.status = IBUserStatusJoined;

        [self.openTokManager cleanupPublisher];
        [self.eventView hideNotification];
        
        if (![self.event.status isEqualToString:@"closed"]) {
            [self.openTokManager leaveLine];
            [self.eventView fanLeaveLine];
        }
        self.openTokManager.backstageSession = nil;
    }
    else {
        self.eventView.getInLineBtn.hidden = YES;
        self.openTokManager.onstageSession = nil;
    }
}


- (void)session:(OTSession*)session
  streamCreated:(OTStream *)stream {
    
    NSLog(@"session streamCreated (%@)", stream.streamId);
    
    NSDictionary *streamConnectionData = [JSON parseJSON:stream.connection.data];
    NSString *userType = streamConnectionData[@"userType"];
    
    if (session.connection.connectionId != self.openTokManager.backstageSession.connection.connectionId) {
        
        if ([userType isEqualToString:@"producer"]) {
            self.openTokManager.privateProducerStream = stream;
        }
        else {
            
            if ([userType isEqualToString:@"host"]){
                self.openTokManager.hostStream = stream;
                if (self.user.role == IBUserRoleHost){
                    self.stopGoingLive = YES;
                }
            }
            else if ([userType isEqualToString:@"celebrity"]){
                self.openTokManager.celebrityStream = stream;
                if (self.user.role == IBUserRoleCelebrity){
                    self.stopGoingLive = YES;
                }
            }
            else if ([userType isEqualToString:@"fan"]){
                self.openTokManager.fanStream = stream;
            }
            
            if ([self.event.status isEqualToString:live] ||
                self.user.role == IBUserRoleCelebrity ||
                self.user.role == IBUserRoleHost) {
                [self doSubscribe:stream];
            }
        }
    }
    else {
        if([userType isEqualToString:@"producer"]){
            self.openTokManager.producerStream = stream;
        }
    }
}

- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream {
    
    NSDictionary *streamConnectionData = [JSON parseJSON:stream.connection.data];
    NSString *userType = streamConnectionData[@"userType"];
    
    if ([userType isEqualToString:@"producer"]) {
        if (session.connection.connectionId == self.openTokManager.backstageSession.connection.connectionId) {
            self.openTokManager.producerStream = nil;
        }
        else {
            self.openTokManager.privateProducerStream = nil;
        }
    }
    else {
        if (session.connection.connectionId == self.openTokManager.onstageSession.connection.connectionId) {
            if ([userType isEqualToString:@"host"]){
                self.openTokManager.hostStream = nil;
            }
            
            if ([userType isEqualToString:@"celebrity"]){
                self.openTokManager.celebrityStream = nil;
            }
            
            if ([userType isEqualToString:@"fan"]){
                self.openTokManager.fanStream = nil;
            }
            [self.openTokManager cleanupSubscriber:userType];
            [self.eventView adjustSubscriberViewsFrameWithSubscribers:self.openTokManager.subscribers];
        }
    }
}

- (void) session:(OTSession*)session didFailWithError:(OTError*)error {
    [self.eventView showNotification:@"You are experiencing network connectivity issues. Please try closing the application and coming back to the event"
                            useColor:[UIColor SLRedColor]];
    NSLog(@"didFailWithError: (%@)", error);
}


#pragma mark - session signal handler
- (void)session:(OTSession*)session receivedSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string {
    
    NSDictionary *connectionData = [JSON parseJSON:connection.data];
    NSString *userType = connectionData[@"userType"];
    if (!type || !userType || ![self.userTypes containsObject:userType]) {
        return;
    }
    
    NSDictionary* messageData;
    if(string){
        messageData = [JSON parseJSON:string];
    }
    NSLog(@"session did receiveSignalType: (%@)", type);
    
    if ([type isEqualToString:@"startEvent"]){
        if ([self.event.status isEqualToString:notStarted]){
            self.event.status = preshow;
        }
    }
    else if ([type isEqualToString:@"muteAudio"]){
        [messageData[@"mute"] isEqualToString:@"on"] ? [_openTokManager.publisher setPublishAudio: NO] : [self.openTokManager.publisher setPublishAudio: YES];
    }
    else if ([type isEqualToString:@"videoOnOff"]){
        [messageData[@"video"] isEqualToString:@"on"] ? [_openTokManager.publisher setPublishVideo: YES] : [self.openTokManager.publisher setPublishVideo: NO];
    }
    else if ([type isEqualToString:@"newBackstageFan"]) { // celebrity and host
        if (self.user.role != IBUserRoleFan) {
            [self.eventView showError:@"A new FAN has been moved to backstage" useColor:[UIColor SLBlueColor]];
        }
    }
    else if ([type isEqualToString:@"joinBackstage"]){
        self.user.status = IBUserStatusBackstage;
        self.eventView.statusLabel.text = @"BACKSTAGE";
        [self.eventView showVideoPreviewWithPublisher:self.openTokManager.publisher];
        [self.eventView showNotification:@"Going Backstage.You are sharing video." useColor:[UIColor SLBlueColor]];
    }
    else if ([type isEqualToString:@"disconnectBackstage"]) {
        self.user.status = IBUserStatusInline;
        self.openTokManager.publisher.publishAudio = NO;
        self.eventView.leaveLineBtn.hidden = NO;
        self.eventView.statusLabel.text = @"IN LINE";
        [self.eventView hideNotification];
        [self.eventView hideVideoPreview];
    }
    else if ([type isEqualToString:@"prepareGoLive"]) { // cel&host only
        [DotSpinnerViewController show];
    }
    else if([type isEqualToString:@"goLive"]){
        [DotSpinnerViewController dismiss];
        self.event.status = live;
    }
    else if([type isEqualToString:@"joinHost"]){
        if (self.user.status != IBUserStatusOnstage) {
            self.user.status = IBUserStatusOnstage;
            [self unpublishBackstage];
            [self hideChatBox];
            [self.eventView fanIsOnStage];
            if (![self.event.status isEqualToString:live]) {
                [self goLive];
            }
            [DotSpinnerViewController show];
        }
    }
    else if ([type isEqualToString:@"joinHostNow"]) {
        [DotSpinnerViewController dismiss];
        [self doPublish];
    }
    else if([type isEqualToString:@"finishEvent"]) {
        // this is the only place where the iOS client should manipulate the event status
        self.event.status = @"closed";
    }
    else if([type isEqualToString:@"disconnect"]) {
        
        self.eventView.statusLabel.hidden = YES;
        self.eventView.chatBtn.hidden = YES;
        self.eventView.closeEvenBtn.hidden = NO;
        self.eventView.getInLineBtn.hidden = NO;
        
        [self hideChatBox];
        
        self.user.status = IBUserStatusInline;
        
        if (self.openTokManager.publisher) {
            [self.openTokManager unpublishFrom:self.openTokManager.onstageSession];
        }
        [self.openTokManager disconnectBackstageSession];
        [self.openTokManager leaveLine];
        
        [self.eventView showError:@"Thank you for participating, you are no longer sharing video/voice. You can continue to watch the session at your leisure." useColor:[UIColor SLBlueColor]];
    }
    else if([type isEqualToString:@"chatMessage"]){
        if (![connection.connectionId isEqualToString:session.connection.connectionId]) {
            self.eventView.chatBtn.hidden = NO;
            self.openTokManager.producerConnection = connection;
            OTKChatMessage *msg = [[OTKChatMessage alloc] init];
            msg.senderAlias = userType;
            msg.senderId = connection.connectionId;
            msg.text = messageData[@"text"];
            _unreadCount ++;
            [self.textChat addMessage:msg];
            [self.eventView.chatBtn setTitle:[NSString stringWithFormat:@"%.0f", _unreadCount] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - status observer
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([change[@"old"] isEqual:[NSNull null]] || [change[@"new"] isEqual:[NSNull null]]) return;
    
    if ([keyPath isEqual:@"event.status"] && ![change[@"old"] isEqualToString:change[@"new"]]) {
        [self eventStatusChanged];
    }
    
    if ([keyPath isEqual:@"openTokManager.startBroadcast"] && ![change[@"old"] isEqualToValue:change[@"new"]]) {
        if (self.openTokManager.startBroadcast) {
            [self startBroadcast];
        }
    }
    
    if ([keyPath isEqual:@"openTokManager.endBroadcast"] && ![change[@"old"] isEqualToValue:change[@"new"]]) {
        if (self.openTokManager.endBroadcast) {
            [self endBroadcast];
        }
    }
    
    if ([keyPath isEqual:@"openTokManager.canJoinShow"] && ![change[@"old"] isEqualToValue:change[@"new"]]) {
        [self startSession];
    }
}

- (void)eventStatusChanged {
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        
        self.eventView.eventName.text = [NSString stringWithFormat:@"%@ (%@)", self.event.name, self.event.descriptiveStatus];
        
        if ([self.event.status isEqualToString:notStarted]) {
            
            if (self.user.role != IBUserRoleFan) {
                self.eventView.eventImage.hidden = YES;
            }
            else {
                self.eventView.eventImage.hidden = NO;
                [self.eventView.eventImage loadImageWithUrl:self.event.imageURL];
                self.eventView.getInLineBtn.hidden = YES;
            }
        }
        else if([self.event.status isEqualToString:preshow]) {
            
            if (self.user.role != IBUserRoleFan) {
                self.eventView.eventImage.hidden = YES;
                self.eventView.getInLineBtn.hidden = YES;
            }
            else {
                self.eventView.eventImage.hidden = NO;
                [self.eventView.eventImage loadImageWithUrl:self.event.imageURL];
                if (self.openTokManager.canJoinShow) {
                    self.eventView.getInLineBtn.hidden = NO;
                }
            }
        }
        else if ([self.event.status isEqualToString:live]) {
            
            if (self.openTokManager.subscribers.count > 0) {
                self.eventView.eventImage.hidden = YES;
            }
            else {
                self.eventView.eventImage.hidden = NO;
                [self.eventView.eventImage loadImageWithUrl:self.event.imageURL];
            }
            
            if (self.user.role == IBUserRoleFan &&
                self.user.status != IBUserStatusInline &&
                self.user.status != IBUserStatusOnstage) {
                if (self.openTokManager.onstageSession) {
                    self.eventView.getInLineBtn.hidden = NO;
                }
            }
            [self goLive];
        }
        else if ([self.event.status isEqualToString:closed]) {
            
            [self.openTokManager disconnectOnstageSession];
            
            if (self.user.status == IBUserStatusInline) {
                [self.openTokManager disconnectBackstageSession];
            }
            [self.eventView eventIsClosed];
            [self.openTokManager cleanupPublisher];
            [self.openTokManager cleanupSubscribers];
            [self endBroadcast];
            
            if (self.event.endImageURL) {
                [self.eventView.eventImage loadImageWithUrl:self.event.endImageURL];
            }
        }
    });
}

- (void)goLive {
    NSLog(@"Event changed status to LIVE");
    if (self.openTokManager.hostStream && !self.openTokManager.subscribers[@"host"]) {
        [self doSubscribe:self.openTokManager.hostStream];
    }
    
    if (self.openTokManager.celebrityStream && !_openTokManager.subscribers[@"celebrity"]) {
        [self doSubscribe:self.openTokManager.celebrityStream];
    }
    
    if (self.openTokManager.fanStream && !_openTokManager.subscribers[@"fan"]) {
        [self doSubscribe:self.openTokManager.fanStream];
    }
}

#pragma mark - OTChat
- (void)keyboardWillShow:(NSNotification*)aNotification {
    NSDictionary* info = aNotification.userInfo;
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    double duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    _chatYPosition = 106 - _textChat.view.bounds.size.height ;
    [UIView animateWithDuration:duration animations:^{
        CGRect r = self.view.bounds;
        r.origin.y += _chatYPosition;
        r.size.height -= _chatYPosition + kbSize.height;
        _textChat.view.frame = r;
    }];
}

- (void)keyboardWillHide:(NSNotification*)aNotification {
    NSDictionary* info = aNotification.userInfo;
    double duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    _chatYPosition = self.eventView.statusBar.layer.frame.size.height + self.eventView.chatBar.layer.frame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        
        CGRect r = self.view.bounds;
        r.origin.y += _chatYPosition;
        r.size.height -= _chatYPosition;
        _textChat.view.frame = r;
    }];
}

- (BOOL)onMessageReadyToSend:(OTKChatMessage *)message {
    OTError *error = nil;
    OTSession *currentSession;

    if (self.user.role != IBUserRoleFan || self.user.status == IBUserStatusOnstage) {
        currentSession = self.openTokManager.onstageSession;
    }
    else {
        currentSession = self.openTokManager.backstageSession;
    }
    
    NSDictionary *textchatInfo = @{
                                   @"text": message.text,
                                   @"timestamp": @([NSDate date].timeIntervalSince1970),
                                   @"fromType": self.user.role == IBUserRoleFan ? @"activeFan" : self.user.userRoleName,
                                   @"fromId": [FIRAuth auth].currentUser.uid
                                   };
    
    [currentSession signalWithType:@"chatMessage"
                            string:[JSON stringify:textchatInfo]
                        connection: self.openTokManager.producerConnection
                             error:&error];
    if (error) {
        return NO;
    }
    return YES;
}

#pragma mark - fan Actions
- (IBAction)chatNow:(id)sender {
    [UIView animateWithDuration:0.5 animations:^() {
        [self showChatBox];
        _unreadCount = 0;
        [self.eventView.chatBtn setTitle:@"" forState:UIControlStateNormal];
    }];
}

- (IBAction)closeChat:(id)sender {
    [UIView animateWithDuration:0.5 animations:^() {
        [self hideChatBox];
        if(self.user.role != IBUserRoleFan){
            self.eventView.chatBtn.hidden = NO;
        }
    }];
}

- (IBAction)getInLineClick:(id)sender {
    self.openTokManager.backstageSession = [[OTSession alloc] initWithApiKey:self.event.apiKey
                                                                   sessionId:self.event.backstageSession
                                                                    delegate:self];
    
    NSError *error = [self.openTokManager connectBackstageWithToken:self.event.backstageToken];
    if (!error) {
        [self.eventView showLoader];
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"Something went wrong, please try again later."];
    }
}

- (IBAction)leaveLine:(id)sender {
    self.user.status = IBUserStatusJoined;
    [self.openTokManager leaveLine];
    [self unpublishBackstage];
    [self.openTokManager disconnectBackstageSession];
    self.openTokManager.backstageSession = nil;
    [self.eventView fanLeaveLine];
    [self.eventView hideNotification];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)showChatBox {
    self.textChat.view.hidden = NO;
    [self.eventView userIsChatting];
}

- (void)hideChatBox {
    self.textChat.view.hidden = YES;
    [self.eventView hideChatBar];
}

- (IBAction)goBack:(id)sender {
    [self.openTokManager disconnectBackstageSession];
    [self.openTokManager disconnectOnstageSession];
    [self.openTokManager cleanupSubscribers];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - orientation
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end
