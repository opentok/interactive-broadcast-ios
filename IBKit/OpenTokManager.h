//
//  OpenTokManager.h
//  IBDemo
//
//  Created by Xi Huang on 5/29/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTDefaultAudioDevice.h"
#import <OpenTok/OpenTok.h>
#import "SIOSocket.h"



@interface OpenTokManager : NSObject
@property (nonatomic) OTSession* session;
@property (nonatomic) OTSession* producerSession;
@property (nonatomic) OTPublisher* publisher;
@property (nonatomic) NSMutableDictionary *subscribers;
@property (nonatomic) OTSubscriber* producerSubscriber;
@property (nonatomic) OTSubscriber* privateProducerSubscriber;
@property (nonatomic) OTSubscriber* selfSubscriber;
@property (nonatomic) OTStream* celebrityStream;
@property (nonatomic) OTStream* hostStream;
@property (nonatomic) OTStream* fanStream;
@property (nonatomic) OTStream* producerStream;
@property (nonatomic) OTStream* privateProducerStream;
@property (nonatomic) OTConnection* producerConnection;
@property (nonatomic) NSMutableDictionary *errors;
@property (nonatomic) SIOSocket *precenseSocket;




- (void)connectWithTokenHost:(NSString *)tokenHost;
- (void)muteOnstageSession:(BOOL)mute;

#pragma mark - OpenTok Signaling
- (NSError *)sendWarningSignal;
- (NSError*)updateQualitySignal:(NSString*)quality;

#pragma sessions
-(NSError*)connectBackstageSessionWithToken:(NSString*)token;
-(NSError*)disconnectBackstageSession;
-(NSError*)disconnectOnstageSession;

#pragma subscribers
- (void)cleanupSubscriber:(NSString*)type;
- (NSError*) subscribeToOnstageWithType:(NSString*)type;
- (NSError*) backstageSubscribeToProducer;
- (NSError*) onstageSubscribeToProducer;
- (NSError*) unsubscribeSelfFromProducerSession;
- (NSError*) unsubscribeFromPrivateProducerCall;
- (NSError*) unsubscribeOnstageProducerCall;

#pragma publisher
-(void)cleanupPublisher;
-(void)unpublishFrom:(OTSession *)session
        withUserRole:(NSString*)userRole;

#pragma mark - SIOSocket Signaling
- (void)connectFanToSocketWithURL:(NSString *)url
                        sessionId:(NSString *)sessionId;

- (void)connectToPresenceSocket:(NSString *)url
                      sessionId:(NSString *)sessionId;

- (NSError *)sendNewUserSignalWithName:(NSString *)username;
- (NSError *)sendScreenShotSignalWithFormattedString:(NSString *)formattedString;
@end
