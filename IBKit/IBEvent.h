//
//  Event.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IBEvent : NSObject

/**
 *  The adminstrator ID.
 */
@property (readonly, nonatomic) NSUInteger adminId;

/**
 *  The adminstrator name.
 */
@property (readonly, nonatomic) NSString *adminName;

/**
 *  The starting timestamp of the event.
 */
@property (readonly, nonatomic) NSDate *startTime;

/**
 *  The end timestamp of the event.
 */
@property (readonly, nonatomic) NSDate *endTime;

/**
 *  The name of the interactive broadcast event.
 */
@property (readonly, nonatomic) NSString *eventName;

/**
 *  The ID of the interactive broadcast event.
 */
@property (readonly, nonatomic) NSString *identifier;

/**
 *  The current descriptive event status.
 */
@property (readonly, nonatomic) NSString *descriptiveStatus;

@end
