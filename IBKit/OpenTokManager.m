//
//  OpenTokManager.m
//  IBDemo
//
//  Created by Xi Huang on 5/29/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "OpenTokManager.h"
#import "JSON.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <OTKAnalytics/OTKAnalytics.h>
#import "IBConstants.h"

#import "UIView+Category.h"

@interface OpenTokManager()

@property (nonatomic) BOOL canJoinShow;
@property (nonatomic) BOOL startBroadcast;
@property (nonatomic) BOOL endBroadcast;
@property (nonatomic) NSString* broadcastUrl;

@property (nonatomic) FIRDatabaseReference *ref;
@property (nonatomic) FIRDatabaseReference *eventRef;
@property (nonatomic) FIRDatabaseReference *eventStatusRef;
@property (nonatomic) FIRDatabaseReference *fanRef;
@property (nonatomic) FIRDatabaseReference *privateCallRef;

@end

@implementation OpenTokManager

- (instancetype)init {
    if (self = [super init]) {
        _subscribers = [[NSMutableDictionary alloc]initWithCapacity:3];
        _ref = [[FIRDatabase database] reference];
    }
    return self;
}

- (void)getInLine:(IBUser *)user {
    if (self.fanRef) {
        
        // snapshot
        NSString *snapshot;
        if (self.publisher.view) {
            UIImage *screenshot = [self.publisher.view captureViewImage];
            NSData *imageData = UIImageJPEGRepresentation(screenshot, 0.3);
            NSString *encodedString = [imageData base64EncodedStringWithOptions:0 ];
            snapshot = [NSString stringWithFormat:@"data:image/png;base64,%@",encodedString];
        }
        
        [self.fanRef updateChildValues:@{
                                         @"name":user.name,
                                         @"inPrivateCall":@(NO),
                                         @"isBackstage":@(NO),
                                         @"isOnStage":@(NO),
                                         @"mobile":@(YES),
                                         @"os": @"ios",
                                         @"snapshot": snapshot,
                                         @"streamId":self.publisher.stream.streamId
                                         }];
    }
}

- (void)getOnstage {
    if (self.fanRef) {
        [self.fanRef updateChildValues:@{@"streamId":self.publisher.stream.streamId}];
    }
}

- (void)leaveLine {
    if (self.fanRef) {
        [self.fanRef setValue:@{@"id": [FIRAuth auth].currentUser.uid}];
    }
}

- (void)closeEvent {
    [self.fanRef removeValue];
}

- (void)updateNetworkQuality:(NSString*)quality {
    if (self.fanRef && quality) {
        [self.fanRef updateChildValues:@{@"networkQuality":quality}];
    }
}

- (void)startEvent:(IBEvent *)event {
    
    __weak OpenTokManager *weakSelf = self;
    
    void (^joinInteractiveModeBlock)(void) = ^(){
        
        NSString *userId = [FIRAuth auth].currentUser.uid;
        
        _fanRef = [[[[[self.ref child:@"activeBroadcasts"] child:event.adminId] child:event.fanURL] child:@"activeFans"] child:userId];
        NSDictionary *fan = @{
                              @"id": userId
                              };
        [self.fanRef setValue:fan];
        
        // remove a record from activeFans array is essential to keep the app run normmally
        [self.fanRef onDisconnectRemoveValue];
        
        _privateCallRef = [[[[self.ref child:@"activeBroadcasts"] child:event.adminId] child:event.fanURL] child:@"privateCall"];
        
        // next steps: connect opentok
        // Previouly, we were doing ping-pong to decide whether we can set canJoinShow to YES
        // now we have determine it from interactiveLimit and activeFans, no need to do ping-pong anymore
        self.canJoinShow = YES;
    };
    
    _eventRef = [[[self.ref child:@"activeBroadcasts"] child:event.adminId] child:event.fanURL];
    [self.eventRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if (snapshot.value == [NSNull null] || snapshot.value[@"interactiveLimit"] == [NSNull null]) return;
        
        // if missing activeFans property, that means there is no fan now
        // interactiveLimit should always be there
        if ([snapshot.value[@"interactiveLimit"] isKindOfClass:[NSNumber class]]) {
            
            NSArray *activeFans = snapshot.value[@"activeFans"];
            NSUInteger interactiveLimit = snapshot.value[@"interactiveLimit"] == nil ? 0 : [snapshot.value[@"interactiveLimit"] integerValue];
            
            if (activeFans.count < interactiveLimit) {
                joinInteractiveModeBlock();
            }
            else {
                weakSelf.broadcastUrl = snapshot.value[@"hlsUrl"];
                if (weakSelf.broadcastUrl) {
                    weakSelf.startBroadcast = YES;
                }
            }
        }
        
    }];
    
    // when Firebase creates a "hlsUrl" ref, we need to buffer 15 seconds for HLS feed
    [self.eventRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if (![snapshot.key isEqualToString:@"hlsUrl"]) return;
        weakSelf.broadcastUrl = snapshot.value;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // check the interactive limit again
            [self.eventRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                
                if (snapshot.value == [NSNull null] || snapshot.value[@"interactiveLimit"] == [NSNull null]) return;
                
                if ([snapshot.value[@"interactiveLimit"] isKindOfClass:[NSNumber class]]) {
                    
                    NSArray *activeFans = snapshot.value[@"activeFans"];
                    NSUInteger interactiveLimit = snapshot.value[@"interactiveLimit"] == nil ? 0 : [snapshot.value[@"interactiveLimit"] integerValue];
                    
                    if (activeFans.count >= interactiveLimit) {
                        weakSelf.startBroadcast = YES;
                        
                        weakSelf.eventStatusRef = [self.eventRef child:@"status"];
                        [weakSelf.eventStatusRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                            if (snapshot.value == [NSNull null] || [snapshot.value isEqualToString:@"closed"]) {
                                weakSelf.endBroadcast = YES;
                            }
                        }];
                    }
                    else {
                        // do nothing
                    }
                }
                
            }];
        });
    }];
}

- (void)muteOnstageSession:(BOOL)mute {
    for (NSString *subscriber in self.subscribers){
        OTSubscriber *sub = self.subscribers[subscriber];
        sub.subscribeToAudio = !mute;
    }
}

#pragma subscriber
- (NSError *)unsubscribeSelfFromProducerSession{
    OTError *error = nil;
    [self.backstageSession unsubscribe:self.selfSubscriber error:&error];
    self.selfSubscriber = nil;
    
    if(error){
        [OTKLogger logEventAction:KLogVariationFanUnpublishesBackstage variation:KLogVariationFailure completion:nil];
    }
    else{
        [OTKLogger logEventAction:KLogVariationFanUnpublishesBackstage variation:KLogVariationSuccess completion:nil];
    }
    return error;
}

- (NSError *)unsubscribeFromPrivateProducerCall {
    OTError *error = nil;
    [self.onstageSession unsubscribe: self.privateProducerSubscriber error:&error];
    self.privateProducerSubscriber = nil;
    [self muteOnstageSession:NO];
    if (error){
        [OTKLogger logEventAction:KLogVariationUnsubscribePrivateCall variation:KLogVariationFailure completion:nil];
    }
    return error;
}

- (NSError *)unsubscribeOnstageProducerCall {
    OTError *error = nil;
    [self.backstageSession unsubscribe:self.producerSubscriber error:&error];
    self.producerSubscriber = nil;
    [self muteOnstageSession:NO];
    if(error){
        [OTKLogger logEventAction:KLogVariationUnsubscribeOnstageCall variation:KLogVariationFailure completion:nil];
    }
    return error;
}

- (NSError *)subscribeToOnstageWithType:(NSString*)type {
    OTError *error = nil;
    [self.onstageSession subscribe:self.subscribers[type] error:&error];
    return error;
}

- (NSError *)backstageSubscribeToProducer {
    OTError *error = nil;
    [self.backstageSession subscribe:self.producerSubscriber error:&error];
    [OTKLogger logEventAction:KLogVariationFanSubscribesProducerBackstage variation:KLogVariationAttempt completion:nil];
    if (error){
        [OTKLogger logEventAction:KLogVariationFanSubscribesProducerBackstage variation:KLogVariationFailure completion:nil];
    }
    else{
        [OTKLogger logEventAction:KLogVariationFanSubscribesProducerBackstage variation:KLogVariationSuccess completion:nil];
    }
    return error;
}

- (NSError *)onstageSubscribeToProducer {
    OTError *error = nil;
    [self.onstageSession subscribe:self.privateProducerSubscriber error:&error];
    return error;
}

- (void)cleanupSubscriber:(NSString*)type {
    OTSubscriber *subscriber = self.subscribers[type];
    if (subscriber){
        [subscriber.view removeFromSuperview];
        [self.subscribers removeObjectForKey:type];
        subscriber = nil;
    }
}

- (void)cleanupSubscribers {
    for (OTSubscriber *subscriber in self.subscribers.allValues) {
        [subscriber.view removeFromSuperview];
    }
    [self.subscribers removeAllObjects];
}

#pragma session

- (NSError *)connectOnstageWithToken:(NSString *)token {
    OTError *error = nil;
    [self.onstageSession connectWithToken:token error:&error];
    if (error) {
        NSLog(@"connectWithTokenHost error: %@", error);
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
    return error;
}

- (NSError *)connectBackstageWithToken:(NSString *)token {
    OTError *error = nil;
    
    [OTKLogger logEventAction:KLogVariationFanConnectsBackstage variation:KLogVariationAttempt completion:nil];
    [self.backstageSession connectWithToken:token error:&error];
    
    if (error) {
        [OTKLogger logEventAction:KLogVariationFanConnectsBackstage variation:KLogVariationFailure completion:nil];
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
    return error;
}

- (void)disconnectBackstageSession {
    
    if (self.selfSubscriber) {
        self.selfSubscriber.delegate = nil;
        [self.backstageSession unsubscribe:self.selfSubscriber error:nil];
        [self cleanupSubscriber:@"fan"];
    }
    self.selfSubscriber = nil;
    
    if (self.producerSubscriber) {
        self.producerSubscriber.delegate = nil;
        [self.backstageSession unsubscribe: self.producerSubscriber error:nil];
    }
    self.producerSubscriber = nil;

    [self.backstageSession disconnect:nil];
    self.backstageSession = nil;
}

- (void)disconnectOnstageSession {
    
    if (self.privateProducerSubscriber) {
        self.privateProducerSubscriber.delegate = nil;
        [self.onstageSession unsubscribe: self.privateProducerSubscriber error:nil];
    }
    self.privateProducerSubscriber = nil;
    
    [self.onstageSession disconnect:nil];
    self.onstageSession = nil;
}

#pragma publisher
- (void)unpublishFrom:(OTSession *)session {
    [self.publisher.view removeFromSuperview];
    [session unpublish:self.publisher error:nil];
    self.publisher = nil;
}

- (void)cleanupPublisher {
    if (self.publisher) {
        [self.onstageSession unpublish:self.publisher error:nil];
        [self.backstageSession unpublish:self.publisher error:nil];
        [self.publisher.view removeFromSuperview];
        self.publisher = nil;
    }
}

@end
