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
@property (readonly, nonatomic) NSString *celebrityURL;
@property (readonly, nonatomic) NSDate *startTime;
@property (readonly, nonatomic) NSDate *endTime;
@property (readonly, nonatomic) NSString *image;
@property (readonly, nonatomic) NSString *endImage;
@property (readonly, nonatomic) NSString *eventName;
@property (readonly, nonatomic) NSString *fanURL;
@property (readonly, nonatomic) NSString *hostURL;
@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *status;

- (instancetype)initWithJson:(NSDictionary *)json;
@end
