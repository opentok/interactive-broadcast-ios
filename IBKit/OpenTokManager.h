//
//  OpenTokManager.h
//  IBDemo
//
//  Created by Xi Huang on 5/29/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>
#import <Firebase/Firebase.h>

#import "IBEvent.h"
#import "IBEvent_Internal.h"

@interface OpenTokManager : NSObject

// it uses for liveSession and producerSession
@property (nonatomic) OTPublisher* publisher;

/**
 *  The OpneTok session for live show
 */
@property (nonatomic) OTSession* onstageSession;

/**
 *  The OpenTok session for connecting to producer
 */
@property (nonatomic) OTSession* backstageSession;


@property (nonatomic) NSMutableDictionary *subscribers;
@property (nonatomic) OTSubscriber *producerSubscriber;
@property (nonatomic) OTSubscriber *privateProducerSubscriber;
@property (nonatomic) OTSubscriber *selfSubscriber;

// we capture this for gaining full control of subscribing
@property (nonatomic) OTStream *celebrityStream;
@property (nonatomic) OTStream *hostStream;
@property (nonatomic) OTStream *fanStream;
@property (nonatomic) OTStream *producerStream;
@property (nonatomic) OTStream *privateProducerStream;

// we capture for sending text chat to producer
@property (nonatomic) OTConnection *producerConnection;

// HLS
@property (readonly, nonatomic) BOOL canJoinShow;
@property (readonly, nonatomic) BOOL startBroadcast;
@property (readonly, nonatomic) BOOL endBroadcast;
@property (readonly, nonatomic) NSString* broadcastUrl;

// Firebase
@property (readonly, nonatomic) FIRDatabaseReference *fanRef;
@property (readonly, nonatomic) FIRDatabaseReference *privateCallRef;

- (void)muteOnstageSession:(BOOL)mute;

#pragma mark - OpenTok Signaling
- (void)updateNetworkQuality:(NSString*)quality;

#pragma sessions
- (NSError *)connectOnstageWithToken:(NSString *)token;
- (NSError *)connectBackstageWithToken:(NSString*)token;
- (void)disconnectBackstageSession;
- (void)disconnectOnstageSession;

#pragma subscribers
- (void)cleanupSubscriber:(NSString*)type;
- (void)cleanupSubscribers;
- (NSError *)subscribeToOnstageWithType:(NSString*)type;
- (NSError *)backstageSubscribeToProducer;
- (NSError *)onstageSubscribeToProducer;
- (NSError *)unsubscribeSelfFromProducerSession;
- (NSError *)unsubscribeFromPrivateProducerCall;
- (NSError *)unsubscribeOnstageProducerCall;

#pragma publisher
- (void)cleanupPublisher;
- (void)unpublishFrom:(OTSession *)session;

#pragma mark - Signaling
- (void)startEvent:(IBEvent *)event;
- (void)closeEvent;
- (void)getInLine:(IBUser *)user;
- (void)getOnstage;
- (void)leaveLine;
@end
