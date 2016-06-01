//
//  EventViewController.m
//  IB-ios
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "SIOSocket.h"

#import "OTKTextChatComponent.h"
#import "IBApi.h"

#import "EventViewController.h"

#import "SVProgressHUD.h"
#import "DotSpinnerViewController.h"

#import "OTKAnalytics.h"

#import "EventView.h"
#import "IBInstance_Internal.h"
#import "IBDateFormatter.h"
#import "AppUtil.h"
#import "JSON.h"
#import "UIColor+AppAdditions.h"
#import "UIView+Category.h"
#import "UIImageView+Category.h"
#import "PerformSelectorWithDebounce.h"

#import "OpenTokManager.h"
#import "OpenTokNetworkTest.h"

#import <Reachability/Reachability.h>

@interface EventViewController () <OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate, OTKTextChatDelegate,OTSubscriberKitNetworkStatsDelegate>

@property (nonatomic) NSString *userName;
@property (nonatomic) BOOL isCeleb;
@property (nonatomic) BOOL isHost;
@property (nonatomic) NSMutableDictionary *errors;

@property (nonatomic) NSString *connectionQuality;

@property (nonatomic) OTKTextChatComponent *textChat;
@property (nonatomic) OTKAnalytics *logging;
@property (nonatomic) SIOSocket *signalingSocket;
@property (nonatomic) CGFloat chatYPosition;

@property (nonatomic) EventView *eventView;
@property (nonatomic) BOOL isBackstage;
@property (nonatomic) BOOL isOnstage;
@property (nonatomic) BOOL shouldResendProducerSignal;
@property (nonatomic) BOOL inCallWithProducer;
@property (nonatomic) BOOL isLive;
@property (nonatomic) BOOL isFan;
@property (nonatomic) BOOL stopGoingLive;
@property (nonatomic) CGFloat unreadCount;

// Reachability
@property (nonatomic) Reachability *internetReachability;

// Data
@property (nonatomic) NSDictionary *user;
@property (nonatomic) IBEvent *event;
@property (nonatomic) IBInstance *instance;

// OpenTok
@property (nonatomic) OpenTokManager *openTokManager;
@property (nonatomic) OpenTokNetworkTest *networkTest;

@end

@implementation EventViewController

static NSString* const kTextChatType = @"chatMessage";

- (instancetype)initWithInstance:(IBInstance *)instance
                       indexPath:(NSIndexPath *)indexPath
                            user:(NSDictionary *)user {
    if (self = [super initWithNibName:@"EventViewController" bundle:[NSBundle bundleForClass:[self class]]]) {
        
        //Unsure of this 2 lines..
        OTDefaultAudioDevice *defaultAudioDevice = [[OTDefaultAudioDevice alloc] init];
        [OTAudioDeviceManager setAudioDevice:defaultAudioDevice];
        
        _instance = instance;
        _event = _instance.events[indexPath.row];
        _userName = user[@"name"] ? user[@"name"] : user[@"type"];
        _user = user;
        _isCeleb = [user[@"type"] isEqualToString:@"celebrity"];
        _isHost = [user[@"type"] isEqualToString:@"host"];
        
        _openTokManager = [[OpenTokManager alloc] init];
        _openTokManager.subscribers = [[NSMutableDictionary alloc]initWithCapacity:3];
        
        _isFan = !_isCeleb && !_isHost;
        
        //observers
        [_event addObserver:self
                     forKeyPath:@"status"
                        options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                        context:NULL];
        
        _internetReachability = [Reachability reachabilityForInternetConnection];
        [_internetReachability startNotifier];
    }
    return self;
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    self.eventView = (EventView *)self.view;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    if (self.internetReachability.currentReachabilityStatus != NotReachable) {
        [self createEventToken];
    }
}

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reachability = [notification object];
    switch (reachability.currentReachabilityStatus) {
        case NotReachable:
            break;
        case ReachableViaWWAN:
        case ReachableViaWiFi:{
            
            if (!self.instance) {
                [self createEventToken];
            }
            break;
        }
    }
}

- (void)createEventToken{
    
    [SVProgressHUD show];
    [IBApi createEventTokenWithUserType:self.user[@"type"]
                                  event:self.event
                             completion:^(IBInstance *instance, NSError *error) {
                                 [SVProgressHUD dismiss];
                                 
                                 if (!error && instance.events.count == 1) {
                                     self.instance = instance;
                                     self.event = [self.instance.events lastObject];
                                     [self statusChanged];
                                     self.eventView.eventName.text = [NSString stringWithFormat:@"%@ (%@)", self.event.eventName, [AppUtil convertToStatusString:self.event]];
                                     [self startSession];
                                 }
                             }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self performSelector:@selector(adjustChildrenWidth) withObject:nil afterDelay:1.0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)startSession{
    _networkTest.prevVideoTimestamp = 0;
    _networkTest.prevVideoBytes = 0;
    _networkTest.prevAudioTimestamp = 0;
    _networkTest.prevAudioBytes = 0;
    _networkTest.prevVideoPacketsLost = 0;
    _networkTest.prevVideoPacketsRcvd = 0;
    _networkTest.prevAudioPacketsLost = 0;
    _networkTest.prevAudioPacketsRcvd = 0;
    _networkTest.video_bw = 0;
    _networkTest.audio_bw = 0;
    _networkTest.video_pl_ratio = -1;
    _networkTest.audio_pl_ratio = -1;
    
    _openTokManager.session = [[OTSession alloc] initWithApiKey:self.instance.apiKey
                                       sessionId:self.instance.sessionIdHost
                                        delegate:self];
    
    self.eventView.getInLineBtn.hidden = YES;
    [self statusChanged];
    [self doConnect];
    
    if(_isFan){
        [self connectFanSignaling];
    }
    
}
-(void)loadChat{
    OTSession *currentSession;
    
    if(_isBackstage){
        currentSession = _openTokManager.producerSession;
    }else{
        currentSession = _openTokManager.session;
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
    
    if(!_isFan){
        self.eventView.chatBtn.hidden = NO;
    }
    
    self.textChat.view.hidden = YES;
    self.eventView.chatBar.hidden = YES;
    _unreadCount = 0;
}

-(void)connectFanSignaling {
    
    __weak EventViewController *weakSelf = self;
    [SIOSocket socketWithHost:_instance.signalingURL response: ^(SIOSocket *socket)
     {
         _signalingSocket = socket;
         _signalingSocket.onConnect = ^()
         {
             [weakSelf.signalingSocket emit:@"joinRoom" args:@[weakSelf.instance.sessionIdProducer]];
         };
     }];
}

///SESSION CONNECTIONS///

- (void)doConnect
{
    OTError *error = nil;
    [_openTokManager.session connectWithToken:self.instance.tokenHost error:&error];

    if (error) {
        NSLog(@"connect error");
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
}

- (void)inLineConnect
{
    
    OTError *error = nil;
    [self.eventView showLoader];
    
    self.eventView.getInLineBtn.hidden = YES;
    [_logging logEventAction:@"fan_connects_backstage" variation:@"attempt"];
    [_openTokManager.producerSession connectWithToken:self.instance.tokenProducer error:&error];
    
    if (error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [_logging logEventAction:@"fan_connects_backstage" variation:@"failed"];
    }
    
}

-(void)disconnectBackstage
{
    [self unpublishFrom:_openTokManager.producerSession];
    _isBackstage = NO;
    self.eventView.inLineHolder.hidden = YES;
    self.eventView.getInLineBtn.hidden = NO;
    _shouldResendProducerSignal = YES;
}

-(void)disconnectBackstageSession{
    OTError *error = nil;
    if(_openTokManager.producerSession){
        [_openTokManager.producerSession disconnect:&error];
    }
    if(error){
        [_logging logEventAction:@"fan_disconnects_backstage" variation:@"failed"];
    }
}

-(void)forceDisconnect
{
    [self cleanupPublisher];
    NSString *text = [NSString stringWithFormat: @"There already is a %@ using this session. If this is you please close all applications or browser sessions and try again.", _isCeleb ? @"celebrity" : @"host"];
    
    
    
    [self.eventView showNotification:text useColor:[UIColor SLBlueColor]];
    OTError *error = nil;
    
    [_openTokManager.session disconnect:&error];
    self.eventView.videoHolder.hidden = YES;
    if (error) {
        NSLog(@"%@", error);
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
}

#pragma mark - logging
- (void)addLogging {
    NSString *apiKey = _instance.apiKey;
    NSString *sessionId = _openTokManager.session.sessionId;
    NSInteger partner = [apiKey integerValue];
    NSString* sourceId = [NSString stringWithFormat:@"%@-event-%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],self.event.identifier];
    
    _logging = [[OTKAnalytics alloc] initWithSessionId:sessionId connectionId:_openTokManager.session.connection.connectionId partnerId:partner clientVersion:@"ib-ios-1.0.1" source:sourceId];
    
    NSString *me = _isHost ? @"host" : _isCeleb ? @"celebrity" : @"fan";
    NSString *logtype = [NSString stringWithFormat:@"%@_connects_onstage",me];
    [_logging logEventAction:logtype variation:@"success"];
}

#pragma mark - publishers
- (void)doPublish{
    if(_isFan){
        //FAN
        if(_isBackstage){
            [self sendNewUserSignal];
            [self publishTo:_openTokManager.producerSession];
            
            //[self showVideoPreview];
            self.eventView.closeEvenBtn.hidden = YES;
            _openTokManager.publisher.publishAudio = NO;
            (_openTokManager.publisher.view).frame = CGRectMake(0, 0, self.eventView.inLineHolder.bounds.size.width, self.eventView.inLineHolder.bounds.size.height);
            [self.eventView stopLoader];
        }
        if(_isOnstage){
            [self publishTo:_openTokManager.session];
            self.eventView.statusLabel.text = @"\u2022 You are live";
            [self.eventView.fanViewHolder addSubview:_openTokManager.publisher.view];
            _openTokManager.publisher.view.frame = CGRectMake(0, 0, self.eventView.fanViewHolder.bounds.size.width, self.eventView.fanViewHolder.bounds.size.height);
            self.eventView.closeEvenBtn.hidden = YES;
            self.eventView.getInLineBtn.hidden = YES;
        }
    }else{
        if(self.isCeleb && !_stopGoingLive){
            [self publishTo:_openTokManager.session];
            [self.eventView.celebrityViewHolder addSubview:_openTokManager.publisher.view];
            (_openTokManager.publisher.view).frame = CGRectMake(0, 0, self.eventView.celebrityViewHolder.bounds.size.width, self.eventView.celebrityViewHolder.bounds.size.height);
            self.eventView.closeEvenBtn.hidden = NO;
        }
        if(_isHost && !_stopGoingLive){
            [self publishTo:_openTokManager.session];
            [self.eventView.hostViewHolder addSubview:_openTokManager.publisher.view];
            self.eventView.closeEvenBtn.hidden = NO;
            (_openTokManager.publisher.view).frame = CGRectMake(0, 0, self.eventView.hostViewHolder.bounds.size.width, self.eventView.hostViewHolder.bounds.size.height);
        }
        if(_stopGoingLive){
            return [self forceDisconnect];
        }
    }
    
    [self adjustChildrenWidth];
}

-(void) publishTo:(OTSession *)session
{
    if(_openTokManager.publisher){
        NSLog(@"PUBLISHER EXISTED");
    }
    NSString *me = _isHost ? @"host" : _isCeleb ? @"celebrity" : @"fan";
    NSString *session_name = _openTokManager.session.sessionId == session.sessionId ? @"onstage" : @"backstage";
    NSString *logtype = [NSString stringWithFormat:@"%@_publishes_%@",me,session_name];

    [_logging logEventAction:logtype variation:@"attempt"];
    
    
    if(!_openTokManager.publisher){
        _openTokManager.publisher = [[OTPublisher alloc] initWithDelegate:self name:self.userName];
    }
    
    OTError *error = nil;
    [session publish:_openTokManager.publisher error:&error];
    
    if (error)
    {
        NSLog(@"%@", error);
        [self sendWarningSignal];
        
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [_logging logEventAction:logtype variation:@"fail"];


    }else{
        [_logging logEventAction:logtype variation:@"success"];
    }
    
}

-(void)unpublishFrom:(OTSession *)session
{
    OTError *error = nil;
    [session unpublish:_openTokManager.publisher error:&error];
    
    NSString *me = _isHost ? @"host" : _isCeleb ? @"celebrity" : @"fan";
    NSString *session_name = _openTokManager.session.sessionId == session.sessionId ? @"onstage" : @"backstage";
    NSString *logtype = [NSString stringWithFormat:@"%@_unpublishes_%@",me,session_name];
    
    [_logging logEventAction:logtype variation:@"attempt"];
    
    if (error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [_logging logEventAction:logtype variation:@"fail"];
    }
}

-(void)cleanupPublisher{
    if(_openTokManager.publisher){
        
        if(_openTokManager.publisher.stream.connection.connectionId == _openTokManager.session.connection.connectionId){
            NSLog(@"cleanup publisher from onstage");
        }else{
            NSLog(@"cleanup publisher from backstage");
        }
        
        [_openTokManager.publisher.view removeFromSuperview];
        _openTokManager.publisher = nil;
    }
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    if(_isBackstage){
        NSLog(@"stream Created PUBLISHER BACK");
        _openTokManager.selfSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        _openTokManager.selfSubscriber.subscribeToAudio = NO;
        
        OTError *error = nil;
        [_openTokManager.producerSession subscribe: _openTokManager.selfSubscriber error:&error];
        if (error)
        {
            NSLog(@"subscribe self error");
        }
    }else{
        NSLog(@"stream Created PUBLISHER ONST");
        [self doSubscribe:stream];
    }
    [self performSelector:@selector(startNetworkTest) withObject:nil afterDelay:5.0];

    
}

- (void)publisher:(OTPublisherKit*)publisher
  streamDestroyed:(OTStream *)stream
{
    NSLog(@"stream DESTROYED PUBLISHER");
    
    if(!_openTokManager.publisher.stream && !stream.connection) return;
    
    NSString *me = _isHost ? @"host" : _isCeleb ? @"celebrity" : @"fan";
    
    
    NSString *connectingTo =[self getStreamData:stream.connection.data];
    OTSubscriber *_subscriber = _openTokManager.subscribers[connectingTo];
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        NSLog(@"stream DESTROYED ONSTAGE %@", connectingTo);
        
        NSString *logtype = [NSString stringWithFormat:@"%@_unpublishes_onstage",me];
        [_logging logEventAction:logtype variation:@"success"];
        
        [self cleanupSubscriber:connectingTo];
    }
    if(_openTokManager.selfSubscriber){
        [_openTokManager.producerSession unsubscribe:_openTokManager.selfSubscriber error:nil];
        _openTokManager.selfSubscriber = nil;
        
        NSString *logtype = [NSString stringWithFormat:@"%@_unpublishes_backstage",me];
        [_logging logEventAction:logtype variation:@"success"];    }
    
        [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher
 didFailWithError:(OTError*) error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self.errors setObject:error forKey:@"publisherError"];
    [self sendWarningSignal];
    [self cleanupPublisher];
}

//Subscribers
- (void)doSubscribe:(OTStream*)stream
{
    
    NSString *connectingTo =[self getStreamData:stream.connection.data];
    
    if(stream.session.connection.connectionId != _openTokManager.producerSession.connection.connectionId && ![connectingTo isEqualToString:@"producer"]){
        OTSubscriber *subs = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        subs.viewScaleBehavior = OTVideoViewScaleBehaviorFit;
        _openTokManager.subscribers[connectingTo] = subs;
        
        NSString *me = _isHost ? @"host" : _isCeleb ? @"celebrity" : @"fan";
        NSString *logtype = [NSString stringWithFormat:@"%@_subscribes_%@",me,connectingTo];
        [_logging logEventAction:logtype variation:@"attempt"];

        
        OTError *error = nil;
        [_openTokManager.session subscribe: _openTokManager.subscribers[connectingTo] error:&error];
        if (error)
        {
            [self.errors setObject:error forKey:connectingTo];
            [_logging logEventAction:logtype variation:@"fail"];
            [self sendWarningSignal];
            NSLog(@"subscriber didFailWithError %@", error);
        }
        subs = nil;
        
    }
    if(stream.session.connection.connectionId == _openTokManager.producerSession.connection.connectionId && [connectingTo isEqualToString:@"producer"]){
        _openTokManager.producerSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        OTError *error = nil;
        [_openTokManager.producerSession subscribe: _openTokManager.producerSubscriber error:&error];
        if (error)
        {
            [self.errors setObject:error forKey:@"producer_backstage"];
            NSLog(@"subscriber didFailWithError %@", error);
        }
        
    }
    if(stream.session.connection.connectionId == _openTokManager.session.connection.connectionId && [connectingTo isEqualToString:@"producer"]){
        _openTokManager.privateProducerSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        OTError *error = nil;
        [_openTokManager.session subscribe: _openTokManager.privateProducerSubscriber error:&error];
        if (error)
        {
            [self.errors setObject:error forKey:@"producer_onstage"];
            NSLog(@"subscriber didFailWithError %@", error);
        }
        
    }
}


- (void)cleanupSubscriber:(NSString*)type
{
    OTSubscriber *_subscriber = _openTokManager.subscribers[type];
    if(_subscriber){
        NSLog(@"SUBSCRIBER CLEANING UP");
        [_subscriber.view removeFromSuperview];
        [_openTokManager.subscribers removeObjectForKey:type];
        _subscriber = nil;
    }
    
    [self adjustChildrenWidth];
}



# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    
    _networkTest.frameRate = @"30";
    _networkTest.resolution = @"640x480";
    
    if(subscriber.session.connection.connectionId == _openTokManager.session.connection.connectionId && subscriber.stream != _openTokManager.privateProducerStream){
        
        NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
        
        UIView *holder;
        NSString *connectingTo =[self getStreamData:subscriber.stream.connection.data];
        OTSubscriber *_subscriber = _openTokManager.subscribers[connectingTo];
        
        NSString *me = _isHost ? @"host" : _isCeleb ? @"celebrity" : @"fan";
        NSString *logtype = [NSString stringWithFormat:@"%@_subscribes_%@",me,connectingTo];
        [_logging logEventAction:logtype variation:@"success"];
        
        assert(_subscriber == subscriber);
        
        holder = [self.eventView valueForKey:[NSString stringWithFormat:@"%@ViewHolder", connectingTo]];
        (_subscriber.view).frame = CGRectMake(0, 0, holder.bounds.size.width,holder.bounds.size.height);
        
        [holder addSubview:_subscriber.view];
        self.eventView.eventImage.hidden = YES;
        [self adjustChildrenWidth];
        
    }
    if(_openTokManager.publisher && _openTokManager.publisher.stream.connection.connectionId == subscriber.stream.connection.connectionId){
        subscriber.subscribeToAudio = NO;
    }
    
}

- (void)subscriber:(OTSubscriberKit*)subscriber
  didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@",
          subscriber.stream.streamId,
          error);
    [self.errors setObject:error forKey:@"subscriberError"];
    [self sendWarningSignal];
}

- (void)subscriberVideoDisabled:(OTSubscriberKit*)subscriber
                         reason:(OTSubscriberVideoEventReason)reason
{
    NSString *feed = [self getStreamData:subscriber.stream.connection.data];
    UIView *feedView = [self.eventView valueForKey:[NSString stringWithFormat:@"%@ViewHolder", feed]];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImageView* avatar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar" inBundle:bundle compatibleWithTraitCollection:nil]];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    
    CGRect frame = feedView.frame;
    avatar.frame = CGRectMake(0, 0, frame.size.width,frame.size.height);
    
    [feedView addSubview:avatar];
}

- (void)subscriberVideoEnabled:(OTSubscriberKit*)subscriber
                        reason:(OTSubscriberVideoEventReason)reason
{
    NSString *feed = [self getStreamData:subscriber.stream.connection.data];
    UIView *feedView = [self.eventView valueForKey:[NSString stringWithFormat:@"%@ViewHolder", feed]];
    for(UIView* subview in [feedView subviews]) {
        if([subview isKindOfClass:[UIImageView class]]) {
            return [subview removeFromSuperview];
        }
    }
}

//Network Test

-(NSArray*)getVideoLimits:(NSString*)resolution framerate:(NSString*)framerate
{
    
    NSDictionary* videoLimits = @{
                                  @"1280x720-30": @[@(250),@(350),@(600),@(1000)],
                                  @"1280x720-15": @[@(150),@(250),@(350),@(800)],
                                  @"1280x720-7": @[@(120),@(150),@(250),@(600)],
                                  //VGA
                                  @"640x480-30": @[@(600),@(250),@(250),@(600),@(150),@(150),@(120)],
                                  @"640x480-15": @[@(400),@(200),@(150),@(200),@(120),@(120),@(75)],
                                  @"640x480-7": @[@(200),@(150),@(120),@(150),@(75),@(50),@(50)],
                                  //QVGA
                                  @"320x240-30": @[@(300),@(200),@(120),@(200),@(120),@(100)],
                                  @"320x240-15": @[@(200),@(150),@(120),@(150),@(120),@(100)],
                                  @"320x240-7": @[@(150),@(100),@(100),@(150),@(75),@(50)]
                                  };
    
    NSString* key = [NSString stringWithFormat:@"%@-%@",resolution,framerate];
    NSLog(@"%@",key);
    return videoLimits[key];
}
-(void)startNetworkTest{
    if(_isBackstage || _isOnstage){
        if(_openTokManager.hostStream && _openTokManager.hostStream.hasVideo && _isLive){
            OTSubscriber *test = _openTokManager.subscribers[@"host"];
            test.networkStatsDelegate = self;
        }else if(_openTokManager.celebrityStream && _openTokManager.celebrityStream.hasVideo && _isLive){
            OTSubscriber *test = _openTokManager.subscribers[@"celebrity"];
            test.networkStatsDelegate = self;
        }else if(_openTokManager.selfSubscriber){
            _openTokManager.selfSubscriber.networkStatsDelegate = self;
        }
    }
}

-(void)subscriber:(OTSubscriberKit*)subscriber
videoNetworkStatsUpdated:(OTSubscriberKitVideoNetworkStats*)stats
{
    //    if(subscriber.stream && subscriber.stream.videoDimensions.width){
    //        resolution = [NSString stringWithFormat:@"%.0fx%.0f",subscriber.stream.videoDimensions.width, subscriber.stream.videoDimensions.height];
    //    }
    
    /// TODO : check how to update the framerate
    
    if (_networkTest.prevVideoTimestamp == 0)
    {
        _networkTest.prevVideoTimestamp = stats.timestamp;
        _networkTest.prevVideoBytes = stats.videoBytesReceived;
    }
    
    if (stats.timestamp - _networkTest.prevVideoTimestamp >= 3000)
    {
        _networkTest.video_bw = (8 * (stats.videoBytesReceived - _networkTest.prevVideoBytes)) / ((stats.timestamp - _networkTest.prevVideoTimestamp) / 1000ull);
        
        subscriber.delegate = nil;
        _networkTest.prevVideoTimestamp = stats.timestamp;
        _networkTest.prevVideoBytes = stats.videoBytesReceived;
        [self processStats:stats];
    }
}

- (void)processStats:(id)stats
{
    if ([stats isKindOfClass:[OTSubscriberKitVideoNetworkStats class]])
    {
        _networkTest.video_pl_ratio = -1;
        OTSubscriberKitVideoNetworkStats *videoStats =
        (OTSubscriberKitVideoNetworkStats *) stats;
        if (_networkTest.prevVideoPacketsRcvd != 0) {
            uint64_t pl = videoStats.videoPacketsLost - _networkTest.prevVideoPacketsLost;
            uint64_t pr = videoStats.videoPacketsReceived - _networkTest.prevVideoPacketsRcvd;
            uint64_t pt = pl + pr;
            if (pt > 0)
                _networkTest.video_pl_ratio = (double) pl / (double) pt;
        }
        _networkTest.prevVideoPacketsLost = videoStats.videoPacketsLost;
        _networkTest.prevVideoPacketsRcvd = videoStats.videoPacketsReceived;
    }
    //[self checkQualityAndSendSignal];
    [self performSelector:@selector(checkQualityAndSendSignal) withDebounceDuration:15.0];
}

- (void)checkQualityAndSendSignal
{
    if(_openTokManager.publisher && _openTokManager.publisher.session){
        
        NSArray *aVideoLimits = [self getVideoLimits:_networkTest.resolution framerate:_networkTest.frameRate];
        if (!aVideoLimits) return;
        
        NSString *quality;
        
        if([_networkTest.resolution isEqualToString:@"1280x720"]){
            if (_networkTest.video_bw < [aVideoLimits[0] longValue]) {
                quality = @"Poor";
            } else if (_networkTest.video_bw > [aVideoLimits[0] longValue] && _networkTest.video_bw <= [aVideoLimits[1] longValue] && _networkTest.video_pl_ratio < 0.1 ) {
                quality = @"Poor";
            } else if (_networkTest.video_bw > [aVideoLimits[0] longValue] && _networkTest.video_pl_ratio > 0.1 ) {
                quality = @"Poor";
            } else if (_networkTest.video_bw > [aVideoLimits[1] longValue] && _networkTest.video_bw <= [aVideoLimits[2] longValue] && _networkTest.video_pl_ratio < 0.1 ) {
                quality = @"Good";
            } else if (_networkTest.video_bw > [aVideoLimits[2] longValue] && _networkTest.video_bw <= [aVideoLimits[3] longValue] && _networkTest.video_pl_ratio > 0.02 && _networkTest.video_pl_ratio < 0.1 ) {
                quality = @"Good";
            } else if (_networkTest.video_bw > [aVideoLimits[2] longValue] && _networkTest.video_bw <= [aVideoLimits[3] longValue] && _networkTest.video_pl_ratio < 0.02 ) {
                quality = @"Good";
            } else if (_networkTest.video_bw > [aVideoLimits[3] longValue] && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Great";
            }
        }
        
        if([_networkTest.resolution isEqualToString:@"640x480"]){
            if(_networkTest.video_bw > [aVideoLimits[0] longValue] && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Great";
            } else if (_networkTest.video_bw > [aVideoLimits[1] longValue] && _networkTest.video_bw <= [aVideoLimits[0] longValue] && _networkTest.video_pl_ratio <0.02) {
                quality = @"Good";
            } else if (_networkTest.video_bw > [aVideoLimits[2] longValue] && _networkTest.video_bw <= [aVideoLimits[3] longValue] && _networkTest.video_pl_ratio >0.02 && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Good";
            } else if (_networkTest.video_bw > [aVideoLimits[4] longValue] && _networkTest.video_bw <= [aVideoLimits[0] longValue] && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Good";
            } else if (_networkTest.video_pl_ratio > 0.1 && _networkTest.video_bw > [aVideoLimits[5] longValue]) {
                quality = @"Poor";
            } else if (_networkTest.video_bw >[aVideoLimits[6] longValue] && _networkTest.video_bw <= [aVideoLimits[4] longValue] && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Poor";
            } else if (_networkTest.video_bw < [aVideoLimits[6] longValue] || _networkTest.video_pl_ratio > 0.1) {
                quality = @"Poor";
            }
        }
        if([_networkTest.resolution isEqualToString:@"320x240"]){
            if(_networkTest.video_bw > [aVideoLimits[0] longValue] && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Great";
            } else if (_networkTest.video_bw > [aVideoLimits[1] longValue] && _networkTest.video_bw <= [aVideoLimits[0] longValue] && _networkTest.video_pl_ratio <0.02) {
                quality = @"Good";
            } else if (_networkTest.video_bw > [aVideoLimits[2] longValue] && _networkTest.video_bw <= [aVideoLimits[3] longValue] && _networkTest.video_pl_ratio >0.02 && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Good";
            } else if (_networkTest.video_bw > [aVideoLimits[4] longValue] && _networkTest.video_bw <= [aVideoLimits[1] longValue] && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Good";
            } else if (_networkTest.video_pl_ratio > 0.1 && _networkTest.video_bw >[aVideoLimits[4] longValue]) {
                quality = @"Poor";
            } else if (_networkTest.video_bw >[aVideoLimits[5] longValue] && _networkTest.video_bw <= [aVideoLimits[4] longValue] && _networkTest.video_pl_ratio < 0.1) {
                quality = @"Poor";
            } else if (_networkTest.video_bw < [aVideoLimits[5] longValue] || _networkTest.video_pl_ratio > 0.1) {
                quality = @"Poor";
            }
        }
        
        self.connectionQuality = quality;
        
        
        NSDictionary *data = @{
                               @"type" : @"qualityUpdate",
                               @"data" :@{
                                       @"connectionId": _openTokManager.publisher.session.connection.connectionId,
                                       @"quality" : quality,
                                       },
                               };
        
        OTError* error = nil;
        NSString *parsedString = [JSON stringify:data];
        [_openTokManager.producerSession signalWithType:@"qualityUpdate" string:parsedString connection:_openTokManager.producerSubscriber.stream.connection error:&error];
        
        if (error) {
            NSLog(@"signal didFailWithError %@", error);
        } else {
            NSLog(@"quality update sent  %@",quality);
        }
        
        [self startNetworkTest];
    }
}
///end network test //


# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session
{
    
    if(_isFan){
        if(session.sessionId == _openTokManager.session.sessionId){
            NSLog(@"sessionDidConnect to Onstage");
            (self.eventView.statusLabel).text = @"";
            self.eventView.closeEvenBtn.hidden = NO;
            [self addLogging];
        }
        if(session.sessionId == _openTokManager.producerSession.sessionId){
            NSLog(@"sessionDidConnect to Backstage");
            _isBackstage = YES;
            self.eventView.closeEvenBtn.hidden = YES;
            self.eventView.leaveLineBtn.hidden = NO;
            self.eventView.getInLineBtn.hidden = YES;
            [self doPublish];
            [self loadChat];
            [_logging logEventAction:@"fan_connects_backstage" variation:@"success"];
        }
    }else{
        [self.eventView showLoader];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(_stopGoingLive){
                [self forceDisconnect];
            }else{
                [self loadChat];
                [self addLogging];
                _isOnstage = YES;
                [self doPublish];
            }
            [self.eventView stopLoader];
        });
        
    }
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
    if(session == _openTokManager.producerSession){
        _isBackstage = NO;
        self.eventView.inLineHolder.hidden = YES;
        self.eventView.getInLineBtn.hidden = NO;
        _shouldResendProducerSignal = YES;
        [self cleanupPublisher];
        self.eventView.leaveLineBtn.hidden = YES;
        [self.eventView hideNotification];
    }else{
        self.eventView.getInLineBtn.hidden = YES;
        _openTokManager.session = nil;
    }
}


- (void)session:(OTSession*)mySession
  streamCreated:(OTStream *)stream {
    
    NSLog(@"session streamCreated (%@)", stream.streamId);
    if(mySession.connection.connectionId != _openTokManager.producerSession.connection.connectionId){
        
        if([stream.connection.data isEqualToString:@"usertype=producer"]){
            _openTokManager.privateProducerStream = stream;
            
        }else{
            if([stream.connection.data isEqualToString:@"usertype=host"]){
                _openTokManager.hostStream = stream;
                if(self.isHost){
                    _stopGoingLive = YES;
                }
            }
            
            if([stream.connection.data isEqualToString:@"usertype=celebrity"]){
                _openTokManager.celebrityStream = stream;
                if(self.isCeleb){
                    _stopGoingLive = YES;
                }
            }
            
            if([stream.connection.data isEqualToString:@"usertype=fan"]){
                _openTokManager.fanStream = stream;
            }
            
            
            if(_isLive || _isCeleb || _isHost){
                [self doSubscribe:stream];
            }
        }
        
    }
    else{
        if([stream.connection.data isEqualToString:@"usertype=producer"]){
            _openTokManager.producerStream = stream;
            if(_openTokManager.producerSession.connection){
                _shouldResendProducerSignal = YES;
            }
        }
    }
}

- (void)session:(OTSession*)session
streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    NSLog(@"disconnectin from stream (%@)", stream.connection.data);
    
    NSString *type = [self getStreamData:stream.connection.data];
    if([type isEqualToString:@"producer"]){
        if(session.connection.connectionId == _openTokManager.producerSession.connection.connectionId){
            _openTokManager.producerStream = nil;
        }else{
            _openTokManager.privateProducerStream = nil;
        }
    }else{
        if(session.connection.connectionId == _openTokManager.session.connection.connectionId){
            
            if([type isEqualToString:@"host"]){
                _openTokManager.hostStream = nil;
            }
            
            if([type isEqualToString:@"celebrity"]){
                _openTokManager.celebrityStream = nil;
            }
            
            if([type isEqualToString:@"fan"]){
                _openTokManager.fanStream = nil;
            }
            [self cleanupSubscriber:type];
        }
    }
}

- (void) session:(OTSession*)session
didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
    [self.errors setObject:error forKey:@"sessionError"];
    [self sendWarningSignal];
}


#pragma mark - session signal handler

- (void)session:(OTSession*)session receivedSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string {
    
    NSDictionary* messageData;
    if (string){
        messageData = [JSON parseJSON:string];
    }
    
    NSLog(@"session did receiveSignalType: (%@)", type);
    
    if([type isEqualToString:@"startEvent"]){
        if([self.event.status isEqualToString:@"N"]){
            self.event.status = @"P";
            self.eventView.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.event.eventName, [AppUtil convertToStatusString:self.event]];
            _shouldResendProducerSignal = YES;
            [self statusChanged];
        }
        
    }
    if([type isEqualToString:@"openChat"]){
        //self.chatBtn.hidden = NO;
        _openTokManager.producerConnection = connection;
    }
    if([type isEqualToString:@"closeChat"]){
        if(_isFan){
            [self hideChatBox];
            self.eventView.chatBtn.hidden = YES;
        }
        
    }
    if([type isEqualToString:@"muteAudio"]){
        [messageData[@"mute"] isEqualToString:@"on"] ? [_openTokManager.publisher setPublishAudio: NO] : [_openTokManager.publisher setPublishAudio: YES];
    }
    
    if([type isEqualToString:@"videoOnOff"]){
        [messageData[@"video"] isEqualToString:@"on"] ? [_openTokManager.publisher setPublishVideo: YES] : [_openTokManager.publisher setPublishVideo: NO];
    }
    if([type isEqualToString:@"newBackstageFan"]){
        if(!_isFan){
            [self.eventView showNotification:@"A new FAN has been moved to backstage" useColor:[UIColor SLBlueColor]];
            [self.eventView performSelector:@selector(hideNotification) withObject:nil afterDelay:10.0];
        }
    }
    if([type isEqualToString:@"joinBackstage"]){
        self.eventView.statusLabel.text = @"BACKSTAGE";
        _openTokManager.publisher.publishAudio = YES;
        [self.eventView showVideoPreviewWithPublisher:_openTokManager.publisher];
        [self.eventView showNotification:@"Going Backstage.You are sharing video." useColor:[UIColor SLBlueColor]];
    }
    
    if([type isEqualToString:@"newFanAck"]){
        _shouldResendProducerSignal = NO;
        [self performSelector:@selector(captureAndSendScreenshot) withObject:nil afterDelay:2.0];
    }
    if([type isEqualToString:@"producerLeaving"]){
        _shouldResendProducerSignal = YES;
    }
    if([type isEqualToString:@"resendNewFanSignal"]){
        
        if(_shouldResendProducerSignal){
            [self sendNewUserSignal];
        }
        
    }
    
    if([type isEqualToString:@"joinProducer"]){
        [self doSubscribe:_openTokManager.producerStream];
        _inCallWithProducer = YES;
        _openTokManager.publisher.publishAudio = YES;
        [self.openTokManager muteOnstageSession:YES];
        [self.eventView showNotification:@"YOU ARE NOW IN CALL WITH PRODUCER" useColor:[UIColor SLBlueColor]];
        [self.eventView showVideoPreviewWithPublisher:_openTokManager.publisher];
    }
    if([type isEqualToString:@"privateCall"]){
        if(_isOnstage || _isBackstage){
            if ([messageData[@"callWith"] isEqualToString: _openTokManager.publisher.stream.connection.connectionId ]) {
                [self doSubscribe:_openTokManager.privateProducerStream];
                _inCallWithProducer = YES;
                [self.openTokManager muteOnstageSession:YES];
                [self.eventView showNotification:@"YOU ARE NOW IN PRIVATE CALL WITH PRODUCER" useColor:[UIColor SLBlueColor]];
                if(_isFan && _isBackstage){
                    [self.eventView showVideoPreviewWithPublisher:_openTokManager.publisher];
                }
            }else{
                [self.openTokManager muteOnstageSession:YES];
                [self.eventView showNotification:@"OTHER PARTICIPANTS ARE IN A PRIVATE CALL. THEY MAY NOT BE ABLE TO HEAR YOU." useColor:[UIColor SLBlueColor]];
            }
        }
        
    }
    
    if([type isEqualToString:@"endPrivateCall"]){
        if(_isBackstage || _isOnstage){
            if(_inCallWithProducer){
                OTError *error = nil;
                [_openTokManager.session unsubscribe: _openTokManager.privateProducerSubscriber error:&error];
                _inCallWithProducer = NO;
                [self.openTokManager muteOnstageSession:NO];
                if(_isFan && _isBackstage){
                    [self.eventView hideVideoPreview];
                }
            }else{
                NSLog(@"I CAN HEAR AGAIN");
                [self.openTokManager muteOnstageSession:NO];
            }
            [self.eventView hideNotification];
        }
    }
    
    if([type isEqualToString:@"disconnectProducer"]){
        if(!_isOnstage){
            OTError *error = nil;
            [_openTokManager.producerSession unsubscribe: _openTokManager.producerSubscriber error:&error];
            _openTokManager.producerSubscriber = nil;
            _inCallWithProducer = NO;
            self.eventView.getInLineBtn.hidden = NO;
            _openTokManager.publisher.publishAudio = NO;
            [self.openTokManager muteOnstageSession:NO];
            [self.eventView hideNotification];
            [self.eventView hideVideoPreview];
        }
    }
    
    if([type isEqualToString:@"disconnectBackstage"]){
        self.eventView.leaveLineBtn.hidden = NO;
        self.eventView.statusLabel.text = @"IN LINE";
        _openTokManager.publisher.publishAudio = NO;
        [self.eventView hideNotification];
        [self.eventView hideVideoPreview];
    }
    if([type isEqualToString:@"goLive"]){
        self.event.status = @"L";
        self.eventView.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.event.eventName, [AppUtil convertToStatusString:self.event]];
        self.eventView.eventImage.hidden = YES;
        
    }
    if([type isEqualToString:@"joinHost"]){
        
        [self disconnectBackstage];
        
        _isOnstage = YES;
        
        self.eventView.statusLabel.text = @"\u2022 You are live";
        self.eventView.statusLabel.hidden = NO;
        self.eventView.leaveLineBtn.hidden = YES;
        self.eventView.getInLineBtn.hidden = YES;
        [self hideChatBox];
        [self.eventView hideNotification];
        self.eventView.chatBtn.hidden = YES;
        
        if(![self.event.status isEqualToString:@"L"] && !_isLive){
            [self goLive];
        }
        [self.eventView hideVideoPreview];
        [DotSpinnerViewController show];
    }
    
    if ([type isEqualToString:@"joinHostNow"]) {
        
        // TODO: remove spinner
        [DotSpinnerViewController dismiss];
        [self doPublish];
    }
    
    if([type isEqualToString:@"finishEvent"]){
        self.event.status = @"C";
    }
    
    if([type isEqualToString:@"disconnect"]){
        
        self.eventView.statusLabel.hidden = YES;
        self.eventView.chatBtn.hidden = YES;
        self.eventView.closeEvenBtn.hidden = NO;
        [self hideChatBox];
        _isOnstage = NO;
        
        if(_openTokManager.publisher){
            [self unpublishFrom:_openTokManager.session];
        }
        [self disconnectBackstageSession];
        
        [self.eventView showNotification:@"Thank you for participating, you are no longer sharing video/voice. You can continue to watch the session at your leisure." useColor:[UIColor SLBlueColor]];
        [self.eventView performSelector:@selector(hideNotification) withObject:nil afterDelay:5.0];
    }
    
    if([type isEqualToString:@"chatMessage"]){
        if (![connection.connectionId isEqualToString:session.connection.connectionId]) {
            self.eventView.chatBtn.hidden = NO;
            _openTokManager.producerConnection = connection;
            NSDictionary *userInfo = [JSON parseJSON:string];
            OTKChatMessage *msg = [[OTKChatMessage alloc]init];
            msg.senderAlias = [self getStreamData:connection.data];
            msg.senderId = connection.connectionId;
            msg.text = userInfo[@"message"][@"message"];
            _unreadCount ++;
            [_textChat addMessage:msg];
            [self.eventView.chatBtn setTitle:[NSString stringWithFormat:@"%f", _unreadCount] forState:UIControlStateNormal];
            
        }
    }
}

- (void)sendWarningSignal
{
    
    [self.eventView showNotification:@"You are experiencing network connectivity issues. Please try closing the application and coming back to the event" useColor:[UIColor SLRedColor]];
    [self.eventView performSelector:@selector(hideNotification) withObject:nil afterDelay:10.0];
    
    if(!_openTokManager.producerSession.connection) return;
    
    BOOL subscribing =  self.errors.count == 0 ? NO : YES;
    
    NSDictionary *data = @{
                           @"type" : @"warning",
                           @"data" :@{
                                   @"connected": @(YES),
                                   @"subscribing":@(subscribing),
                                   @"connectionId": _openTokManager.publisher && _openTokManager.publisher.stream ? _openTokManager.publisher.stream.connection.connectionId : @"",
                                   },
                           };
    
    OTError* error = nil;
    
    NSString *parsedString = [JSON stringify:data];
    [_openTokManager.producerSession signalWithType:@"warning" string:parsedString connection:_openTokManager.publisher.stream.connection error:&error];
    
    if (error) {
        NSLog(@"signal error %@", error);
    } else {
        NSLog(@"signal sent of type Warning");
    }
}

- (void)sendNewUserSignal
{
    NSLog(@"sending new user signal");
    
    if(!self.connectionQuality){
        self.connectionQuality = @"";
    }
    
    NSDictionary *data = @{
                           @"type" : @"newFan",
                           @"user" :@{
                                   @"username": self.userName,
                                   @"quality":self.connectionQuality,
                                   @"user_id": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                   @"mobile":@(YES),
                                   @"os":@"iOS",
                                   @"device":[[UIDevice currentDevice] model]
                                   },
                           @"chat" : @{
                                   @"chatting" : @"false",
                                   @"messages" : @"[]"
                                   }
                           };
    
    OTError* error = nil;
    
    NSString *parsedString = [JSON stringify:data];
    [_openTokManager.producerSession signalWithType:@"newFan" string:parsedString connection:nil error:&error];
    
    if (error) {
        NSLog(@"signal error %@", error);
    } else {
        NSLog(@"signal sent of type newFan");
    }
    
}

- (void)captureAndSendScreenshot {

    if (_openTokManager.publisher.view) {
        UIImage *screenshot = [_openTokManager.publisher.view captureViewImage];
        
        NSData *imageData = UIImageJPEGRepresentation(screenshot, 0.3);
        NSString *encodedString = [imageData base64EncodedStringWithOptions:0 ];
        NSString *formated = [NSString stringWithFormat:@"data:image/png;base64,%@",encodedString];
        
        [_signalingSocket emit:@"mySnapshot" args:@[@{
                                                       @"connectionId": _openTokManager.publisher.session.connection.connectionId,
                                                       @"sessionId" : _openTokManager.producerSession.sessionId,
                                                       @"snapshot": formated
                                                       }]];
    }
}

#pragma mark - status observer
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqual:@"status"]) {
        [self statusChanged];
    }
}

-(void) statusChanged{
    if([self.event.status isEqualToString:@"N"]){
        if(!_isFan){
            self.eventView.eventImage.hidden = YES;
        }else{
            self.eventView.eventImage.hidden = NO;
            [self.eventView.eventImage loadImageWithUrl:[NSString stringWithFormat:@"%@%@", self.instance.frontendURL, self.event.image]];
            self.eventView.getInLineBtn.hidden = YES;
        }
    };
    if([self.event.status isEqualToString:@"P"]){
        if(!_isFan){
            self.eventView.eventImage.hidden = YES;
        }else{
            self.eventView.eventImage.hidden = NO;
            [self.eventView.eventImage loadImageWithUrl:[NSString stringWithFormat:@"%@%@", self.instance.frontendURL, self.event.image]];
            self.eventView.getInLineBtn.hidden = NO;
        }
        
    };
    if([self.event.status isEqualToString:@"L"]){
        [self.eventView.eventImage loadImageWithUrl:[NSString stringWithFormat:@"%@%@", self.instance.frontendURL, self.event.image]];
        
        if (_openTokManager.subscribers.count > 0) {
            self.eventView.eventImage.hidden = YES;
        }else{
            self.eventView.eventImage.hidden = NO;
        }
        if(!_isCeleb && !_isHost && !_isBackstage && !_isOnstage){
            self.eventView.getInLineBtn.hidden = NO;
        }
        _isLive = YES;
        [self goLive];
    };
    if([self.event.status isEqualToString:@"C"]){
        self.eventView.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.event.eventName,  [AppUtil convertToStatusString:self.event]];

        if(self.event.endImage){
            [self.eventView.eventImage loadImageWithUrl:[NSString stringWithFormat:@"%@%@", self.instance.frontendURL, self.event.endImage]];
        }
        //Event Closed, disconect fan and show image
        self.eventView.eventImage.hidden = NO;
        self.eventView.getInLineBtn.hidden = YES;
        self.eventView.leaveLineBtn.hidden = YES;
        self.eventView.statusLabel.hidden = YES;
        self.eventView.chatBtn.hidden = YES;
        self.eventView.internalHolder.hidden = YES;

        OTError *error = nil;
        
        if(_openTokManager.session){
            [_openTokManager.session disconnect:&error];
        }
        
        if (error) {
            NSLog(@"Disconnect error: (%@)", error);
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }
        
        if(_isBackstage){
            [self disconnectBackstageSession];
        }
        [self cleanupPublisher];
        self.eventView.closeEvenBtn.hidden = NO;
    };
    
};

-(void)goLive {
    NSLog(@"Event changed status to LIVE");
    _isLive = YES;
    if(_openTokManager.hostStream && !_openTokManager.subscribers[@"host"]){
        [self doSubscribe:_openTokManager.hostStream];
    }
    if(_openTokManager.celebrityStream && !_openTokManager.subscribers[@"celebrity"]){
        [self doSubscribe:_openTokManager.celebrityStream];
    }
    if(_openTokManager.fanStream && !_openTokManager.subscribers[@"fan"]){
        [self doSubscribe:_openTokManager.fanStream];
    }
}


#pragma mark - OTChat
- (void)keyboardWillShow:(NSNotification*)aNotification
{
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

- (void)keyboardWillHide:(NSNotification*)aNotification
{
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
    currentSession = _openTokManager.producerSession;
    
    NSDictionary *user_message = @{@"message": message.text};
    NSDictionary *userInfo = @{@"message": user_message};
    
    [currentSession signalWithType:kTextChatType string:[JSON stringify:userInfo] connection: _openTokManager.producerConnection error:&error];
    if (error) {
        return NO;
    }
    return YES;
}

#pragma mark - Utils
- (void) adjustChildrenWidth {
    CGFloat c = 0;
    CGFloat new_width = 1;
    CGFloat new_height = self.eventView.internalHolder.bounds.size.height;
    if(_openTokManager.subscribers.count == 0){
        self.eventView.eventImage.hidden = NO;
    }
    else{
        self.eventView.eventImage.hidden = YES;
        new_width = CGRectGetWidth([UIScreen mainScreen].bounds) / _openTokManager.subscribers.count;
    }
    
    NSArray *viewNames = @[@"host",@"celebrity",@"fan"];
    
    for(NSString *viewName in viewNames){
        
        UIView *view = [self.eventView valueForKey:[NSString stringWithFormat:@"%@ViewHolder", viewName]];
        if(_openTokManager.subscribers[viewName]){
            [view setHidden:NO];
            OTSubscriber *temp = _openTokManager.subscribers[viewName];
            
            [view setFrame:CGRectMake((c*new_width), 0, new_width, new_height)];
            temp.view.frame = CGRectMake(0, 0, new_width,new_height);
            c++;
        }
        else{
            [view setHidden:YES];
            [view setFrame:CGRectMake(0, 0, 5,new_height)];
        }
    }
}

-(NSString*)getStreamData:(NSString*)data {
    return [data stringByReplacingOccurrencesOfString:@"usertype=" withString:@""];
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
        if(!_isFan){
            self.eventView.chatBtn.hidden = NO;
        }
    }];
}

- (IBAction)getInLineClick:(id)sender {
    self.userName = self.userName;
    _openTokManager.producerSession = [[OTSession alloc] initWithApiKey:_instance.apiKey
                                               sessionId:self.instance.sessionIdProducer
                                                delegate:self];
    [self inLineConnect];
}

- (IBAction)leaveLine:(id)sender {
    self.eventView.leaveLineBtn.hidden = YES;
    self.eventView.chatBtn.hidden = YES;
    self.eventView.closeEvenBtn.hidden = NO;
    [self disconnectBackstage];
    [self disconnectBackstageSession];
    self.eventView.statusLabel.text = @"";
    self.eventView.getInLineBtn.hidden = NO;
}

//UI

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)showChatBox{
    self.eventView.chatBtn.hidden = YES;
    self.textChat.view.hidden = NO;
    self.eventView.chatBar.hidden = NO;
}

-(void)hideChatBox{
    self.textChat.view.hidden = YES;
    self.eventView.chatBar.hidden = YES;
}

-(IBAction)dismissInlineTxt:(id)sender {
    [self.eventView hideVideoPreview];
}

//GO BACK
- (IBAction)goBack:(id)sender {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        
        OTError *error = nil;
        if(_openTokManager.producerSession){
            [self disconnectBackstageSession];
        }
        if(_openTokManager.session){
            [_openTokManager.session disconnect:&error];
        }
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^(){
                [SVProgressHUD showErrorWithStatus:error.localizedDescription];
            });
        }
    });
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - orientation
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end