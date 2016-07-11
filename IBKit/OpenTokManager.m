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
    [self.session connectWithToken:tokenHost error:&error];
    
    if (error) {
        NSLog(@"connectWithTokenHost error: %@", error);
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
}

- (void)closeSocket{
    [self.socket close];
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
    
    [OTKLogger logEventAction:@"fan_unpublishes_backstage" variation:@"success" completion:nil];
    if(error){
        [OTKLogger logEventAction:@"fan_unpublishes_backstage" variation:@"fail" completion:nil];
    }
    return error;
}

- (NSError*) unsubscribeFromPrivateProducerCall{
    OTError *error = nil;
    [self.session unsubscribe: self.privateProducerSubscriber error:&error];
    [self muteOnstageSession:NO];
    if(error){
        [OTKLogger logEventAction:@"unsubscribe_private_call" variation:@"fail" completion:nil];
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
        [OTKLogger logEventAction:@"unsubscribe_onstage_call" variation:@"fail" completion:nil];
    }
    return error;
}

- (NSError*) subscribeToOnstageWithType:(NSString*)type{
    OTError *error = nil;
    [self.session subscribe: self.subscribers[type] error:&error];
    if(error){
        [self.errors setObject:error forKey:type];
        [self sendWarningSignal];
    }
    return error;
}

- (NSError*) backstageSubscribeToProducer{
    OTError *error = nil;
    [self.producerSession subscribe: self.producerSubscriber error:&error];
    if(error){
        [self.errors setObject:error forKey:@"producer_backstage"];
    }
    return error;

}
- (NSError*) onstageSubscribeToProducer{
    OTError *error = nil;
    [self.session subscribe: self.privateProducerSubscriber error:&error];
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


#pragma session

-(NSError*)connectBackstageSessionWithToken:(NSString*)token{
    OTError *error = nil;
    
    [OTKLogger logEventAction:@"fan_connects_backstage" variation:@"attempt" completion:nil];
    [_producerSession connectWithToken:token error:&error];
    
    if (error) {
        [OTKLogger logEventAction:@"fan_connects_backstage" variation:@"failed" completion:nil];
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
    return error;
}

-(NSError*)disconnectBackstageSession{
    OTError *error = nil;
    if(_producerSession){
        [_producerSession disconnect:&error];
    }
    if(error){
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [OTKLogger logEventAction:@"fan_disconnects_backstage" variation:@"failed" completion:nil];
    }else{
        _producerSession = nil;
    }
    return error;
}

-(NSError*)disconnectOnstageSession{
    OTError *error = nil;
    if(_session){
        [_session disconnect:&error];
    }
    if(error){
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [OTKLogger logEventAction:@"fan_disconnects_onstage" variation:@"failed" completion:nil];
    }else{
        _session = nil;
    }
    return error;
}

#pragma publisher
-(void)unpublishFrom:(OTSession *)session
        withUserRole:(NSString*)userRole
{
    OTError *error = nil;
    [session unpublish:self.publisher error:&error];
    
    NSString *session_name = self.session.sessionId == session.sessionId ? @"onstage" : @"backstage";
    NSString *logtype = [NSString stringWithFormat:@"%@_unpublishes_%@", userRole, session_name];
    
    [OTKLogger logEventAction:logtype variation:@"attempt" completion:nil];
    
    if (error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        [OTKLogger logEventAction:logtype variation:@"fail" completion:nil];
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


#pragma mark - OpenTok Signaling
- (NSError *)sendWarningSignal {
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

#pragma mark - SIOSocket Signaling
- (void)connectFanToSocketWithURL:(NSString *)url
                        sessionId:(NSString *)sessionId {
    
    __weak OpenTokManager *weakSelf = self;
    
    [SIOSocket socketWithHost:url response:^(SIOSocket *socket){
        
        weakSelf.socket = socket;
        
        [weakSelf.socket on:@"eventGoLive" callback:^(id data) {
            if(self.broadcastUrl && !self.startBroadcast){
                self.startBroadcast = YES;
            }
        }];
        
        [weakSelf.socket on:@"eventEnded" callback:^(id data) {
            self.broadcastEnded = YES;
        }];
        
        [weakSelf.socket on:@"ableToJoin" callback:^(id data) {
            self.canJoinShow = [data[0][@"ableToJoin"] boolValue];

            if(!_canJoinShow){
                if(![data[0][@"broadcastData"]  isKindOfClass:[NSNull class]]){
                    [weakSelf.socket emit:@"joinBroadcast" args:@[[NSString stringWithFormat:@"broadcast%@",data[0][@"broadcastData"][@"broadcastId"]]]];

                    if(data[0][@"broadcastData"][@"broadcastUrl"]){
                        self.broadcastUrl = data[0][@"broadcastData"][@"broadcastUrl"];
                        if([data[0][@"broadcastData"][@"eventLive"] isEqualToString:@"true"]){
                            self.startBroadcast = YES;
                        }
                        else
                        {
                            self.waitingOnBroadcast = YES;
                        }
                    }
                }
                else
                {
                    [SVProgressHUD showErrorWithStatus:@"This show is over the maximum number of participants. Please try again in a few minutes."];
                }
                
            }
        }];
        weakSelf.socket.onDisconnect = ^(){
            NSLog(@"SOCKET DISCONNECTED");
        };
        weakSelf.socket.onConnect = ^(){
            [weakSelf.socket emit:@"joinInteractive" args:@[sessionId]];
        };
    }];
}
- (void) emitJoinRoom:(NSString *)sessionId{
    [self.socket emit:@"joinRoom" args:@[sessionId]];
}
- (NSError *)sendNewUserSignalWithName:(NSString *)username {
    
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

- (NSError *)sendScreenShotSignalWithFormattedString:(NSString *)formattedString {
    
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

- (NSError*)updateQualitySignal:(NSString*)quality
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

@end
