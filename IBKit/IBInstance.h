//
//  EventInstance.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBEvent.h"

@interface IBInstance : NSObject

/**
 *  An OpenTok API key.
 */
@property (readonly, nonatomic) NSString *apiKey;

/**
 *  An OpenTok session identifier for host.
 */
@property (readonly, nonatomic) NSString *sessionIdHost;

/**
 *  An OpenTok token for host.
 */
@property (readonly, nonatomic) NSString *tokenHost;

/**
 *  An OpenTok session identifier for producer.
 */
@property (readonly, nonatomic) NSString *sessionIdProducer;

/**
 *  An OpenTok token for producer.
 */
@property (readonly, nonatomic) NSString *tokenProducer;

/**
 *  All interactive broadcast events associated with the instance
 */
@property (readonly, nonatomic) NSArray<IBEvent *> * events;

/**
 *  An identifier of the instance
 */
@property (readonly, nonatomic) NSString *instanceId;

@end
