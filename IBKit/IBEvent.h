//
//  Event.h
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IBEvent : NSObject
@property (readonly, nonatomic) NSUInteger adminId;
@property (readonly, nonatomic) NSString *adminName;
@property (readonly, nonatomic) NSString *celebrityURL;
@property (readonly, nonatomic) NSString *fanURL;
@property (readonly, nonatomic) NSString *hostURL;
@property (readonly, nonatomic) NSString *startTime;
@property (readonly, nonatomic) NSString *endTime;
@property (readonly, nonatomic) NSString *image;
@property (readonly, nonatomic) NSString *endImage;
@property (readonly, nonatomic) NSString *eventName;
@property (readonly, nonatomic) NSString *identifier;
@property (nonatomic) NSString *status;
@property (readonly, nonatomic) NSString *displayStatus;

- (instancetype)initWithJson:(NSDictionary *)json;
- (void)updateEventWithJson:(NSDictionary *)updatedJson;
@end
