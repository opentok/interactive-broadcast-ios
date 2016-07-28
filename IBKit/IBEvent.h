//
//  Event.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IBEvent : NSObject

/**
 *  An admin identifier.
 */
@property (readonly, nonatomic) NSUInteger adminId;

/**
 *  An admin name.
 */
@property (readonly, nonatomic) NSString *adminName;

/**
 *  A starting timestamp of the event.
 */
@property (readonly, nonatomic) NSDate *startTime;

/**
 *  An end timestamp of the event.
 */
@property (readonly, nonatomic) NSDate *endTime;

/**
 *  A name of the interactive broadcast event.
 */
@property (readonly, nonatomic) NSString *eventName;

/**
 *  An identifier of the interactive broadcast event.
 */
@property (readonly, nonatomic) NSString *identifier;

/**
 *  A current descriptive event status.
 */
@property (readonly, nonatomic) NSString *descriptiveStatus;

@end
