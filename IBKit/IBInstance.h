//
//  EventInstance.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBEvent.h"

@interface IBInstance : NSObject

/**
 *  The OpenTok API key.
 */
@property (readonly, nonatomic) NSString *apiKey;

/**
 *  The OpenTok session ID for the host.
 */
@property (readonly, nonatomic) NSString *sessionIdHost;

/**
 *  The OpenTok token for the host.
 */
@property (readonly, nonatomic) NSString *tokenHost;

/**
 *  The OpenTok session identifier for the producer.
 */
@property (readonly, nonatomic) NSString *sessionIdProducer;

/**
 *  The OpenTok token for the producer.
 */
@property (readonly, nonatomic) NSString *tokenProducer;

/**
 *  All interactive broadcast events associated with the instance.
 */
@property (readonly, nonatomic) NSArray<IBEvent *> * events;

/**
 *  The instance ID.
 */
@property (readonly, nonatomic) NSString *instanceId;

@end
