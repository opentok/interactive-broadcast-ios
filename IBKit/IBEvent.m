//
//  Event.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBEvent.h"
#import "IBEvent_Internal.h"
#import "IBDateFormatter.h"

@interface IBEvent()
@property (nonatomic) NSString *descriptiveStatus;
@end

@implementation IBEvent

- (NSString *)descriptiveStatus {
    if (!_status) return nil;
    
    if ([_status isEqualToString:@"N"]) {
        
        if (!_startTime) return nil;
        
        if (_startTime && ![_startTime isEqual:[NSNull null]]) {
            return [IBDateFormatter convertToAppStandardFromDate:_startTime];
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
        
        _identifier = json[@"id"];
        
        _adminId = json[@"adminId"];
        
        _celebrityURL = json[@"celebrityUrl"];
        _fanURL = json[@"fanUrl"];
        _hostURL = json[@"hostUrl"];
        
        if (json[@"dateTimeStart"]) {
            _startTime = [IBDateFormatter convertFromBackendDateString:json[@"dateTimeStart"]];
        }
        
        if (json[@"dateTimeEnd"]) {
            _endTime = [IBDateFormatter convertFromBackendDateString:json[@"dateTimeEnd"]];
        }
        
        if (json[@"startImage"]) {
            _image = json[@"startImage"][@"url"];
        }
        
        if (json[@"endImage"]) {
            _endImage = json[@"endImage"][@"url"];
        }
        
        _name = json[@"name"];
        
        _status = json[@"status"];
        
        _apiKey = json[@"apiKey"];
        _onstageSession = json[@"stageSessionId"];
        _onstageToken = json[@"stageToken"];
        _backstageSession = json[@"sessionId"];
        _backstageToken = json[@"backstageToken"];
    }
    return self;
}

- (void)updateEventWithJson:(NSDictionary *)updatedJson {
    if (!updatedJson) return;
    
    _status = updatedJson[@"newStatus"];
}

@end
