//
//  EventViewController.m
//  IB-ios
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import <OpenTok/OpenTok.h>
#import "SIOSocket.h"

#import "OTKTextChatComponent.h"
#import "IBApi.h"
#import "PerformSelectorWithDebounce.h"

#import "EventViewController.h"
#import "DGActivityIndicatorView.h"
#import "UIColor+AppAdditions.h"

#import "SVProgressHUD.h"
#import "DotSpinnerViewController.h"

#import "OTDefaultAudioDevice.h"
#import "OTKAnalytics.h"


#define TIME_WINDOW 3000 // 3 seconds
#define AUDIO_ONLY_TEST_DURATION 6 // 6 seconds


@interface EventViewController () <OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate, OTKTextChatDelegate,OTSubscriberKitNetworkStatsDelegate>
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
@property (nonatomic) NSMutableDictionary *errors;

@property (nonatomic) NSString *connectionQuality;

@property (weak, nonatomic) IBOutlet UIView *internalHolder;
@property (weak, nonatomic) IBOutlet UIView *HostViewHolder;
@property (weak, nonatomic) IBOutlet UIView *FanViewHolder;
@property (weak, nonatomic) IBOutlet UIView *CelebrityViewHolder;
@property (weak, nonatomic) IBOutlet UIView *inLineHolder;
@property (weak, nonatomic) IBOutlet UIImageView *eventImage;

@property (weak, nonatomic) IBOutlet UIView *notificationBar;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@end

@implementation EventViewController

NSMutableDictionary *instanceData;

OTSession* _session;
OTSession* _producerSession;
OTPublisher* _publisher;


NSMutableDictionary *_subscribers;
OTSubscriber* _producerSubscriber;
OTSubscriber* _privateProducerSubscriber;
OTSubscriber* _selfSubscriber;


id<OTVideoCapture> _cameraCapture;

OTStream* _celebrityStream;
OTStream* _hostStream;
OTStream* _fanStream;
OTStream* _producerStream;
OTStream* _privateProducerStream;

OTConnection* _producerConnection;

DGActivityIndicatorView *activityIndicatorView;
OTKTextChatComponent *textChat;
OTKAnalytics *logging;

SIOSocket *signalingSocket;

NSMutableDictionary* videoViews;

static bool isBackstage = NO;
static bool isOnstage = NO;
static bool shouldResendProducerSignal = NO;
static bool inCallWithProducer = NO;
static bool isLive = NO;
static bool isSingleEvent = NO;
static bool isFan = NO;
static bool stopGoingLive = NO;

CGRect screen;
CGFloat screen_width;
CGFloat chatYPosition;
CGFloat activeStreams;
CGFloat unreadCount = 0;


//Network Testing
NSTimer *_sampleTimer;
BOOL _runQualityStatsTest;
int _qualityTestDuration;
double prevVideoTimestamp;
double prevVideoBytes;
double prevAudioTimestamp;
double prevAudioBytes;
uint64_t prevVideoPacketsLost;
uint64_t prevVideoPacketsRcvd;
uint64_t prevAudioPacketsLost;
uint64_t prevAudioPacketsRcvd;
long video_bw;
long audio_bw;
double video_pl_ratio;
double audio_pl_ratio;
NSString *frameRate;
NSString *resolution;

static NSString* const kTextChatType = @"chatMessage";

@synthesize apikey, userName, isCeleb, isHost, eventData,connectionData,user,eventName,statusBar,chatBar;

- (instancetype)initEventWithData:(NSMutableDictionary *)aEventData
                   connectionData:(NSMutableDictionary *)aConnectionData
                             user:(NSMutableDictionary *)aUser
                         isSingle:(BOOL)aSingle {
    
    OTDefaultAudioDevice *defaultAudioDevice = [[OTDefaultAudioDevice alloc] init];
    [OTAudioDeviceManager setAudioDevice:defaultAudioDevice];
    
    if (self = [super initWithNibName:@"EventViewController" bundle:[NSBundle bundleForClass:[self class]]]) {
        
        OTDefaultAudioDevice *defaultAudioDevice = [[OTDefaultAudioDevice alloc] init];
        [OTAudioDeviceManager setAudioDevice:defaultAudioDevice];
        
        instanceData = [aConnectionData mutableCopy];
        self.eventData = [aEventData mutableCopy];
        self.userName = aUser[@"name"] ? aUser[@"name"] : aUser[@"type"];
        self.user = aUser;
        self.isCeleb = [aUser[@"type"] isEqualToString:@"celebrity"];
        self.isHost = [aUser[@"type"] isEqualToString:@"host"];
        
        isFan = !self.isCeleb && !self.isHost;
        
        isSingleEvent = aSingle;
        
        
        //observers
        [self.eventData  addObserver:self
                          forKeyPath:@"status"
                             options:(NSKeyValueObservingOptionNew |
                                      NSKeyValueObservingOptionOld)
                             context:NULL];
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
    }
    return self;
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    isLive = NO;
    
    [self.statusBar setBackgroundColor: [UIColor BarColor]];
    videoViews = [[NSMutableDictionary alloc] init];
    videoViews[@"fan"] = self.FanViewHolder;
    videoViews[@"celebrity"] = self.CelebrityViewHolder;
    videoViews[@"host"] = self.HostViewHolder;
    
    _subscribers = [[NSMutableDictionary alloc]initWithCapacity:3];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [SVProgressHUD show];
    [self createEventToken];
}

- (void)createEventToken{
    [[IBApi sharedInstance] creteEventToken:self.user[@"type"]
                                   back_url:instanceData[@"backend_base_url"]
                                       data:self.eventData
                                 completion:^(NSMutableDictionary *resultData) {
                                     
                                     [SVProgressHUD dismiss];
                                     self.connectionData = resultData;
                                     self.eventData = [self.connectionData[@"event"] mutableCopy];
                                     [self statusChanged];
                                     [self loadUser];
                                 }];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    screen = [UIScreen mainScreen].bounds;
    screen_width = CGRectGetWidth(screen);
    [self performSelector:@selector(adjustChildrenWidth) withObject:nil afterDelay:1.0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) loadUser{
    
    //Load UI
    self.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.eventData[@"event_name"],[self getEventStatus]];
    
    [self.getInLineBtn setBackgroundColor:[UIColor SLGreenColor]];
    [self.leaveLineBtn setBackgroundColor:[UIColor SLRedColor]];
    
    self.eventName.hidden = NO;
    self.closeEvenBtn.layer.cornerRadius = 3;
    
    self.statusLabel.layer.borderWidth = 2.0;
    self.statusLabel.layer.borderColor = [UIColor SLGreenColor].CGColor;
    self.statusLabel.layer.cornerRadius = 3;
    self.getInLineBtn.layer.cornerRadius = 3;
    self.leaveLineBtn.layer.cornerRadius = 3;
    
    self.inLineHolder.layer.cornerRadius = 3;
    self.inLineHolder.layer.borderColor = [UIColor SLGrayColor].CGColor;;
    self.inLineHolder.layer.borderWidth = 3.0f;
    
    [self startSession];
    
}
-(void)startSession{
    prevVideoTimestamp = 0;
    prevVideoBytes = 0;
    prevAudioTimestamp = 0;
    prevAudioBytes = 0;
    prevVideoPacketsLost = 0;
    prevVideoPacketsRcvd = 0;
    prevAudioPacketsLost = 0;
    prevAudioPacketsRcvd = 0;
    video_bw = 0;
    audio_bw = 0;
    video_pl_ratio = -1;
    audio_pl_ratio = -1;
    
    NSNumber *api = self.connectionData[@"apiKey"];
    self.apikey = [NSString stringWithFormat:@"%@", api];
    
    _session = [[OTSession alloc] initWithApiKey:self.apikey
                                       sessionId:self.connectionData[@"sessionIdHost"]
                                        delegate:self];
    
    self.getInLineBtn.hidden = YES;
    [self statusChanged];
    [self doConnect];
    
    if(isFan){
        [self connectFanSignaling];
    }
    
}
-(void)loadChat{
    OTSession *currentSession;
    
    if(isBackstage){
        currentSession = _producerSession;
    }else{
        currentSession = _session;
    }
    
    textChat = [[OTKTextChatComponent alloc] init];
    
    textChat.delegate = self;
    
    [textChat setMaxLength:1050];
    
    [textChat setSenderId:currentSession.connection.connectionId alias:@"You"];
    
    chatYPosition = self.statusBar.layer.frame.size.height + self.chatBar.layer.frame.size.height;
    
    CGRect r = self.view.bounds;
    r.origin.y += chatYPosition;
    r.size.height -= chatYPosition;
    (textChat.view).frame = r;
    [self.view insertSubview:textChat.view belowSubview:self.chatBar];
    
    if(!isFan){
        self.chatBtn.hidden = NO;
    }
    
    textChat.view.alpha = 0;
    chatBar.hidden = YES;
    
}

-(void)connectFanSignaling{
    
    [SIOSocket socketWithHost:instanceData[@"signaling_url"] response: ^(SIOSocket *socket)
     {
         signalingSocket = socket;
         signalingSocket.onConnect = ^()
         {
             [signalingSocket emit:@"joinRoom" args:@[self.connectionData[@"sessionIdProducer"]]];
         };
     }];
}

///SESSION CONNECTIONS///

- (void)doConnect
{
    OTError *error = nil;
    
    NSString *logType = isHost ? @"host_connects_onstage" : isCeleb ? @"celeb_connects_onstage" : @"fan_connects_onstage";
    
    [_session connectWithToken:self.connectionData[@"tokenHost"] error:&error];
    //[logging logEventAction:logType variation:@"attempt"];

    if (error)
    {
        NSLog(@"connect error");
        //[logging logEventAction:logType variation:@"failed"];
        [self showAlert:error.localizedDescription];
    }
}

- (void)inLineConnect
{
    
    OTError *error = nil;
    [self showLoader];
    
    self.getInLineBtn.hidden = YES;
    [logging logEventAction:@"fan_connects_backstage" variation:@"attempt"];
    [_producerSession connectWithToken:self.connectionData[@"tokenProducer"] error:&error];
    
    if (error)
    {
        [self showAlert:error.localizedDescription];
        [logging logEventAction:@"fan_connects_backstage" variation:@"failed"];
    }
    
}

-(void)disconnectBackstage
{
    [self unpublishFrom:_producerSession];
    isBackstage = NO;
    self.inLineHolder.hidden = YES;
    self.getInLineBtn.hidden = NO;
    shouldResendProducerSignal = YES;
}

-(void)disconnectBackstageSession{
    OTError *error = nil;
    if(_producerSession){
        [_producerSession disconnect:&error];
    }
    if(error){
        [logging logEventAction:@"fan_disconnects_backstage" variation:@"failed"];
    }
}

-(void)forceDisconnect
{
    [self cleanupPublisher];
    NSString *text = [NSString stringWithFormat: @"There already is a %@ using this session. If this is you please close all applications or browser sessions and try again.", isCeleb ? @"celebrity" : @"host"];
    
    
    
    [self showNotification:text useColor:[UIColor SLBlueColor]];
    OTError *error = nil;
    
    [_session disconnect:&error];
    _videoHolder.hidden = YES;
    if (error)
    {
        NSLog(@"%@", error);
        [self showAlert:error.localizedDescription];
    }
}

#pragma mark - logging
- (void)addLogging {
    NSString *apiKey = self.apikey;
    NSString *sessionId = _session.sessionId;
    NSInteger partner = [apiKey integerValue];
    NSString* sourceId = [NSString stringWithFormat:@"%@-event-%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],self.eventData[@"id"]];
    
    logging = [[OTKAnalytics alloc] initWithSessionId:sessionId connectionId:_session.connection.connectionId partnerId:partner clientVersion:@"ib-ios-1.0.1" source:sourceId];
    
    NSString *me = isHost ? @"host" : isCeleb ? @"celebrity" : @"fan";
    NSString *logtype = [NSString stringWithFormat:@"%@_connects_onstage",me];
    [logging logEventAction:logtype variation:@"success"];
}

#pragma mark - publishers
- (void)doPublish{
    if(isFan){
        //FAN
        if(isBackstage){
            [self sendNewUserSignal];
            [self publishTo:_producerSession];
            
            //[self showVideoPreview];
            self.closeEvenBtn.hidden = YES;
            _publisher.publishAudio = NO;
            (_publisher.view).frame = CGRectMake(0, 0, self.inLineHolder.bounds.size.width, self.inLineHolder.bounds.size.height);
            [self stopLoader];
        }
        if(isOnstage){
            [self publishTo:_session];
            self.statusLabel.text = @"\u2022 You are live";
            [self.FanViewHolder addSubview:_publisher.view];
            _publisher.view.frame = CGRectMake(0, 0, self.FanViewHolder.bounds.size.width, self.FanViewHolder.bounds.size.height);
            self.closeEvenBtn.hidden = YES;
            self.getInLineBtn.hidden = YES;
        }
    }else{
        if(self.isCeleb && !stopGoingLive){
            [self publishTo:_session];
            [videoViews[@"celebrity"] addSubview:_publisher.view];
            (_publisher.view).frame = CGRectMake(0, 0, self.CelebrityViewHolder.bounds.size.width, self.CelebrityViewHolder.bounds.size.height);
            self.closeEvenBtn.hidden = NO;
        }
        if(self.isHost && !stopGoingLive){
            [self publishTo:_session];
            [videoViews[@"host"] addSubview:_publisher.view];
            self.closeEvenBtn.hidden = NO;
            (_publisher.view).frame = CGRectMake(0, 0, self.HostViewHolder.bounds.size.width, self.HostViewHolder.bounds.size.height);
        }
        if(stopGoingLive){
            return [self forceDisconnect];
        }
    }
    
    [self adjustChildrenWidth];
}

-(void) publishTo:(OTSession *)session
{
    if(_publisher){
        NSLog(@"PUBLISHER EXISTED");
    }
    NSString *me = isHost ? @"host" : isCeleb ? @"celebrity" : @"fan";
    NSString *session_name = _session.sessionId == session.sessionId ? @"onstage" : @"backstage";
    NSString *logtype = [NSString stringWithFormat:@"%@_publishes_%@",me,session_name];

    [logging logEventAction:logtype variation:@"attempt"];
    
    
    if(!_publisher){
        _publisher = [[OTPublisher alloc] initWithDelegate:self name:self.userName];
    }
    
    OTError *error = nil;
    [session publish:_publisher error:&error];
    
    if (error)
    {
        NSLog(@"%@", error);
        [self sendWarningSignal];
        
        [self showAlert:error.localizedDescription];
        [logging logEventAction:logtype variation:@"fail"];


    }else{
        [logging logEventAction:logtype variation:@"success"];
    }
    
}

-(void)unpublishFrom:(OTSession *)session
{
    OTError *error = nil;
    [session unpublish:_publisher error:&error];
    
    NSString *me = isHost ? @"host" : isCeleb ? @"celebrity" : @"fan";
    NSString *session_name = _session.sessionId == session.sessionId ? @"onstage" : @"backstage";
    NSString *logtype = [NSString stringWithFormat:@"%@_unpublishes_%@",me,session_name];
    
    [logging logEventAction:logtype variation:@"attempt"];
    
    if (error)
    {
        [self showAlert:error.localizedDescription];
        [logging logEventAction:logtype variation:@"fail"];
    }
}

-(void)cleanupPublisher{
    if(_publisher){
        
        if(_publisher.stream.connection.connectionId == _session.connection.connectionId){
            NSLog(@"cleanup publisher from onstage");
        }else{
            NSLog(@"cleanup publisher from backstage");
        }
        
        [_publisher.view removeFromSuperview];
        _publisher = nil;
    }
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    if(isBackstage){
        NSLog(@"stream Created PUBLISHER BACK");
        _selfSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        _selfSubscriber.subscribeToAudio = NO;
        
        OTError *error = nil;
        [_producerSession subscribe: _selfSubscriber error:&error];
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
    
    if(!_publisher.stream && !stream.connection) return;
    
    NSString *me = isHost ? @"host" : isCeleb ? @"celebrity" : @"fan";
    
    
    NSString *connectingTo =[self getStreamData:stream.connection.data];
    OTSubscriber *_subscriber = _subscribers[connectingTo];
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        NSLog(@"stream DESTROYED ONSTAGE %@", connectingTo);
        
        NSString *logtype = [NSString stringWithFormat:@"%@_unpublishes_onstage",me];
        [logging logEventAction:logtype variation:@"success"];
        
        [self cleanupSubscriber:connectingTo];
    }
    if(_selfSubscriber){
        [_producerSession unsubscribe:_selfSubscriber error:nil];
        _selfSubscriber = nil;
        
        NSString *logtype = [NSString stringWithFormat:@"%@_unpublishes_backstage",me];
        [logging logEventAction:logtype variation:@"success"];    }
    
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
    
    if(stream.session.connection.connectionId != _producerSession.connection.connectionId && ![connectingTo isEqualToString:@"producer"]){
        OTSubscriber *subs = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        subs.viewScaleBehavior = OTVideoViewScaleBehaviorFit;
        _subscribers[connectingTo] = subs;
        
        NSString *me = isHost ? @"host" : isCeleb ? @"celebrity" : @"fan";
        NSString *logtype = [NSString stringWithFormat:@"%@_subscribes_%@",me,connectingTo];
        [logging logEventAction:logtype variation:@"attempt"];

        
        OTError *error = nil;
        [_session subscribe: _subscribers[connectingTo] error:&error];
        if (error)
        {
            [self.errors setObject:error forKey:connectingTo];
            [logging logEventAction:logtype variation:@"fail"];
            [self sendWarningSignal];
            NSLog(@"subscriber didFailWithError %@", error);
        }
        subs = nil;
        
    }
    if(stream.session.connection.connectionId == _producerSession.connection.connectionId && [connectingTo isEqualToString:@"producer"]){
        _producerSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        OTError *error = nil;
        [_producerSession subscribe: _producerSubscriber error:&error];
        if (error)
        {
            [self.errors setObject:error forKey:@"producer_backstage"];
            NSLog(@"subscriber didFailWithError %@", error);
        }
        
    }
    if(stream.session.connection.connectionId == _session.connection.connectionId && [connectingTo isEqualToString:@"producer"]){
        _privateProducerSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        OTError *error = nil;
        [_session subscribe: _privateProducerSubscriber error:&error];
        if (error)
        {
            [self.errors setObject:error forKey:@"producer_onstage"];
            NSLog(@"subscriber didFailWithError %@", error);
        }
        
    }
}


- (void)cleanupSubscriber:(NSString*)type
{
    OTSubscriber *_subscriber = _subscribers[type];
    if(_subscriber){
        NSLog(@"SUBSCRIBER CLEANING UP");
        [_subscriber.view removeFromSuperview];
        [_subscribers removeObjectForKey:type];
        _subscriber = nil;
    }
    
    [self adjustChildrenWidth];
}



# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    
    frameRate = @"30";
    resolution = @"640x480";
    
    if(subscriber.session.connection.connectionId == _session.connection.connectionId && subscriber.stream != _privateProducerStream){
        
        NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
        
        UIView *holder;
        NSString *connectingTo =[self getStreamData:subscriber.stream.connection.data];
        OTSubscriber *_subscriber = _subscribers[connectingTo];
        
        NSString *me = isHost ? @"host" : isCeleb ? @"celebrity" : @"fan";
        NSString *logtype = [NSString stringWithFormat:@"%@_subscribes_%@",me,connectingTo];
        [logging logEventAction:logtype variation:@"success"];
        
        assert(_subscriber == subscriber);
        
        holder = videoViews[connectingTo];
        
        (_subscriber.view).frame = CGRectMake(0, 0, holder.bounds.size.width,holder.bounds.size.height);
        
        [holder addSubview:_subscriber.view];
        self.eventImage.hidden = YES;
        [self adjustChildrenWidth];
        
    }
    if(_publisher && _publisher.stream.connection.connectionId == subscriber.stream.connection.connectionId){
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
    [self showAvatarFor:feed];
}

- (void)subscriberVideoEnabled:(OTSubscriberKit*)subscriber
                        reason:(OTSubscriberVideoEventReason)reason
{
    NSString *feed = [self getStreamData:subscriber.stream.connection.data];
    [self hideAvatarFor:feed];
}

- (void) showAvatarFor:(NSString*)feed
{
    UIView *feedView = videoViews[feed];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImageView* avatar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar" inBundle:bundle compatibleWithTraitCollection:nil]];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    
    CGRect frame = feedView.frame;
    avatar.frame = CGRectMake(0, 0, frame.size.width,frame.size.height);
    
    [videoViews[feed] addSubview:avatar];
}

- (void) hideAvatarFor:(NSString*)feed
{
    for(UIView* subview in [videoViews[feed] subviews])
    {
        if([subview isKindOfClass:[UIImageView class]])
        {
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
    if(isBackstage || isOnstage){
        if(_hostStream && _hostStream.hasVideo && isLive){
            OTSubscriber *test = _subscribers[@"host"];
            test.networkStatsDelegate = self;
        }else if(_celebrityStream && _celebrityStream.hasVideo && isLive){
            OTSubscriber *test = _subscribers[@"celebrity"];
            test.networkStatsDelegate = self;
        }else if(_selfSubscriber){
            _selfSubscriber.networkStatsDelegate = self;
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
    
    if (prevVideoTimestamp == 0)
    {
        prevVideoTimestamp = stats.timestamp;
        prevVideoBytes = stats.videoBytesReceived;
    }
    
    if (stats.timestamp - prevVideoTimestamp >= TIME_WINDOW)
    {
        video_bw = (8 * (stats.videoBytesReceived - prevVideoBytes)) / ((stats.timestamp - prevVideoTimestamp) / 1000ull);
        
        subscriber.delegate = nil;
        prevVideoTimestamp = stats.timestamp;
        prevVideoBytes = stats.videoBytesReceived;
        [self processStats:stats];
    }
}

- (void)processStats:(id)stats
{
    if ([stats isKindOfClass:[OTSubscriberKitVideoNetworkStats class]])
    {
        video_pl_ratio = -1;
        OTSubscriberKitVideoNetworkStats *videoStats =
        (OTSubscriberKitVideoNetworkStats *) stats;
        if (prevVideoPacketsRcvd != 0) {
            uint64_t pl = videoStats.videoPacketsLost - prevVideoPacketsLost;
            uint64_t pr = videoStats.videoPacketsReceived - prevVideoPacketsRcvd;
            uint64_t pt = pl + pr;
            if (pt > 0)
                video_pl_ratio = (double) pl / (double) pt;
        }
        prevVideoPacketsLost = videoStats.videoPacketsLost;
        prevVideoPacketsRcvd = videoStats.videoPacketsReceived;
    }
    //[self checkQualityAndSendSignal];
    [self performSelector:@selector(checkQualityAndSendSignal) withDebounceDuration:15.0];
}

- (void)checkQualityAndSendSignal
{
    if(_publisher && _publisher.session){
        
        NSArray *aVideoLimits = [self getVideoLimits:resolution framerate:frameRate];
        if (!aVideoLimits) return;
        
        NSString *quality;
        
        if([resolution isEqualToString:@"1280x720"]){
            if (video_bw < [aVideoLimits[0] longValue]) {
                quality = @"Poor";
            } else if (video_bw > [aVideoLimits[0] longValue] && video_bw <= [aVideoLimits[1] longValue] && video_pl_ratio < 0.1 ) {
                quality = @"Poor";
            } else if (video_bw > [aVideoLimits[0] longValue] && video_pl_ratio > 0.1 ) {
                quality = @"Poor";
            } else if (video_bw > [aVideoLimits[1] longValue] && video_bw <= [aVideoLimits[2] longValue] && video_pl_ratio < 0.1 ) {
                quality = @"Good";
            } else if (video_bw > [aVideoLimits[2] longValue] && video_bw <= [aVideoLimits[3] longValue] && video_pl_ratio > 0.02 && video_pl_ratio < 0.1 ) {
                quality = @"Good";
            } else if (video_bw > [aVideoLimits[2] longValue] && video_bw <= [aVideoLimits[3] longValue] && video_pl_ratio < 0.02 ) {
                quality = @"Good";
            } else if (video_bw > [aVideoLimits[3] longValue] && video_pl_ratio < 0.1) {
                quality = @"Great";
            }
        }
        
        if([resolution isEqualToString:@"640x480"]){
            if(video_bw > [aVideoLimits[0] longValue] && video_pl_ratio < 0.1) {
                quality = @"Great";
            } else if (video_bw > [aVideoLimits[1] longValue] && video_bw <= [aVideoLimits[0] longValue] && video_pl_ratio <0.02) {
                quality = @"Good";
            } else if (video_bw > [aVideoLimits[2] longValue] && video_bw <= [aVideoLimits[3] longValue] && video_pl_ratio >0.02 && video_pl_ratio < 0.1) {
                quality = @"Good";
            } else if (video_bw > [aVideoLimits[4] longValue] && video_bw <= [aVideoLimits[0] longValue] && video_pl_ratio < 0.1) {
                quality = @"Good";
            } else if (video_pl_ratio > 0.1 && video_bw > [aVideoLimits[5] longValue]) {
                quality = @"Poor";
            } else if (video_bw >[aVideoLimits[6] longValue] && video_bw <= [aVideoLimits[4] longValue] && video_pl_ratio < 0.1) {
                quality = @"Poor";
            } else if (video_bw < [aVideoLimits[6] longValue] || video_pl_ratio > 0.1) {
                quality = @"Poor";
            }
        }
        if([resolution isEqualToString:@"320x240"]){
            if(video_bw > [aVideoLimits[0] longValue] && video_pl_ratio < 0.1) {
                quality = @"Great";
            } else if (video_bw > [aVideoLimits[1] longValue] && video_bw <= [aVideoLimits[0] longValue] && video_pl_ratio <0.02) {
                quality = @"Good";
            } else if (video_bw > [aVideoLimits[2] longValue] && video_bw <= [aVideoLimits[3] longValue] && video_pl_ratio >0.02 && video_pl_ratio < 0.1) {
                quality = @"Good";
            } else if (video_bw > [aVideoLimits[4] longValue] && video_bw <= [aVideoLimits[1] longValue] && video_pl_ratio < 0.1) {
                quality = @"Good";
            } else if (video_pl_ratio > 0.1 && video_bw >[aVideoLimits[4] longValue]) {
                quality = @"Poor";
            } else if (video_bw >[aVideoLimits[5] longValue] && video_bw <= [aVideoLimits[4] longValue] && video_pl_ratio < 0.1) {
                quality = @"Poor";
            } else if (video_bw < [aVideoLimits[5] longValue] || video_pl_ratio > 0.1) {
                quality = @"Poor";
            }
        }
        
        self.connectionQuality = quality;
        
        
        NSDictionary *data = @{
                               @"type" : @"qualityUpdate",
                               @"data" :@{
                                       @"connectionId": _publisher.session.connection.connectionId,
                                       @"quality" : quality,
                                       },
                               };
        
        OTError* error = nil;
        
        NSString *stringified = [NSString stringWithFormat:@"%@", [self stringify:data]];
        [_producerSession signalWithType:@"qualityUpdate" string:stringified connection:_producerSubscriber.stream.connection error:&error];
        
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
    
    if(isFan){
        if(session.sessionId == _session.sessionId){
            NSLog(@"sessionDidConnect to Onstage");
            (self.statusLabel).text = @"";
            self.closeEvenBtn.hidden = NO;
            [self addLogging];
        }
        if(session.sessionId == _producerSession.sessionId){
            NSLog(@"sessionDidConnect to Backstage");
            isBackstage = YES;
            self.closeEvenBtn.hidden = YES;
            self.leaveLineBtn.hidden = NO;
            self.getInLineBtn.hidden = YES;
            [self doPublish];
            [self loadChat];
            [logging logEventAction:@"fan_connects_backstage" variation:@"success"];
        }
    }else{
        [self showLoader];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(stopGoingLive){
                [self forceDisconnect];
            }else{
                [self loadChat];
                [self addLogging];
                isOnstage = YES;
                [self doPublish];
            }
            [self stopLoader];
        });
        
    }
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
    if(session == _producerSession){
        isBackstage = NO;
        self.inLineHolder.hidden = YES;
        self.getInLineBtn.hidden = NO;
        shouldResendProducerSignal = YES;
        [self cleanupPublisher];
        self.leaveLineBtn.hidden = YES;
        [self hideNotification];
    }else{
        self.getInLineBtn.hidden = YES;
        _session = nil;
    }
}


- (void)session:(OTSession*)mySession
  streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (%@)", stream.streamId);
    if(mySession.connection.connectionId != _producerSession.connection.connectionId){
        
        if([stream.connection.data isEqualToString:@"usertype=producer"]){
            _privateProducerStream = stream;
            
        }else{
            if([stream.connection.data isEqualToString:@"usertype=host"]){
                _hostStream = stream;
                if(self.isHost){
                    stopGoingLive = YES;
                }
            }
            
            if([stream.connection.data isEqualToString:@"usertype=celebrity"]){
                _celebrityStream = stream;
                if(self.isCeleb){
                    stopGoingLive = YES;
                }
            }
            
            if([stream.connection.data isEqualToString:@"usertype=fan"]){
                _fanStream = stream;
            }
            
            
            if(isLive || isCeleb || isHost){
                [self doSubscribe:stream];
            }
        }
        
        
        
        
    }else{
        if([stream.connection.data isEqualToString:@"usertype=producer"]){
            _producerStream = stream;
            if(_producerSession.connection){
                shouldResendProducerSignal = YES;
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
        if(session.connection.connectionId == _producerSession.connection.connectionId){
            _producerStream = nil;
        }else{
            _privateProducerStream = nil;
        }
    }else{
        if(session.connection.connectionId == _session.connection.connectionId){
            
            if([type isEqualToString:@"host"]){
                _hostStream = nil;
            }
            
            if([type isEqualToString:@"celebrity"]){
                _celebrityStream = nil;
            }
            
            if([type isEqualToString:@"fan"]){
                _fanStream = nil;
            }
            [self cleanupSubscriber:type];
        }
    }
    
}


- (void)  session:(OTSession *)session
connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}


- (void) session:(OTSession*)session
didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
    [self.errors setObject:error forKey:@"sessionError"];
    [self sendWarningSignal];
    
}



///Show Alert
- (void)showAlert:(NSString *)string
{
    // show alertview on main UI
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OTError"
                                                        message:string
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] ;
        [alert show];
    });
}


#pragma mark - session signal handler

- (void)session:(OTSession*)session receivedSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string {
    NSDictionary* messageData;
    
    if(string){
        messageData = [self parseJSON:string];
    }
    
    NSLog(@"session did receiveSignalType: (%@)", type);
    
    if([type isEqualToString:@"startEvent"]){
        self.eventData[@"status"] = @"P";
        self.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.eventData[@"event_name"],[self getEventStatus]];
        shouldResendProducerSignal = YES;
        [self statusChanged];
    }
    if([type isEqualToString:@"openChat"]){
        //self.chatBtn.hidden = NO;
        _producerConnection = connection;
    }
    if([type isEqualToString:@"closeChat"]){
        if(isFan){
            [self hideChatBox];
            self.chatBtn.hidden = YES;
        }
        
    }
    if([type isEqualToString:@"muteAudio"]){
        [messageData[@"mute"] isEqualToString:@"on"] ? [_publisher setPublishAudio: NO] : [_publisher setPublishAudio: YES];
    }
    
    if([type isEqualToString:@"videoOnOff"]){
        [messageData[@"video"] isEqualToString:@"on"] ? [_publisher setPublishVideo: YES] : [_publisher setPublishVideo: NO];
    }
    if([type isEqualToString:@"newBackstageFan"]){
        if(isHost || isCeleb){
            [self showNotification:@"A new FAN has been moved to backstage" useColor:[UIColor SLBlueColor]];
            [self performSelector:@selector(hideNotification) withObject:nil afterDelay:10.0];
        }
    }
    if([type isEqualToString:@"joinBackstage"]){
        self.statusLabel.text = @"BACKSTAGE";
        _publisher.publishAudio = YES;
        [self showVideoPreview];
        [self showNotification:@"Going Backstage.You are sharing video." useColor:[UIColor SLBlueColor]];
    }
    
    if([type isEqualToString:@"newFanAck"]){
        shouldResendProducerSignal = NO;
        [self performSelector:@selector(captureAndSendScreenshot) withObject:nil afterDelay:2.0];
    }
    if([type isEqualToString:@"producerLeaving"]){
        shouldResendProducerSignal = YES;
    }
    if([type isEqualToString:@"resendNewFanSignal"]){
        
        if(shouldResendProducerSignal){
            [self sendNewUserSignal];
        }
        
    }
    
    if([type isEqualToString:@"joinProducer"]){
        [self doSubscribe:_producerStream];
        inCallWithProducer = YES;
        _publisher.publishAudio = YES;
        [self muteOnstageSession:YES];
        [self showNotification:@"YOU ARE NOW IN CALL WITH PRODUCER" useColor:[UIColor SLBlueColor]];
        [self showVideoPreview];
    }
    if([type isEqualToString:@"privateCall"]){
        if(isOnstage || isBackstage){
            if ([messageData[@"callWith"] isEqualToString: _publisher.stream.connection.connectionId ]) {
                [self doSubscribe:_privateProducerStream];
                inCallWithProducer = YES;
                [self muteOnstageSession:YES];
                [self showNotification:@"YOU ARE NOW IN PRIVATE CALL WITH PRODUCER" useColor:[UIColor SLBlueColor]];
                if(isFan && isBackstage){
                    [self showVideoPreview];
                }
            }else{
                [self muteOnstageSession:YES];
                [self showNotification:@"OTHER PARTICIPANTS ARE IN A PRIVATE CALL. THEY MAY NOT BE ABLE TO HEAR YOU." useColor:[UIColor SLBlueColor]];
            }
        }
        
    }
    
    if([type isEqualToString:@"endPrivateCall"]){
        if(isBackstage || isOnstage){
            if(inCallWithProducer){
                OTError *error = nil;
                [_session unsubscribe: _privateProducerSubscriber error:&error];
                inCallWithProducer = NO;
                [self muteOnstageSession:NO];
                if(isFan && isBackstage){
                    [self hideVideoPreview];
                }
            }else{
                NSLog(@"I CAN HEAR AGAIN");
                [self muteOnstageSession:NO];
            }
            [self hideNotification];
        }
    }
    
    if([type isEqualToString:@"disconnectProducer"]){
        if(!isOnstage){
            OTError *error = nil;
            [_producerSession unsubscribe: _producerSubscriber error:&error];
            _producerSubscriber = nil;
            inCallWithProducer = NO;
            self.getInLineBtn.hidden = NO;
            _publisher.publishAudio = NO;
            [self muteOnstageSession:NO];
            [self hideNotification];
            [self hideVideoPreview];
        }
    }
    
    if([type isEqualToString:@"disconnectBackstage"]){
        self.leaveLineBtn.hidden = NO;
        self.statusLabel.text = @"IN LINE";
        _publisher.publishAudio = NO;
        [self hideNotification];
        [self hideVideoPreview];
    }
    if([type isEqualToString:@"goLive"]){
        self.eventData[@"status"] = @"L";
        self.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.eventData[@"event_name"],[self getEventStatus]];
        if(!isLive){
            [self goLive];
        }
        [self statusChanged];
        self.eventImage.hidden = YES;
        
    }
    if([type isEqualToString:@"joinHost"]){
        
        [self disconnectBackstage];
        
        isOnstage = YES;
        
        self.statusLabel.text = @"\u2022 You are live";
        self.statusLabel.hidden = NO;
        self.leaveLineBtn.hidden = YES;
        self.getInLineBtn.hidden = YES;
        [self hideChatBox];
        [self hideNotification];
        self.chatBtn.hidden = YES;
        
        if(![self.eventData[@"status"] isEqualToString:@"L"] && !isLive){
            [self goLive];
        }
        [self hideVideoPreview];
        [DotSpinnerViewController show];
    }
    
    if ([type isEqualToString:@"joinHostNow"]) {
        
        // TODO: remove spinner
        [DotSpinnerViewController dismiss];
        [self doPublish];
    }
    
    if([type isEqualToString:@"finishEvent"]){
        self.eventData[@"status"] = @"C";
        self.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.eventData[@"event_name"],[self getEventStatus]];
        self.statusLabel.hidden = YES;
        self.chatBtn.hidden = YES;
        [self statusChanged];
    }
    
    if([type isEqualToString:@"disconnect"]){
        
        self.statusLabel.hidden = YES;
        self.chatBtn.hidden = YES;
        self.closeEvenBtn.hidden = NO;
        [self hideChatBox];
        isOnstage = NO;
        
        if(_publisher){
            [self unpublishFrom:_session];
        }
        [self disconnectBackstageSession];
        
        [self showNotification:@"Thank you for participating, you are no longer sharing video/voice. You can continue to watch the session at your leisure." useColor:[UIColor SLBlueColor]];
        [self performSelector:@selector(hideNotification) withObject:nil afterDelay:5.0];
        
    }
    
    if([type isEqualToString:@"chatMessage"]){
        if (![connection.connectionId isEqualToString:session.connection.connectionId]) {
            self.chatBtn.hidden = NO;
            _producerConnection = connection;
            NSDictionary *userInfo = [self parseJSON:string];
            OTKChatMessage *msg = [[OTKChatMessage alloc]init];
            msg.senderAlias = [self getStreamData:connection.data];
            msg.senderId = connection.connectionId;
            msg.text = userInfo[@"message"][@"message"];
            unreadCount ++;
            [textChat addMessage:msg];
            [self.chatBtn setTitle:[[NSNumber numberWithFloat:unreadCount] stringValue] forState:UIControlStateNormal];
            
        }
        
        
        
    }
}

- (void)sendWarningSignal
{
    
    [self showNotification:@"You are experiencing network connectivity issues. Please try closing the application and coming back to the event" useColor:[UIColor SLRedColor]];
    [self performSelector:@selector(hideNotification) withObject:nil afterDelay:10.0];
    
    if(!_producerSession.connection) return;
    
    BOOL subscribing =  self.errors.count == 0 ? NO : YES;
    
    NSDictionary *data = @{
                           @"type" : @"warning",
                           @"data" :@{
                                   @"connected": @(YES),
                                   @"subscribing":@(subscribing),
                                   @"connectionId": _publisher && _publisher.stream ? _publisher.stream.connection.connectionId : @"",
                                   },
                           };
    
    OTError* error = nil;
    
    NSString *stringified = [NSString stringWithFormat:@"%@", [self stringify:data]];
    [_producerSession signalWithType:@"warning" string:stringified connection:_publisher.stream.connection error:&error];
    
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
    
    NSString *stringified = [NSString stringWithFormat:@"%@", [self stringify:data]];
    [_producerSession signalWithType:@"newFan" string:stringified connection:nil error:&error];
    
    if (error) {
        NSLog(@"signal error %@", error);
    } else {
        NSLog(@"signal sent of type newFan");
    }
    
}

- (void)captureAndSendScreenshot{

    if (_publisher.view) {
        UIImage *screenshot = [self imageFromView:_publisher.view];
        
        NSData *imageData = UIImageJPEGRepresentation(screenshot, 0.3);
        NSString *encodedString = [imageData base64EncodedStringWithOptions:0 ];
        NSString *formated = [NSString stringWithFormat:@"data:image/png;base64,%@",encodedString];
        
        [signalingSocket emit:@"mySnapshot" args:@[@{
                                                       @"connectionId": _publisher.session.connection.connectionId,
                                                       @"sessionId" : _producerSession.sessionId,
                                                       @"snapshot": formated
                                                       }]];
    }
}

- (UIImage *) imageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,
                                           NO, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds
               afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if([self.eventData[@"status"] isEqualToString:@"N"]){
        if(isCeleb || isHost){
            self.eventImage.hidden = YES;
        }else{
            self.eventImage.hidden = NO;
            [self updateEventImage: [NSString stringWithFormat:@"%@%@", instanceData[@"frontend_url"], self.eventData[@"event_image"]]];
            self.getInLineBtn.hidden = YES;
            self.getInLineBtn.alpha = 1;
        }
    };
    if([self.eventData[@"status"] isEqualToString:@"P"]){
        if(isCeleb || isHost){
            self.eventImage.hidden = YES;
        }else{
            self.eventImage.hidden = NO;
            NSString *url = [NSString stringWithFormat:@"%@%@", instanceData[@"frontend_url"], self.eventData[@"event_image"]];
            [self updateEventImage: url];
            self.getInLineBtn.hidden = NO;
        }
        
    };
    if([self.eventData[@"status"] isEqualToString:@"L"]){
        NSString *url = [NSString stringWithFormat:@"%@%@", instanceData[@"frontend_url"], self.eventData[@"event_image"]];
        [self updateEventImage: url];
        
        if (_subscribers.count > 0) {
            self.eventImage.hidden = YES;
        }else{
            self.eventImage.hidden = NO;
        }
        if(!isCeleb && !isHost && !isBackstage && !isOnstage){
            self.getInLineBtn.hidden = NO;
            self.getInLineBtn.alpha = 1;
        }
        isLive = YES;
    };
    if([self.eventData[@"status"] isEqualToString:@"C"]){
        if(self.eventData[@"event_image_end"]){
            [self updateEventImage: [NSString stringWithFormat:@"%@%@", instanceData[@"frontend_url"], self.eventData[@"event_image_end"]]];
        }
        //Event Closed, disconect fan and show image
        self.eventImage.hidden = NO;
        self.getInLineBtn.hidden = YES;
        self.getInLineBtn.alpha = 0;
        self.leaveLineBtn.hidden = YES;
        
        OTError *error = nil;
        
        [_session disconnect:&error];
        if(isBackstage){
            [self disconnectBackstageSession];
        }
        if (error)
        {
            NSLog(@"error: (%@)", error);
            [self showAlert:error.localizedDescription];
        }
        [self cleanupPublisher];
        self.closeEvenBtn.hidden = NO;
        
    };
    
};

-(void)goLive{
    NSLog(@"Event changed status to LIVE");
    isLive = YES;
    if(_hostStream && !_subscribers[@"host"]){
        [self doSubscribe:_hostStream];
    }
    if(_celebrityStream && !_subscribers[@"celebrity"]){
        [self doSubscribe:_celebrityStream];
    }
    if(_fanStream && !_subscribers[@"fan"]){
        [self doSubscribe:_fanStream];
    }
}


#pragma mark - OTChat
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSDictionary* info = aNotification.userInfo;
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    double duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    chatYPosition = 106 - textChat.view.bounds.size.height ;
    [UIView animateWithDuration:duration animations:^{
        CGRect r = self.view.bounds;
        r.origin.y += chatYPosition;
        r.size.height -= chatYPosition + kbSize.height;
        textChat.view.frame = r;
    }];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    NSDictionary* info = aNotification.userInfo;
    double duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    chatYPosition = self.statusBar.layer.frame.size.height + self.chatBar.layer.frame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        
        CGRect r = self.view.bounds;
        r.origin.y += chatYPosition;
        r.size.height -= chatYPosition;
        textChat.view.frame = r;
        
        
    }];
}

- (BOOL)onMessageReadyToSend:(OTKChatMessage *)message {
    OTError *error = nil;
    OTSession *currentSession;
    currentSession = _producerSession;
    
    NSDictionary *user_message = @{@"message": message.text};
    NSDictionary *userInfo = @{@"message": user_message};
    
    [currentSession signalWithType:kTextChatType string:[self stringify:userInfo] connection: _producerConnection error:&error];
    if (error) {
        return NO;
    } else {
        return YES;
    }
}


#pragma mark - Utils

- (void) updateEventImage:(NSString*)url {
    NSURL *finalUrl = [NSURL URLWithString:url];
    NSData *imageData = [NSData dataWithContentsOfURL:finalUrl];
    if(imageData){
        [self.eventImage setImage:[UIImage imageWithData:imageData]];
    }
    
}

- (void) adjustChildrenWidth{
    CGFloat c = 0;
    CGFloat new_width = 1;
    CGFloat new_height = self.internalHolder.bounds.size.height;
    if(_subscribers.count == 0){
        self.eventImage.hidden = NO;
    }
    else{
        self.eventImage.hidden = YES;
        new_width = screen_width/_subscribers.count;
    }
    
    NSArray *viewNames = @[@"host",@"celebrity",@"fan"];
    
    for(NSString *viewName in viewNames){
        if(_subscribers[viewName]){
            [videoViews[viewName] setHidden:NO];
            OTSubscriber *temp = _subscribers[viewName];
            
            [videoViews[viewName] setFrame:CGRectMake((c*new_width), 0, new_width, new_height)];
            temp.view.frame = CGRectMake(0, 0, new_width,new_height);
            c++;
            
        }else{
            [videoViews[viewName] setHidden:YES];
            [videoViews[viewName] setFrame:CGRectMake(0, 0, 5,new_height)];
        }
        
    }
}

- (NSString*)getSessionStatus{
    NSString* connectionStatus = @"";
    if (_session.sessionConnectionStatus==OTSessionConnectionStatusConnected) {
        connectionStatus = @"Connected";
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusConnecting) {
        connectionStatus = @"Connecting";
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusDisconnecting) {
        connectionStatus = @"Disconnecting";
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusNotConnected) {
        connectionStatus = @"Disconnected";
    }else{
        connectionStatus = @"Failed";
    }
    return connectionStatus;
}

- (NSString*)getEventStatus{
    NSString* status = @"";
    if([self.eventData[@"status"] isEqualToString:@"N"]){
        status = [self getFormattedDate:self.eventData[@"date_time_start"]];
    };
    if([self.eventData[@"status"] isEqualToString:@"P"]){
        status = @"Not Started";
    };
    if([self.eventData[@"status"] isEqualToString:@"L"]){
        status = @"Live";
    };
    if([self.eventData[@"status"] isEqualToString:@"C"]){
        status = @"Closed";
    };
    return status;
    
}

- (NSString*)getFormattedDate:(NSString *)dateString{
    if(dateString != (id)[NSNull null]){
        NSDateFormatter * dateFormat = [[NSDateFormatter alloc]init];
        [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormat setLocale:[NSLocale currentLocale]];
        [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss.0"];
        [dateFormat setFormatterBehavior:NSDateFormatterBehaviorDefault];
        
        NSDate *date = [dateFormat dateFromString:dateString];
        dateFormat.dateFormat = @"dd MMM YYYY HH:mm:ss";
        
        return [dateFormat stringFromDate:date];
    }else{
        return @"Not Started";
    }
    
}

- (void) changeStatusLabelColor{
    if (_session.sessionConnectionStatus==OTSessionConnectionStatusConnected) {
        self.statusLabel.textColor = [UIColor greenColor];
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusConnecting) {
        self.statusLabel.textColor = [UIColor blueColor];
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusDisconnecting) {
        self.statusLabel.textColor = [UIColor blueColor];
    }else {
        self.statusLabel.textColor = [UIColor SLBlueColor];
    }
}

-(NSString*)getStreamData:(NSString*)data{
    return [data stringByReplacingOccurrencesOfString:@"usertype="withString:@""];
};

-(NSDictionary*)parseJSON:(NSString*)string{
    NSString *toParse = [[NSString alloc] initWithString:string];
    NSError * errorDictionary = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[toParse dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&errorDictionary];
    return dictionary;
}

-(NSString*)stringify:(NSDictionary*)data{
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:data options:0 error:&err];
    NSString * string = [[NSString alloc] initWithData:jsonData   encoding:NSUTF8StringEncoding];
    return string;
}


#pragma mark - fan Actions
- (IBAction)chatNow:(id)sender {
    [UIView animateWithDuration:0.5 animations:^() {
        //_connectingLabel.alpha = 0;
        [self showChatBox];
        unreadCount = 0;
        [self.chatBtn setTitle:@"" forState:UIControlStateNormal];
    }];
}

- (IBAction)closeChat:(id)sender {
    [UIView animateWithDuration:0.5 animations:^() {
        [self hideChatBox];
        if(!isFan){
            self.chatBtn.hidden = NO;
        }
        
    }];
}

- (IBAction)getInLineClick:(id)sender {
    self.userName = self.userName;
    _producerSession = [[OTSession alloc] initWithApiKey:self.apikey
                                               sessionId:self.connectionData[@"sessionIdProducer"]
                                                delegate:self];
    [self inLineConnect];
}

- (IBAction)leaveLine:(id)sender {
    self.leaveLineBtn.hidden = YES;
    self.chatBtn.hidden = YES;
    self.closeEvenBtn.hidden = NO;
    [self disconnectBackstage];
    [self disconnectBackstageSession];
    self.statusLabel.text = @"";
    self.getInLineBtn.hidden = NO;
    
}

-(void)muteOnstageSession:(BOOL)mute{
    for(NSString *_subscriber in _subscribers){
        OTSubscriber *sub = _subscribers[_subscriber];
        sub.subscribeToAudio = !mute;
    }
}

#pragma mark - notifications
- (void)showNotification:(NSString *)text useColor:(UIColor *)nColor {
    self.notificationLabel.text = text;
    self.notificationBar.backgroundColor = nColor;
    self.notificationBar.hidden = NO;
}

-(void)hideNotification{
    self.notificationBar.hidden = YES;
}

//UI

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)showChatBox{
    self.chatBtn.hidden = YES;
    textChat.view.alpha = 1;
    chatBar.hidden = NO;
}

-(void)hideChatBox{
    textChat.view.alpha = 0;
    chatBar.hidden = YES;
}

-(void)showLoader{
    activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeFiveDots
                                                                tintColor:[UIColor SLBlueColor] size:50.0f];
    activityIndicatorView.frame = CGRectMake(0.0f, 100.0f, screen_width, 100.0f);
    [self.view addSubview:activityIndicatorView];
    [self.view bringSubviewToFront:activityIndicatorView];
    [activityIndicatorView startAnimating];
}

-(void)stopLoader{
    [activityIndicatorView stopAnimating];
    [activityIndicatorView removeFromSuperview];
}

-(IBAction)dismissInlineTxt:(id)sender {
    [self hideVideoPreview];
}

-(void)hideVideoPreview{
    [UIView animateWithDuration:3 animations:^{
        self.inLineHolder.hidden = YES;
    }];
}
-(void)showVideoPreview{
    if(_publisher){
        _publisher.view.layer.cornerRadius = 0.5;
        [self.inLineHolder addSubview:_publisher.view];
        [self.inLineHolder sendSubviewToBack:_publisher.view];
        self.inLineHolder.hidden = NO;
    }
    
}

//GO BACK

- (IBAction)goBack:(id)sender {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        
        OTError *error = nil;
        if(_producerSession){
            [self disconnectBackstageSession];
        }
        if(_session){
            [_session disconnect:&error];
        }
        
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^(){
                [self showAlert:error.localizedDescription];
            });
        }
    });

    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
    
    if(isSingleEvent){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMainController"
                                                            object:nil
                                                          userInfo:nil];
    }
}

#pragma mark - orientation
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end