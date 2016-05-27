//
//  EventInstance.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBInstance.h"

@implementation IBInstance

- (instancetype)initWithJson:(NSDictionary *)json {
    if (!json) return nil;
    
    if (self = [super init]) {
        
        _defaultEventImage = json[@"default_event_image"];
        
        if (json[@"enable_analytics"]) {
            _isAnalyticsEnabled = [json[@"enable_analytics"] boolValue];
        }
        
        if (json[@"enable_getinline"]) {
            _isGetInLineEnabled = [json[@"enable_getinline"] boolValue];
        }
        
        if (json[@"events"]) {
            NSArray *eventsJson = json[@"events"];
            NSMutableArray *events = [NSMutableArray array];
            for (NSDictionary *eventJson in eventsJson) {
                IBEvent *event = [[IBEvent alloc] initWithJson:eventJson];
                [events addObject:event];
            }
            _events = events;
        }
        
        _frontendURL = json[@"frontend_url"];
        _instanceId = json[@"instance_id"];
        _signalingURL = json[@"signaling_url"];
    }
    return self;
}

@end
