//
//  EventInstance.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBInstance.h"
#import "IBInstance_Internal.h"

#import "IBEvent_Internal.h"

@implementation IBInstance

- (instancetype)initWithJson:(NSDictionary *)json {
    if (!json) return nil;
    
    if (self = [super init]) {
        
        _defaultEventImagePath = json[@"default_event_image"];
//        
//        if (json[@"enable_analytics"]) {
//            _isAnalyticsEnabled = [json[@"enable_analytics"] boolValue];
//        }
//        
//        if (json[@"enable_getinline"]) {
//            _isGetInLineEnabled = [json[@"enable_getinline"] boolValue];
//        }
        
        if (json[@"events"]) {
            NSArray *eventsJson = json[@"events"];
            NSMutableArray *events = [NSMutableArray array];
            for (NSDictionary *eventJson in eventsJson) {
                IBEvent *event = [[IBEvent alloc] initWithJson:eventJson];
                [events addObject:event];
            }
            _events = [events copy];
            events = nil;
        }
        
        if (json[@"event"]) {
            _events = @[[[IBEvent alloc] initWithJson:json[@"event"]]];
        }
        
        _frontendURL = json[@"frontend_url"];
        _instanceId = json[@"instance_id"];
        _signalingURL = json[@"signaling_url"];
        
        if (json[@"apiKey"]) {
            _apiKey = [NSString stringWithFormat:@"%ld", (unsigned long)[json[@"apiKey"] integerValue]];
        }
        _sessionIdHost = json[@"sessionIdHost"];
        _tokenHost = json[@"tokenHost"];
        _sessionIdProducer = json[@"sessionIdProducer"];
        _tokenProducer = json[@"tokenProducer"];
    }
    return self;
}

@end
