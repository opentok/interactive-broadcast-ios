//
//  EventInstance.h
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBEvent.h"

@interface IBInstance : NSObject
@property (readonly, nonatomic) NSString *defaultEventImage;
@property (readonly, nonatomic) BOOL isAnalyticsEnabled;
@property (readonly, nonatomic) BOOL isGetInLineEnabled;
@property (readonly, nonatomic) NSArray<IBEvent *> * events;
@property (readonly, nonatomic) NSString *frontendURL;
@property (readonly, nonatomic) NSString *instanceId;
@property (readonly, nonatomic) NSString *signalingURL;
- (instancetype)initWithJson:(NSDictionary *)json;
@end
