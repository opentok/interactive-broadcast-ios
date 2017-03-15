//
//  OpenTokManager.m
//  IBDemo
//
//  Created by Xi Huang on 5/29/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "OpenTokManager.h"
#import "SIOSocket.h"
#import "JSON.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <OTKAnalytics/OTKAnalytics.h>
#import "IBConstants.h"

@interface OpenTokManager()
@property (nonatomic) SIOSocket *socket;

@property (nonatomic) BOOL canJoinShow;
@property (nonatomic) BOOL waitingOnBroadcast;
@property (nonatomic) BOOL startBroadcast;
@property (nonatomic) BOOL broadcastEnded;
@property (nonatomic) NSString* broadcastUrl;
@end

@implementation OpenTokManager

- (instancetype)init {
    if (self = [super init]) {
        _subscribers = [[NSMutableDictionary alloc]initWithCapacity:3];
    }
    return self;
}

- (void)connectWithTokenHost:(NSString *)tokenHost {
    OTError *error = nil;
    [_liveSession connectWithToken:tokenHost error:&error];
    
    if (error) {
        NSLog(@"connectWithTokenHost error: %@", error);
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
}

- (void)closeSocket{
    [self.socket close];
    self.socket = nil;
}

- (void)muteOnstageSession:(BOOL)mute {
    for(NSString *subscriber in self.subscribers){
        OTSubscriber *sub = self.subscribers[subscriber];
        sub.subscribeToAudio = !mute;
    }
}

- (void)dealloc {
    [self.socket close];
}

#pragma subscriber
- (NSError*) unsubscribeSelfFromProducerSession{
    OTError *error = nil;
    [self.producerSession unsubscribe:self.selfSubscriber error:&error];
    self.selfSubscriber = nil;
    
    if(error){
        [OTKLogger logEventAction:KLogVariationFanUnpublishesBackstage variation:KLogVariationFailure completion:nil];
    }
    else{
        [OTKLogger logEventAction:KLogVariationFanUnpublishesBackstage variation:KLogVariationSuccess completion:nil];
    }
    return error;
}

- (NSError*) unsubscribeFromPrivateProducerCall{
    OTError *error = nil;
    [_liveSession unsubscribe: self.privateProducerSubscriber error:&error];
    [self muteOnstageSession:NO];
    if(error){
        [OTKLogger logEventAction:KLogVariationUnsubscribePrivateCall variation:KLogVariationFailure completion:nil];
    }
    return error;
}

- (NSError*) unsubscribeOnstageProducerCall{
    OTError *error = nil;
    [self.producerSession unsubscribe: self.producerSubscriber error:&error];
    self.producerSubscriber = nil;
//    self.publisher.publishAudio = NO;
    [self muteOnstageSession:NO];
    if(error){
        [OTKLogger logEventAction:KLogVariationUnsubscribeOnstageCall variation:KLogVariationFailure completion:nil];
    }
    return error;
}

- (NSError*) subscribeToOnstageWithType:(NSString*)type{
    OTError *error = nil;
    [_liveSession subscribe: self.subscribers[type] error:&error];
    if(error){
        [self.errors setObject:error forKey:type];
        [self signalWarningUpdate];
    }
    return error;
}

- (NSError*) backstageSubscribeToProducer{
    OTError *error = nil;
    [self.producerSession subscribe: self.producerSubscriber error:&error];
    [OTKLogger logEventAction:KLogVariationFanSubscribesProducerBackstage variation:KLogVariationAttempt completion:nil];
    if(error){
        [self.errors setObject:error forKey:@"producer_backstage"];
        [OTKLogger logEventAction:KLogVariationFanSubscribesProducerBackstage variation:KLogVariationFailure completion:nil];
    }
    else{
        [OTKLogger logEventAction:KLogVariationFanSubscribesProducerBackstage variation:KLogVariationSuccess completion:nil];
    }
    return error;

}
- (NSError*) onstageSubscribeToProducer{
    OTError *error = nil;
    [_liveSession subscribe: self.privateProducerSubscriber error:&error];
    if(error){
        [self.errors setObject:error forKey:@"producer_onstage"];
    }
    return error;
}

- (void)cleanupSubscriber:(NSString*)type {
    OTSubscriber *_subscriber = _subscribers[type];
    if(_subscriber){
        NSLog(@"SUBSCRIBER CLEANING UP");
        [_subscriber.view removeFromSuperview];
        [_subscribers removeObjectForKey:type];
        _subscriber = nil;
    }
}

- (void)cleanupSubscribers {
    [_subscribers removeAllObjects];
}

#pragma session

-(NSError*)connectBackstageSessionWithToken:(NSString*)token{
    OTError *error = nil;
    
    [OTKLogger logEventAction:KLogVariationFanConnectsBackstage variation:KLogVariationAttempt completion:nil];
    [_producerSession connectWithToken:token error:&error];
    
    if (error) {
        [OTKLogger logEventAction:KLogVariationFanConnectsBackstage variation:KLogVariationFailure completion:nil];
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
    return error;
}

-(NSError*)disconnectBackstageSession{
    
    if (self.selfSubscriber) {
        self.selfSubscriber.delegate = nil;
        [self.producerSession unsubscribe:self.selfSubscriber error:nil];
    }
    self.selfSubscriber = nil;
    
    if (self.producerSubscriber) {
        self.producerSubscriber.delegate = nil;
        [self.producerSession unsubscribe: self.producerSubscriber error:nil];
    }
    self.producerSubscriber = nil;
    
    OTError *error = nil;
    [_producerSession disconnect:&error];
    _producerSession = nil;
    if(error){
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [OTKLogger logEventAction:KLogVariationFanDisconnectsBackstage variation:KLogVariationFailure completion:nil];
    }
    return error;
}

-(NSError*)disconnectOnstageSession{
    
    if (self.privateProducerSubscriber) {
        self.privateProducerSubscriber.delegate = nil;
        [self.liveSession unsubscribe: self.privateProducerSubscriber error:nil];
    }
    self.privateProducerSubscriber = nil;
    
    OTError *error = nil;
    [_liveSession disconnect:&error];
    _liveSession = nil;
    if(error){
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [OTKLogger logEventAction:KLogVariationFanDisconnectsBackstage variation:KLogVariationFailure completion:nil];
    }
    return error;
}

#pragma publisher
-(void)unpublishFrom:(OTSession *)session
        withUserRole:(NSString*)userRole
{
    OTError *error = nil;
    [session unpublish:self.publisher error:&error];
    
    NSString *session_name = _liveSession.sessionId == session.sessionId ? @"Onstage" : @"Backstage";
    NSString *logtype = [NSString stringWithFormat:@"%@Unpublishes%@", [userRole capitalizedString], session_name];
    
    [OTKLogger logEventAction:logtype variation:KLogVariationAttempt completion:nil];
    
    if (error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [OTKLogger logEventAction:logtype variation:KLogVariationFailure completion:nil];
    }
}

-(void)cleanupPublisher {
    if(_publisher){
        [_publisher.view removeFromSuperview];
        _publisher = nil;
    }
}


#pragma mark - OpenTok Signaling
- (NSError *)signalWarningUpdate {
    if (self.producerSession.sessionConnectionStatus != OTSessionConnectionStatusConnected) {
        return [NSError errorWithDomain:@"OpenTokManagerDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"sendNewUserSignalWithName: producerSession has not connected"}];
    }

    
    NSDictionary *data = @{
                           @"type" : @"warning",
                           @"data" :@{
                                   @"connected": @(YES),
                                   @"subscribing":@(_errors.count == 0 ? NO : YES),
                                   @"connectionId": _publisher && _publisher.stream ? _publisher.stream.connection.connectionId : @"",
                                   },
                           };
    
    OTError* error = nil;
    [_producerSession signalWithType:@"warning" string:[JSON stringify:data] connection:_publisher.stream.connection error:&error];
    
    if (error) {
        return [NSError errorWithDomain:@"OpenTokManagerDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"sendWarningSignal: unable to send warning signal"}];
    }
    return nil;
    
    
}

- (NSError*)signalQualityUpdate:(NSString*)quality
{
    NSDictionary *data = @{
                           @"type" : @"qualityUpdate",
                           @"data" :@{
                                   @"connectionId":_publisher.session.connection.connectionId,
                                   @"quality" : quality,
                                   },
                           };
    
    OTError* error = nil;
    NSString *parsedString = [JSON stringify:data];
    [_producerSession signalWithType:@"qualityUpdate" string:parsedString connection:_producerSubscriber.stream.connection error:&error];
    
    if (error) {
        NSLog(@"signal didFailWithError %@", error);
        return error;
    }
    
    return nil;
}

#pragma mark - SIOSocket Signaling
- (void)connectFanToSocketWithURL:(NSString *)url
                        sessionId:(NSString *)sessionId {
    
    __weak OpenTokManager *weakSelf = self;
    
    [SIOSocket socketWithHost:url response:^(SIOSocket *socket){
        
        weakSelf.socket = socket;
        
        [weakSelf.socket on:@"eventGoLive" callback:^(id data) {
            if(weakSelf.broadcastUrl && !weakSelf.startBroadcast){
                weakSelf.startBroadcast = YES;
            }
        }];
        
        [weakSelf.socket on:@"eventEnded" callback:^(id data) {
            weakSelf.broadcastEnded = YES;
        }];
        
        [weakSelf.socket on:@"ableToJoin" callback:^(id data) {
            
            if (!data || ![data isKindOfClass: [NSArray class]]) return;
            NSArray *dataArray = (NSArray *)data;
            if (dataArray.count != 1) return;
            if (![[dataArray lastObject] isKindOfClass: [NSDictionary class]]) return;
            
            weakSelf.canJoinShow = [data[0][@"ableToJoin"] boolValue];

            if(!_canJoinShow){
                if(![data[0][@"broadcastData"]  isKindOfClass:[NSNull class]]){
                    [weakSelf.socket emit:@"joinBroadcast" args:@[[NSString stringWithFormat:@"broadcast%@",data[0][@"broadcastData"][@"broadcastId"]]]];

                    if(data[0][@"broadcastData"][@"broadcastUrl"]){
                        weakSelf.broadcastUrl = data[0][@"broadcastData"][@"broadcastUrl"];
                        if([data[0][@"broadcastData"][@"eventLive"] isEqualToString:@"true"]){
                            weakSelf.startBroadcast = YES;
                        }
                        else{
                            weakSelf.waitingOnBroadcast = YES;
                        }
                    }
                }
                else{
                    [SVProgressHUD showErrorWithStatus:@"This show is over the maximum number of participants. Please try again in a few minutes."];
                }
                
            }
        }];
        
        weakSelf.socket.onDisconnect = ^(){
            NSLog(@"SOCKET DISCONNECTED");
            if(weakSelf.startBroadcast){
              [SVProgressHUD showErrorWithStatus:@"Internet connection is down. Attempting to reconnect"];
            }
        };
        
        weakSelf.socket.onConnect = ^(){
            [weakSelf.socket emit:@"joinInteractive" args:@[sessionId]];
        };
    }];
}
- (void) emitJoinRoom:(NSString *)sessionId{
    [self.socket emit:@"joinRoom" args:@[sessionId]];
}
- (NSError *)signalNewUserName:(NSString *)username {
    
    if (self.producerSession.sessionConnectionStatus != OTSessionConnectionStatusConnected) {
        return [NSError errorWithDomain:@"OpenTokManagerDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"sendNewUserSignalWithName: producerSession has not connected"}];
    }
    
    if (!username) {
        return [NSError errorWithDomain:@"OpenTokManagerDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"sendNewUserSignalWithName: Misses username"}];
    }
    
    NSLog(@"sending new user signal");
    NSDictionary *data = @{
                           @"type":@"newFan",
                           @"user":
                               @{
                                   @"username": username,
                                   @"quality":@"",
                                   @"user_id": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                   @"mobile":@(YES),
                                   @"os":@"iOS",
                                   @"device":[[UIDevice currentDevice] model]
                                },
                           @"chat":
                               @{
                                   @"chatting" : @"false",
                                   @"messages" : @"[]"
                                }
                           };
    
    OTError* error = nil;
    [self.producerSession signalWithType:@"newFan" string:[JSON stringify:data] connection:nil error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    return error;
}

- (NSError *)signalScreenShotWithFormattedString:(NSString *)formattedString {
    
    if (!self.publisher.session.connection) {
        return [NSError errorWithDomain:@"OpenTokManagerDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"sendScreenShotWithFormattedString: pubisher has not published"}];
    }
    
    if (self.producerSession.sessionConnectionStatus != OTSessionConnectionStatusConnected) {
        return [NSError errorWithDomain:@"OpenTokManagerDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"sendNewUserSignalWithName: producerSession has not connected"}];
    }
    
    [self.socket emit:@"mySnapshot" args:@[
                                           @{
                                               @"connectionId": self.publisher.session.connection.connectionId,
                                               @"sessionId" : self.producerSession.sessionId,
                                               @"snapshot": formattedString
                                            }
                                        ]];
    
    return nil;
}

@end
