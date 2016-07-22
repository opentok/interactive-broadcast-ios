//
//  Event.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBEvent.h"
#import "IBDateFormatter.h"

@interface IBEvent()
@property (nonatomic) NSString *displayStatus;
@end

@implementation IBEvent

- (NSString *)displayStatus {
    if (!_status) return nil;
    
    if ([_status isEqualToString:@"N"]) {
        
        if (!_startTime) return nil;
        
        if (_startTime && ![_startTime isEqual:[NSNull null]]) {
            return [IBDateFormatter convertToAppStandardFromDateString:_startTime];
        }
        else{
            return @"Not Started";
        }
    }
    
    if([_status isEqualToString:@"P"]){
        return @"Not Started";
    }
    
    if([_status isEqualToString:@"L"]){
        return @"Live";
    }
    
    if([_status isEqualToString:@"C"]){
        return @"Closed";
    }
    
    return nil;
}

- (instancetype)initWithJson:(NSDictionary *)json {
    if (!json) return nil;
    
    if (self = [super init]) {
        
        if (json[@"admins_id"]) {
            _adminId = [json[@"admins_id"] integerValue];
            _adminName = json[@"admins_name"];
        }
        _celebrityURL = json[@"celebrity_url"];
        _fanURL = json[@"fan_url"];
        _hostURL = json[@"host_url"];
        
        _startTime = json[@"date_time_start"];
        _endTime = json[@"date_time_end"];
        _image = json[@"event_image"];
        _endImage = json[@"event_image_end"];
        _eventName = json[@"event_name"];
        _fanURL = json[@"fan_url"];
        _hostURL = json[@"host_url"];
        _identifier = json[@"id"];
        _status = json[@"status"];
    }
    return self;
}

- (void)updateEventWithJson:(NSDictionary *)updatedJson {
    if (!updatedJson) return;
    
    _status = updatedJson[@"newStatus"];
}

@end
