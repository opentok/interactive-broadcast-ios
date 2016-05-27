//
//  Event.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBEvent.h"

@implementation IBEvent

- (instancetype)initWithJson:(NSDictionary *)json {
    if (!json) return nil;
    
    if (self = [super init]) {
        
        if (json[@"admins_id"]) {
            _adminId = [json[@"admins_id"] integerValue];
        }
        _celebrityURL = json[@"celebrity_url"];
        
        if (json[@"date_time_start"]) {
            
        }
        
        if (json[@"date_time_end"]) {
            
        }
        
        if (json[@"event_image"]) {
            
        }
        
        if (json[@"event_image_end"]) {
            
        }
        
        _eventName = json[@"event_name"];
        _fanURL = json[@"fan_url"];
        _hostURL = json[@"host_url"];
        _identifier = json[@"id"];
        _status = json[@"status"];
    }
    return self;
}

@end
